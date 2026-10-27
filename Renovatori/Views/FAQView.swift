import SwiftUI

/// "ხ.დ.კ." screen: every question from `GET /faq`, answers expand one at a time.
struct FAQView: View {
    @State private var state: Loadable<[FAQItem]> = .loading

    var body: some View {
        content
            .navigationTitle("ხ.დ.კ.")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error) { await load() }
        case .loaded(let items):
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(FAQAccordion.title)
                            .font(.largeTitle.bold())
                        Text(FAQAccordion.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    FAQAccordion(items: items)
                }
                .padding()
            }
            .refreshable { await load() }
        }
    }

    private func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    private func load() async {
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

#Preview {
    NavigationStack {
        FAQView()
    }
}
