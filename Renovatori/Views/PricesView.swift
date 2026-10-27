import SwiftUI

/// "ფასები" screen (`views/pages/prices-page/prices-page.pug`), built from standard SwiftUI components.
struct PricesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("რემონტის ფასები")
                        .font(.largeTitle.bold())
                    Text("ქვემოთ მოცემულია რემონტის საშუალო ფასები, რომლებიც მოიცავს თეთრი, შავი და მწვანე კარკასის სამუშაოებს.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                estimateNotice

                PriceComparison(expandsAllCategories: true)
            }
            .padding()
        }
        .navigationTitle("ფასები")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The site's warning alert: prices are indicative, with a shortcut to the calculator.
    private var estimateNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("მოცემული ფასები არის საორიენტაციო. საბოლოო ღირებულება განისაზღვრება ინდივიდუალურად — მომხმარებლის მოთხოვნებისა და ობიექტის თავისებურებების გათვალისწინებით.")
                    .font(.footnote)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            NavigationLink(value: AppRoute.calculator) {
                Label("გამოიყენეთ კალკულატორი", systemImage: "plus.forwardslash.minus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        PricesView()
    }
}
