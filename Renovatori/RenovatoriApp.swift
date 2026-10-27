import SwiftUI

@main
struct RenovatoriApp: App {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(auth)
                .task { await auth.restoreSession() }
                .onAppear { theme.apply() }
                .onChange(of: theme) { _, newValue in newValue.apply() }
        }
    }
}
