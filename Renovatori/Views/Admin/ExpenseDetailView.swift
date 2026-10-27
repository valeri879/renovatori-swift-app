import SwiftUI

/// Admin expense project (`views/pages/expenses-detail-page`): finances, progress, spending by type,
/// payments and expense rows. Admins can add expenses and payments while the project is „მიმდინარე",
/// and edit or delete expense rows and payments in any status.
struct ExpenseDetailView: View {
    let id: String

    private enum Sheet: Identifiable {
        case editProject, addExpense, addPayment
        case editExpense(ExpenseDetail.Item)
        case editPayment(ExpenseDetail.PaidAmount)

        var id: String {
            switch self {
            case .editProject: "editProject"
            case .addExpense: "addExpense"
            case .addPayment: "addPayment"
            case .editExpense(let item): "editExpense-\(item.id)"
            case .editPayment(let payment): "editPayment-\(payment.id)"
            }
        }
    }

    /// A row waiting for the delete confirmation.
    private enum PendingDelete {
        case expense(ExpenseDetail.Item)
        case payment(ExpenseDetail.PaidAmount)

        var id: String {
            switch self {
            case .expense(let item): item.id
            case .payment(let payment): payment.id
            }
        }

        var question: String {
            switch self {
            case .expense: "ნამდვილად გსურთ ხარჯის ჩანაწერის წაშლა? ეს ოპერაცია შეუქცევადია."
            case .payment: "ნამდვილად გსურთ ჩარიცხვის წაშლა? ეს ოპერაცია შეუქცევადია."
            }
        }
    }

    @State private var state: Loadable<ExpenseDetail> = .loading
    @State private var sheet: Sheet?
    @State private var pendingDelete: PendingDelete?
    /// Row (expense or payment) whose delete request is in flight.
    @State private var deletingID: String?
    @State private var deleteError: String?
    /// Expense-type filter for the rows, set by tapping a type in the breakdown.
    @State private var selectedType: String?
    @State private var notice: String?
    @State private var viewerImages: ImageViewerItem?

