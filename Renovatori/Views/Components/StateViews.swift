import SwiftUI

/// Full-screen error with a retry button; a 404 shows a "not found" message instead.
struct ErrorStateView: View {
    let error: APIError
    var notFoundTitle = "ვერ მოიძებნა"
    let retry: () async -> Void

    var body: some View {
        if error.isNotFound {
            ContentUnavailableView(
                notFoundTitle,
                systemImage: "magnifyingglass",
                description: Text(error.message)
            )
        } else {
            ContentUnavailableView {
                Label("ჩატვირთვა ვერ მოხერხდა", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("თავიდან ცდა") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// Spinner shown in the footer of a list while the next page loads.
struct PageLoadingFooter: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding()
    }
}
