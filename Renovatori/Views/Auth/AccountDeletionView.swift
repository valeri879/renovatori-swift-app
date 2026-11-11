import SwiftUI

/// "ანგარიშის წაშლა" (`views/pages/profile-delete-account-page`): what gets deleted, the current
/// password and a confirmation dialog. Staff accounts can't delete themselves, as on the web.
struct AccountDeletionView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.siteContacts) private var contacts
    @Environment(\.appNavigation) private var navigation

    @State private var password = ""
    @State private var passwordError: String?
    @State private var errorMessage: String?
    @State private var isConfirming = false
    @State private var isDeleting = false

    var body: some View {
        Group {
            if auth.accountWasDeleted {
                deleted
            } else if let user = auth.currentUser {
                if user.isStaff {
                    staffNotice
                } else {
                    form
                }
            } else {
                ContentUnavailableView("არ ხართ ავტორიზებული", systemImage: "person.crop.circle.badge.xmark")
            }
        }
        .navigationTitle("ანგარიშის წაშლა")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var form: some View {
        Form {
            Section {
                Text("ანგარიშის წაშლა სამუდამოა და მისი აღდგენა შეუძლებელია. წაიშლება:")
                VStack(alignment: .leading, spacing: 8) {
                    bullet("პროფილი (სახელი, გვარი, ელ-ფოსტა, ტელეფონი) და პროფილის ფოტო")
                    bullet("კონსულტაციის მოთხოვნები")
                    bullet("კალკულატორით გაკეთებული გათვლები")
                    bullet("შესვლის სესიები ყველა მოწყობილობაზე, მათ შორის ამ აპლიკაციაში")
                }
                .padding(.vertical, 4)
            } footer: {
                Text("თქვენთვის შესრულებული პროექტები და ფინანსური ჩანაწერები რჩება კომპანიაში, თუმცა თქვენს ანგარიშს აღარ დაუკავშირდება.")
            }

            Section {
                FormFieldRow(title: "პაროლი", error: passwordError) {
                    SecureField("მიმდინარე პაროლი", text: $password)
                        .textContentType(.password)
                        .onChange(of: password) { passwordError = nil }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if let errorMessage {
                        FormErrorBanner(message: errorMessage)
                    }
                    Text("დასადასტურებლად შეიყვანეთ მიმდინარე პაროლი.")
                        .font(.footnote)
                }
                .padding(.top, 4)
            }

            Section {
                Button(role: .destructive, action: askToConfirm) {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                        } else {
                            Text("ანგარიშის წაშლა")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(isDeleting)
            }
        }
        .confirmationDialog(
            "ნამდვილად გსურთ ანგარიშის სამუდამოდ წაშლა? ამ მოქმედების გაუქმება შეუძლებელია.",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("წაშლა", role: .destructive, action: delete)
            Button("გაუქმება", role: .cancel) {}
        }
    }

    private var staffNotice: some View {
        ContentUnavailableView {
            Label("წაშლა შეუძლებელია", systemImage: "person.badge.key")
        } description: {
            Text("ადმინისტრატორის ან მოდერატორის ანგარიშის წაშლა შეუძლებელია. ჯერ როლი უნდა მოიხსნას.")
        } actions: {
            if let email = contacts.mainEmail {
                ContactButton(action: .email(email.email)) {
                    Text("დაგვიკავშირდით: \(email.email)")
                }
            } else {
                Button("დაგვიკავშირდით") { navigation.open(.contact) }
            }
        }
    }

    private var deleted: some View {
        ContentUnavailableView {
            Label("ანგარიში წაიშალა", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } description: {
            Text("თქვენი ანგარიში წაიშალა. დადასტურება გამოგზავნილია თქვენს ელ-ფოსტაზე.")
        } actions: {
            Button("მთავარ გვერდზე დაბრუნება") { navigation.goHome() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func bullet(_ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
        .font(.subheadline)
    }

    /// Checks the field first, so the dialog only opens for a request that can succeed.
    private func askToConfirm() {
        errorMessage = nil
        passwordError = password.isEmpty ? "პაროლი აუცილებელია" : nil
        guard passwordError == nil else { return }
        isConfirming = true
    }

    private func delete() {
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await auth.deleteAccount(password: password)
                password = ""
            } catch let error as APIError {
                if let message = error.details?["password"] {
                    passwordError = message
                } else {
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
        AccountDeletionView()
    }
    .environmentObject(AuthViewModel())
}
