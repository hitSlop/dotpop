import Foundation
import PopCoreBinding

/// Swift 6 async/await handle for a live `.pop` document backed by Rust `NativeOwner`.
/// Supports Loro CRDT state, live bounded `rquickjs` `commands.ts`, undo/redo, theme
/// overrides, Takumi icon re-rendering on save, and `pop://` WebKit asset serving.
public final class PopDocument: @unchecked Sendable {
    public let url: URL
    public let metadata: PopAppMetadata
    public let events: AsyncStream<PopDocumentEvent>

    private let owner: NativeOwner
    private let executablePath: String
    private let continuation: AsyncStream<PopDocumentEvent>.Continuation

    private init(
        url: URL,
        owner: NativeOwner,
        executablePath: String,
        events: AsyncStream<PopDocumentEvent>,
        continuation: AsyncStream<PopDocumentEvent>.Continuation
    ) {
        self.url = url
        self.owner = owner
        self.executablePath = executablePath
        self.metadata = PopAppMetadata(owner.app())
        self.events = events
        self.continuation = continuation
    }

    deinit {
        continuation.finish()
    }

    /// Opens a `.pop` document with bounded in-process `rquickjs` command & Takumi capture support.
    public static func open(
        at url: URL,
        mode: PopStoreMode = .document,
        executablePath: String = PopKitRuntime.defaultExecutablePath
    ) throws -> PopDocument {
        var capturedContinuation: AsyncStream<PopDocumentEvent>.Continuation!
        let stream = AsyncStream<PopDocumentEvent> { continuation in
            capturedContinuation = continuation
        }
        let listener = ListenerBox(continuation: capturedContinuation)
        do {
            let owner = try NativeOwner.openInProcess(
                path: url.path,
                mode: mode.ffi,
                executablePath: executablePath,
                listener: listener
            )
            return PopDocument(
                url: url,
                owner: owner,
                executablePath: executablePath,
                events: stream,
                continuation: capturedContinuation
            )
        } catch {
            capturedContinuation.finish()
            throw PopError.wrap(error)
        }
    }

    public func stateJSON() async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            owner.state(completion: StringBox(cont))
        }
    }

    public func runCommand(
        _ name: String,
        argsJSON: String = "{}",
        origin: PopEditOrigin = .agent
    ) async throws -> PopCommandResult {
        let raw: OwnerCommandResult = try await withCheckedThrowingContinuation { cont in
            owner.runCommand(name: name, argsJson: argsJSON, origin: origin.ffi, completion: CommandBox(cont))
        }
        return PopCommandResult(raw)
    }

    public func undo() async throws -> UInt64 {
        let applied: OwnerApplied = try await withCheckedThrowingContinuation { cont in
            owner.undo(completion: AppliedBox(cont))
        }
        return applied.sequence
    }

    public func redo() async throws -> UInt64 {
        let applied: OwnerApplied = try await withCheckedThrowingContinuation { cont in
            owner.redo(completion: AppliedBox(cont))
        }
        return applied.sequence
    }

    public func theme() async throws -> PopThemeState {
        let theme: OwnerTheme = try await withCheckedThrowingContinuation { cont in
            owner.theme(completion: ThemeBox(cont))
        }
        return PopThemeState(theme.state)
    }

    @discardableResult
    public func setThemeOverrides(_ values: [String: String]) async throws -> UInt64 {
        let applied: OwnerApplied = try await withCheckedThrowingContinuation { cont in
            owner.changeTheme(change: .set(values: values), completion: AppliedBox(cont))
        }
        return applied.sequence
    }

    @discardableResult
    public func resetThemeOverrides() async throws -> UInt64 {
        let applied: OwnerApplied = try await withCheckedThrowingContinuation { cont in
            owner.changeTheme(change: .resetAll, completion: AppliedBox(cont))
        }
        return applied.sequence
    }

    public func artwork(_ kind: PopArtworkKind) async throws -> Data? {
        try await withCheckedThrowingContinuation { cont in
            owner.artwork(name: kind.ffi, completion: BytesBox(cont))
        }
    }

    public func setArtwork(sourceVersion: String, preview: Data?, icon: Data?) async throws {
        try await withCheckedThrowingContinuation { cont in
            owner.setArtwork(
                sourceVersion: sourceVersion,
                preview: preview,
                icon: icon,
                completion: UnitBox(cont)
            )
        }
    }

    /// Flushes live Loro state to a temporary snapshot, re-renders `Icon.svelte` + `Preview.svelte`
    /// via in-process Takumi, and persists the updated PNGs back into the `.pop` file.
    public func refreshArtworkWithTakumi() async throws -> PopCapturedArtwork {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("popkit-capture-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let snapshotURL = tempDir.appendingPathComponent("source.pop")

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            owner.captureSource(destination: snapshotURL.path, completion: UnitBox(cont))
        }

        let execPath = executablePath
        let captured = try await Task.detached(priority: .utility) {
            try PopLibrary.renderArtwork(at: snapshotURL, executablePath: execPath)
        }.value

        try await setArtwork(
            sourceVersion: captured.sourceVersion,
            preview: captured.previewPNG,
            icon: captured.iconPNG
        )
        return captured
    }

    public func flush() async throws {
        try await withCheckedThrowingContinuation { cont in
            owner.flush(completion: UnitBox(cont))
        }
    }

    public func close(preview: Data? = nil, icon: Data? = nil) async throws {
        try await withCheckedThrowingContinuation { cont in
            owner.close(preview: preview, icon: icon, completion: UnitBox(cont))
        }
        continuation.finish()
    }

    /// Dispatches a raw page bridge JSON request from a mounted WebView.
    public func dispatchPageRequest(_ json: String, viewID: String) async -> PageDispatch {
        await withCheckedContinuation { cont in
            owner.page(json: json, view: viewID, completion: PageBox(cont))
        }
    }

    public func attachView(_ viewID: String) {
        owner.attach(view: viewID)
    }

    @MainActor
    public func makeSchemeHandler() throws -> PopSchemeHandler {
        do {
            let reader = try owner.resourceReader()
            return PopSchemeHandler(reader: reader)
        } catch {
            throw PopError.wrap(error)
        }
    }
}

