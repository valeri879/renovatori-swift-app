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

/// "ჩვენ მიერ შესრულებული პროექტები": horizontally scrolling photo cards.
struct ProjectsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "ჩვენ მიერ შესრულებული პროექტები",
                subtitle: "პროექტები, რომლეიც ჩვენს მიერ შესრულდა"
            )
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(MainPageData.projects) { project in
                        ProjectCard(project: project)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.85 }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

private struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(5 / 3, contentMode: .fit)
                .overlay {
                    Image(resource: "\(project.image).jpg")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(project.title)
                .font(.headline)
            Text(project.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
