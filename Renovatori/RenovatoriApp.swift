import SwiftUI

@main
struct RenovatoriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system
    @AppStorage(APIEnvironment.storageKey) private var apiEnvironment: APIEnvironment = .local
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                // A new identity reloads every screen from the newly selected backend.
                .id(apiEnvironment)
                .environmentObject(auth)
                .task { await auth.restoreSession() }
                .onAppear { theme.apply() }
                .onChange(of: theme) { _, newValue in newValue.apply() }
                .onChange(of: apiEnvironment) { _, _ in auth.forgetSessionForEnvironmentChange() }
                // Each signed-in account registers this device for its push notifications.
                .task(id: auth.currentUser?.id) {
                    if auth.currentUser != nil {
                        await PushNotifications.shared.userDidSignIn()
                    } else {
                        PushNotifications.shared.userDidSignOut()
                    }
                }
        }
    }
}
