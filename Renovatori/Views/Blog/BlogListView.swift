import SwiftUI

/// "ბლოგი": published posts from `GET /blog`, loaded page by page, newest or oldest first.
struct BlogListView: View {
    @StateObject private var list = PagedList<BlogSummary>(path: "blog", query: Self.query(for: .desc))
    @State private var sort: BlogSort = .desc

    var body: some View {
        content
            .navigationTitle("ბლოგი")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("დალაგება", selection: $sort) {
                            ForEach(BlogSort.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("დალაგება")
                }
            }
            .task { await list.loadIfNeeded() }
            .onChange(of: sort) { _, newSort in
                Task { await list.reload(query: Self.query(for: newSort)) }
            }
    }

    @ViewBuilder
    private var content: some View {
        if list.items.isEmpty {
            if let error = list.error {
                ErrorStateView(error: error) { await list.reload() }
            } else if list.isEmpty {
                ContentUnavailableView("ბლოგები ჯერ არ მოიძებნა.", systemImage: "newspaper")
            } else {
                ProgressView()
            }
        } else {
            List {
                ForEach(list.items) { blog in
                    NavigationLink(value: AppRoute.blogPost(blog.id)) {
                        BlogSummaryRow(blog: blog)
                    }
                    .task { await list.loadMoreIfNeeded(after: blog) }
                }
                if list.hasNext {
                    PageLoadingFooter()
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable { await list.reload() }
        }
    }

    private static func query(for sort: BlogSort) -> [URLQueryItem] {
        [URLQueryItem(name: "sort", value: sort.rawValue)]
    }
}

/// A post in the blog list and under a post („ბოლო ბლოგები").
struct BlogSummaryRow: View {
    let blog: BlogSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImage(url: APIConfig.imageURL(blog.coverImageUrl), fallbackAsset: "cover.jpg")
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(blog.title)
                    .font(.subheadline.bold())
                    .lineLimit(3)
                if !blog.metaDescription.isEmpty {
                    Text(blog.metaDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let date = blog.createdAt {
                    Label(date.siteFormatted, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BlogListView()
    }
}
