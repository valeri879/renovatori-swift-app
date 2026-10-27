import SwiftUI

/// "ჩვენ შესახებ" screen (`views/pages/about-page/about-page.pug`), built from standard SwiftUI components.
struct AboutView: View {
    /// Opens the prices screen.
    let showPrices: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                AboutHero()
                values
                whoWeAre
                clientSpace
                process
                callToAction
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("ჩვენ შესახებ")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Values

    private var values: some View {
        VStack(spacing: 12) {
            ForEach(Array(AboutPageData.values.enumerated()), id: \.element.id) { index, value in
                GroupBox {
                    Text(value.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(.tint)
                        Text(value.title)
                            .font(.headline)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: Who we are

    private var whoWeAre: some View {
        VStack(alignment: .leading, spacing: 16) {
            AboutSectionHeader(
                label: AboutPageData.whoLabel,
                title: AboutPageData.whoTitle,
                text: AboutPageData.whoText
            )

            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(AboutPageData.differences) { item in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.text)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            AssetIcon(name: item.icon ?? "clock", size: 24)
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    // MARK: Client space

    private var clientSpace: some View {
        VStack(alignment: .leading, spacing: 16) {
            AboutSectionHeader(
                label: AboutPageData.clientLabel,
                title: AboutPageData.clientTitle,
                text: AboutPageData.clientText
            )

            NavigationLink("პროექტების ნახვა", value: AppRoute.projects)
                .buttonStyle(.bordered)

            ProjectDashboardPreview()
        }
        .padding(.horizontal)
    }

    // MARK: Process

    private var process: some View {
        VStack(alignment: .leading, spacing: 16) {
            AboutSectionHeader(
                label: AboutPageData.processLabel,
                title: AboutPageData.processTitle,
                text: AboutPageData.processText
            )

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(AboutPageData.processSteps.enumerated()), id: \.element.id) { index, step in
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
        }
        .padding(.horizontal)
    }

    // MARK: Call to action

    private var callToAction: some View {
        VStack(spacing: 12) {
            Text(AboutPageData.ctaTitle)
                .font(.title2.bold())
            Text(AboutPageData.ctaText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                NavigationLink(value: AppRoute.consultation) {
                    Text("კონსულტაციის მოთხოვნა")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: showPrices) {
                    Text("ფასების ნახვა")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

/// Cover photo with the headline, intro, actions and the "service idea" note.
private struct AboutHero: View {
    var body: some View {
        Color.clear
            .frame(height: 520)
            .overlay {
                Image(resource: "cover.jpg")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AboutPageData.heroEyebrow)
                        .font(.caption.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(AboutPageData.heroTitle)
                        .font(.title.bold())
                    Text(AboutPageData.heroText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    HStack(spacing: 12) {
                        NavigationLink("კონსულტაცია", value: AppRoute.consultation)
                            .buttonStyle(.borderedProminent)
                        NavigationLink("პროექტები", value: AppRoute.projects)
                            .buttonStyle(.bordered)
                            .tint(.white)
                    }
                    .controlSize(.large)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(AboutPageData.ideaLabel)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(AboutPageData.ideaText)
                            .font(.footnote)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .environment(\.colorScheme, .dark)
                    .padding(.top, 4)
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.85), .black.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
    }
}

/// Illustration of the client's project page: badge, progress and what it contains.
private struct ProjectDashboardPreview: View {
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(AboutPageData.dashboardProgressLabel)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(AboutPageData.dashboardProgressNote)
                            .bold()
                    }
                    .font(.caption)
                    ProgressView(value: AboutPageData.dashboardProgress)
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(AboutPageData.dashboardCards) { card in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(card.text)
                                    .font(.footnote.bold())
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                }
            }
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AboutPageData.dashboardBadge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.tint, in: Capsule())
                    Text(AboutPageData.dashboardTitle)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 4)
        }
    }
}

/// Small tinted label, bold title and secondary paragraph that open each about section.
private struct AboutSectionHeader: View {
    let label: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.tint)
            Text(title)
                .font(.title2.bold())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AboutView {}
    }
}
