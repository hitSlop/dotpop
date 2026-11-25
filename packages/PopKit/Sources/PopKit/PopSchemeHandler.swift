import Foundation
import PopCoreBinding
import WebKit

/// Serves `.pop` package assets (`/assets/...`) and attachments (`/attachments/...`)
/// over a custom `WKURLSchemeHandler` (e.g. `pop://app/...`) with strict CSP headers
/// computed by `pop-contracts`.
public final class PopSchemeHandler: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    private let reader: ResourceReader

    init(reader: ResourceReader) {
        self.reader = reader
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
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

        do {
            guard let info = try reader.info(route: route, key: key) else {
                let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didFinish()
                return
            }
            let rangeHeader = urlSchemeTask.request.value(forHTTPHeaderField: "Range")
            let plan = resourceResponse(info: info, route: route, range: rangeHeader)
            let body: Data
            if let span = plan.span {
                body = (try reader.readRange(route: route, key: key, offset: span.offset, length: span.length)) ?? Data()
            } else {
                body = Data()
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: Int(plan.status),
                httpVersion: "HTTP/1.1",
                headerFields: plan.headers
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
