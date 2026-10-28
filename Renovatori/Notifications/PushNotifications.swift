import SwiftUI
import UIKit
import UserNotifications

/// Push notifications from the server (e.g. „დაემატა პროექტის ისტორია"). After sign-in the app asks
/// for permission, registers with APNs and sends the device token to `PUT /profile/devices`;
/// sign-out removes it. Tapping a notification that carries a `projectId` opens that project.
@MainActor
final class PushNotifications: NSObject, ObservableObject {
    static let shared = PushNotifications()

    /// Screen a tapped notification asked for; `HomeView` opens it and clears it.
    @Published var pendingRoute: AppRoute?

    private var deviceToken: String?
    private var isSignedIn = false

    /// Xcode debug builds get tokens for the APNs sandbox, App Store builds for production.
    private static var environment: String {
        #if DEBUG
        "sandbox"
        #else
        "production"
        #endif
    }

    /// A user is signed in: ask once for permission, then register this device for their notifications.
    func userDidSignIn() async {
        isSignedIn = true
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        UIApplication.shared.registerForRemoteNotifications()
        await uploadToken()
    }

    /// The session ended without a sign-out request (expired, or the footer switched backends).
    func userDidSignOut() {
        isSignedIn = false
    }

    /// Before signing out, while the access token still works: stop notifications to this device.
    func unregisterBeforeSignOut() async {
        isSignedIn = false
        guard let deviceToken else { return }
        _ = try? await APIClient.shared.send(
            Endpoint(method: .delete, path: "profile/devices/\(deviceToken)", requiresAuth: true),
            as: DeviceDeletedResponse.self
        )
    }

    /// APNs answered `registerForRemoteNotifications` with this device's token.
    func didRegister(deviceToken data: Data) {
        deviceToken = data.map { String(format: "%02x", $0) }.joined()
        Task { await uploadToken() }
    }

    private func uploadToken() async {
        guard isSignedIn, let deviceToken else { return }
        do {
            _ = try await APIClient.shared.send(
                Endpoint(
                    method: .put,
                    path: "profile/devices",
                    body: DeviceRegistration(token: deviceToken, environment: Self.environment),
                    requiresAuth: true
                ),
                as: DeviceRegisteredResponse.self
            )
        } catch {
            // Older backends have no `/profile/devices`; the app works the same without notifications.
            print("Push device registration failed:", error)
        }
    }
}

extension PushNotifications: UNUserNotificationCenterDelegate {
    /// Shows the banner while the app is open, too.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// The user tapped a notification: open the project it is about.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let projectID = response.notification.request.content.userInfo["projectId"] as? String else { return }
        await MainActor.run {
            pendingRoute = .project(projectID)
        }
    }
}

/// Connects UIKit's push callbacks to `PushNotifications`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set before launch finishes, so a tap that launched the app is delivered too.
        UNUserNotificationCenter.current().delegate = PushNotifications.shared
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotifications.shared.didRegister(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Expected in debug builds signed by a personal team, which cannot use push notifications.
        print("APNs registration failed:", error.localizedDescription)
    }
}

/// `PUT /profile/devices` body.
private struct DeviceRegistration: Encodable {
    let token: String
    let environment: String
}

private struct DeviceRegisteredResponse: Decodable {
    let registered: Bool
}

private struct DeviceDeletedResponse: Decodable {
    let deleted: Bool
}
