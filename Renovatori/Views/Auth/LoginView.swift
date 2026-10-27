import SwiftUI

/// Email + password sign-in, with a link to registration.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isShowingForgotPassword = false
    /// Shown after a successful password reset.
    @State private var infoMessage: String?

    var body: some View {
        Form {
            Section {
                FormFieldRow(title: "ელ-ფოსტა") {
                    TextField("ელ-ფოსტის მისამართი", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                FormFieldRow(title: "პაროლი") {
                    SecureField("პაროლი", text: $password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(submit)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    if let errorMessage {
                        FormErrorBanner(message: errorMessage)
                    } else if let infoMessage {
                        Label(infoMessage, systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                    Button("დაგავიწყდათ პაროლი?") {
                        isShowingForgotPassword = true
                    }
                    .font(.footnote.weight(.semibold))
                }
                .padding(.top, 4)
            }

            Section {
                SubmitButton(title: "შესვლა", isLoading: isSubmitting, action: submit)
            }

            Section {
                NavigationLink {
                    SignupView()
                } label: {
                    Text("არ გაქვთ ანგარიში? ") + Text("რეგისტრაცია").bold()
                }
            }
        }
        .navigationTitle("შესვლა")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingForgotPassword) {
            ForgotPasswordView(email: email) { resetEmail in
                // Back to this form, ready to sign in with the new password.
                email = resetEmail
                password = ""
                errorMessage = nil
                infoMessage = "პაროლი შეიცვალა. შედით ახალი პაროლით."
                isShowingForgotPassword = false
            }
        }
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "ელ-ფოსტა და პაროლი სავალდებულოა."
            return
        }

        errorMessage = nil
        infoMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.login(email: trimmedEmail, password: password)
            } catch let error as APIError where error.status == 401 {
                errorMessage = "ელ-ფოსტა ან პაროლი არასწორია"
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
        LoginView()
    }
    .environmentObject(AuthViewModel())
}
