import SwiftUI

/// Card in `GET /admin/expenses` (`serializeExpenseCard` on the backend).
struct ExpenseCard: Decodable, Identifiable, Hashable {
    struct Progress: Decodable, Hashable {
        /// Share of the planned duration that has passed, 0–100.
        let percent: Int
        let label: String
        /// False when the dates are missing or invalid.
        let isValid: Bool
    }

    let id: String
    let projectName: String
    let projectStatus: String
    let totalAmount: Double
    let totalExpenses: Double
    let remainingAmount: Double
    /// `totalAmount − remainingAmount − totalExpenses`, computed by the server.
    let currentAmount: Double
    let startDate: Date?
    let endDate: Date?
    let progress: Progress
    let createdAt: Date?

    var status: ExpenseStatus { ExpenseStatus(rawValue: projectStatus) }
}

struct ExpenseStatusesResponse: Decodable {
    let statuses: [String]
}

struct ExpenseDeleteResponse: Decodable {
    let deleted: Bool
}

/// A project status from `expenseStatuses` on the backend, with the site's emoji and colors.
/// Unknown values are kept as-is so a new status on the server never breaks the list.
struct ExpenseStatus: Hashable {
    let rawValue: String

    init(rawValue: String) {
        // Legacy records use "დაწყებული"; the web shows them as "დასაწყები".
        self.rawValue = rawValue == "დაწყებული" ? "დასაწყები" : rawValue
    }

    var emoji: String {
        switch rawValue {
        case "დასაწყები": "🚀"
        case "მიმდინარე": "🔄"
        case "დასრულებული": "✅"
        case "შეწყვეტილი": "⛔"
        default: ""
        }
    }

    var title: String {
        emoji.isEmpty ? rawValue : "\(emoji) \(rawValue)"
    }

    var color: Color {
        switch rawValue {
        case "დასაწყები": .blue
        case "მიმდინარე": .cyan
        case "დასრულებული": .green
        case "შეწყვეტილი": .red
        default: .gray
        }
    }
}

// MARK: Detail

/// `GET /admin/expenses/:id` → `{ expense }` (`serializeExpenseDetail` on the backend).
struct ExpenseDetail: Decodable, Identifiable, Hashable {
    struct TypeSummary: Decodable, Hashable, Identifiable {
        let title: String
        let amount: Double
        let percent: Double
        var id: String { title }
    }

    struct PaidAmount: Decodable, Hashable, Identifiable {
        let id: String
        let paidAmount: Double
        let paidAmountDollar: Double
        let paidAt: Date?
        let comment: String
    }

    struct Item: Decodable, Hashable, Identifiable {
        struct ExpenseType: Decodable, Hashable {
            let id: String
            let title: String
        }

        struct Image: Decodable, Hashable {
            /// Relative paths; build URLs with `APIConfig.imageURL`.
            let url: String
            let thumbUrl: String
        }

        let id: String
        let expenseType: ExpenseType?
        let expenseDate: Date?
        let amount: Double
        let comment: String
        let images: [Image]

        /// Title used to group and filter rows, matching the web's "ტიპი არ არის მითითებული".
        var typeTitle: String { expenseType?.title ?? ExpenseDetail.untypedTitle }
    }

    struct Permissions: Decodable, Hashable {
        /// Admin (moderators only read).
        let canManage: Bool
        /// Admin and the project is „მიმდინარე".
        let canAddEntries: Bool
    }

    static let untypedTitle = "ტიპი არ არის მითითებული"

    let id: String
    let projectName: String
    let projectStatus: String
    let projectAddress: String
    let publicProjectId: String?
    let clientId: String?
    let clientName: String
    let clientPhone: String
    let clientEmail: String
    let area: Double
    let totalAmount: Double
    let totalAmountDollar: Double
    let pricePerSquareArea: Double
    let pricePerSquareAreaDollar: Double
    let remainingAmount: Double
    let remainingAmountDollar: Double
    let totalExpenses: Double
    let totalProfit: Double
    let totalPaidAmount: Double
    let totalPaidAmountDollar: Double
    /// Payments received minus money spent (as on the web detail page).
    let currentAmount: Double
    let startDate: Date?
    let endDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let progress: ExpenseCard.Progress
    let expenseTypeSummary: [TypeSummary]
    let paidAmounts: [PaidAmount]
    let expenses: [Item]
    let permissions: Permissions

    var status: ExpenseStatus { ExpenseStatus(rawValue: projectStatus) }
}

struct ExpenseDetailResponse: Decodable {
    let expense: ExpenseDetail
}

struct ExpenseTypeOption: Decodable, Hashable, Identifiable {
    let id: String
    let title: String
}

struct ExpenseTypesResponse: Decodable {
    let expenseTypes: [ExpenseTypeOption]
}

/// Body of `POST /admin/expenses/:id/paid-amounts`.
struct PaidAmountRequest: Encodable {
    let paidAmount: Double
    let paidAmountDollar: Double?
    /// `YYYY-MM-DD`.
    let paidAt: String
    let comment: String
    let sendTelegramNotification: Bool
    let sendClientEmail: Bool
}

struct PaidAmountResponse: Decodable {
    let expense: ExpenseDetail
    let clientEmailSent: Bool
}

extension Double {
    /// Same output as the web's `formatMoney`: spaces between thousands and a dot before
    /// decimals (`2 250 ₾`, `4 450.5 ₾`, `2 850.00 ₾`, `$1 850.00`). Without `fractionDigits`
    /// decimals appear only when the value has them. The `ka_GE` locale would skip grouping
    /// below 10 000.
    func webMoney(fractionDigits: Int? = nil, currency: String = "₾") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = " "
        formatter.groupingSize = 3
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = fractionDigits ?? 0
        formatter.maximumFractionDigits = fractionDigits ?? 3
        let number = formatter.string(from: NSNumber(value: self)) ?? String(self)
        // The web puts `$` before the number and `₾` after it.
        return currency == "$" ? "$\(number)" : "\(number) \(currency)"
    }
}

extension DateFormatter {
    /// `YYYY-MM-DD` in the user's calendar day, matching the web's date inputs.
    static let apiDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
