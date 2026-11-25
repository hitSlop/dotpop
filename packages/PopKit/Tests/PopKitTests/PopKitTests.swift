import CryptoKit
import Foundation
import Testing
@testable import PopKit

@Suite("PopKit End-to-End")
struct PopKitTests {
    private func repoTemplatesDir() -> URL {
        // packages/PopKit/Tests/PopKitTests/PopKitTests.swift -> repo root -> generated/templates
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("generated/templates", isDirectory: true)
    }

    private func makeTempWorkspace() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("popkit-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let registry = dir.appendingPathComponent("registry", isDirectory: true)
        try FileManager.default.createDirectory(at: registry, withIntermediateDirectories: true)
        try PopLibrary.useRegistryFolder(registry)
        return dir
    }

    @Test("Inspect template, create, duplicate, run headless & live commands, undo, theme overrides, and Takumi icon capture")
    func fullLifecycle() async throws {
        let templates = repoTemplatesDir()
        let templateURL = templates.appendingPathComponent("small-expenses.pop")
        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            Issue.record("Missing template fixture at \(templateURL.path)")
            return
        }

        let workDir = try makeTempWorkspace()
        defer { try? FileManager.default.removeItem(at: workDir) }

        // 1. Inspect template metadata & declared commands directly from Rust
        let templateMeta = try PopLibrary.inspect(at: templateURL)
        #expect(templateMeta.kind == .template)
        #expect(templateMeta.slug == "small-expenses")
        let commandNames = Set(templateMeta.commands.map(\.name))
        #expect(commandNames.contains("addItem"))
        #expect(commandNames.contains("settleItem"))
        #expect(commandNames.contains("removeItem"))

        // 2. Create a new document from template
        let docURL = workDir.appendingPathComponent("trip-expenses.pop")
        try PopLibrary.createDocument(fromTemplate: templateURL, to: docURL)
        let docMeta = try PopLibrary.inspect(at: docURL)
        #expect(docMeta.kind == .document)
        #expect(docMeta.documentID != nil)

        // 3. Duplicate document -> fresh independent UUID
        let copyURL = workDir.appendingPathComponent("trip-expenses-copy.pop")
        try PopLibrary.duplicateDocument(from: docURL, to: copyURL)
        let copyMeta = try PopLibrary.inspect(at: copyURL)
        #expect(copyMeta.documentID != nil)
        #expect(copyMeta.documentID != docMeta.documentID)

        // 4. Headless closed-file command via bounded in-process rquickjs (zero WebKit!)
        let closedResult = try PopLibrary.runClosedCommand(
            at: docURL,
            name: "addItem",
            argsJSON: #"{"merchant":"Matcha latte","amountMinor":650,"note":"morning"}"#
        )
        #expect(closedResult.sequence > 0)
        #expect(closedResult.resultJSON.contains("id"))

        // 5. Open live PopDocument, verify persisted state, run live command + undo + theme overrides
        let doc = try PopDocument.open(at: docURL)
        let stateAfterClosed = try await doc.stateJSON()
        #expect(stateAfterClosed.contains("Matcha latte"))

        let liveResult = try await doc.runCommand(
            "addItem",
            argsJSON: #"{"merchant":"Tahoe dinner","amountMinor":8460}"#
        )
        #expect(liveResult.sequence >= 1)
        let stateAfterLive = try await doc.stateJSON()
        #expect(stateAfterLive.contains("Tahoe dinner"))

        // Loro undo removes the second item cleanly
        _ = try await doc.undo()
        let stateAfterUndo = try await doc.stateJSON()
        #expect(!stateAfterUndo.contains("Tahoe dinner"))
        #expect(stateAfterUndo.contains("Matcha latte"))

        // Theme overrides persist via Loro ThemeChange (lowercase #rrggbb)
        let themeBefore = try await doc.theme()
        if let firstToken = themeBefore.defaults.keys.sorted().first {
            try await doc.setThemeOverrides([firstToken: "#e91e63"])
            let themeAfter = try await doc.theme()
            #expect(themeAfter.overrides[firstToken] == "#e91e63")
            #expect(themeAfter.effective[firstToken] == "#e91e63")

            try await doc.resetThemeOverrides()
            let themeReset = try await doc.theme()
            #expect(themeReset.overrides.isEmpty)
        }

        // 6. Takumi in-process Icon.svelte & Preview.svelte re-render on save!
        let captured = try await doc.refreshArtworkWithTakumi()
        #expect(captured.iconPNG != nil)
        #expect((captured.iconPNG?.count ?? 0) > 100)
        #expect(captured.iconPNG?.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47])) // PNG magic bytes

        try await doc.close()
    }

    @Test("PopDeviceIdentity mints valid RFC 8037 EdDSA JWTs verifiable with the embedded pk: public key")
    func eddsaDeviceIdentityTokenRoundTrip() throws {
        let identity = PopDeviceIdentity.ephemeral()
        #expect(identity.accountID.hasPrefix("pk:"))
        let pubPart = String(identity.accountID.dropFirst(3))
        #expect(pubPart.count == 43)

        let jwt = try identity.mintBearerToken(ttlSeconds: 300)
        let parts = jwt.split(separator: ".").map(String.init)
        #expect(parts.count == 3)

        // Verify signature directly with the embedded public key
        func decodeB64URL(_ s: String) -> Data? {
            var base = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            while base.count % 4 != 0 { base.append("=") }
            return Data(base64Encoded: base)
        }
        let pubBytes = try #require(decodeB64URL(pubPart))
        let sigBytes = try #require(decodeB64URL(parts[2]))
        let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: pubBytes)
        let signingInput = Data("\(parts[0]).\(parts[1])".utf8)
        #expect(pubKey.isValidSignature(sigBytes, for: signingInput))
    }
}
