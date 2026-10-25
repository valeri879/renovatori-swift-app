import SwiftUI

/// Phone, email, working hours and social links from the site's top bar.
struct ContactBar: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                ContactButton(action: .call) {
                    Label { Text(SiteInfo.phoneDisplay) } icon: { AssetIcon(name: "phone", size: 14) }
                }
                ContactButton(action: .email) {
                    Label { Text(SiteInfo.email) } icon: { AssetIcon(name: "envelope", size: 14) }
                }
                Label {
                    Text("ორშ-პარ, ") + Text("10:00-18:00").bold()
                } icon: {
                    AssetIcon(name: "clock", size: 14)
                }
                .foregroundStyle(.secondary)
            }
            .font(.footnote)

            Spacer()

            HStack(spacing: 8) {
                socialLink("facebook-black", url: SiteInfo.facebookURL)
                socialLink("instagram-black", url: SiteInfo.instagramURL)
                socialLink("tiktok-black", url: SiteInfo.tiktokURL)
            }
        }
        .padding(.horizontal)
    }

    private func socialLink(_ icon: String, url: URL) -> some View {
        Link(destination: url) {
            AssetIcon(name: icon, size: 16)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(.primary)
    }
}

/// Cover photo with the headline and the two call-to-action buttons.
struct CoverView: View {
    /// Scrolls the page down to the price comparison.
    let showPrices: () -> Void

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
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("რემონტი, რომელიც იწყება გეგმიდან და სრულდება სრულყოფილებით.")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 12) {
                        Button(action: showPrices) {
                            Label { Text("ფასები") } icon: { AssetIcon(name: "dollar-white", size: 16) }
                        }
                        .buttonStyle(.borderedProminent)

                        ContactButton(action: .call) {
                            Label { Text("კონტაქტი") } icon: { AssetIcon(name: "phone-black", size: 18) }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    .controlSize(.large)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.75), .black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
    }
}
