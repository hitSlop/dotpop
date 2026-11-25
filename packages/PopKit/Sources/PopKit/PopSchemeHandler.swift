import Foundation
import PopCoreBinding
import WebKit

/// Serves `.pop` package assets (`/assets/...`), attachments (`/attachments/...`), and
/// optionally the bundled page shell (`/` + `/__shell__/...`) over a custom `WKURLSchemeHandler`
/// (`pop://app/...`) with strict CSP headers computed by `pop-contracts`.
public final class PopSchemeHandler: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    #if os(iOS)
    private static let viewport = "width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover"
    #else
    private static let viewport = "width=device-width,initial-scale=1,viewport-fit=cover"
    #endif

    private static let visiblePage = Data(
        "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"\(viewport)\"><title>pop</title></head><body><script type=\"module\" src=\"/__shell__/boot.js\"></script></body></html>"
            .utf8
    )

    private static let csp = appResourcePolicy()

    private let reader: ResourceReader
    private let shellDirectory: URL?

    init(reader: ResourceReader, shellDirectory: URL? = nil) {
        self.reader = reader
        self.shellDirectory = shellDirectory
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        let rangeHeader = urlSchemeTask.request.value(forHTTPHeaderField: "Range")
        let isHead = urlSchemeTask.request.httpMethod == "HEAD"

        do {
            // Serve the page shell root document (`/`) when a shell directory is provided.
            if shellDirectory != nil, url.path == "/" || url.path.isEmpty {
                let info = ResourceInfo(size: UInt64(Self.visiblePage.count), mediaType: "text/html; charset=utf-8")
                let plan = resourceResponse(info: info, route: .app, range: nil)
                var headers = plan.headers
                headers["Content-Security-Policy"] = Self.csp
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: Int(plan.status),
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                urlSchemeTask.didReceive(response)
                if !isHead {
                    urlSchemeTask.didReceive(Self.visiblePage)
                }
                urlSchemeTask.didFinish()
                return
            }

            // Serve bundled page shell assets (`/__shell__/boot.js`, `/__shell__/index.js`).
            if let shellDir = shellDirectory, url.path.hasPrefix("/__shell__/") {
                let key = String(url.path.dropFirst("/__shell__/".count))
                guard validAssetPath(path: key) else {
                    urlSchemeTask.didFailWithError(URLError(.noPermissionsToReadFile))
                    return
                }
                let base = shellDir.standardizedFileURL
                let file = base.appendingPathComponent(key).standardizedFileURL
                guard file.path.hasPrefix(base.path + "/"), let data = try? Data(contentsOf: file) else {
                    let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didFinish()
                    return
                }
                let info = ResourceInfo(size: UInt64(data.count), mediaType: contentType(path: key))
                let plan = resourceResponse(info: info, route: .app, range: rangeHeader)
                var headers = plan.headers
                headers["Content-Security-Policy"] = Self.csp
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: Int(plan.status),
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                urlSchemeTask.didReceive(response)
                if !isHead, let span = plan.span {
                    let start = Int(span.offset)
                    let end = min(data.count, start + Int(span.length))
                    if start < end {
                        urlSchemeTask.didReceive(data.subdata(in: start..<end))
                    }
                }
                urlSchemeTask.didFinish()
                return
            }

            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let route: ResourceRoute
            let key: String
            if path.hasPrefix("attachments/") {
                route = .attachment
                key = String(path.dropFirst("attachments/".count))
            } else if path.hasPrefix("assets/") {
                route = .app
                key = String(path.dropFirst("assets/".count))
            } else {
                route = .app
                key = path
            }

            guard validAssetPath(path: key), let info = try reader.info(route: route, key: key) else {
                let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didFinish()
                return
            }
            let plan = resourceResponse(info: info, route: route, range: rangeHeader)
            var headers = plan.headers
            if route == .app {
                headers["Content-Security-Policy"] = Self.csp
            }
            let body: Data
            if !isHead, let span = plan.span {
                body = (try reader.readRange(route: route, key: key, offset: span.offset, length: span.length)) ?? Data()
            } else {
                body = Data()
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: Int(plan.status),
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            urlSchemeTask.didReceive(response)
            if !body.isEmpty {
                urlSchemeTask.didReceive(body)
            }
            urlSchemeTask.didFinish()
        } catch {
            urlSchemeTask.didFailWithError(error)
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}
