import SwiftUI

/// "პროექტები": completed projects from `GET /projects`, loaded page by page. Admins and moderators
/// also see drafts, with the web's status filter and badges (`views/pages/project-list-page`).
struct ProjectsListView: View {
    /// The web's `?status=` filter, available to staff only.
    private enum PublishFilter: String, CaseIterable, Identifiable {
        case all, published, draft

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: "ყველა პროექტი"
            case .published: "გამოქვეყნებული"
            case .draft: "დრაფტი"
            }
        }
    }

    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var list = PagedList<ProjectSummary>(path: "projects")
    @State private var filter = PublishFilter.all
    /// The account the list was last loaded for, so going back to the list keeps it.
    @State private var loadedFor: String?

    private var isStaff: Bool { auth.currentUser?.isStaff == true }

    var body: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                if isStaff {
                    Picker("სტატუსი", selection: $filter) {
                        ForEach(PublishFilter.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
                }
            }
            .navigationTitle("პროექტები")
            .navigationBarTitleDisplayMode(.inline)
            // Signing in or out changes which projects are listed, so reload for a new account.
            .task(id: auth.currentUser?.id ?? "") {
                let account = auth.currentUser?.id ?? ""
                guard loadedFor != account else { return }
                loadedFor = account
                await reloadList()
            }
            .onChange(of: filter) { _, _ in
                Task { await reloadList() }
            }
    }

    /// Staff send their token (and the filter) to include drafts; everyone else gets the public list.
    private func reloadList() async {
        let query = isStaff ? [URLQueryItem(name: "status", value: filter.rawValue)] : []
        await list.reload(query: query, requiresAuth: isStaff)
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
                            ProjectCardView(project: project, showsPublishStatus: isStaff)
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
    /// Staff see the web's „გამოქვეყნებული" / „დრაფტი" badges.
    let showsPublishStatus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(16 / 10, contentMode: .fit)
                .overlay {
                    RemoteImage(url: APIConfig.imageURL(project.coverImageUrl), fallbackAsset: "cover.jpg")
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let isPublished = project.isPublished, showsPublishStatus {
                Text(isPublished ? "გამოქვეყნებული" : "დრაფტი")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isPublished ? Color.green : Color.gray, in: Capsule())
            }
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
    .environmentObject(AuthViewModel())
}
