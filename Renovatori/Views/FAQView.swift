import SwiftUI

/// "ხ.დ.კ." screen: every question from `GET /faq`, answers expand one at a time.
struct FAQView: View {
    @StateObject private var model = FAQViewModel()

    var body: some View {
        content
            .navigationTitle("ხ.დ.კ.")
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error) { await model.load() }
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
            .refreshable { await model.load() }
        }
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}
