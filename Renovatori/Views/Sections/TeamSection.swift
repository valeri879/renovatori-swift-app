import SwiftUI

/// "ჩვენი გუნდი": horizontally scrolling partner cards.
struct TeamSection: View {
    var body: some View {
        if !MainPageData.partners.isEmpty {
            VStack(spacing: 16) {
                SectionHeader(
                    title: "ჩვენი გუნდი",
                    subtitle: "ჩვენი პარტნიორი პროფესიონალები, რომლებიც გამოცდილებით, პასუხისმგებლობით და ხარისხზე ორიენტირებული მუშაობით ქმნიან რენოვატორის სერვისს."
                )
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(MainPageData.partners) { partner in
                            PartnerCard(partner: partner)
                                .containerRelativeFrame(.horizontal, count: 2, spacing: 12)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }
}

private struct PartnerCard: View {
    let partner: Partner

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RemoteImage(url: partner.imageURL, fallbackAsset: "unisex-avatar")
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 4)

            Text(partner.name)
                .font(.headline)
            Text(partner.profession)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
