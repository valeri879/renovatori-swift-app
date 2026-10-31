import SwiftUI

/// Native expense table. Compact widths combine the other columns into the first
/// column, while wider layouts show amounts, dates, comments and photos separately.
struct ExpenseTableView: View {
    let items: [ExpenseDetail.Item]
    let canManage: Bool
    let deletingID: String?
    let edit: (ExpenseDetail.Item) -> Void
    let delete: (ExpenseDetail.Item) -> Void
    let openImages: (ExpenseDetail.Item) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var tableHeight: CGFloat = 120

    private var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        let rows = ExpenseTableRow.makeRows(from: items)

        ContentSizedTable(height: $tableHeight) {
            Table(rows) {
                TableColumn("ხარჯის ტიპი") { row in
                    primaryCell(row)
                }
                .width(min: 160, ideal: 220)

                TableColumn("თანხა") { row in
                    amount(row)
                }
                .width(min: 100, ideal: 120)

                TableColumn("თარიღი") { row in
                    Text(row.day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .width(min: 90, ideal: 110)

                TableColumn("კომენტარი") { row in
                    Text(row.item?.comment ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .width(min: 120, ideal: 200)

                TableColumn("სურათები") { row in
                    if let item = row.item, !item.images.isEmpty {
                        photos(item)
                    }
                }
                .width(80)
            }
            .tableStyle(.inset)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
        }
        .frame(height: tableHeight)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .padding(4)
    }

    /// Keeps the essential fields visible when Table hides the remaining columns on iPhone.
    private func primaryCell(_ row: ExpenseTableRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(row.item.map { "#\(row.number ?? 0) · \($0.typeTitle)" } ?? "დღის ჯამი:")
                    .font(.subheadline.weight(row.isSubtotal ? .bold : .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCompact {
                    amount(row)
                }
                if canManage, let item = row.item {
                    actions(item)
                }
            }

            if isCompact {
                HStack {
                    Text(row.day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let item = row.item, !item.images.isEmpty {
                        photos(item)
                    }
                }
                if let item = row.item, !item.comment.isEmpty {
                    Text(item.comment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func amount(_ row: ExpenseTableRow) -> some View {
        Text(row.amount.webMoney(fractionDigits: 2))
            .font(.subheadline.weight(row.isSubtotal ? .bold : .semibold))
            .monospacedDigit()
            .foregroundStyle(.red)
            .fixedSize(horizontal: true, vertical: false)
    }

    /// Opens all of the row's photos in the existing full-screen image viewer.
    private func photos(_ item: ExpenseDetail.Item) -> some View {
        Button {
            openImages(item)
        } label: {
            Label("\(item.images.count)", systemImage: "photo")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("სურათების ნახვა: \(item.images.count)")
    }

    /// Administrative actions remain available without relying on List-only swipe gestures.
    @ViewBuilder
    private func actions(_ item: ExpenseDetail.Item) -> some View {
        if deletingID == item.id {
            ProgressView()
                .controlSize(.small)
        } else {
            Menu {
                Button("რედაქტირება", systemImage: "pencil") { edit(item) }
                Button("წაშლა", systemImage: "trash", role: .destructive) { delete(item) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .padding(4)
            }
            .accessibilityLabel("ხარჯის მოქმედებები: \(item.typeTitle)")
        }
    }
}
