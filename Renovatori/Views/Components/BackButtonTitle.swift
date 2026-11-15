import SwiftUI
import UIKit

extension View {
    /// The back button text on screens opened from this one. Without it the system shows this
    /// screen's title, and when that doesn't fit next to the next screen's title, the English "Back".
    func backButtonTitle(_ title: String) -> some View {
        background(BackButtonTitle(title: title).frame(width: 0, height: 0))
    }
}

/// SwiftUI has no API for this, so it is set on the `navigationItem` of the controller that holds
/// this screen in the navigation stack, before anything is pushed on top of it.
private struct BackButtonTitle: UIViewControllerRepresentable {
    let title: String

    func makeUIViewController(context: Context) -> Controller {
        Controller(backTitle: title)
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.backTitle = title
        controller.apply()
    }

    final class Controller: UIViewController {
        var backTitle: String

        init(backTitle: String) {
            self.backTitle = backTitle
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            apply()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        func apply() {
            // The screen's controller is the ancestor that sits directly in the navigation stack.
            var screen: UIViewController? = self
            while let current = screen, !(current.parent is UINavigationController) {
                screen = current.parent
            }
            screen?.navigationItem.backButtonTitle = backTitle
        }
    }
}
