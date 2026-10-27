import SwiftUI

/// Email + password sign-in, with a link to registration.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

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
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
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
    }

    private func submit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "ელ-ფოსტა და პაროლი სავალდებულოა."
            return
        }

        errorMessage = nil
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
