import SwiftUI
import UIKit
import WebKit

/// Converts simple HTML from the CMS (FAQ answers) into styled text.
/// Keeps bold, italic, links and line breaks; drops the HTML's own fonts and colors
/// so the text follows Dynamic Type and dark mode.
enum HTMLText {
    @MainActor
    static func attributedString(from html: String) -> AttributedString {
        let data = Data(html.utf8)
        guard let parsed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) else {
            return AttributedString(html)
        }

        var result = AttributedString()
        parsed.enumerateAttributes(in: NSRange(location: 0, length: parsed.length)) { attributes, range, _ in
            var run = AttributedString(parsed.attributedSubstring(from: range).string)
            let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            var font = Font.subheadline
            if traits.contains(.traitBold) {
                font = font.bold()
            }
            if traits.contains(.traitItalic) {
                font = font.italic()
            }
            run.font = font
            if let link = attributes[.link] as? URL {
                run.link = link
            } else if let link = (attributes[.link] as? String).flatMap(URL.init(string:)) {
                run.link = link
            }
            result += run
        }

        // The HTML parser ends every paragraph with a newline, including the last.
        while let last = result.characters.last, last.isNewline || last == " " {
            result.characters.removeLast()
        }
        return result
    }
}

/// Renders a blog post's HTML body with WebKit, so images, lists and headings look like the site.
/// Grows to fit its content. Links to renovatori.ge pages the app has open those screens;
/// other links open outside the app.
struct HTMLContentView: View {
    let html: String
    @Environment(\.appNavigation) private var navigation
    @State private var height: CGFloat = 1

    var body: some View {
        HTMLWebView(html: html, height: $height, openRoute: navigation.open)
            .frame(height: height)
    }
}

private struct HTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat
    let openRoute: (AppRoute) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link, .phoneNumber]
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.openRoute = openRoute
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        // Relative `/uploads/...` images resolve against the API origin.
        webView.loadHTMLString(Self.document(body: html), baseURL: APIConfig.origin)
    }

    private static func document(body: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          :root { color-scheme: light dark; }
          html, body { margin: 0; padding: 0; background: transparent; }
          body { font: -apple-system-body; line-height: 1.55; overflow-wrap: break-word; }
          body > :first-child { margin-top: 0; }
          body > :last-child { margin-bottom: 0; }
          img, video, iframe { max-width: 100%; height: auto; border-radius: 10px; }
          table { display: block; max-width: 100%; overflow-x: auto; border-collapse: collapse; }
          td, th { border: 1px solid rgba(128,128,128,.35); padding: 4px 6px; }
          h1, h2, h3, h4 { line-height: 1.3; }
          a { color: -apple-system-blue; }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedHTML: String?
        var openRoute: (AppRoute) -> Void = { _ in }
        private let height: Binding<CGFloat>

        init(height: Binding<CGFloat>) {
            self.height = height
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            measure(webView)
            // Images can finish loading after `didFinish`; measure again once they settle.
            Task { @MainActor [weak webView] in
                for delay in [0.3, 1.0, 2.5] {
                    try? await Task.sleep(for: .seconds(delay))
                    guard let webView else { return }
                    measure(webView)
                }
            }
        }

        private func measure(_ webView: WKWebView) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { [height] value, _ in
                guard let newHeight = value as? CGFloat, newHeight > 0 else { return }
                Task { @MainActor in
                    if abs(height.wrappedValue - newHeight) > 1 {
                        height.wrappedValue = newHeight
                    }
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            // The initial `loadHTMLString` is `.other`; a tapped site link opens its in-app screen,
            // anything else opens in Safari / the dialer.
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                if let route = AppRoute(siteURL: url) {
                    openRoute(route)
                } else {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
