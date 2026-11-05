import SwiftUI

/// "კონტაქტი" screen (`views/pages/contact-page/contact-page.pug`): hours, phones, emails, social links
/// and the call request form.
struct ContactView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.siteContacts) private var contacts

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
                ForEach(contacts.workingHours) { hours in
                    Label {
                        Text("\(hours.daysLabel), ") + Text("\(hours.opensAt)-\(hours.closesAt)").bold()
                    } icon: {
                        AssetIcon(name: "clock", size: 18)
                            .foregroundStyle(.tint)
                    }
                }
            }

            Section("ტელეფონი") {
                ForEach(contacts.phones) { phone in
                    ContactButton(action: .call(phone)) {
                        Label { labeled(phone.display, phone.label) } icon: { AssetIcon(name: "phone", size: 18) }
                    }
                }
            }

            Section("ელ-ფოსტა") {
                ForEach(contacts.emails) { email in
                    ContactButton(action: .email(email.email)) {
                        Label { labeled(email.email, email.label) } icon: { AssetIcon(name: "envelope", size: 18) }
                    }
                }
            }

            if !contacts.socialLinks.isEmpty {
                Section("სოციალური ქსელები") {
                    ForEach(contacts.socialLinks) { link in
                        if let url = link.link {
                            socialLink(link, url: url)
                        }
                    }
                }
            }

            // Like the web, the call request form is reachable at any time of day.
            Section {
                NavigationLink(value: AppRoute.callRequest) {
                    Label("ზარის მოთხოვნა", systemImage: "phone.arrow.down.left")
                }
            }
        }
        .navigationTitle("კონტაქტი")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: SiteInfo.page("/contact")) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("გაზიარება")
            }
        }
    }

    /// A phone or address followed by its grey label, e.g. "(ოფისი)".
    private func labeled(_ value: String, _ label: String) -> Text {
        label.isEmpty ? Text(value) : Text(value) + Text(" (\(label))").foregroundColor(.secondary)
    }

    private func socialLink(_ link: SiteContacts.SocialLink, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Label { Text(link.title) } icon: { SocialIcon(link: link, size: 18) }
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
