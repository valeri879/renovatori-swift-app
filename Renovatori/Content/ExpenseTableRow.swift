import Foundation

/// A numbered expense or the subtotal following a day's visible expenses.
struct ExpenseTableRow: Identifiable {
    let id: String
    let item: ExpenseDetail.Item?
    let number: Int?
    let day: String
    let amount: Double

    var isSubtotal: Bool { item == nil }

    /// Preserves the API's date order and numbers only expenses. Filter before calling
    /// so each day's subtotal contains exactly the expenses currently shown.
    static func makeRows(from items: [ExpenseDetail.Item]) -> [ExpenseTableRow] {
        var result: [ExpenseTableRow] = []
        var dayTotal = 0.0

        for (index, item) in items.enumerated() {
            let day = item.expenseDate.map {
                $0.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
            } ?? "-"
            result.append(ExpenseTableRow(
                id: "expense-\(item.id)", item: item, number: index + 1,
                day: day, amount: item.amount
            ))
            dayTotal += item.amount

            let nextDay = index + 1 < items.count ? items[index + 1].expenseDate.map {
                $0.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
            } ?? "-" : nil

            // End each displayed date group with a subtotal, including the final group.
            if day != nextDay {
                result.append(ExpenseTableRow(
                    id: "subtotal-\(item.id)", item: nil, number: nil,
                    day: day, amount: dayTotal
                ))
                dayTotal = 0
            }
        }

        return result
    }
}
