import SwiftUI

/// One post from `GET /blog/:id`: cover, title, date and the HTML body.
struct BlogDetailView: View {
    let id: String

    @State private var state: Loadable<BlogDetail> = .loading

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
        case .loaded(let blog):
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
            state = .loaded(response.blog)
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }
}

#Preview {
    NavigationStack {
        BlogDetailView(id: "000000000000000000000000")
    }
}
