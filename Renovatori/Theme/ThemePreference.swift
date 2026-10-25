import SwiftUI
import UIKit

/// Light / system / dark choice from the footer theme switch.
enum ThemePreference: String, CaseIterable, Identifiable {
    case light, system, dark

    static let storageKey = "theme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: "ღია"
        case .system: "სისტემური"
        case .dark: "მუქი"
        }
    }

    private var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: .light
        case .system: .unspecified
        case .dark: .dark
        }
    }

    /// Overrides the style on every window; unlike `preferredColorScheme(nil)`,
    /// this reliably returns to the system appearance.
    func apply() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = interfaceStyle
            }
        }
    }
}
