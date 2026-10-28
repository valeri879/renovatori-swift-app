import Foundation

// Models for the public content endpoints (`/projects`, `/blog`, `/faq`).
// Image fields keep the relative path from the API; build URLs with `APIConfig.imageURL`.

/// Card in `GET /projects`.
struct ProjectSummary: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let metaTitle: String
    let metaDescription: String
    let location: String
    let area: Double?
    let startDate: Date?
    let endDate: Date?
    let coverImageUrl: String?
    /// Nil from backends that send only `updatedAt` on cards.
    let createdAt: Date?
    let updatedAt: Date?
    /// Staff lists include drafts; nil from backends that list only published projects.
    let isPublished: Bool?
}

/// `GET /projects/:id` → `{ project }`.
struct ProjectDetail: Decodable, Identifiable, Hashable {
    struct Image: Decodable, Hashable {
        let url: String
        let thumbUrl: String
    }

    let id: String
    let title: String
    let description: String
    let metaTitle: String
    let metaDescription: String
    let location: String
    let area: Double?
    let startDate: Date?
    let endDate: Date?
    let images: [Image]
    let createdAt: Date?
    let updatedAt: Date?
    /// Sent only by the backend version with viewer extras; nil means published.
    let isPublished: Bool?
    /// Linked client account; prefills the history form's client id.
    let clientId: String?
}

/// `GET /projects/:id` → `{ project, access, client, financialSummary, history }`. A signed-in request
/// adds what the web project page shows that user; guests (and older backends) get only `project`.
struct ProjectDetailResponse: Decodable {
    struct Access: Decodable, Hashable {
        /// Admins, moderators and the linked client: dates, client contact, finances.
        let canViewClientInfo: Bool
        /// Admins and the linked client.
        let canViewHistory: Bool
        /// Admins: add, edit and delete history entries.
        let canManage: Bool

        static let guest = Access(canViewClientInfo: false, canViewHistory: false, canManage: false)
    }

    struct Client: Decodable, Hashable {
        let firstName: String
        let lastName: String
        let email: String
        let phoneNumber: String
    }

    /// The expense project linked to this public project and client, in dollars (as on the web).
    struct FinancialSummary: Decodable, Hashable {
        struct Payment: Decodable, Hashable, Identifiable {
            let id: String
            let paidAmountDollar: Double
            let paidAt: Date?
        }

        let totalAmountDollar: Double
        let remainingAmountDollar: Double
        let totalPaidAmountDollar: Double
        let paidAmounts: [Payment]
        let progress: ExpenseCard.Progress
    }

    let project: ProjectDetail
    let access: Access
    let client: Client?
    let financialSummary: FinancialSummary?
    let history: [ProjectHistoryEntry]

    private enum CodingKeys: String, CodingKey {
        case project, access, client, financialSummary, history
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        project = try container.decode(ProjectDetail.self, forKey: .project)
        access = try container.decodeIfPresent(Access.self, forKey: .access) ?? .guest
        client = try container.decodeIfPresent(Client.self, forKey: .client)
        financialSummary = try container.decodeIfPresent(FinancialSummary.self, forKey: .financialSummary)
        history = try container.decodeIfPresent([ProjectHistoryEntry].self, forKey: .history) ?? []
    }
}

/// One "პროექტის ისტორია" entry (`serializeProjectHistory` on the backend).
struct ProjectHistoryEntry: Decodable, Hashable, Identifiable {
    let id: String
    let comment: String
    let timestamp: Date?
    /// The client the entry is addressed to; the client sees only their own entries.
    let clientId: String?
    let images: [ProjectDetail.Image]
}

/// `POST /admin/projects/:id/history`, `PUT` / `DELETE /admin/project-history/:id` → every entry of the project.
struct ProjectHistoryResponse: Decodable {
    let history: [ProjectHistoryEntry]
    /// Absent on delete.
    let clientEmailSent: Bool?
}

/// Card in `GET /blog`.
struct BlogSummary: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let metaTitle: String
    let metaDescription: String
    let coverImageUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
}

/// `GET /blog/:id` → `{ blog }`. `description` is HTML.
struct BlogDetail: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let metaTitle: String
    let metaDescription: String
    let coverImageUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
}

/// `GET /blog/:id` → `{ blog, latestBlogs, latestProjects }`, like the web blog page. Older backends send only `blog`.
struct BlogDetailResponse: Decodable {
    let blog: BlogDetail
    /// The 3 latest other published posts.
    let latestBlogs: [BlogSummary]
    /// The 3 latest published projects.
    let latestProjects: [ProjectSummary]

    private enum CodingKeys: String, CodingKey {
        case blog, latestBlogs, latestProjects
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blog = try container.decode(BlogDetail.self, forKey: .blog)
        latestBlogs = try container.decodeIfPresent([BlogSummary].self, forKey: .latestBlogs) ?? []
        latestProjects = try container.decodeIfPresent([ProjectSummary].self, forKey: .latestProjects) ?? []
    }
}

/// Entry in `GET /faq`. `description` is HTML.
struct FAQEntry: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let timestamp: Date?
}

enum BlogSort: String, CaseIterable, Identifiable {
    case desc, asc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .desc: "უახლესი"
        case .asc: "უძველესი"
        }
    }
}

extension Date {
    /// `12/06/2026`, the date format used on renovatori.ge.
    var siteFormatted: String {
        formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(Locale(identifier: "en_GB")))
    }
}

extension Double {
    /// `55` or `55.5`, without trailing zeros.
    var compactFormatted: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}
