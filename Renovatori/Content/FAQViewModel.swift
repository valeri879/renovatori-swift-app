import Foundation

/// Loads `GET /faq` and converts HTML answers for both the home section and the FAQ screen.
@MainActor
final class FAQViewModel: ObservableObject {
    @Published private(set) var state: Loadable<[FAQItem]> = .loading

    /// Keeps the loaded questions when returning to the view.
    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    /// Fetches the latest questions for initial loading, refresh and retry.
    func load() async {
        do {
            let entries: [FAQEntry] = try await APIClient.shared.send(Endpoint(method: .get, path: "faq"))
            state = .loaded(entries.map { entry in
                FAQItem(id: entry.id, question: entry.title, answer: HTMLText.attributedString(from: entry.description))
            })
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }
}
