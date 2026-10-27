import SwiftUI

/// "ხარჯის დამატება / რედაქტირება" (`views/pages/expenses-add-page`, `expenses-edit-page`): a project's
/// base fields → `POST /admin/expenses` or `PUT /admin/expenses/:id`. Payments and expense rows
/// are edited on the detail screen.
struct ExpenseProjectFormView: View {
    private enum Field: String {
        case projectName, projectStatus, publicProjectId, totalAmount, totalAmountDollar, area,
             startDate, endDate, projectAddress, clientName, clientPhone, clientEmail, clientId
    }

    /// The project being edited; nil creates a new one.
    let expense: ExpenseDetail?
    let onSaved: (ExpenseDetail) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var statuses = ExpenseProjectFormView.knownStatuses
    @State private var projectName: String
    @State private var projectStatus: String
    @State private var publicProjectId: String
    @State private var totalAmount: String
    @State private var totalAmountDollar: String
    @State private var area: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var projectAddress: String
    @State private var clientName: String
    @State private var clientPhone: String
    @State private var clientEmail: String
    @State private var clientId: String
    @State private var sendTelegram = false

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    /// `expenseStatuses` on the backend; replaced by `GET /admin/expenses/statuses` when it loads.
    private static let knownStatuses = ["დასაწყები", "მიმდინარე", "დასრულებული", "შეწყვეტილი"]

    init(expense: ExpenseDetail? = nil, onSaved: @escaping (ExpenseDetail) -> Void) {
        self.expense = expense
        self.onSaved = onSaved
        _projectName = State(initialValue: expense?.projectName ?? "")
        // Legacy "დაწყებული" maps to "დასაწყები", like the web's select.
        _projectStatus = State(initialValue: expense?.status.rawValue ?? Self.knownStatuses[0])
        _publicProjectId = State(initialValue: expense?.publicProjectId ?? "")
        _totalAmount = State(initialValue: expense.map { Self.inputText($0.totalAmount) } ?? "")
        // A zero dollar total means "not given", so the field starts empty.
        _totalAmountDollar = State(initialValue: expense.flatMap { $0.totalAmountDollar > 0 ? Self.inputText($0.totalAmountDollar) : nil } ?? "")
        _area = State(initialValue: expense.map { Self.inputText($0.area) } ?? "")
        _startDate = State(initialValue: expense?.startDate ?? Date())
        _endDate = State(initialValue: expense?.endDate ?? Date())
        _projectAddress = State(initialValue: expense?.projectAddress ?? "")
        _clientName = State(initialValue: expense?.clientName ?? "")
        _clientPhone = State(initialValue: expense?.clientPhone ?? "")
        _clientEmail = State(initialValue: expense?.clientEmail ?? "")
        _clientId = State(initialValue: expense?.clientId ?? "")
    }