    var body: some View {
        content
            .navigationTitle("ხარჯების დეტალები")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error, notFoundTitle: "პროექტი ვერ მოიძებნა") { await load() }
        case .loaded(let expense):
            detail(expense)
        }
    }

    // MARK: Layout

    /// A `List` (not a `ScrollView`) so payment and expense rows can have swipe actions.
    /// The top blocks are clear, inset-free rows, so they keep the card layout.
    private func detail(_ expense: ExpenseDetail) -> some View {
        List {
            Section {
                Group {
                    header(expense)
                    if let notice {
                        Label(notice, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity)
                    }
                    finances(expense)
                    projectInfo(expense)
                    progress(expense)
                    typeBreakdown(expense)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            payments(expense)
            expenseRows(expense)
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .refreshable { await load() }
        .toolbar {
            if expense.permissions.canManage {
                ToolbarItem(placement: .primaryAction) {
                    Button("რედაქტირება", systemImage: "pencil") {
                        sheet = .editProject
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if expense.permissions.canManage {
                actionBar(expense)
            }
        }
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .editProject:
                    ExpenseProjectFormView(expense: expense) { updated in
                        apply(updated, notice: "პროექტი განახლდა.")
                    }
                case .addExpense:
                    ExpenseItemFormView(expense: expense) { updated in
                        apply(updated, notice: "ხარჯის ჩანაწერი დაემატა.")
                    }
                case .editExpense(let item):
                    ExpenseItemFormView(expense: expense, item: item) { updated in
                        apply(updated, notice: "ხარჯის ჩანაწერი განახლდა.")
                    }
                case .addPayment:
                    PaidAmountFormView(expense: expense) { updated, emailSent in
                        apply(updated, notice: emailSent ? "ჩარიცხვა დაემატა. კლიენტს ელ-ფოსტა გაეგზავნა." : "ჩარიცხვა დაემატა.")
                    }
                case .editPayment(let payment):
                    PaidAmountFormView(expense: expense, payment: payment) { updated, emailSent in
                        apply(updated, notice: emailSent ? "ჩარიცხვა განახლდა. კლიენტს ელ-ფოსტა გაეგზავნა." : "ჩარიცხვა განახლდა.")
                    }
                }
            }
        }
        .sheet(item: $viewerImages) { item in
            ImageViewer(item: item)
        }
        .confirmationDialog(
            pendingDelete?.question ?? "",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { row in
            Button("წაშლა", role: .destructive) {
                Task { await delete(row, from: expense) }
            }
        }
        .alert("წაშლა ვერ მოხერხდა", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
            Button("კარგი", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    private func header(_ expense: ExpenseDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(expense.projectName.isEmpty ? "-" : expense.projectName)
                .font(.title2.bold())
            ExpenseStatusBadge(status: expense.status)
        }
    }

    private func finances(_ expense: ExpenseDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("💰 ფინანსები")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                FinanceTile(title: "ჯამური ღირებულება", caption: "ლარში", value: expense.totalAmount.webMoney(fractionDigits: 2), color: .primary)
                FinanceTile(title: "ჯამური ღირებულება ($)", caption: "დოლარში", value: expense.totalAmountDollar.webMoney(fractionDigits: 2, currency: "$"), color: .primary)
                FinanceTile(title: "ჯამური ხარჯი", caption: "ყველა ხარჯის ჯამი", value: expense.totalExpenses.webMoney(fractionDigits: 2), color: .red)
                FinanceTile(title: "მიმდინარე თანხა", caption: "ჩარიცხვები მინუს ხარჯები", value: expense.currentAmount.webMoney(fractionDigits: 2), color: expense.currentAmount >= 0 ? .green : .red)
                FinanceTile(title: "დარჩენილი თანხა ($)", caption: "გადასახდელი დოლარში", value: expense.remainingAmountDollar.webMoney(fractionDigits: 2, currency: "$"), color: .red)
                FinanceTile(title: "მთლიანი მოგება", caption: "ღირებულება მინუს ხარჯები", value: expense.totalProfit.webMoney(fractionDigits: 2), color: expense.totalProfit >= 0 ? .green : .red)
            }
        }
    }

    private func projectInfo(_ expense: ExpenseDetail) -> some View {
        GroupBox {
            DisclosureGroup("ℹ️ პროექტის დეტალური ინფორმაცია") {
                VStack(spacing: 10) {
                    infoRow("მისამართი", expense.projectAddress)
                    infoRow("დამკვეთი", expense.clientName)
                    if !expense.clientPhone.isEmpty, let url = URL(string: "tel:\(expense.clientPhone.filter(\.isNumber))") {
                        LabeledContent("ტელეფონი") {
                            Link(expense.clientPhone, destination: url)
                        }
                    } else {
                        infoRow("ტელეფონი", "")
                    }
                    if !expense.clientEmail.isEmpty, let url = URL(string: "mailto:\(expense.clientEmail)") {
                        LabeledContent("ელ-ფოსტა") {
                            Link(expense.clientEmail, destination: url)
                        }
                    } else {
                        infoRow("ელ-ფოსტა", "")
                    }
                    infoRow("ფართობი", expense.area > 0 ? "\(expense.area.formatted()) მ²" : "")
                    infoRow("ფასი კვ.მ-ზე", expense.pricePerSquareArea.webMoney(fractionDigits: 2))
                    infoRow("ფასი კვ.მ-ზე ($)", expense.pricePerSquareAreaDollar.webMoney(fractionDigits: 2, currency: "$"))
                    infoRow("დარჩენილი თანხა", expense.remainingAmount.webMoney(fractionDigits: 2))
                    infoRow("პროექტის დაწყება", expense.startDate.map(Self.day) ?? "")
                    infoRow("პროექტის დასრულება", expense.endDate.map(Self.day) ?? "")
                    infoRow("შექმნის თარიღი", expense.createdAt.map(Self.dayTime) ?? "")
                    infoRow("განახლების თარიღი", expense.updatedAt.map(Self.dayTime) ?? "")
                }
                .font(.subheadline)
                .padding(.top, 10)
            }
            .tint(.primary)
        }
    }

    private func progress(_ expense: ExpenseDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("📈 პროექტის პროგრესი")
            HStack {
                Text("\(expense.startDate.map(Self.day) ?? "-") - \(expense.endDate.map(Self.day) ?? "-")")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(expense.progress.label)
                    .bold()
            }
            .font(.footnote)
            ProgressView(value: Double(expense.progress.percent), total: 100)
                .tint(Self.progressColor(expense.progress))
        }
    }

    private func typeBreakdown(_ expense: ExpenseDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("📊 ხარჯები ტიპების მიხედვით")
            if expense.expenseTypeSummary.isEmpty {
                Text("ხარჯის ტიპების მიხედვით პროგრესი ჯერ ვერ გამოითვლება.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                // Stacked bar: each type's share of all spending.
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(Array(expense.expenseTypeSummary.enumerated()), id: \.element.id) { index, item in
                            Self.typeColor(index)
                                .frame(width: max(2, (proxy.size.width - CGFloat(expense.expenseTypeSummary.count - 1) * 2) * item.percent / 100))
                        }
                    }
                }
                .frame(height: 14)
                .clipShape(Capsule())

                ForEach(Array(expense.expenseTypeSummary.enumerated()), id: \.element.id) { index, item in
                    Button {
                        withAnimation { selectedType = selectedType == item.title ? nil : item.title }
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Self.typeColor(index))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text("\(item.amount.webMoney(fractionDigits: 2)) · \(Int(item.percent.rounded()))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedType == item.title {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(10)
                        .background(
                            selectedType == item.title ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Text("შეეხეთ ტიპს ხარჯების გასაფილტრად.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func payments(_ expense: ExpenseDetail) -> some View {
        Section {
            if expense.paidAmounts.isEmpty {
                emptyRow("ჩარიცხვები ჯერ არ დამატებულა.")
            } else {
                ForEach(expense.paidAmounts) { payment in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(payment.paidAmount.webMoney(fractionDigits: 2))
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                            if payment.paidAmountDollar > 0 {
                                Text(payment.paidAmountDollar.webMoney(fractionDigits: 2, currency: "$"))
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            if !payment.comment.isEmpty {
                                Text(payment.comment)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(payment.paidAt.map(Self.day) ?? "-")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if deletingID == payment.id {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                    .rowActions(
                        enabled: expense.permissions.canManage,
                        edit: { sheet = .editPayment(payment) },
                        delete: { pendingDelete = .payment(payment) }
                    )
                }
            }
        } header: {
            HStack {
                sectionTitle("💵 ჩარიცხვები")
                Spacer()
                Text("ჯამი: \(expense.totalPaidAmount.webMoney(fractionDigits: 2))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            .listSectionHeader()
        } footer: {
            if !expense.paidAmounts.isEmpty {
                Text("ჯამში ($): \(expense.totalPaidAmountDollar.webMoney(fractionDigits: 2, currency: "$"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listRowBackground(Color(.secondarySystemBackground))
    }

    private func expenseRows(_ expense: ExpenseDetail) -> some View {
        let rows = expense.expenses.filter { selectedType == nil || $0.typeTitle == selectedType }
        let total = rows.reduce(0) { $0 + $1.amount }

        return Section {
            if rows.isEmpty {
                emptyRow("ხარჯის ჩანაწერები ჯერ არ დამატებულა.")
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, item in
                    ExpenseItemRow(item: item, number: index + 1, isDeleting: deletingID == item.id) { tappedIndex in
                        viewerImages = ImageViewerItem(images: item.images, startIndex: tappedIndex)
                    }
                    .rowActions(
                        enabled: expense.permissions.canManage,
                        edit: { sheet = .editExpense(item) },
                        delete: { pendingDelete = .expense(item) }
                    )
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    sectionTitle("🧾 ხარჯები")
                    Spacer()
                    Text("ჯამი: \(total.webMoney(fractionDigits: 2))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                if let selectedType {
                    HStack {
                        Text("ფილტრი: ").foregroundStyle(.secondary) + Text(selectedType).bold() + Text(" (\(rows.count))").foregroundStyle(.secondary)
                        Spacer()
                        Button("✕ მოხსნა") {
                            withAnimation { self.selectedType = nil }
                        }
                    }
                    .font(.footnote)
                }
            }
            .listSectionHeader()
        } footer: {
            if expense.permissions.canManage && !expense.expenses.isEmpty {
                Text("რედაქტირებისთვის ან წასაშლელად გადაასრიალეთ ჩანაწერი მარცხნივ.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listRowBackground(Color(.secondarySystemBackground))
    }

    private func actionBar(_ expense: ExpenseDetail) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    sheet = .addExpense
                } label: {
                    Label("ხარჯის დამატება", systemImage: "minus.circle")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
                Button {
                    sheet = .addPayment
                } label: {
                    Label("ჩარიცხვის დამატება", systemImage: "plus.circle")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!expense.permissions.canAddEntries)

            if !expense.permissions.canAddEntries {
                Text("ხარჯის/ჩარიცხვის დასამატებლად პროექტის სტატუსი უნდა იყოს „მიმდინარე“.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: Pieces

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value.isEmpty ? "-" : value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    // MARK: Loading

    private func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    private func load() async {
        do {
            let response: ExpenseDetailResponse = try await APIClient.shared.send(
                Endpoint(method: .get, path: "admin/expenses/\(id)", requiresAuth: true)
            )
            state = .loaded(response.expense)
        } catch is CancellationError {
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.network)
        }
    }

    private func delete(_ row: PendingDelete, from expense: ExpenseDetail) async {
        let (path, notice) = switch row {
        case .expense(let item): ("admin/expenses/\(expense.id)/expenses/\(item.id)", "ხარჯის ჩანაწერი წაიშალა.")
        case .payment(let payment): ("admin/expenses/\(expense.id)/paid-amounts/\(payment.id)", "ჩარიცხვა წაიშალა.")
        }
        deletingID = row.id
        defer { deletingID = nil }
        do {
            let response: ExpenseDetailResponse = try await APIClient.shared.send(
                Endpoint(method: .delete, path: path, requiresAuth: true)
            )
            apply(response.expense, notice: notice)
        } catch let error as APIError {
            deleteError = error.message
        } catch {
            deleteError = APIError.network.message
        }
    }

    private func apply(_ expense: ExpenseDetail, notice: String) {
        state = .loaded(expense)
        withAnimation { self.notice = notice }
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { self.notice = nil }
        }
    }

    // MARK: Formatting

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
    }

    static func dayTime(_ date: Date) -> String {
        date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().hour().minute())
    }

    /// Same colors as the web progress bar classes.
    static func progressColor(_ progress: ExpenseCard.Progress) -> Color {
        if !progress.isValid || progress.percent == 0 { return .gray }
        if progress.percent >= 100 { return .green }
        return progress.percent >= 80 ? .orange : .blue
    }

    static func typeColor(_ index: Int) -> Color {
        let palette: [Color] = [.blue, .green, .red, .orange, .cyan, .gray, .purple, .pink, .mint, .indigo, .brown, .teal]
        return palette[index % palette.count]
    }
}

/// Status pill shared by the expense screens.
struct ExpenseStatusBadge: View {
    let status: ExpenseStatus

    var body: some View {
        Text(status.title)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color, in: Capsule())
            .fixedSize()
    }
}

/// One of the six money tiles at the top of the detail screen.
private struct FinanceTile: View {
    let title: String
    let caption: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// An expense row: type, amount, date, comment and image thumbnails.
private struct ExpenseItemRow: View {
    let item: ExpenseDetail.Item
    let number: Int
    let isDeleting: Bool
    let openImage: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(number) · \(item.expenseType?.title ?? "-")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.amount.webMoney(fractionDigits: 2))
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                Spacer()
                Text(item.expenseDate.map(ExpenseDetailView.day) ?? "-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            if !item.comment.isEmpty {
                Text(item.comment)
                    .font(.footnote)
            }
            if !item.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(item.images.enumerated()), id: \.offset) { index, image in
                            Button {
                                openImage(index)
                            } label: {
                                RemoteImage(url: APIConfig.imageURL(image.thumbUrl))
                                    .frame(width: 64, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension View {
    /// Right-to-left swipe with „რედაქტირება" and „წაშლა" on expense and payment rows (admins only).
    /// Delete is tinted rather than `role: .destructive`, which would animate the row away
    /// before the confirmation dialog is answered.
    @ViewBuilder
    fileprivate func rowActions(enabled: Bool, edit: @escaping () -> Void, delete: @escaping () -> Void) -> some View {
        if enabled {
            swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(action: delete) {
                    Label("წაშლა", systemImage: "trash")
                }
                .tint(.red)
                Button(action: edit) {
                    Label("რედაქტირება", systemImage: "pencil")
                }
                .tint(.orange)
            }
        } else {
            self
        }
    }

    /// Section header styled like the other block titles instead of the grouped-list caps.
    fileprivate func listSectionHeader() -> some View {
        textCase(nil)
            .foregroundStyle(.primary)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
    }
}

/// Images to show full screen, starting at the tapped one.
struct ImageViewerItem: Identifiable {
    let id = UUID()
    let images: [ExpenseDetail.Item.Image]
    let startIndex: Int
}

/// Full-screen, swipeable viewer for expense photos.
private struct ImageViewer: View {
    let item: ImageViewerItem
    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(Array(item.images.enumerated()), id: \.offset) { index, image in
                    AsyncImage(url: APIConfig.imageURL(image.url)) { phase in
                        if let loaded = phase.image {
                            loaded.resizable().scaledToFit()
                        } else if phase.error != nil {
                            ContentUnavailableView("სურათი ვერ ჩაიტვირთა", systemImage: "photo")
                        } else {
                            ProgressView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: item.images.count > 1 ? .always : .never))
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("დახურვა") { dismiss() }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { selection = item.startIndex }
        }
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(id: "preview")
    }
}
