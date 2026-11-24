import Foundation
import UIKit

/// Session state and the auth actions the screens call.
@MainActor
final class AuthViewModel: ObservableObject {
    enum State: Equatable {
        /// Checking a stored token against `/auth/me` on launch.
        case loading
        case unauthenticated
        /// A stored session that opens only after Face ID (the user turned it on in the profile).
        case locked
        case authenticated(User)
    }

    /// UserDefaults key for "open the account with Face ID".
    static let biometricUnlockKey = "biometricUnlockEnabled"

    @Published private(set) var state: State = .loading
    /// Set by `deleteAccount`, so the deletion screen can show its result after the sign-out
    /// rebuilds the navigation stack (and the screen's own state with it).
    @Published private(set) var accountWasDeleted = false
    /// Set after signing in with the password on a device with Face ID that hasn't turned it on yet,
    /// so the app can offer it once.
    @Published var shouldOfferBiometricUnlock = false
    @Published private(set) var isBiometricUnlockEnabled = UserDefaults.standard.bool(forKey: AuthViewModel.biometricUnlockKey)

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
    /// With Face ID turned on, the session waits for `unlockWithBiometrics()` instead.
    func restoreSession() async {
        guard tokenStore.accessToken != nil else {
            setBiometricUnlock(false)
            state = .unauthenticated
            return
        }
        if isBiometricUnlockEnabled, BiometricAuth.availableKind != nil {
            state = .locked
            return
        }
        await confirmStoredSession()
    }

    /// Opens the stored session after Face ID. Stays locked when it fails or is cancelled.
    func unlockWithBiometrics() async {
        guard state == .locked else { return }
        guard await BiometricAuth.authenticate(reason: "ანგარიშში შესასვლელად") else { return }
        state = .loading
        await confirmStoredSession()
    }

    /// Turns "open the account with Face ID" on (after a Face ID check) or off.
    @discardableResult
    func setBiometricUnlock(enabled: Bool) async -> Bool {
        if enabled {
            guard await BiometricAuth.authenticate(reason: "Face ID-ით შესვლის ჩასართავად") else { return false }
        }
        setBiometricUnlock(enabled)
        return true
    }

    private func setBiometricUnlock(_ enabled: Bool) {
        isBiometricUnlockEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.biometricUnlockKey)
        if !enabled {
            shouldOfferBiometricUnlock = false
        }
    }

    /// Offers Face ID after a password sign-in, unless it is on already or the device has none.
    private func offerBiometricUnlockIfAvailable() {
        shouldOfferBiometricUnlock = !isBiometricUnlockEnabled && BiometricAuth.availableKind != nil
    }

    /// Forgets the session on this device (tokens and the Face ID choice that unlocks them).
    private func clearSession() {
        tokenStore.clear()
        setBiometricUnlock(false)
        state = .unauthenticated
    }

    private func confirmStoredSession() async {
        do {
            try await reloadUser()
        } catch let error as APIError where error.code == APIError.networkCode {
            // Offline: keep the tokens and try again on the next launch.
            state = .unauthenticated
        } catch {
            clearSession()
        }
    }

    func login(email: String, password: String) async throws {
        let bundle: TokenBundle = try await client.send(Endpoint(
            method: .post,
            path: "auth/login",
            body: LoginRequest(email: email, password: password, device: UIDevice.current.name)
        ))
        signIn(with: bundle)
        offerBiometricUnlockIfAvailable()
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
        offerBiometricUnlockIfAvailable()
    }

    /// Fetches the latest profile; signs out if the session can no longer be refreshed.
    func reloadUser() async throws {
        do {
            let response: MeResponse = try await client.send(Endpoint(method: .get, path: "auth/me", requiresAuth: true))
            state = .authenticated(response.user)
        } catch let error as APIError where error.code == APIError.sessionExpiredCode || error.code == "not_found" {
            clearSession()
            throw error
        }
    }

    /// Revokes the refresh token on the backend, then forgets the session locally either way.
    func logout() async {
        // Needs the access token, so it runs before the session is revoked.
        await PushNotifications.shared.unregisterBeforeSignOut()
        if let refreshToken = tokenStore.refreshToken {
            _ = try? await client.send(
                Endpoint(method: .post, path: "auth/logout", body: LogoutRequest(refreshToken: refreshToken)),
                as: LogoutResponse.self
            )
        }
        clearSession()
    }

    /// After the footer switches backends: the stored tokens belong to the other server, so drop them
    /// without calling `/auth/logout` (that request would now go to the wrong backend).
    func forgetSessionForEnvironmentChange() {
        clearSession()
    }

    // MARK: Password reset (signed out)

    /// Emails a reset code. The server answers the same way for unknown emails.
    func requestPasswordReset(email: String) async throws {
        _ = try await client.send(
            Endpoint(method: .post, path: "auth/password-reset/request", body: PasswordResetRequest(email: email)),
            as: SentResponse.self
        )
    }

    /// Sets a new password with the emailed code. The server revokes every session, so the user signs in again.
    func confirmPasswordReset(email: String, code: String, password: String) async throws {
        _ = try await client.send(
            Endpoint(
                method: .post,
                path: "auth/password-reset/confirm",
                body: PasswordResetConfirmRequest(email: email, code: code, password: password)
            ),
            as: PasswordResetResponse.self
        )
    }

    // MARK: Account (signed in)

    func verifyEmail(code: String) async throws {
        let response: MeResponse = try await client.send(Endpoint(
            method: .post,
            path: "auth/email-verification",
            body: EmailVerificationRequest(code: code),
            requiresAuth: true
        ))
        state = .authenticated(response.user)
    }

    func resendVerificationCode() async throws {
        _ = try await client.send(
            Endpoint(method: .post, path: "auth/email-verification/resend", requiresAuth: true),
            as: SentResponse.self
        )
    }

    /// Changes the password. The server signs out other devices and returns a fresh pair for this one.
    func changePassword(current: String, new: String, confirmation: String) async throws {
        let bundle: TokenBundle = try await client.send(Endpoint(
            method: .post,
            path: "auth/password-change",
            body: PasswordChangeRequest(
                currentPassword: current,
                newPassword: new,
                confirmPassword: confirmation,
                device: UIDevice.current.name
            ),
            requiresAuth: true
        ))
        signIn(with: bundle)
    }

    /// Permanently deletes the account (the password is asked again). The server also removes this
    /// device's push registration and every session, so the app only forgets the tokens.
    func deleteAccount(password: String) async throws {
        _ = try await client.send(
            Endpoint(
                method: .post,
                path: "auth/account-deletion",
                body: AccountDeletionRequest(password: password),
                requiresAuth: true
            ),
            as: AccountDeletionResponse.self
        )
        clearSession()
        accountWasDeleted = true
    }

    private func signIn(with bundle: TokenBundle) {
        tokenStore.save(accessToken: bundle.accessToken, refreshToken: bundle.refreshToken)
        accountWasDeleted = false
        state = .authenticated(bundle.user)
    }
}
