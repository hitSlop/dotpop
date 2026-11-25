import Foundation
import PopCoreBinding

/// Live collaboration status for a single `.pop` document.
public struct PopCollaborationInfo: Sendable, Equatable {
    public let documentID: String
    public let link: String?
    public let isLive: Bool
    public let isOwner: Bool
    public let phase: String
    public let detail: String

    public init(
        documentID: String,
        link: String?,
        isLive: Bool,
        isOwner: Bool,
        phase: String,
        detail: String
    ) {
        self.documentID = documentID
        self.link = link
        self.isLive = isLive
        self.isOwner = isOwner
        self.phase = phase
        self.detail = detail
    }
}

/// Zero-config, one-way live collaboration client for `.pop` documents over `NativeLibrary`.
///
/// Defaults to `PopDeviceIdentity.shared` (self-issued `EdDSA` JWT backed by Apple Keychain,
/// automatically syncing across a user's Apple devices via iCloud Keychain) so **any** app
/// importing `PopKit` gets live collaboration on `share.dotpop.click` with zero login walls,
/// zero hardcoded app allowlists, and zero third-party auth SDKs.
public final class PopCloudSession: @unchecked Sendable {
    public typealias TokenProvider = @Sendable () async throws -> String

    public let rootDirectory: URL
    public let accountID: String

    private let library: NativeLibrary
    private let tokenProvider: TokenProvider

    public init(
        rootDirectory: URL,
        identity: PopDeviceIdentity = .shared
    ) throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let acct = identity.accountID
        self.rootDirectory = rootDirectory
        self.accountID = acct
        self.tokenProvider = { try identity.mintBearerToken() }
        do {
            self.library = try NativeLibrary.open(root: rootDirectory.path, account: acct)
        } catch {
            throw PopError.wrap(error)
        }
    }

    public init(
        rootDirectory: URL,
        accountID: String,
        tokenProvider: @escaping TokenProvider
    ) throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        self.rootDirectory = rootDirectory
        self.accountID = accountID
        self.tokenProvider = tokenProvider
        do {
            self.library = try NativeLibrary.open(root: rootDirectory.path, account: accountID)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Registers a live open `PopDocument` with the sync engine so local and remote Loro edits
    /// replicate in real time while the document is open.
    public func register(document: PopDocument) throws {
        do {
            try library.registerOwner(owner: document.rawOwner)
        } catch {
            throw PopError.wrap(error)
        }
    }

    public func unregister(documentID: String) throws {
        do {
            try library.unregisterOwner(id: documentID)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// One-way promotion of a local `.pop` document into a live collaborative room on
    /// `share.dotpop.click`. Returns the shareable invite link immediately.
    public func enableCollaboration(
        documentURL: URL,
        title: String,
        openDocument: PopDocument? = nil
    ) async throws -> PopCollaborationInfo {
        let token = try await tokenProvider()
        let acct = accountID
        let lib = library
        let path = documentURL.path
        let rawOwner = openDocument?.rawOwner

        return try await Task.detached(priority: .medium) {
            do {
                let existingEntries = try lib.entries()
                let entry: LibraryEntry
                if let matched = existingEntries.first(where: { $0.path == path || $0.id == openDocument?.metadata.documentID }) {
                    entry = matched
                } else {
                    entry = try lib.adopt(source: path, title: title)
                }

                if let rawOwner {
                    try? lib.registerOwner(owner: rawOwner)
                }

                if entry.localOnly {
                    _ = try lib.enableSync(account: acct, id: entry.id, token: token)
                }
                let access = try lib.sharing(account: acct, id: entry.id, enabled: true, token: token)
                let link = try sharingLink(access: access)
                return PopCollaborationInfo(
                    documentID: access.document,
                    link: link,
                    isLive: access.sharing,
                    isOwner: access.role == .owner,
                    phase: "live",
                    detail: "Anyone with the link can edit together."
                )
            } catch {
                throw PopError.wrap(error)
            }
        }.value
    }

    /// Joins an existing collaborative `.pop` room from a `share.dotpop.click` link and downloads
    /// the local synced `.pop` file ready to open in `PopDocument`.
    public func joinCollaboration(link: String) async throws -> URL {
        let token = try await tokenProvider()
        let acct = accountID
        let lib = library
        return try await Task.detached(priority: .medium) {
            do {
                let entry = try lib.join(account: acct, link: link, token: token)
                return URL(fileURLWithPath: entry.path)
            } catch {
                throw PopError.wrap(error)
            }
        }.value
    }

    /// Fetches the current collaboration state & invite link for a document if already synced.
    public func refreshStatus(documentID: String) async throws -> PopCollaborationInfo? {
        let entries = (try? library.entries()) ?? []
        guard let entry = entries.first(where: { $0.id == documentID }), !entry.localOnly else {
            return nil
        }
        let token = try await tokenProvider()
        let acct = accountID
        let lib = library
        return try await Task.detached(priority: .medium) {
            do {
                let access = try lib.access(account: acct, id: documentID, token: token)
                let link = try sharingLink(access: access)
                return PopCollaborationInfo(
                    documentID: access.document,
                    link: link,
                    isLive: access.sharing,
                    isOwner: access.role == .owner,
                    phase: String(describing: entry.phase),
                    detail: entry.detail
                )
            } catch {
                throw PopError.wrap(error)
            }
        }.value
    }

    /// Triggers an immediate sync cycle across all collaborative documents in this session.
    public func syncNow() async throws {
        let token = try await tokenProvider()
        let acct = accountID
        let lib = library
        try await Task.detached(priority: .utility) {
            do {
                try lib.sync(account: acct, token: token)
            } catch {
                throw PopError.wrap(error)
            }
        }.value
    }

    /// Creates an independent, local-only copy of a collaborative document (the clean alternative
    /// to revoking/un-sharing in one-way collaboration).
    public func duplicatePrivateCopy(documentID: String, title: String) throws -> URL {
        do {
            let copy = try library.localCopy(id: documentID, title: title)
            return URL(fileURLWithPath: copy.path)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Checks whether a URL looks like a dotpop live collaboration link.
    public static func isCollaborationLink(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == "dotpop" { return true }
        if url.host?.lowercased() == "share.dotpop.click" { return true }
        return (try? sharingDocument(link: url.absoluteString)) != nil
    }
}
