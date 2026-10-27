import SwiftUI

/// "ჩემი პროფილი": the signed-in user's details and logout.
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var isConfirmingLogout = false
    @State private var isLoggingOut = false

    var body: some View {
        Group {
            if let user = auth.currentUser {
                content(for: user)
            } else {
                ContentUnavailableView("არ ხართ ავტორიზებული", systemImage: "person.crop.circle.badge.xmark")
            }
        }
        .navigationTitle("ჩემი პროფილი")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for user: User) -> some View {
        List {
            Section {
                HStack(spacing: 16) {
                    avatar(for: user)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName)
                            .font(.title3.bold())
                        verificationBadge(isVerified: user.isVerified)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("კონტაქტი") {
                contactRow("ელ-ფოსტა", value: user.email, systemImage: "envelope")
                contactRow("ტელეფონი", value: user.phoneNumber, systemImage: "phone")
            }

            Section("ანგარიში") {
                if user.isAdmin || user.isModerator {
                    LabeledContent {
                        Text(user.isAdmin ? "ადმინისტრატორი" : "მოდერატორი")
                    } label: {
                        Label("როლი", systemImage: "person.badge.key")
                    }
                }
                if let createdAt = user.createdAt {
                    LabeledContent {
                        Text(createdAt, format: .dateTime.day().month().year())
                    } label: {
                        Label("რეგისტრაცია", systemImage: "calendar")
                    }
                }
            }

            if user.isStaff {
                Section("ადმინისტრირება") {
                    NavigationLink(value: AppRoute.expenses) {
                        Label("ხარჯები", systemImage: "banknote")
                    }
                }
            }

            Section("უსაფრთხოება") {
                if !user.isVerified {
                    NavigationLink(value: AppRoute.emailVerification) {
                        Label {
                            Text("ელ-ფოსტის დადასტურება")
                        } icon: {
                            Image(systemName: "envelope.badge")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                NavigationLink(value: AppRoute.passwordChange) {
                    Label("პაროლის შეცვლა", systemImage: "key")
                }
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingLogout = true
                } label: {
                    HStack {
                        Label("გასვლა", systemImage: "rectangle.portrait.and.arrow.right")
                        if isLoggingOut {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isLoggingOut)
            }
        }
        .refreshable {
            try? await auth.reloadUser()
        }
        .confirmationDialog("გსურთ ანგარიშიდან გასვლა?", isPresented: $isConfirmingLogout, titleVisibility: .visible) {
            Button("გასვლა", role: .destructive) {
                isLoggingOut = true
                Task {
                    await auth.logout()
                    isLoggingOut = false
                }
            }
            Button("გაუქმება", role: .cancel) {}
        }
    }

    /// Caption above the value, so long emails get the full row width instead of wrapping mid-word.
    private func contactRow(_ title: String, value: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .textSelection(.enabled)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }

    private func avatar(for user: User) -> some View {
        RemoteImage(url: user.profileImageURL, fallbackAsset: "unisex-avatar")
            .frame(width: 64, height: 64)
            .clipShape(Circle())
    }

    @ViewBuilder
    private func verificationBadge(isVerified: Bool) -> some View {
        if isVerified {
            Label("ვერიფიცირებული", systemImage: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(.green)
        } else {
            Label("ელ-ფოსტა არ არის დადასტურებული", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthViewModel())
}
