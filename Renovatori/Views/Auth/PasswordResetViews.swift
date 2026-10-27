import SwiftUI

/// "დაგავიწყდათ პაროლი?" — step 1: ask for the email and send a reset code.
struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthViewModel

    /// Pre-filled from the login form.
    @State var email: String
    /// Called after a successful reset, with the email to sign in with.
    let onPasswordReset: (String) -> Void

    @State private var emailError: String?
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isShowingCodeStep = false

    var body: some View {
        Form {
            Section {
                FormFieldRow(title: "ელ-ფოსტა", error: emailError) {
                    TextField("ელ-ფოსტის მისამართი", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.send)
                        .onSubmit(submit)
                }
            } header: {
                Text("მიუთითეთ ანგარიშის ელ-ფოსტა. გამოგიგზავნით კოდს, რომლითაც ახალ პაროლს დააყენებთ.")
                    .textCase(nil)
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: "კოდის გაგზავნა", isLoading: isSubmitting, action: submit)
            }

            Section {
                Button("უკვე მაქვს კოდი") {
                    guard validate() else { return }
                    isShowingCodeStep = true
                }
            }
        }
        .navigationTitle("პაროლის აღდგენა")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingCodeStep) {
            ResetPasswordView(email: trimmedEmail, onPasswordReset: onPasswordReset)
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validate() -> Bool {
        emailError = trimmedEmail.isEmpty ? "ელ-ფოსტა აუცილებელია" : nil
        return emailError == nil
    }

    private func submit() {
        errorMessage = nil
        guard validate() else { return }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.requestPasswordReset(email: trimmedEmail)
                isShowingCodeStep = true
            } catch let error as APIError {
                emailError = error.details?["email"]
                if emailError == nil {
                    errorMessage = error.message
                }
            } catch {
                errorMessage = APIError.network.message
            }
        }
    }
}

/// Step 2: enter the emailed code and the new password.
struct ResetPasswordView: View {
    private enum Field: String {
        case code, password, confirmation
    }

    @EnvironmentObject private var auth: AuthViewModel

    let email: String
    let onPasswordReset: (String) -> Void

    @State private var code = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var isSubmitting = false
    @State private var isResending = false

    var body: some View {
        Form {
            Section {
                FormFieldRow(title: "აღდგენის კოდი", error: fieldErrors[.code]) {
                    TextField("8-სიმბოლოიანი კოდი", text: $code)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                }
                FormFieldRow(title: "ახალი პაროლი", error: fieldErrors[.password]) {
                    SecureField("მინიმუმ 8 სიმბოლო", text: $password)
                        .textContentType(.newPassword)
                }
                FormFieldRow(title: "გაიმეორეთ პაროლი", error: fieldErrors[.confirmation]) {
                    SecureField("ახალი პაროლი კიდევ ერთხელ", text: $confirmation)
                        .textContentType(.newPassword)
                }
            } header: {
                Text("კოდი გაიგზავნა მისამართზე \(email). კოდი მოქმედებს 1 საათის განმავლობაში.")
                    .textCase(nil)
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                } else if let infoMessage {
                    Label(infoMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: "პაროლის შეცვლა", isLoading: isSubmitting, action: submit)
            }

            Section {
                Button {
                    resend()
                } label: {
                    HStack {
                        Text("კოდის თავიდან გაგზავნა")
                        if isResending {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isResending)
            }
        }
        .navigationTitle("ახალი პაროლი")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        if code.trimmingCharacters(in: .whitespaces).isEmpty { errors[.code] = "აღდგენის კოდი აუცილებელია" }
        if password.isEmpty {
            errors[.password] = "ახალი პაროლი აუცილებელია"
        } else if password.count < 8 {
            errors[.password] = "პაროლი უნდა შედგებოდეს მინიმუმ 8 სიმბოლოსგან"
        }
        if confirmation.isEmpty {
            errors[.confirmation] = "გაიმეორეთ ახალი პაროლი"
        } else if confirmation != password {
            errors[.confirmation] = "პაროლები არ ემთხვევა"
        }
        return errors
    }

    private func submit() {
        errorMessage = nil
        infoMessage = nil
        fieldErrors = validate()
        guard fieldErrors.isEmpty else { return }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.confirmPasswordReset(
                    email: email,
                    code: code.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                onPasswordReset(email)
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

    private func resend() {
        errorMessage = nil
        infoMessage = nil
        isResending = true
        Task {
            defer { isResending = false }
            do {
                try await auth.requestPasswordReset(email: email)
                infoMessage = "ახალი კოდი გაიგზავნა. ძველი კოდი აღარ მოქმედებს."
            } catch let error as APIError {
                errorMessage = error.message
            } catch {
                errorMessage = APIError.network.message
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(email: "") { _ in }
    }
    .environmentObject(AuthViewModel())
}
