import Foundation
import UIKit

/// Session state and the auth actions the screens call.
@MainActor
final class AuthViewModel: ObservableObject {
    enum State: Equatable {
        /// Checking a stored token against `/auth/me` on launch.
        case loading
        case unauthenticated
        case authenticated(User)
    }

    @Published private(set) var state: State = .loading

    private let client: APIClient
    private let tokenStore: TokenStore

    init(client: APIClient = .shared, tokenStore: TokenStore = .shared) {
        self.client = client
        self.tokenStore = tokenStore
    }

    var currentUser: User? {
        if case .authenticated(let user) = state { user } else { nil }
    }

    /// On launch: with a stored token, confirm it (refreshing if needed) via `/auth/me`.
    func restoreSession() async {
        guard tokenStore.accessToken != nil else {
            state = .unauthenticated
            return
        }
        do {
            try await reloadUser()
        } catch let error as APIError where error.code == APIError.networkCode {
            // Offline: keep the tokens and try again on the next launch.
            state = .unauthenticated
        } catch {
            tokenStore.clear()
            state = .unauthenticated
        }
    }

    func login(email: String, password: String) async throws {
        let bundle: TokenBundle = try await client.send(Endpoint(
            method: .post,
            path: "auth/login",
            body: LoginRequest(email: email, password: password, device: UIDevice.current.name)
        ))
        signIn(with: bundle)
    }

    func signup(firstName: String, lastName: String, phoneNumber: String, email: String, password: String) async throws {
        let bundle: TokenBundle = try await client.send(Endpoint(
            method: .post,
            path: "auth/signup",
            body: SignupRequest(
                firstName: firstName,
                lastName: lastName,
                phoneNumber: phoneNumber,
                email: email,
                password: password,
                device: UIDevice.current.name
            )
        ))
        signIn(with: bundle)
    }

    /// Fetches the latest profile; signs out if the session can no longer be refreshed.
    func reloadUser() async throws {
        do {
            let response: MeResponse = try await client.send(Endpoint(method: .get, path: "auth/me", requiresAuth: true))
            state = .authenticated(response.user)
        } catch let error as APIError where error.code == APIError.sessionExpiredCode || error.code == "not_found" {
            tokenStore.clear()
            state = .unauthenticated
            throw error
        }
    }

    /// Revokes the refresh token on the backend, then forgets the session locally either way.
    func logout() async {
        if let refreshToken = tokenStore.refreshToken {
            _ = try? await client.send(
                Endpoint(method: .post, path: "auth/logout", body: LogoutRequest(refreshToken: refreshToken)),
                as: LogoutResponse.self
            )
        }
        tokenStore.clear()
        state = .unauthenticated
    }

    private func signIn(with bundle: TokenBundle) {
        tokenStore.save(accessToken: bundle.accessToken, refreshToken: bundle.refreshToken)
        state = .authenticated(bundle.user)
    }
}
