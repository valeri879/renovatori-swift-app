import SwiftUI

/// Registration form. Validates on the client first, then maps server errors onto the fields.
struct SignupView: View {
    private enum Field: String {
        case firstName, lastName, phoneNumber, email, password
    }

    @EnvironmentObject private var auth: AuthViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var password = ""

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        Form {
            Section {
                FormFieldRow(title: "სახელი", error: fieldErrors[.firstName]) {
                    TextField("სახელი", text: $firstName)
                        .textContentType(.givenName)
                }
                FormFieldRow(title: "გვარი", error: fieldErrors[.lastName]) {
                    TextField("გვარი", text: $lastName)
                        .textContentType(.familyName)
                }
                FormFieldRow(title: "ტელეფონის ნომერი", error: fieldErrors[.phoneNumber]) {
                    TextField("5XXXXXXXX", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: phoneNumber) { _, newValue in
                            // Digits only, at most 9 — the backend requires exactly 9.
                            let digits = String(newValue.filter(\.isNumber).prefix(9))
                            if digits != newValue {
                                phoneNumber = digits
                            }
                        }
                }
                FormFieldRow(title: "ელ-ფოსტა", error: fieldErrors[.email]) {
                    TextField("ელ-ფოსტის მისამართი", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                FormFieldRow(title: "პაროლი", error: fieldErrors[.password]) {
                    SecureField("მინიმუმ 8 სიმბოლო", text: $password)
                        .textContentType(.newPassword)
                }
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: "რეგისტრაცია", isLoading: isSubmitting, action: submit)
            }
        }
        .navigationTitle("რეგისტრაცია")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var trimmed: (firstName: String, lastName: String, email: String) {
        (
            firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Mirrors the backend's signup validation so most mistakes never reach the server.
    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        if trimmed.firstName.isEmpty { errors[.firstName] = "სახელი აუცილებელია" }
        if trimmed.lastName.isEmpty { errors[.lastName] = "გვარი აუცილებელია" }
        if phoneNumber.isEmpty {
            errors[.phoneNumber] = "ტელეფონის ნომერი აუცილებელია"
        } else if phoneNumber.count != 9 {
            errors[.phoneNumber] = "ტელეფონის ნომერი უნდა შეიცავდეს 9 ციფრს"
        }
        if trimmed.email.isEmpty {
            errors[.email] = "ელ-ფოსტა აუცილებელია"
        } else if !trimmed.email.contains("@") || !trimmed.email.contains(".") {
            errors[.email] = "ელ-ფოსტის ფორმატი არასწორია"
        }
        if password.isEmpty {
            errors[.password] = "პაროლი აუცილებელია"
        } else if password.count < 8 {
            errors[.password] = "პაროლი უნდა იყოს მინიმუმ 8 სიმბოლო"
        }
        return errors
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = validate()
        guard fieldErrors.isEmpty else { return }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.signup(
                    firstName: trimmed.firstName,
                    lastName: trimmed.lastName,
                    phoneNumber: phoneNumber,
                    email: trimmed.email,
                    password: password
                )
            } catch let error as APIError where error.code == "email_taken" {
                fieldErrors[.email] = error.message
            } catch let error as APIError {
                // 400 `validation` carries per-field messages under `details`.
                for (key, message) in error.details ?? [:] {
                    if let field = Field(rawValue: key) {
                        fieldErrors[field] = message
                    }
                }
                if fieldErrors.isEmpty {
                    errorMessage = error.message
                }
            } catch {
                errorMessage = APIError.network.message
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignupView()
    }
    .environmentObject(AuthViewModel())
}
