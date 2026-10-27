import SwiftUI

/// "ბლოგები რემონტზე": latest posts as tappable rows.
struct BlogsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ბლოგები რემონტზე",
                subtitle: "წაიკითხეთ ბლოგები რემონტზე: ინტერიერის დიზაინი, სარემონტო ფასები, მასალების არჩევა და პრაქტიკული რჩევები ბინისა და სახლის განახლებისთვის."
            )

            if MainPageData.blogs.isEmpty {
                ContentUnavailableView("ბლოგები ჯერ არ მოიძებნა.", systemImage: "newspaper")
            } else {
                GroupBox {
                    VStack(spacing: 12) {
                        ForEach(Array(MainPageData.blogs.enumerated()), id: \.element.id) { index, blog in
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
    }
}

private struct BlogRow: View {
    let blog: BlogPost

    var body: some View {
        NavigationLink(value: AppRoute.blog) {
            HStack(alignment: .top, spacing: 12) {
                RemoteImage(url: blog.imageURL)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(blog.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                    Text(blog.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Label(blog.date, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
