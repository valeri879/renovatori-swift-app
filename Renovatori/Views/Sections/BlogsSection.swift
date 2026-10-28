import SwiftUI

/// "ბლოგები რემონტზე": the 3 latest posts from `GET /blog` (like the web main page); each row opens its post.
struct BlogsSection: View {
    @StateObject private var latest = PagedList<BlogSummary>(path: "blog", pageSize: 3)

    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ბლოგები რემონტზე",
                subtitle: "წაიკითხეთ ბლოგები რემონტზე: ინტერიერის დიზაინი, სარემონტო ფასები, მასალების არჩევა და პრაქტიკული რჩევები ბინისა და სახლის განახლებისთვის."
            )

            if latest.isEmpty {
                ContentUnavailableView("ბლოგები ჯერ არ მოიძებნა.", systemImage: "newspaper")
            } else if latest.items.isEmpty {
                // Loading, or the request failed: the "all blogs" button below still works.
                if latest.error == nil {
                    ProgressView()
                }
            } else {
                GroupBox {
                    VStack(spacing: 12) {
                        ForEach(Array(latest.items.enumerated()), id: \.element.id) { index, blog in
                            if index > 0 {
                                Divider()
                            }
                            BlogRow(blog: blog)
                        }
                    }
                }
            }

            NavigationLink(value: AppRoute.blog) {
                Label("ყველა ბლოგის ნახვა", systemImage: "newspaper")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .task { await latest.loadIfNeeded() }
    }
}

private struct BlogRow: View {
    let blog: BlogSummary

    var body: some View {
        NavigationLink(value: AppRoute.blogPost(blog.id)) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImage(url: APIConfig.imageURL(blog.coverImageUrl), fallbackAsset: "cover.jpg")
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(blog.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
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
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
                    .frame(maxHeight: 88)
            }
        }
        // Plain style keeps the row's own text colors instead of tinting everything.
        .buttonStyle(.plain)
    }
}
