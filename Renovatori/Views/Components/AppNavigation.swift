import SwiftUI

/// Navigation actions that screens deep in the stack can trigger without owning the path.
/// `HomeView` provides the real implementation; previews get no-ops.
struct AppNavigation {
    /// Pushes `route` onto the main navigation stack.
    var open: (AppRoute) -> Void = { _ in }
    /// Shows the login sheet. After a successful sign-in, `destination` is opened
    /// (the profile when it is nil).
    var signIn: (_ destination: AppRoute?) -> Void = { _ in }
}

private struct AppNavigationKey: EnvironmentKey {
    static let defaultValue = AppNavigation()
}

extension EnvironmentValues {
    var appNavigation: AppNavigation {
        get { self[AppNavigationKey.self] }
        set { self[AppNavigationKey.self] = newValue }
    }
}
