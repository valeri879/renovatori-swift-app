import SwiftUI

/// "კონსულტაცია" screen (`views/pages/consultation-page/consultation-page.pug`).
/// Booking requires an account, as on the site: guests are asked to sign in first.
struct ConsultationView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.appNavigation) private var navigation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 32) {
                    header {
                        withAnimation { proxy.scrollTo(PricingAnchor.id, anchor: .top) }
                    }
                    benefits
                    steps
                    pricing
                        .id(PricingAnchor.id)
                    FAQSection()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("კონსულტაცია")
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum PricingAnchor {
        static let id = "consultation-pricing"
    }

    // MARK: Sections

    private func header(showPricing: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Text(ConsultationPageData.eyebrow)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(ConsultationPageData.title)
                .font(.title.bold())
            Text(ConsultationPageData.intro)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("კონსულტაციის დაჯავშნა", action: showPricing)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }

    private var benefits: some View {
        VStack(spacing: 12) {
            sectionTitle(ConsultationPageData.benefitsTitle)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ConsultationPageData.benefits) { item in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.subheadline.bold())
                            Text(item.text)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(ConsultationPageData.stepsTitle)
            ForEach(Array(ConsultationPageData.steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "\(index + 1).circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline.bold())
                        Text(step.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var pricing: some View {
        VStack(spacing: 16) {
            sectionTitle(ConsultationPageData.pricingTitle)

            ForEach(ConsultationPageData.packages) { package in
                PackageCard(package: package) { book(package) }
            }

            Label(ConsultationPageData.refundNote, systemImage: "info.circle.fill")
                .font(.footnote)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    // MARK: Booking

    /// Opens the order form for `package`, signing the guest in first when needed.
    private func book(_ package: ConsultationPackage) {
        let route = AppRoute.consultationOrder(package.name)
        if auth.currentUser == nil {
            navigation.signIn(route)
        } else {
            navigation.open(route)
        }
    }
}

/// One price card: name, price, features and a booking button.
private struct PackageCard: View {
    let package: ConsultationPackage
    let book: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(package.name)
                .font(.headline)

            Text(package.priceFormatted)
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 6) {
                ForEach(package.features, id: \.self) { feature in
                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Group {
                if package.isHighlighted {
                    Button(action: book) { bookLabel }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button(action: book) { bookLabel }
                        .buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            if package.isHighlighted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.tint, lineWidth: 2)
            }
        }
    }

    private var bookLabel: some View {
        Text("დაჯავშნა")
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ConsultationView()
    }
    .environmentObject(AuthViewModel())
}
