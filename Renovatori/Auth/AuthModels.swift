import Foundation

/// Account returned by the API (`serializeUser` on the backend).
struct User: Codable, Identifiable, Equatable {
    let id: String
    let firstName, lastName, email, phoneNumber: String
    /// File name under `/uploads/small/`, when the user uploaded a photo.
    let profileImage: String?
    let isAdmin, isModerator, isVerified: Bool
    /// Missing for some older accounts, so optional despite the API docs.
    let createdAt: Date?

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var profileImageURL: URL? {
        profileImage.map { SiteInfo.page("/uploads/small/\($0)") }
    }
}

/// Response of login, signup and refresh.
struct TokenBundle: Decodable {
    let accessToken, refreshToken: String
    /// Access token lifetime in seconds (3600).
    let expiresIn: Int
    let user: User
}

struct LoginRequest: Encodable {
    let email, password, device: String
}

struct SignupRequest: Encodable {
    let firstName, lastName, phoneNumber, email, password, device: String
}

struct RefreshRequest: Encodable {
    let refreshToken, device: String
}

struct LogoutRequest: Encodable {
    let refreshToken: String
}

struct MeResponse: Decodable {
    let user: User
}

struct LogoutResponse: Decodable {
    let loggedOut: Bool
}
