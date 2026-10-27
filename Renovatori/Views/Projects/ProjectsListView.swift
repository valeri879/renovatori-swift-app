import SwiftUI

/// "პროექტები": completed projects from `GET /projects`, loaded page by page.
struct ProjectsListView: View {
    @StateObject private var list = PagedList<ProjectSummary>(path: "projects")

    var body: some View {
        content
            .navigationTitle("პროექტები")
            .navigationBarTitleDisplayMode(.inline)
            .task { await list.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if list.items.isEmpty {
            if let error = list.error {
                ErrorStateView(error: error) { await list.reload() }
            } else if list.isEmpty {
                ContentUnavailableView("პროექტები ჯერ არ მოიძებნა.", systemImage: "hammer")
            } else {
                ProgressView()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(list.items) { project in
                        NavigationLink(value: AppRoute.project(project.id)) {
                            ProjectCardView(project: project)
                        }
                        .buttonStyle(.plain)
                        .task { await list.loadMoreIfNeeded(after: project) }
                    }
                    if list.hasNext {
                        PageLoadingFooter()
                    }
                }
                .padding()
            }
            .refreshable { await list.reload() }
        }
    }
}

private struct ProjectCardView: View {
    let project: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(16 / 10, contentMode: .fit)
                .overlay {
                    RemoteImage(url: APIConfig.imageURL(project.coverImageUrl), fallbackAsset: "cover.jpg")
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(project.title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            ProjectFacts(location: project.location, area: project.area)
        }
        .contentShape(Rectangle())
    }
}

/// Location and area, shown on project cards and the detail screen.
struct ProjectFacts: View {
    let location: String
    let area: Double?

    var body: some View {
        HStack(spacing: 16) {
            if !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
            }
            if let area {
                Label("\(area.compactFormatted) მ²", systemImage: "square.dashed")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        ProjectsListView()
    }
}
