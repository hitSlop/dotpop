// swift-tools-version: 6.0
import PackageDescription

/// Standalone, zero-external-dependency SwiftPM package for `.pop` documents.
/// Embeds Loro CRDT state, SQLite `.pop` persistence, bounded in-process `rquickjs`
/// `commands.ts` evaluation, Takumi PNG icon/preview rendering, and `pop://` WebKit hosting.
let package = Package(
    name: "PopKit",
    platforms: [.macOS(.v15), .iOS("26.0")],
    products: [
        .library(name: "PopKit", targets: ["PopKit"]),
        .library(name: "PopCoreBinding", targets: ["PopCoreBinding"]),
    ],
    targets: [
        .binaryTarget(
            name: "PopCoreFFI",
            path: "Generated/PopCoreFFI.xcframework"
        ),
        // UniFFI's generated callback vtables predate Swift 6 strict concurrency checking.
        .target(
            name: "PopCoreBinding",
            dependencies: ["PopCoreFFI"],
            path: "Generated/PopCoreBinding",
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .target(
            name: "PopKit",
            dependencies: ["PopCoreBinding"],
            linkerSettings: [.linkedFramework("WebKit")]
        ),
        .testTarget(
            name: "PopKitTests",
            dependencies: ["PopKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
