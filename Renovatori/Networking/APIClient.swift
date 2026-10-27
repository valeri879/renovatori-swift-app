import Foundation
import UIKit

/// One API call: method, path under `APIConfig.baseURL`, optional JSON or multipart body,
/// and whether it needs a Bearer token.
struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    let method: Method
    let path: String
    var query: [URLQueryItem] = []
    var body: (any Encodable)?
    /// Sent instead of `body` for file uploads (`multipart/form-data`).
    var form: MultipartForm?
    var requiresAuth = false
}

/// A `multipart/form-data` body: text fields plus files.
struct MultipartForm {
    struct File {
        let field: String
        let fileName: String
        let mimeType: String
        let data: Data
    }

    var fields: [(name: String, value: String)] = []
    var files: [File] = []
    let boundary = "Boundary-\(UUID().uuidString)"

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    func encoded() -> Data {
        var body = Data()
        func append(_ string: String) { body.append(Data(string.utf8)) }

        for field in fields {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            append("\(field.value)\r\n")
        }
        for file in files {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(file.field)\"; filename=\"\(file.fileName)\"\r\n")
            append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        return body
    }
}

/// Sends requests to the Renovatori API.
///
/// Adds `Authorization: Bearer <access>` to protected requests. When one comes back 401,
/// it refreshes the token pair once and retries the request. Refreshes are single-flight:
/// refresh tokens rotate, so parallel refreshes would invalidate each other.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let tokenStore: TokenStore
    private var refreshTask: Task<TokenBundle, Error>?

    init(session: URLSession = .shared, tokenStore: TokenStore = .shared) {
        self.session = session
        self.tokenStore = tokenStore
    }

    /// Performs `endpoint` and decodes the `data` payload as `T`.
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let response: APIResponse<T> = try await sendEnvelope(endpoint)
        return response.data
    }

    /// Performs a list `endpoint` and returns one page of items with its pagination.
    func sendPaged<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> PagedResponse<T> {
        try await sendEnvelope(endpoint)
    }

    /// Performs `endpoint` and decodes the whole success envelope as `Envelope`.
    private func sendEnvelope<Envelope: Decodable>(_ endpoint: Endpoint) async throws -> Envelope {
        guard endpoint.requiresAuth else {
            return try await perform(endpoint, accessToken: nil)
        }

        guard let accessToken = tokenStore.accessToken else {
            throw APIError.sessionExpired
        }

        do {
            return try await perform(endpoint, accessToken: accessToken)
        } catch let error as APIError where error.status == 401 {
            let freshToken = try await validAccessToken(replacing: accessToken)
            return try await perform(endpoint, accessToken: freshToken)
        }
    }

    // MARK: Refresh

    /// Returns an access token newer than `rejectedToken`, refreshing only if no other call already has.
    private func validAccessToken(replacing rejectedToken: String) async throws -> String {
        // Another request may have refreshed while this one was in flight.
        if let current = tokenStore.accessToken, current != rejectedToken {
            return current
        }
        return try await refreshTokens().accessToken
    }

    /// Rotates the token pair. Concurrent callers share the same in-flight refresh.
    @discardableResult
    func refreshTokens() async throws -> TokenBundle {
        if let refreshTask {
            return try await refreshTask.value
        }

        guard let refreshToken = tokenStore.refreshToken else {
            tokenStore.clear()
            throw APIError.sessionExpired
        }

        let device = await MainActor.run { UIDevice.current.name }
        let task = Task<TokenBundle, Error> {
            let response: APIResponse<TokenBundle> = try await perform(
                Endpoint(method: .post, path: "auth/refresh", body: RefreshRequest(refreshToken: refreshToken, device: device)),
                accessToken: nil
            )
            return response.data
        }
        refreshTask = task
        defer { refreshTask = nil }

        do {
            let bundle = try await task.value
            // Rotation: the old refresh token is now invalid, so always keep the new one.
            tokenStore.save(accessToken: bundle.accessToken, refreshToken: bundle.refreshToken)
            return bundle
        } catch let error as APIError where error.status == 401 || error.status == 400 {
            // invalid_refresh / expired_refresh: the session is over.
            tokenStore.clear()
            throw APIError.sessionExpired
        }
    }

    // MARK: Transport

    /// Sends the request and decodes the full success envelope (`{ data, ... }`) as `Envelope`.
    private func perform<Envelope: Decodable>(_ endpoint: Endpoint, accessToken: String?) async throws -> Envelope {
        var url = APIConfig.baseURL.appending(path: endpoint.path)
        if !endpoint.query.isEmpty {
            url.append(queryItems: endpoint.query)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let form = endpoint.form {
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = form.encoded()
        } else if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if let envelope = try? JSONDecoder.api.decode(APIErrorEnvelope.self, from: data) {
                throw APIError(status: status, body: envelope.error)
            }
            throw APIError(status: status, code: "http_\(status)", message: "სერვერის შეცდომა (\(status)).")
        }

        do {
            return try JSONDecoder.api.decode(Envelope.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
