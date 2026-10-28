import SwiftUI

/// One post from `GET /blog/:id`: cover, title, date and the HTML body, then the latest
/// 3 posts and 3 projects (like the web blog page).
struct BlogDetailView: View {
    let id: String

    @State private var state: Loadable<BlogDetailResponse> = .loading

    var body: some View {
        content
            .navigationTitle("ბლოგი")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: id) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error, notFoundTitle: "ბლოგი ვერ მოიძებნა") { await load() }
        case .loaded(let response):
            let blog = response.blog
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let cover = APIConfig.imageURL(blog.coverImageUrl) {
                        Color.clear
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .overlay { RemoteImage(url: cover, fallbackAsset: "cover.jpg") }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text(blog.title)
                        .font(.title2.bold())

                    if let date = blog.createdAt {
                        Label(date.siteFormatted, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HTMLContentView(html: blog.description)

                    if !response.latestBlogs.isEmpty {
                        Divider()
                        Text("ბოლო ბლოგები")
                            .font(.title3.bold())
                        ForEach(response.latestBlogs) { latest in
                            NavigationLink(value: AppRoute.blogPost(latest.id)) {
                                BlogSummaryRow(blog: latest)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !response.latestProjects.isEmpty {
                        Divider()
                        Text("ბოლო 3 პროექტი")
                            .font(.title3.bold())
                        ForEach(response.latestProjects) { project in
                            NavigationLink(value: AppRoute.project(project.id)) {
                                LatestProjectRow(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: SiteInfo.page("/blog/\(blog.id)")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("გაზიარება")
                }
            }
        }
    }

    private func load() async {
        do {
            let response: BlogDetailResponse = try await APIClient.shared.send(
                Endpoint(method: .get, path: "blog/\(id)")
            )
            state = .loaded(response)
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }
}

/// A project under a post: thumbnail, title and date, like the web's „ბოლო 3 პროექტი" cards.
private struct LatestProjectRow: View {
    let project: ProjectSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(url: APIConfig.imageURL(project.coverImageUrl), fallbackAsset: "cover.jpg")
                .frame(width: 96, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.subheadline.bold())
                    .lineLimit(3)
                ProjectFacts(location: project.location, area: project.area)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        BlogDetailView(id: "000000000000000000000000")
    }
}
