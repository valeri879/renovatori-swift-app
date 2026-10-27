import SwiftUI

/// One project from `GET /projects/:id`: photo gallery, facts and description. Signed-in users also get
/// what the web project page shows them: dates, client contact and finances (admins, moderators and the
/// linked client) and the project history (admins and the linked client), which admins can add to,
/// edit and delete.
struct ProjectDetailView: View {
    let id: String

    private enum HistorySheet: Identifiable {
        case add
        case edit(ProjectHistoryEntry)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let entry): entry.id
            }
        }
    }

    @EnvironmentObject private var auth: AuthViewModel
    @State private var state: Loadable<ProjectDetailResponse> = .loading
    /// Kept apart from `state` so history changes apply without reloading the page.
    @State private var history: [ProjectHistoryEntry] = []
    @State private var galleryIndex = 0
    @State private var viewer: GalleryPosition?
    @State private var historySheet: HistorySheet?
    @State private var pendingDelete: ProjectHistoryEntry?
    @State private var deletingID: ProjectHistoryEntry.ID?
    @State private var actionError: String?
    @State private var notice: String?

    var body: some View {
        content
            .navigationTitle("პროექტი")
            .navigationBarTitleDisplayMode(.inline)
            // Signing in or out changes what the page shows, so the account is part of the task id.
            .task(id: "\(id)|\(auth.currentUser?.id ?? "")") { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error, notFoundTitle: "პროექტი ვერ მოიძებნა") { await load() }
        case .loaded(let response):
            detail(response)
        }
    }

    private func detail(_ response: ProjectDetailResponse) -> some View {
        let project = response.project
        let access = response.access

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                gallery(project.images)

                VStack(alignment: .leading, spacing: 12) {
                    Text(project.title)
                        .font(.title2.bold())
                    if access.canManage, project.isPublished == false {
                        Text("გამოუქვეყნებელი")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray, in: Capsule())
                    }
                    // Like the web, dates are shown only to the people who may see the client details.
                    if access.canViewClientInfo, let dates = dateRange(project) {
                        Label(dates, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ProjectFacts(location: project.location, area: project.area)

                    if let notice {
                        Label(notice, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity)
                    }
                    if access.canViewClientInfo {
                        clientInfo(response.client)
                    }
                    if let finance = response.financialSummary {
                        financeCard(finance, project: project)
                    }
                    if access.canManage {
                        Button("ისტორიის დამატება", systemImage: "plus") {
                            historySheet = .add
                        }
                        .buttonStyle(.bordered)
                    }
                    if !project.description.isEmpty {
                        Divider()
                        HTMLContentView(html: project.description)
                    }
                    if access.canViewHistory {
                        Divider()
                        historySection(canManage: access.canManage)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .refreshable { await load() }
        .fullScreenCover(item: $viewer) { position in
            ImageViewer(images: position.images, startIndex: position.index)
        }
        .sheet(item: $historySheet) { sheet in
            NavigationStack {
                switch sheet {
                case .add:
                    ProjectHistoryFormView(project: project) { updated, emailSent in
                        applyHistory(updated, notice: emailSent ? "ისტორია დაემატა. კლიენტს ელ-ფოსტა გაეგზავნა." : "ისტორია დაემატა.")
                    }
                case .edit(let entry):
                    ProjectHistoryFormView(project: project, entry: entry) { updated, emailSent in
                        applyHistory(updated, notice: emailSent ? "ისტორია განახლდა. კლიენტს ელ-ფოსტა გაეგზავნა." : "ისტორია განახლდა.")
                    }
                }
            }
        }
        .confirmationDialog(
            "ნამდვილად გსურთ ამ ისტორიის ჩანაწერის წაშლა? ეს მოქმედება შეუქცევადია.",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { entry in
            Button("წაშლა", role: .destructive) {
                Task { await delete(entry) }
            }
        }
        .alert("მოქმედება ვერ შესრულდა", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("კარგი", role: .cancel) {}
        } message: {
            Text(actionError ?? "")
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
                        viewer = GalleryPosition(images: images, index: index)
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

    // MARK: Signed-in blocks

    private func clientInfo(_ client: ProjectDetailResponse.Client?) -> some View {
        PrivateCard(title: "დამკვეთის ინფორმაცია") {
            VStack(spacing: 10) {
                LabeledContent("სახელი", value: nonEmpty(client?.firstName))
                LabeledContent("გვარი", value: nonEmpty(client?.lastName))
                LabeledContent("ელ-ფოსტა") {
                    if let email = client?.email, !email.isEmpty, let url = URL(string: "mailto:\(email)") {
                        Link(email, destination: url)
                    } else {
                        Text("-")
                    }
                }
                LabeledContent("ტელეფონი") {
                    if let phone = client?.phoneNumber, !phone.isEmpty, let url = URL(string: "tel:\(phone.filter(\.isNumber))") {
                        Link(phone, destination: url)
                    } else {
                        Text("-")
                    }
                }
            }
            .font(.subheadline)
        }
    }

    private func financeCard(_ finance: ProjectDetailResponse.FinancialSummary, project: ProjectDetail) -> some View {
        PrivateCard(title: "პროექტის ფინანსები და პროგრესი") {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("ჯამური ღირებულება", value: finance.totalAmountDollar.webMoney(fractionDigits: 2, currency: "$"))
                LabeledContent("ჩასარიცხი თანხა") {
                    Text(finance.remainingAmountDollar.webMoney(fractionDigits: 2, currency: "$"))
                        .foregroundStyle(.red)
                }

                Divider()
                if finance.paidAmounts.isEmpty {
                    Text("ინდივიდუალური ჩარიცხვები ჯერ არ არის დამატებული.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(finance.paidAmounts) { payment in
                        LabeledContent(payment.paidAt?.siteFormatted ?? "-") {
                            Text(payment.paidAmountDollar.webMoney(fractionDigits: 2, currency: "$"))
                                .foregroundStyle(.green)
                        }
                    }
                }
                LabeledContent("ჯამში ჩარიცხული") {
                    Text(finance.totalPaidAmountDollar.webMoney(fractionDigits: 2, currency: "$"))
                        .bold()
                        .foregroundStyle(.green)
                }

                Divider()
                HStack {
                    Text("\(project.startDate?.siteFormatted ?? "-") – \(project.endDate?.siteFormatted ?? "-")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(finance.progress.label)
                        .bold()
                }
                .font(.footnote)
                ProgressView(value: Double(finance.progress.percent), total: 100)
                    .tint(ExpenseDetailView.progressColor(finance.progress))
            }
            .font(.subheadline)
        }
    }

    private func historySection(canManage: Bool) -> some View {
        PrivateCard(title: "პროექტის ისტორია") {
            if history.isEmpty {
                Text("ამ პროექტზე ისტორიის ჩანაწერები ჯერ არ არის დამატებული.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { Divider().padding(.vertical, 10) }
                        historyRow(entry, canManage: canManage)
                    }
                }
            }
        }
    }

    private func historyRow(_ entry: ProjectHistoryEntry, canManage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.timestamp.map(ExpenseDetailView.dayTime) ?? "-")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemFill), in: Capsule())
            if !entry.comment.isEmpty {
                Text(entry.comment)
                    .font(.subheadline)
            }
            if !entry.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(entry.images.enumerated()), id: \.offset) { index, image in
                            Button {
                                viewer = GalleryPosition(images: entry.images, index: index)
                            } label: {
                                RemoteImage(url: APIConfig.imageURL(image.thumbUrl))
                                    .frame(width: 80, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("ფოტო \(index + 1), \(entry.images.count)-დან")
                        }
                    }
                }
            }
            if canManage {
                HStack(spacing: 8) {
                    Button("რედაქტირება") { historySheet = .edit(entry) }
                        .buttonStyle(.bordered)
                    Button("წაშლა", role: .destructive) { pendingDelete = entry }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    if deletingID == entry.id {
                        ProgressView()
                    }
                }
                .controlSize(.small)
                .disabled(deletingID == entry.id)
            }
        }
        .opacity(deletingID == entry.id ? 0.5 : 1)
    }

    // MARK: Helpers

    private func dateRange(_ project: ProjectDetail) -> String? {
        switch (project.startDate, project.endDate) {
        case let (start?, end?): "\(start.siteFormatted) – \(end.siteFormatted)"
        case let (start?, nil): "დაწყება: \(start.siteFormatted)"
        case let (nil, end?): "დასრულება: \(end.siteFormatted)"
        case (nil, nil): nil
        }
    }

    private func nonEmpty(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        return value
    }

    // MARK: Loading and actions

    private func load() async {
        let signedIn = auth.currentUser != nil
        do {
            let response: ProjectDetailResponse
            do {
                response = try await APIClient.shared.send(
                    Endpoint(method: .get, path: "projects/\(id)", requiresAuth: signedIn)
                )
            } catch let error as APIError where signedIn && error.code == APIError.sessionExpiredCode {
                // The session could not be refreshed: show the public page rather than an error.
                response = try await APIClient.shared.send(Endpoint(method: .get, path: "projects/\(id)"))
            }
            history = response.history
            state = .loaded(response)
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }

    private func delete(_ entry: ProjectHistoryEntry) async {
        deletingID = entry.id
        defer { deletingID = nil }
        do {
            let response: ProjectHistoryResponse = try await APIClient.shared.send(
                Endpoint(method: .delete, path: "admin/project-history/\(entry.id)", requiresAuth: true)
            )
            applyHistory(response.history, notice: "ისტორიის ჩანაწერი წაიშალა.")
        } catch let error as APIError {
            actionError = error.message
        } catch {
            actionError = APIError.network.message
        }
    }

    private func applyHistory(_ updated: [ProjectHistoryEntry], notice: String) {
        withAnimation {
            history = updated
            self.notice = notice
        }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { self.notice = nil }
        }
    }
}

/// A block only signed-in viewers get, titled like the web's accordions ("ხილულია მხოლოდ თქვენთვის").
private struct PrivateCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text("ხილულია მხოლოდ თქვენთვის")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Images to open full screen, starting at the tapped one.
private struct GalleryPosition: Identifiable {
    let id = UUID()
    let images: [ProjectDetail.Image]
    let index: Int
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
    .environmentObject(AuthViewModel())
}
