import SwiftUI

/// The profile tab while a stored session waits for Face ID: unlock it, or sign out and use the password.
struct BiometricUnlockView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var isSigningOut = false

    private var biometry: BiometricAuth.Kind {
        BiometricAuth.availableKind ?? .faceID
    }

    var body: some View {
        ContentUnavailableView {
            Label("შესვლა \(biometry.title)-ით", systemImage: biometry.systemImage)
        } description: {
            Text("თქვენი ანგარიში ამ მოწყობილობაზე \(biometry.title)-ით იხსნება.")
        } actions: {
            Button {
                Task { await auth.unlockWithBiometrics() }
            } label: {
                Label("\(biometry.title)-ით შესვლა", systemImage: biometry.systemImage)
                    .frame(maxWidth: 260)
            }
            .primaryButtonStyle()
            .controlSize(.large)

            Button("პაროლით შესვლა") {
                isSigningOut = true
                Task {
                    await auth.logout()
                    isSigningOut = false
                }
            }
            .disabled(isSigningOut)
        }
        .navigationTitle("შესვლა")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BiometricUnlockView()
    }
    .environmentObject(AuthViewModel())
}
