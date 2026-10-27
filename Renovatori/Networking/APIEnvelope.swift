import Foundation

/// Success envelope: `{ "data": T }`.
struct APIResponse<T: Decodable>: Decodable {
    let data: T
}

/// Paging info that list endpoints return next to `data`.
struct Pagination: Decodable, Equatable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasPrev: Bool
    let hasNext: Bool
}

/// List envelope: `{ "data": [T], "pagination": Pagination }`.
struct PagedResponse<T: Decodable>: Decodable {
    let data: [T]
    let pagination: Pagination
}

/// Error envelope payload: `{ "error": { message, code, details? } }`.
struct APIErrorBody: Decodable {
    let message: String
    let code: String
    let details: [String: String]?
}

struct APIErrorEnvelope: Decodable {
    let error: APIErrorBody
}

/// A failed API call. `status` is 0 for transport failures that never reached the server.
struct APIError: Error {
    let status: Int
    let code: String
    let message: String
    let details: [String: String]?

    init(status: Int, code: String, message: String, details: [String: String]? = nil) {
        self.status = status
        self.code = code
        self.message = message
        self.details = details
    }

    init(status: Int, body: APIErrorBody) {
        self.init(status: status, code: body.code, message: body.message, details: body.details)
    }

    // Client-side codes; the server's own codes come from `APIErrorBody.code`.
    static let networkCode = "network"
    static let sessionExpiredCode = "session_expired"
    static let decodingCode = "decoding"

    static let network = APIError(status: 0, code: networkCode, message: "სერვერთან დაკავშირება ვერ მოხერხდა. სცადეთ თავიდან.")
    static let sessionExpired = APIError(status: 401, code: sessionExpiredCode, message: "სესიის ვადა ამოიწურა. გთხოვთ, თავიდან შეხვიდეთ.")
    static let decoding = APIError(status: 0, code: decodingCode, message: "სერვერის პასუხის დამუშავება ვერ მოხერხდა.")
}

extension JSONDecoder {
    /// Decoder for API payloads. Dates are ISO-8601, with or without fractional seconds
    /// (MongoDB dates serialize as `2026-10-25T16:03:00.123Z`, which `.iso8601` rejects).
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: value)
                ?? ISO8601DateFormatter.plain.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(value)")
        }
        return decoder
    }()
}

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let plain = ISO8601DateFormatter()
}
