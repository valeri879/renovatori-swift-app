import SwiftUI
import UIKit

/// Gives a native Table its full content height inside an already scrolling page.
/// The hosting controller isolates the table's scroll view from the surrounding List.
struct ContentSizedTable<Content: View>: UIViewControllerRepresentable {
    @Binding var height: CGFloat
    @ViewBuilder let content: Content

    func makeUIViewController(context: Context) -> ContentSizedTableController {
        let controller = ContentSizedTableController(rootView: AnyView(content.environment(\.self, context.environment)))
        controller.onHeightChange = { measuredHeight in
            if abs(height - measuredHeight) > 0.5 {
                height = measuredHeight
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: ContentSizedTableController, context: Context) {
        controller.rootView = AnyView(content.environment(\.self, context.environment))
        controller.view.setNeedsLayout()
    }
}

/// Measures the table's UIKit content size, including native row spacing and headers.
final class ContentSizedTableController: UIHostingController<AnyView> {
    var onHeightChange: (CGFloat) -> Void = { _ in }

    private weak var tableScrollView: UIScrollView?
    private var contentSizeObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let scrollView = findScrollView(in: view), scrollView !== tableScrollView {
            tableScrollView = scrollView
            scrollView.isScrollEnabled = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            contentSizeObservation = scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    self?.reportHeight()
                }
            }
        }

        // Publish after layout rather than changing SwiftUI state during a view update.
        Task { @MainActor [weak self] in
            self?.reportHeight()
        }
    }

    /// Searches only the hosted table, so the outer page remains scrollable.
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for child in view.subviews {
            if let scrollView = findScrollView(in: child) {
                return scrollView
            }
        }
        return nil
    }

    private func reportHeight() {
        guard let tableScrollView else { return }
        let insets = tableScrollView.adjustedContentInset
        let headerHeight = max(0, view.bounds.height - tableScrollView.bounds.height)
        let height = ceil(tableScrollView.contentSize.height + insets.top + insets.bottom + headerHeight)
        guard height.isFinite, height > 0 else { return }
        onHeightChange(height)
    }
}
