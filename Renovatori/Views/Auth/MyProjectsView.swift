import SwiftUI

/// "ჩემი პროექტები" (`views/pages/profile-my-projects-page`): projects linked to the signed-in user
/// from `GET /profile/my-projects`, published or not, newest first. Each row opens the project.
struct MyProjectsView: View {
    @StateObject private var list = PagedList<ProjectSummary>(path: "profile/my-projects", requiresAuth: true)

    var body: some View {
        content
            .navigationTitle("ჩემი პროექტები")
            .navigationBarTitleDisplayMode(.inline)
            .task { await list.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if list.items.isEmpty {
            if let error = list.error {
                ErrorStateView(error: error) { await list.reload() }
            } else if list.isEmpty {
                ContentUnavailableView(
                    "პროექტები ვერ მოიძებნა",
                    systemImage: "hammer",
                    description: Text("ამ ეტაპზე თქვენთან დაკავშირებული პროექტები ვერ მოიძებნა.")
                )
            } else {
                ProgressView()
            }
        } else {
            List {
                ForEach(list.items) { project in
                    NavigationLink(value: AppRoute.project(project.id)) {
                        MyProjectRow(project: project)
                    }
                    .task { await list.loadMoreIfNeeded(after: project) }
                }
                if list.hasNext {
                    PageLoadingFooter()
                        .listRowSeparator(.hidden)
                }
            }
            .refreshable { await list.reload() }
        }
    }
}

/// Title with the web's „გამოქვეყნებული" / „დრაფტი" badge, description, location and area, creation date.
private struct MyProjectRow: View {
    let project: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.title)
                    .font(.headline)
                Spacer(minLength: 8)
                if let isPublished = project.isPublished {
                    Text(isPublished ? "გამოქვეყნებული" : "დრაფტი")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isPublished ? Color.green : Color.gray, in: Capsule())
                }
            }
            Text(project.metaDescription.isEmpty ? "აღწერა არ არის დამატებული" : project.metaDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            ProjectFacts(location: project.location, area: project.area)
            if let createdAt = project.createdAt {
                Text("შექმნილია: \(ExpenseDetailView.dayTime(createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MyProjectsView()
    }
}
