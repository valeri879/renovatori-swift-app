import SwiftUI

/// One project from `GET /projects/:id`: photo gallery, facts and description.
struct ProjectDetailView: View {
    let id: String

    @State private var state: Loadable<ProjectDetail> = .loading
    @State private var galleryIndex = 0
    @State private var viewerIndex: Int?

    var body: some View {
        content
            .navigationTitle("პროექტი")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: id) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error, notFoundTitle: "პროექტი ვერ მოიძებნა") { await load() }
        case .loaded(let project):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    gallery(project.images)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(project.title)
                            .font(.title2.bold())
                        ProjectFacts(location: project.location, area: project.area)
                        if let dates = dateRange(project) {
                            Label(dates, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if !project.description.isEmpty {
                            Divider()
                            HTMLContentView(html: project.description)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .fullScreenCover(item: Binding(
                get: { viewerIndex.map(GalleryPosition.init) },
                set: { viewerIndex = $0?.index }
            )) { position in
                ImageViewer(images: project.images, startIndex: position.index)
            }
        }
    }

    @ViewBuilder
    private func gallery(_ images: [ProjectDetail.Image]) -> some View {
        if images.isEmpty {
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay { RemoteImage(url: nil, fallbackAsset: "cover.jpg") }
        } else {
            TabView(selection: $galleryIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Button {
                        viewerIndex = index
                    } label: {
                        RemoteImage(url: APIConfig.imageURL(image.url))
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                    .accessibilityLabel("ფოტო \(index + 1), \(images.count)-დან")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
            .aspectRatio(4 / 3, contentMode: .fit)
        }
    }

    private func dateRange(_ project: ProjectDetail) -> String? {
        switch (project.startDate, project.endDate) {
        case let (start?, end?): "\(start.siteFormatted) – \(end.siteFormatted)"
        case let (start?, nil): "დაწყება: \(start.siteFormatted)"
        case let (nil, end?): "დასრულება: \(end.siteFormatted)"
        case (nil, nil): nil
        }
    }

    private func load() async {
        do {
            let response: ProjectDetailResponse = try await APIClient.shared.send(
                Endpoint(method: .get, path: "projects/\(id)")
            )
            state = .loaded(response.project)
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }
}

private struct GalleryPosition: Identifiable {
    let index: Int
    var id: Int { index }
}

/// Full-screen, swipeable photos with pinch and double-tap zoom.
private struct ImageViewer: View {
    let images: [ProjectDetail.Image]
    @State var startIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $startIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZoomableImage(url: APIConfig.imageURL(image.url))
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
            .accessibilityLabel("დახურვა")
        }
        .preferredColorScheme(.dark)
    }
}

private struct ZoomableImage: View {
    let url: URL?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(magnify)
                    .simultaneousGesture(scale > 1 ? pan : nil)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring) {
                            if scale > 1 {
                                reset()
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), 5)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    withAnimation(.spring) { reset() }
                }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(id: "000000000000000000000000")
    }
}
