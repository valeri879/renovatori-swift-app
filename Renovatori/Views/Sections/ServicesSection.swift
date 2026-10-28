import SwiftUI

/// "ჩვენ გთავაზობთ შემდეგ მომსახურებებს": one group box per service.
struct ServicesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ჩვენ გთავაზობთ შემდეგ მომსახურებებს",
                subtitle: "მომსახურებები, რომლებსაც გთავაზობთ ჩვენი გუნდი."
            )

            ForEach(MainPageData.services) { service in
                GroupBox {
                    Text(service.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } label: {
                    Label {
                        Text(service.title)
                            .font(.headline)
                    } icon: {
                        AssetIcon(name: service.icon, size: 28)
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// "ჩვენ მიერ შესრულებული პროექტები": the 3 latest published projects from `GET /projects`,
/// as horizontally scrolling photo cards; each card opens its project.
struct ProjectsSection: View {
    @StateObject private var latest = PagedList<ProjectSummary>(path: "projects", pageSize: 3)

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ჩვენ მიერ შესრულებული პროექტები",
                subtitle: "პროექტები, რომლეიც ჩვენს მიერ შესრულდა"
            )
            .padding(.horizontal)

            if latest.isEmpty {
                ContentUnavailableView("პროექტები ჯერ არ მოიძებნა.", systemImage: "hammer")
            } else if latest.items.isEmpty {
                // Loading, or the request failed: the "all projects" button below still works.
                if latest.error == nil {
                    ProgressView()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(latest.items) { project in
                            NavigationLink(value: AppRoute.project(project.id)) {
                                ProjectCard(project: project)
                            }
                            // Plain style keeps the card's own text colors instead of tinting everything.
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.85 }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
            }

            NavigationLink(value: AppRoute.projects) {
                Label("ყველა პროექტის ნახვა", systemImage: "hammer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
        }
        .task { await latest.loadIfNeeded() }
    }
}

private struct ProjectCard: View {
    let project: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(5 / 3, contentMode: .fit)
                .overlay {
                    RemoteImage(url: APIConfig.imageURL(project.coverImageUrl), fallbackAsset: "cover.jpg")
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(project.title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            ProjectFacts(location: project.location, area: project.area)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
