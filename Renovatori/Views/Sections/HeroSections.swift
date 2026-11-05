import SwiftUI

/// Main phone, main email, working hours and social links from the site's top bar.
struct ContactBar: View {
    @Environment(\.siteContacts) private var contacts

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                if let phone = contacts.mainPhone {
                    ContactButton(action: .call(phone)) {
                        Label { Text(phone.display) } icon: { AssetIcon(name: "phone", size: 14) }
                    }
                }
                if let email = contacts.mainEmail {
                    ContactButton(action: .email(email.email)) {
                        Label { Text(email.email) } icon: { AssetIcon(name: "envelope", size: 14) }
                    }
                }
                ForEach(contacts.workingHours) { hours in
                    Label {
                        Text("\(hours.daysShortLabel), ") + Text("\(hours.opensAt)-\(hours.closesAt)").bold()
                    } icon: {
                        AssetIcon(name: "clock", size: 14)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .font(.footnote)

            Spacer()

            HStack(spacing: 8) {
                ForEach(contacts.socialLinks) { link in
                    if let url = link.link {
                        Link(destination: url) {
                            SocialIcon(link: link)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .tint(.primary)
                        .accessibilityLabel(link.title)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Cover photo with the headline and the two call-to-action buttons.
struct CoverView: View {
    /// Opens the prices screen.
    let showPrices: () -> Void

    @Environment(\.siteContacts) private var contacts
    @Environment(\.appNavigation) private var navigation

    var body: some View {
        // The photo sits in an overlay so its natural width can't widen the page.
        Color.clear
            .frame(height: 340)
            .overlay {
                Image(resource: "cover.jpg")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            // Darkens the photo from the bottom up, so the white slogan stays readable over light areas.
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.85), location: 0),
                        .init(color: .black.opacity(0.6), location: 0.45),
                        .init(color: .black.opacity(0.15), location: 1),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("რემონტი, რომელიც იწყება გეგმიდან და სრულდება სრულყოფილებით.")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 1)

                    HStack(spacing: 12) {
                        Button(action: showPrices) {
                            Label { Text("ფასები") } icon: { AssetIcon(name: "dollar-white", size: 16) }
                        }
                        .buttonStyle(.borderedProminent)

                        // Calls the main phone (the call request form outside working hours); without one
                        // it opens the contact screen, like the web.
                        if let phone = contacts.mainPhone {
                            ContactButton(action: .call(phone)) { contactLabel }
                                .buttonStyle(.bordered)
                                .tint(.white)
                        } else {
                            Button { navigation.open(.contact) } label: { contactLabel }
                                .buttonStyle(.bordered)
                                .tint(.white)
                        }
                    }
                    .controlSize(.large)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
    }

    private var contactLabel: some View {
        Label { Text("კონტაქტი") } icon: { AssetIcon(name: "phone-black", size: 18) }
    }
}
