import SwiftUI

/// "პაროლის შეცვლა" (`views/pages/profile-password-change-page`): current, new and repeated password.
struct PasswordChangeView: View {
    private enum Field: String {
        case currentPassword, newPassword, confirmPassword
    }

    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isChanged = false

    var body: some View {
        Group {
            if isChanged {
                changed
            } else {
                form
            }
        }
        .navigationTitle("პაროლის შეცვლა")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        Form {
            Section {
                FormFieldRow(title: "მიმდინარე პაროლი", error: fieldErrors[.currentPassword]) {
                    SecureField("მიმდინარე პაროლი", text: $currentPassword)
                        .textContentType(.password)
                }
                FormFieldRow(title: "ახალი პაროლი", error: fieldErrors[.newPassword]) {
                    SecureField("მინიმუმ 8 სიმბოლო", text: $newPassword)
                        .textContentType(.newPassword)
                }
                FormFieldRow(title: "გაიმეორეთ ახალი პაროლი", error: fieldErrors[.confirmPassword]) {
                    SecureField("ახალი პაროლი კიდევ ერთხელ", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if let errorMessage {
                        FormErrorBanner(message: errorMessage)
                    }
                    Text("პაროლის შეცვლის შემდეგ სხვა მოწყობილობებზე ანგარიშიდან გამოხვალთ.")
                        .font(.footnote)
                }
                .padding(.top, 4)
            }

            Section {
                SubmitButton(title: "პაროლის შეცვლა", isLoading: isSubmitting, action: submit)
            }
        }
    }

    private var changed: some View {
        ContentUnavailableView {
            Label("პაროლი შეიცვალა", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } description: {
            Text("თქვენი პაროლი წარმატებით შეიცვალა. დადასტურება გამოგეგზავნათ ელ-ფოსტაზე.")
        } actions: {
            Button("პროფილზე დაბრუნება") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    /// Mirrors the backend's checks that can be done without the current password.
    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        if currentPassword.isEmpty { errors[.currentPassword] = "მიმდინარე პაროლი აუცილებელია" }
        if newPassword.isEmpty {
            errors[.newPassword] = "ახალი პაროლი აუცილებელია"
        } else if newPassword.count < 8 {
            errors[.newPassword] = "ახალი პაროლი უნდა შედგებოდეს მინიმუმ 8 სიმბოლოსგან"
        } else if newPassword == currentPassword {
            errors[.newPassword] = "ახალი პაროლი არ უნდა ემთხვეოდეს ძველს"
        }
        if confirmPassword.isEmpty {
            errors[.confirmPassword] = "გაიმეორეთ ახალი პაროლი"
        } else if confirmPassword != newPassword {
            errors[.confirmPassword] = "ახალი პაროლები არ ემთხვევა"
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
                try await auth.changePassword(current: currentPassword, new: newPassword, confirmation: confirmPassword)
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                isChanged = true
            } catch let error as APIError {
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
        PasswordChangeView()
    }
    .environmentObject(AuthViewModel())
}
