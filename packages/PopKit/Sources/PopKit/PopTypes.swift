import Foundation
import PopCoreBinding

/// Clean Swift 6 value types exposed by `PopKit` over Rust `PopCoreFFI`.
public enum PopKitRuntime {
    /// Absolute path of the current host executable, used by `pop-runner`'s in-process
    /// evaluator for renderer/font freshness checks (never spawned as a child process).
    public static var defaultExecutablePath: String {
        Bundle.main.executablePath
            ?? CommandLine.arguments.first.map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            ?? "/usr/bin/env"
    }

    public static var coreBuildID: String {
        coreBuildId()
    }
}

public enum PopError: Error, LocalizedError, Sendable, Equatable {
    case failure(kind: String, message: String, code: String?)

    public var errorDescription: String? {
        switch self {
        case .failure(_, let message, _): return message
        }
    }

    static func wrap(_ error: Error) -> PopError {
        if let pop = error as? PopError { return pop }
        if let core = error as? CoreError {
            switch core {
            case .Failure(let failure):
                return .failure(
                    kind: String(describing: failure.kind),
                    message: failure.message,
                    code: failure.reason.map { String(describing: $0) }
                )
            }
        }
        return .failure(kind: "Failed", message: error.localizedDescription, code: nil)
    }

    static func wrap(_ failure: OwnerFailure) -> PopError {
        .failure(
            kind: String(describing: failure.kind),
            message: failure.message,
            code: failure.reason.map { String(describing: $0) }
        )
    }
}

public enum PopStoreMode: Sendable, Equatable {
    case document
    case snapshot

    var ffi: StoreMode {
        switch self {
        case .document: .document
        case .snapshot: .snapshot
        }
    }
}

public enum PopFileKind: Sendable, Equatable {
    case template
    case document

    init(_ kind: FileKind) {
        switch kind {
        case .template: self = .template
        case .document: self = .document
        }
    }
}

public enum PopArtworkKind: Sendable, Equatable {
    case preview
    case icon

    var ffi: Artwork {
        switch self {
        case .preview: .preview
        case .icon: .icon
        }
    }

    init(_ artwork: Artwork) {
        switch artwork {
        case .preview: self = .preview
        case .icon: self = .icon
        }
    }
}

public enum PopEditOrigin: Sendable, Equatable {
    case page
    case window
    case agent

    var ffi: EditOrigin {
        switch self {
        case .page: .page
        case .window: .window
        case .agent: .agent
        }
    }
}

public struct PopCommandDescriptor: Sendable, Equatable, Identifiable {
    public var id: String { name }
    public let name: String
    public let description: String
    public let argsSchemaJSON: String

    public init(name: String, description: String, argsSchemaJSON: String) {
        self.name = name
        self.description = description
        self.argsSchemaJSON = argsSchemaJSON
    }

    init(_ spec: CommandSpec) {
        self.name = spec.name
        self.description = spec.description
        self.argsSchemaJSON = spec.argsSchemaJson
    }
}

public struct PopAppMetadata: Sendable, Equatable {
    public let documentID: String?
    public let kind: PopFileKind
    public let slug: String
    public let title: String
    public let description: String
    public let authorName: String
    public let authorURL: String?
    public let commands: [PopCommandDescriptor]
    public let themeDefaults: [String: String]
    public let hasIconView: Bool
    public let hasPreviewView: Bool
    public let windowWidth: Int
    public let windowHeight: Int
    public let descriptorJSON: String
    public let byteCount: UInt64

    init(_ opened: OpenedFile) {
        self.documentID = opened.documentId
        self.kind = PopFileKind(opened.kind)
        self.slug = opened.app.metadata.slug
        self.title = opened.app.metadata.title
        self.description = opened.app.metadata.description
        self.authorName = opened.app.metadata.author.name
        self.authorURL = opened.app.metadata.author.url
        self.commands = opened.app.commands.map(PopCommandDescriptor.init)
        var defaults: [String: String] = [:]
        for token in opened.app.theme {
            defaults[token.name] = token.value
        }
        self.themeDefaults = defaults
        self.hasIconView = opened.app.views.icon
        self.hasPreviewView = opened.app.views.preview
        self.windowWidth = Int(opened.app.window.width)
        self.windowHeight = Int(opened.app.window.height)
        self.descriptorJSON = opened.app.descriptorJson
        self.byteCount = opened.byteCount
    }
}

public struct PopThemeState: Sendable, Equatable {
    public let defaults: [String: String]
    public let overrides: [String: String]
    public let effective: [String: String]

    public init(defaults: [String: String], overrides: [String: String], effective: [String: String]) {
        self.defaults = defaults
        self.overrides = overrides
        self.effective = effective
    }

    init(_ state: ThemeState) {
        self.defaults = state.defaults
        self.overrides = state.overrides
        self.effective = state.effective
    }
}

public struct PopCommandResult: Sendable, Equatable {
    public let sequence: UInt64
    public let ids: [String]
    public let resultJSON: String

    init(_ result: OwnerCommandResult) {
        self.sequence = result.sequence
        self.ids = result.ids
        self.resultJSON = result.resultJson
    }
}

public struct PopCapturedArtwork: Sendable, Equatable {
    public let sourceVersion: String
    public let previewPNG: Data?
    public let iconPNG: Data?

    init(_ captured: CapturedArtwork) {
        self.sourceVersion = captured.sourceVersion
        self.previewPNG = captured.preview
        self.iconPNG = captured.icon
    }
}

public enum PopSaveStatus: Sendable, Equatable {
    case saved
    case saving
    case failed

    init(_ status: OwnerSaveStatus) {
        switch status {
        case .saved: self = .saved
        case .saving: self = .saving
        case .failed: self = .failed
        }
    }
}

public enum PopDocumentEvent: Sendable, Equatable {
    case publication(json: String)
    case saveStatus(PopSaveStatus, shared: Bool)
    case undoState(canUndo: Bool, canRedo: Bool)
    case themeChanged
}
