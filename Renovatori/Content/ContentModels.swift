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
    let updatedAt: Date?
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
}

struct ProjectDetailResponse: Decodable {
    let project: ProjectDetail
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

struct BlogDetailResponse: Decodable {
    let blog: BlogDetail
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
