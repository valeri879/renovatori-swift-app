import SwiftUI

@main
struct RenovatoriApp: App {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear { theme.apply() }
                .onChange(of: theme) { _, newValue in newValue.apply() }
        }
    }
}
