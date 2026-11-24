import Foundation
import LocalAuthentication

/// Face ID / Touch ID through LocalAuthentication. The face never reaches the app: iOS only answers
/// whether it matched.
enum BiometricAuth {
    enum Kind {
        case faceID, touchID, opticID

        var title: String {
            switch self {
            case .faceID: "Face ID"
            case .touchID: "Touch ID"
            case .opticID: "Optic ID"
            }
        }

        var systemImage: String {
            switch self {
            case .faceID: "faceid"
            case .touchID: "touchid"
            case .opticID: "opticid"
            }
        }
    }

    /// The biometry this device has set up, or nil (none, not enrolled, or turned off for the app).
    static var availableKind: Kind? {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return nil }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return nil
        }
    }

    /// Asks for the face (or finger). False when it fails or the user cancels; the password is the fallback.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "გაუქმება"
        context.localizedFallbackTitle = ""
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}
