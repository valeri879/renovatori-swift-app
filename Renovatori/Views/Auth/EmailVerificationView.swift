import SwiftUI

/// "ელ-ფოსტის დადასტურება": enter the code emailed at signup, or ask for it again.
struct EmailVerificationView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var codeError: String?
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var isSubmitting = false
    @State private var isResending = false
    /// Seconds left before the code can be sent again, so the button is not spammed.
    @State private var resendCooldown = 0

    var body: some View {
        Group {
            if let user = auth.currentUser, user.isVerified {
                verified
            } else {
                form
            }
        }
        .navigationTitle("ელ-ფოსტის დადასტურება")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: resendCooldown) {
            guard resendCooldown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            resendCooldown -= 1
        }
    }

    private var form: some View {
        Form {
            Section {
                FormFieldRow(title: "ვერიფიკაციის კოდი", error: codeError) {
                    TextField("კოდი ელ-ფოსტიდან", text: $code)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .submitLabel(.done)
                        .onSubmit(submit)
                }
            } header: {
                Text("კოდი გამოგეგზავნათ მისამართზე \(auth.currentUser?.email ?? "") რეგისტრაციისას. კოდი განასხვავებს დიდ და პატარა ასოებს.")
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
                SubmitButton(title: "დადასტურება", isLoading: isSubmitting, action: submit)
            }

            Section {
                Button {
                    resend()
                } label: {
                    HStack {
                        Text(resendCooldown > 0 ? "კოდის თავიდან გაგზავნა (\(resendCooldown) წმ)" : "კოდის თავიდან გაგზავნა")
                        if isResending {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isResending || resendCooldown > 0)
            }
        }
    }

    private var verified: some View {
        ContentUnavailableView {
            Label("ელ-ფოსტა დადასტურებულია", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        } description: {
            Text("გილოცავთ! თქვენი ელ-ფოსტა წარმატებით ვერიფიცირდა.")
        } actions: {
            Button("პროფილზე დაბრუნება") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func submit() {
        errorMessage = nil
        infoMessage = nil
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            codeError = "ვერიფიკაციის კოდი აუცილებელია"
            return
        }
        codeError = nil

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.verifyEmail(code: trimmed)
            } catch let error as APIError {
                codeError = error.details?["code"]
                if codeError == nil {
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
                try await auth.resendVerificationCode()
                infoMessage = "კოდი თავიდან გაიგზავნა. შეამოწმეთ ელ-ფოსტა."
                resendCooldown = 60
            } catch let error as APIError where error.code == "already_verified" {
                try? await auth.reloadUser()
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
        EmailVerificationView()
    }
    .environmentObject(AuthViewModel())
}
