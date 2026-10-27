import SwiftUI

/// "კარკასული რემონტის ფასები" on the main page.
struct PricesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "კარკასული რემონტის ფასები",
                subtitle: "ჩვენ გთავაზობთ სრულ სარემონტო მომსახურებას მაქსიმალურად მისაღები ფასებით."
            )
            PriceComparison()
        }
        .padding(.horizontal)
    }
}

/// `price-list.component.pug`: package comparison with a collapsible group per work category.
struct PriceComparison: View {
    /// The main page opens only the first category; the prices screen opens all of them.
    var expandsAllCategories = false

    private let columnWidth: CGFloat = 64

    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                packageHeader
                Divider()
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    CategoryGroup(
                        category: category,
                        columnWidth: columnWidth,
                        startsExpanded: expandsAllCategories || index == 0
                    )
                    if index < categories.count - 1 {
                        Divider()
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("პაკეტების შედარება")
                    .font(.headline)
                Text("აირჩიეთ თქვენთვის სასურველი კარკასის პაკეტი სერვისების მიხედვით.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
        }
    }

    private var packageHeader: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text("ოპცია")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(MainPageData.pricePackages) { package in
                Link(destination: package.url) {
                    VStack(spacing: 2) {
                        Text(package.shortTitle)
                            .font(.caption.bold())
                        Text("\(package.pricePerSquareMeter) ₾/მ²")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: columnWidth)
            }
        }
    }

    /// Splits the flat table rows into categories with their options.
    private var categories: [PriceCategory] {
        var result: [PriceCategory] = []
        for row in MainPageData.priceRows {
            switch row {
            case .category(let title):
                result.append(PriceCategory(title: title, options: []))
            case .option(let title, let included):
                result[result.count - 1].options.append(PriceOption(title: title, included: included))
            }
        }
        return result
    }
}

private struct PriceCategory {
    let title: String
    var options: [PriceOption]
}

private struct PriceOption {
    let title: String
    let included: [Bool]
}

private struct CategoryGroup: View {
    let category: PriceCategory
    let columnWidth: CGFloat
    @State private var isExpanded: Bool

    init(category: PriceCategory, columnWidth: CGFloat, startsExpanded: Bool) {
        self.category = category
        self.columnWidth = columnWidth
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                ForEach(category.options, id: \.title) { option in
                    HStack(spacing: 0) {
                        Text(option.title)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Array(option.included.enumerated()), id: \.offset) { _, isIncluded in
                            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(isIncluded ? .green : .red)
                                .frame(width: columnWidth)
                                .accessibilityLabel(isIncluded ? "შედის" : "არ შედის")
                        }
                    }
                }
            }
            .padding(.top, 10)
        } label: {
            Text(category.title)
                .font(.subheadline.bold())
        }
        .tint(.primary)
    }
}
