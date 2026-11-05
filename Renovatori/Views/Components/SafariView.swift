import SafariServices
import SwiftUI

/// An external page open in the in-app browser.
struct WebPage: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The system in-app browser. It only accepts `http` and `https` URLs.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
