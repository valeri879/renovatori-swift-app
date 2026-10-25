import SwiftUI

/// "ხშირად დასმული კითხვები": disclosure groups where only one answer is open at a time.
struct FAQSection: View {
    /// The first question starts expanded, as on the site.
    @State private var expandedID: FAQItem.ID? = MainPageData.faqs.first?.id

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ხშირად დასმული კითხვები",
                subtitle: "კითხვები, რომლებსაც ყველაზე ხშირად გვისვამენ ჩვენი მომხმარებლები"
            )

            if MainPageData.faqs.isEmpty {
                ContentUnavailableView("FAQ ინფორმაცია ცარიელია.", systemImage: "questionmark.circle")
            } else {
                GroupBox {
                    VStack(spacing: 12) {
                        ForEach(Array(MainPageData.faqs.enumerated()), id: \.element.id) { index, item in
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
        .padding(.horizontal)
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