    var body: some View {
        Form {
            if let expense {
                ExpenseContextSection(expense: expense)
            }

            Section {
                FormFieldRow(title: "პროექტის სახელი", error: fieldErrors[.projectName]) {
                    TextField("პროექტის სახელი", text: $projectName)
                }
                FormFieldRow(title: "პროექტის სტატუსი", error: fieldErrors[.projectStatus]) {
                    Picker("პროექტის სტატუსი", selection: $projectStatus) {
                        ForEach(statuses, id: \.self) { status in
                            Text(ExpenseStatus(rawValue: status).title).tag(status)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
            }

            Section {
                FormFieldRow(title: "საჯარო პროექტის ID", isRequired: false, error: fieldErrors[.publicProjectId]) {
                    TextField("საჯარო პროექტის ID", text: $publicProjectId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .monospaced()
                }
            } footer: {
                Text("გამოიყენება ამ ხარჯის საჯარო პროექტის გვერდთან დასაკავშირებლად.")
            }

            Section {
                FormFieldRow(title: "პროექტის ჯამური ღირებულება (₾)", error: fieldErrors[.totalAmount]) {
                    TextField("0.00", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }
                FormFieldRow(title: "პროექტის ჯამური ღირებულება ($)", isRequired: false, error: fieldErrors[.totalAmountDollar]) {
                    TextField("0.00", text: $totalAmountDollar)
                        .keyboardType(.decimalPad)
                }
                FormFieldRow(title: "ფართობი (მ²)", error: fieldErrors[.area]) {
                    TextField("0.00", text: $area)
                        .keyboardType(.decimalPad)
                }
            }

            Section {
                FormFieldRow(title: "პროექტის დაწყების თარიღი", error: fieldErrors[.startDate]) {
                    DatePicker("პროექტის დაწყების თარიღი", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }
                FormFieldRow(title: "პროექტის დასრულების თარიღი", error: fieldErrors[.endDate]) {
                    DatePicker("პროექტის დასრულების თარიღი", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
                FormFieldRow(title: "პროექტის მისამართი", isRequired: false, error: fieldErrors[.projectAddress]) {
                    TextField("პროექტის მისამართი", text: $projectAddress)
                }
            }

            Section {
                FormFieldRow(title: "დამკვეთის სახელი/გვარი", isRequired: false, error: fieldErrors[.clientName]) {
                    TextField("დამკვეთის სახელი/გვარი", text: $clientName)
                        .textContentType(.name)
                }
                FormFieldRow(title: "დამკვეთის ტელეფონი", isRequired: false, error: fieldErrors[.clientPhone]) {
                    TextField("დამკვეთის ტელეფონი", text: $clientPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                FormFieldRow(title: "დამკვეთის ელფოსტა", isRequired: false, error: fieldErrors[.clientEmail]) {
                    TextField("დამკვეთის ელფოსტა", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                FormFieldRow(title: "დამკვეთის ID", isRequired: false, error: fieldErrors[.clientId]) {
                    TextField("დამკვეთის ID", text: $clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .monospaced()
                }
            } header: {
                Text("დამკვეთი")
            } footer: {
                Text("მომხმარებლის ID იპოვი საიტის გვერდზე /users: დააჭირე „რედაქტირება“ და იქ ნახავ „მომხმარებლის ID“-ს.")
            }

            Section {
                Toggle("Telegram-ზე შეტყობინების გაგზავნა", isOn: $sendTelegram)
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: expense == nil ? "დამატება" : "განახლება", isLoading: isSubmitting, action: submit)
            }
        }
        .navigationTitle(expense == nil ? "ხარჯის დამატება" : "ხარჯის რედაქტირება")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("გაუქმება") { dismiss() }
                    .disabled(isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
        .task { await loadStatuses() }
    }

    // MARK: Submit

    private func loadStatuses() async {
        guard let response = try? await APIClient.shared.send(
            Endpoint(method: .get, path: "admin/expenses/statuses", requiresAuth: true),
            as: ExpenseStatusesResponse.self
        ), !response.statuses.isEmpty else { return }
        // Keep an unknown current status selectable instead of silently changing it.
        statuses = response.statuses.contains(projectStatus) ? response.statuses : response.statuses + [projectStatus]
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = [:]

        let lari = parseRequired(totalAmount, field: .totalAmount, missing: "ჯამური ღირებულება სავალდებულოა.")
        let squareMeters = parseRequired(area, field: .area, missing: "ფართობი სავალდებულოა.")
        let dollars = Double.parseMoney(totalAmountDollar)
        if !totalAmountDollar.trimmingCharacters(in: .whitespaces).isEmpty {
            if dollars == nil {
                fieldErrors[.totalAmountDollar] = "თანხა არასწორია."
            } else if let dollars, dollars < 0 {
                fieldErrors[.totalAmountDollar] = "თანხა არ შეიძლება იყოს უარყოფითი."
            }
        }
        guard fieldErrors.isEmpty, let lari, let squareMeters else { return }

        let request = ExpenseProjectRequest(
            projectName: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
            projectStatus: projectStatus,
            publicProjectId: publicProjectId.trimmingCharacters(in: .whitespacesAndNewlines),
            totalAmount: lari,
            totalAmountDollar: dollars,
            area: squareMeters,
            startDate: DateFormatter.apiDay.string(from: startDate),
            endDate: DateFormatter.apiDay.string(from: endDate),
            projectAddress: projectAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            clientPhone: clientPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            clientEmail: clientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            clientId: clientId.trimmingCharacters(in: .whitespacesAndNewlines),
            sendTelegramNotification: sendTelegram
        )

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response: ExpenseDetailResponse = try await APIClient.shared.send(Endpoint(
                    method: expense == nil ? .post : .put,
                    path: expense.map { "admin/expenses/\($0.id)" } ?? "admin/expenses",
                    body: request,
                    requiresAuth: true
                ))
                onSaved(response.expense)
                dismiss()
            } catch let error as APIError {
                for (key, message) in error.details ?? [:] {
                    if let field = Field(rawValue: key) {
                        fieldErrors[field] = message
                    }
                }
                if fieldErrors.isEmpty {
                    errorMessage = error.message
                }
            } catch {
                errorMessage = APIError.network.message
            }
        }
    }

    /// Parses a required, non-negative amount, recording the field error when it is not.
    private func parseRequired(_ text: String, field: Field, missing: String) -> Double? {
        guard let value = Double.parseMoney(text) else {
            fieldErrors[field] = text.trimmingCharacters(in: .whitespaces).isEmpty ? missing : "მნიშვნელობა არასწორია."
            return nil
        }
        guard value >= 0 else {
            fieldErrors[field] = field == .area ? "ფართობი არ შეიძლება იყოს უარყოფითი." : "თანხა არ შეიძლება იყოს უარყოფითი."
            return nil
        }
        return value
    }

    /// Whole values without a trailing ".0", like the web's number input.
    private static func inputText(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
