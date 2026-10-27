import SwiftUI

/// "ხშირად დასმული კითხვები" on the main page.
struct FAQSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: FAQAccordion.title,
                subtitle: FAQAccordion.subtitle
            )
            FAQAccordion()

            NavigationLink(value: AppRoute.faq) {
                Label("ყველა კითხვის ნახვა", systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
}

/// `faq.component.pug`: disclosure groups where only one answer is open at a time.
struct FAQAccordion: View {
    static let title = "ხშირად დასმული კითხვები"
    static let subtitle = "კითხვები, რომლებსაც ყველაზე ხშირად გვისვამენ ჩვენი მომხმარებლები"

    let items: [FAQItem]
    /// The first question starts expanded, as on the site.
    @State private var expandedID: FAQItem.ID?

    init(items: [FAQItem] = MainPageData.faqs) {
        self.items = items
        _expandedID = State(initialValue: items.first?.id)
    }

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("FAQ ინფორმაცია ცარიელია.", systemImage: "questionmark.circle")
        } else {
            GroupBox {
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider()
                        }
                        DisclosureGroup(isExpanded: binding(for: item)) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        } label: {
                            Text(item.question)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .tint(.primary)
                    }
                }
            }
        }
    }

    private func binding(for item: FAQItem) -> Binding<Bool> {
        Binding {
            expandedID == item.id
        } set: { isExpanded in
            withAnimation {
                expandedID = isExpanded ? item.id : nil
            }
        }
    }
}