// MARK: - UniFFI Callback Adapters

private final class ListenerBox: OwnerListener, @unchecked Sendable {
    let continuation: AsyncStream<PopDocumentEvent>.Continuation
    init(continuation: AsyncStream<PopDocumentEvent>.Continuation) {
        self.continuation = continuation
    }

    func event(event: OwnerEvent) {
        switch event {
        case .publication(let json):
            continuation.yield(.publication(json: json))
        case .saveStatus(let status, _, _, let shared):
            continuation.yield(.saveStatus(PopSaveStatus(status), shared: shared))
        case .undoState(let canUndo, let canRedo):
            continuation.yield(.undoState(canUndo: canUndo, canRedo: canRedo))
        case .themeChanged:
            continuation.yield(.themeChanged)
        }
    }
}

private final class UnitBox: OwnerUnitCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<Void, Error>
    init(_ cont: CheckedContinuation<Void, Error>) { self.cont = cont }
    func complete() { cont.resume() }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class StringBox: OwnerStringCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<String, Error>
    init(_ cont: CheckedContinuation<String, Error>) { self.cont = cont }
    func complete(value: String) { cont.resume(returning: value) }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class AppliedBox: OwnerAppliedCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<OwnerApplied, Error>
    init(_ cont: CheckedContinuation<OwnerApplied, Error>) { self.cont = cont }
    func complete(value: OwnerApplied) { cont.resume(returning: value) }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class CommandBox: OwnerCommandCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<OwnerCommandResult, Error>
    init(_ cont: CheckedContinuation<OwnerCommandResult, Error>) { self.cont = cont }
    func complete(value: OwnerCommandResult) { cont.resume(returning: value) }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class ThemeBox: OwnerThemeCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<OwnerTheme, Error>
    init(_ cont: CheckedContinuation<OwnerTheme, Error>) { self.cont = cont }
    func complete(value: OwnerTheme) { cont.resume(returning: value) }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class BytesBox: OwnerBytesCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<Data?, Error>
    init(_ cont: CheckedContinuation<Data?, Error>) { self.cont = cont }
    func complete(value: Data?) { cont.resume(returning: value) }
    func failed(failure: OwnerFailure) { cont.resume(throwing: PopError.wrap(failure)) }
}

private final class PageBox: PageCompletion, @unchecked Sendable {
    let cont: CheckedContinuation<PageDispatch, Never>
    init(_ cont: CheckedContinuation<PageDispatch, Never>) { self.cont = cont }
    func complete(reply: PageDispatch) { cont.resume(returning: reply) }
}
