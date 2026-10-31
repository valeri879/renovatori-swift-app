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
/// `#section` links scroll the surrounding `ScrollView` to that section; other links open
/// outside the app.
struct HTMLContentView: View {
    let html: String
    @Environment(\.appNavigation) private var navigation
    @State private var height: CGFloat = 1
    /// Distance of the last requested section from the top of the content.
    @State private var anchorOffset: CGFloat = 0

    private static let anchorID = "html-content-anchor"

    var body: some View {
        ScrollViewReader { proxy in
            HTMLWebView(html: html, height: $height, openRoute: navigation.open) { offset in
                anchorOffset = offset
                // The marker has to move first; `scrollTo` reads its laid-out position.
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(Self.anchorID, anchor: .top)
                    }
                }
            }
            .frame(height: height)
            .overlay(alignment: .top) {
                Color.clear
                    .frame(height: 1)
                    .id(Self.anchorID)
                    .padding(.top, anchorOffset)
            }
        }
    }
}

private struct HTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat
    let openRoute: (AppRoute) -> Void
    let scrollToOffset: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link, .phoneNumber]
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.openRoute = openRoute
        context.coordinator.scrollToOffset = scrollToOffset
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.load(html, in: webView)
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
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var loadedHTML: String?
        var openRoute: (AppRoute) -> Void = { _ in }
        var scrollToOffset: (CGFloat) -> Void = { _ in }
        private let height: Binding<CGFloat>

        init(height: Binding<CGFloat>) {
            self.height = height
        }

        func load(_ html: String, in webView: WKWebView) {
            loadedHTML = html
            // Relative `/uploads/...` images resolve against the API origin.
            webView.loadHTMLString(HTMLWebView.document(body: html), baseURL: APIConfig.origin)
        }

        /// iOS can end the web process of an app left in the background, which blanks the view.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            guard let loadedHTML else { return }
            load(loadedHTML, in: webView)
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

        /// The section a link points at, when it stays on the loaded document (`href="#floor"`).
        private func sectionName(of url: URL, in webView: WKWebView) -> String? {
            guard let fragment = url.fragment(percentEncoded: false), !fragment.isEmpty,
                  let current = webView.url,
                  url.absoluteString.split(separator: "#").first == current.absoluteString.split(separator: "#").first
            else { return nil }
            return fragment
        }

        /// Web view scrolling is off, so the section's position goes to the enclosing `ScrollView`.
        /// CMS anchors are written both as `<a id>` and as `<a name>`.
        private func scrollToSection(_ name: String, in webView: WKWebView) {
            let script = """
                const target = document.getElementById(name) ?? document.getElementsByName(name)[0];
                return target ? target.getBoundingClientRect().top + window.scrollY : null;
                """
            webView.callAsyncJavaScript(script, arguments: ["name": name], in: nil, in: .page) { [weak self] result in
                guard case .success(let value) = result, let offset = value as? CGFloat else { return }
                self?.scrollToOffset(offset)
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            // A section link would otherwise reach the external branch below as a link to the site root.
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               let section = sectionName(of: url, in: webView) {
                scrollToSection(section, in: webView)
                decisionHandler(.cancel)
            // Route site pages before checking the navigation type: new-window links and
            // scripted navigations can arrive as `.other`. The initial HTML load has no route.
            } else if let url = navigationAction.request.url, let route = AppRoute(siteURL: url) {
                openRoute(route)
                decisionHandler(.cancel)
            } else if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        /// Handles links requesting a new window (`target="_blank"` or `window.open`).
        /// Site pages use native navigation; external destinations use the system browser.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                if let route = AppRoute(siteURL: url) {
                    openRoute(route)
                } else {
                    UIApplication.shared.open(url)
                }
            }
            return nil
        }
    }
}
