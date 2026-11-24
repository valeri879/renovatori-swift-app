import SwiftUI

extension View {
    /// The main action: Liquid Glass tinted with the accent color on iOS 26, a filled button before.
    @ViewBuilder
    func primaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    /// A secondary action: clear Liquid Glass on iOS 26, a tinted bordered button before.
    @ViewBuilder
    func secondaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
