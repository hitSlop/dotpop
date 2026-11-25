import Foundation
import PopCoreBinding

/// Stateless file-level `.pop` operations: inspect, create from template, duplicate,
/// read stored artwork, execute closed commands headlessly (`rquickjs`), and render
/// fresh `Icon.svelte` / `Preview.svelte` PNGs via in-process Takumi.
public enum PopLibrary {
    /// Reads full validated metadata, declared `commands.ts` specs, and theme defaults.
    public static func inspect(at url: URL) throws -> PopAppMetadata {
        do {
            return PopAppMetadata(try openFile(path: url.path))
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Reads the document's kind (`template` or `document`) from header checks alone.
    public static func fileKind(at url: URL) throws -> PopFileKind {
        do {
            return PopFileKind(try PopCoreBinding.fileKind(path: url.path))
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Reads the first available embedded artwork PNG (`icon` or `preview`).
    public static func artwork(
        at url: URL,
        preferred: [PopArtworkKind] = [.icon, .preview]
    ) throws -> (kind: PopArtworkKind, png: Data)? {
        do {
            guard let image = try fileArtwork(path: url.path, preferred: preferred.map(\.ffi)) else {
                return nil
            }
            return (PopArtworkKind(image.name), image.png)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Creates a new independent `.pop` document from a template (never overwrites an existing file).
    public static func createDocument(fromTemplate templateURL: URL, to destinationURL: URL) throws {
        do {
            try PopCoreBinding.createDocument(template: templateURL.path, destination: destinationURL.path)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Duplicates an existing `.pop` document with a fresh identity and independent state.
    public static func duplicateDocument(from sourceURL: URL, to destinationURL: URL) throws {
        do {
            try importDocument(source: sourceURL.path, destination: destinationURL.path)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Deletes a closed `.pop` document safely under its writer lock.
    public static func deleteDocument(at url: URL) throws {
        do {
            try PopCoreBinding.deleteDocument(path: url.path)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Runs an authored `commands.ts` command headlessly against a closed `.pop` document
    /// using bounded in-process `rquickjs` (16 MiB heap, 512 KiB stack, 250 ms timeout),
    /// commits atomically to Loro, flushes to SQLite, and releases the writer lock.
    public static func runClosedCommand(
        at url: URL,
        name: String,
        argsJSON: String = "{}",
        executablePath: String = PopKitRuntime.defaultExecutablePath
    ) throws -> PopCommandResult {
        do {
            let result = try PopCoreBinding.runClosedCommand(
                path: url.path,
                name: name,
                argsJson: argsJSON,
                executablePath: executablePath
            )
            return PopCommandResult(result)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Renders fresh `Preview.svelte` and `Icon.svelte` 512×512 PNGs from the saved `.pop`
    /// state using in-process Takumi (works identically on iOS and macOS, zero WebKit).
    public static func renderArtwork(
        at url: URL,
        executablePath: String = PopKitRuntime.defaultExecutablePath
    ) throws -> PopCapturedArtwork {
        do {
            let runtime = try CaptureRuntime.inProcess(executablePath: executablePath)
            let captured = try runtime.renderArtwork(path: url.path)
            return PopCapturedArtwork(captured)
        } catch {
            throw PopError.wrap(error)
        }
    }

    /// Configures an isolated writer-lock registry folder (useful for unit tests).
    public static func useRegistryFolder(_ url: URL) throws {
        do {
            try PopCoreBinding.useRegistryFolder(path: url.path)
        } catch {
            throw PopError.wrap(error)
        }
    }
}
