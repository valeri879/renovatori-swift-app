import SwiftUI

/// Admin "ხარჯები" list (`views/pages/expenses-list-page`): status filter, endless paging, a tap
/// opens the project and, for admins only, „+" adds a project and swipe deletes one with confirmation.
/// Moderators only read.
struct ExpensesListView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var list = PagedList<ExpenseCard>(path: "admin/expenses", pageSize: 20, requiresAuth: true)

    @State private var statuses: [String] = []
    /// nil shows every project ("ყველა").
    @State private var selectedStatus: String?
    @State private var pendingDelete: ExpenseCard?
    @State private var deletingID: ExpenseCard.ID?
    @State private var deleteError: String?
    @State private var isAddingProject = false
    /// Set after the first appearance, so coming back from a project refreshes its numbers.
    @State private var hasAppeared = false

    /// Admins add and delete projects; moderators only read.
    private var isAdmin: Bool { auth.currentUser?.isAdmin == true }

    var body: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                filterBar
            }
            .navigationTitle("ხარჯები")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isAdmin {
                    ToolbarItem(placement: .primaryAction) {
                        Button("ხარჯის დამატება", systemImage: "plus") {
                            isAddingProject = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddingProject) {
                NavigationStack {
                    ExpenseProjectFormView { _ in
                        // Newest first, so the new project is the first row.
                        Task { await list.reload() }
                    }
                }
            }
            .task {
                await loadStatuses()
                await list.loadIfNeeded()
            }
            .onAppear {
                if hasAppeared {
                    Task { await list.reload() }
                }
                hasAppeared = true
            }
            .confirmationDialog(
                "ნამდვილად გსურთ ჩანაწერის წაშლა? ეს მოქმედება შეუქცევადია.",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { expense in
                Button("წაშლა", role: .destructive) {
                    Task { await delete(expense) }
                }
                Button("გაუქმება", role: .cancel) {}
            } message: { expense in
                Text(expense.projectName)
            }
            .alert("წაშლა ვერ მოხერხდა", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) {
                Button("კარგი", role: .cancel) {}
            } message: {
                Text(deleteError ?? "")
            }
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        if list.items.isEmpty, let error = list.error {
            if error.status == 403 {
                ContentUnavailableView(
                    "წვდომა არ გაქვთ",
                    systemImage: "lock",
                    description: Text("ხარჯების ნახვა შეუძლია მხოლოდ ადმინისტრატორს და მოდერატორს.")
                )
            } else {
                ErrorStateView(error: error) { await list.reload() }
            }
        } else if list.isEmpty {
            ContentUnavailableView("ჩანაწერები არ მოიძებნა.", systemImage: "tray")
        } else if list.items.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            expensesList
        }
    }

    private var expensesList: some View {
        List {
            Section {
                ForEach(Array(list.items.enumerated()), id: \.element.id) { index, expense in
                    NavigationLink(value: AppRoute.expenseDetail(expense.id)) {
                        ExpenseRow(expense: expense, number: index + 1)
                    }
                    .opacity(deletingID == expense.id ? 0.4 : 1)
                    .task { await list.loadMoreIfNeeded(after: expense) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if isAdmin {
                            Button("წაშლა", systemImage: "trash", role: .destructive) {
                                pendingDelete = expense
                            }
                        }
                    }
                }
                if list.hasNext {
                    PageLoadingFooter()
                }
            } header: {
                if let total = list.totalItems {
                    Text("სულ ჩანაწერები: \(total)")
                        .textCase(nil)
                }
            }
        }
        .refreshable { await list.reload() }
    }

    // MARK: Filter

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("ყველა", isSelected: selectedStatus == nil) { select(nil) }
                ForEach(statuses, id: \.self) { status in
                    filterChip(ExpenseStatus(rawValue: status).title, isSelected: selectedStatus == status) {
                        select(status)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    @ViewBuilder
    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        if isSelected {
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        } else {
            Button(title, action: action)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        }
    }

    private func select(_ status: String?) {
        guard status != selectedStatus else { return }
        selectedStatus = status
        Task {
            await list.reload(query: status.map { [URLQueryItem(name: "status", value: $0)] } ?? [])
        }
    }

    // MARK: Actions

    private func loadStatuses() async {
        guard statuses.isEmpty else { return }
        let response = try? await APIClient.shared.send(
            Endpoint(method: .get, path: "admin/expenses/statuses", requiresAuth: true),
            as: ExpenseStatusesResponse.self
        )
        statuses = response?.statuses ?? []
    }

    private func delete(_ expense: ExpenseCard) async {
        deletingID = expense.id
        defer { deletingID = nil }
        do {
            _ = try await APIClient.shared.send(
                Endpoint(method: .delete, path: "admin/expenses/\(expense.id)", requiresAuth: true),
                as: ExpenseDeleteResponse.self
            )
            list.remove(id: expense.id)
            // Refresh totals and pull the next item up into the current page.
            await list.reload()
        } catch let error as APIError {
            deleteError = error.message
        } catch {
            deleteError = APIError.network.message
        }
    }
}

/// One project card: number, name, status, four amounts and the date-based progress.
private struct ExpenseRow: View {
    let expense: ExpenseCard
    let number: Int

    private let columns = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expense.projectName.isEmpty ? "-" : expense.projectName)
                        .font(.headline)
                }
                Spacer()
                Text(expense.status.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(expense.status.color, in: Capsule())
                    .fixedSize()
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                amount("ჯამური ღირებულება", expense.totalAmount.webMoney(), color: .primary)
                amount("ჯამური ხარჯი", expense.totalExpenses.webMoney(), color: .red)
                amount("დარჩენილი თანხა", expense.remainingAmount.webMoney(), color: .green)
                amount("მიმდინარე თანხა", expense.currentAmount.webMoney(fractionDigits: 2), color: expense.currentAmount >= 0 ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("პროექტის პროგრესი")
                    Spacer()
                    Text(expense.progress.label)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                ProgressView(value: Double(expense.progress.percent), total: 100)
                    .tint(progressColor)
            }
        }
        .padding(.vertical, 6)
    }

    /// Same colors as the web progress bar classes.
    private var progressColor: Color {
        let percent = expense.progress.percent
        if !expense.progress.isValid || percent == 0 { return .gray }
        if percent >= 100 { return .green }
        return percent >= 80 ? .orange : .blue
    }

    private func amount(_ title: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    NavigationStack {
        ExpensesListView()
    }
    .environmentObject(AuthViewModel())
}
