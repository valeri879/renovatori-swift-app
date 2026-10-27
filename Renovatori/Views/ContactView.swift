import SwiftUI

/// "კონტაქტი" screen (`views/pages/contact-page/contact-page.pug`): hours, phone, email and social links.
struct ContactView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // The site swaps to a dark illustration in dark mode.
                    Image(resource: colorScheme == .dark ? "contact-illustration-dark" : "contact-illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text("კომუნიკაცია ჩვენთან მარტივია — უბრალოდ აირჩიეთ ქვემოთ ჩამოთვლილი საშუალებებიდან ერთი.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section("სამუშაო საათები") {
                Label {
                    Text("ორშაბათი - პარასკევი, ") + Text("10:00-18:00").bold()
                } icon: {
                    AssetIcon(name: "clock", size: 18)
                        .foregroundStyle(.tint)
                }
            }

            Section("ტელეფონი") {
                ContactButton(action: .call) {
                    Label { Text(SiteInfo.phoneDisplay) } icon: { AssetIcon(name: "phone", size: 18) }
                }
            }

            Section("ელ-ფოსტა") {
                ContactButton(action: .email) {
                    Label { Text(SiteInfo.email) } icon: { AssetIcon(name: "envelope", size: 18) }
                }
            }

            Section("სოციალური ქსელები") {
                socialLink("Facebook", icon: "facebook-black", url: SiteInfo.facebookURL)
                socialLink("Instagram", icon: "instagram-black", url: SiteInfo.instagramURL)
                socialLink("TikTok", icon: "tiktok-black", url: SiteInfo.tiktokURL)
            }
        }
        .navigationTitle("კონტაქტი")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func socialLink(_ title: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Label { Text(title) } icon: { AssetIcon(name: icon, size: 18) }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactView()
    }
}
