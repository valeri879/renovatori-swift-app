import PhotosUI
import SwiftUI

/// "ხარჯის ჩანაწერის დამატება" (`views/pages/expenses-add-expense-page`), sent as multipart to
/// `POST /admin/expenses/:id/expenses` so photos can go with it.
struct AddExpenseItemView: View {
    private enum Field: String {
        case expenseType, expenseDate, amount, comment
    }

    let expense: ExpenseDetail
    let onSaved: (ExpenseDetail) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var expenseTypes: [ExpenseTypeOption] = []
    /// Empty string means "no type", like the web's empty option.
    @State private var expenseTypeID = ""
    @State private var expenseDate = Date()
    @State private var amount = ""
    @State private var comment = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [SelectedPhoto] = []
    @State private var sendTelegram = false

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        Form {
            ExpenseContextSection(expense: expense)

            Section {
                FormFieldRow(title: "ხარჯის ტიპი", isRequired: false, error: fieldErrors[.expenseType]) {
                    Picker("ხარჯის ტიპი", selection: $expenseTypeID) {
                        Text("აირჩიე ხარჯის ტიპი").tag("")
                        ForEach(expenseTypes) { type in
                            Text(type.title).tag(type.id)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                FormFieldRow(title: "ხარჯის თარიღი", error: fieldErrors[.expenseDate]) {
                    DatePicker("ხარჯის თარიღი", selection: $expenseDate, displayedComponents: .date)
                        .labelsHidden()
                }
                FormFieldRow(title: "თანხა (₾)", error: fieldErrors[.amount]) {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }
                FormFieldRow(title: "კომენტარი", isRequired: false, error: fieldErrors[.comment]) {
                    TextField("კომენტარი", text: $comment, axis: .vertical)
                        .lineLimit(2...5)
                }
            }

            Section {
                PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                    Label(photos.isEmpty ? "სურათების დამატება" : "სურათების შეცვლა", systemImage: "photo.on.rectangle.angled")
                }
                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photos) { photo in
                                Image(uiImage: photo.preview)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            remove(photo)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .black.opacity(0.6))
                                        }
                                        .padding(2)
                                    }
                            }
                        }
                    }
                }
            } header: {
                Text("სურათები")
            } footer: {
                Text("ატვირთვა არ არის სავალდებულო.")
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
                SubmitButton(title: "დამატება", isLoading: isSubmitting, action: submit)
            }
        }
        .navigationTitle("ხარჯის დამატება")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("გაუქმება") { dismiss() }
                    .disabled(isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
        .task { await loadTypes() }
        .onChange(of: photoItems) { _, items in
            Task { await loadPhotos(items) }
        }
    }

    // MARK: Photos

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var loaded: [SelectedPhoto] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let photo = SelectedPhoto(data: data) {
                loaded.append(photo)
            }
        }
        photos = loaded
    }

    private func remove(_ photo: SelectedPhoto) {
        guard let index = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        photos.remove(at: index)
        if photoItems.indices.contains(index) {
            photoItems.remove(at: index)
        }
    }

    // MARK: Submit

    private func loadTypes() async {
        guard expenseTypes.isEmpty else { return }
        let response = try? await APIClient.shared.send(
            Endpoint(method: .get, path: "admin/expense-types", requiresAuth: true),
            as: ExpenseTypesResponse.self
        )
        expenseTypes = response?.expenseTypes ?? []
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = [:]
        guard let parsedAmount = Double.parseMoney(amount) else {
            fieldErrors[.amount] = amount.trimmingCharacters(in: .whitespaces).isEmpty ? "თანხა სავალდებულოა." : "თანხა არასწორია."
            return
        }
        guard parsedAmount >= 0 else {
            fieldErrors[.amount] = "თანხა არ შეიძლება იყოს უარყოფითი."
            return
        }

        var form = MultipartForm()
        form.fields = [
            ("expenseType", expenseTypeID),
            ("expenseDate", DateFormatter.apiDay.string(from: expenseDate)),
            ("amount", String(parsedAmount)),
            ("comment", comment.trimmingCharacters(in: .whitespacesAndNewlines)),
            ("sendTelegramNotification", sendTelegram ? "true" : "false"),
        ]
        form.files = photos.enumerated().map { index, photo in
            MultipartForm.File(field: "images", fileName: "photo-\(index + 1).jpg", mimeType: "image/jpeg", data: photo.jpegData)
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response: ExpenseDetailResponse = try await APIClient.shared.send(Endpoint(
                    method: .post,
                    path: "admin/expenses/\(expense.id)/expenses",
                    form: form,
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
}

/// "ჩარიცხვის დამატება" (`views/pages/expenses-add-paid-amount-page`) → `POST /admin/expenses/:id/paid-amounts`.
struct AddPaidAmountView: View {
    private enum Field: String {
        case paidAmount, paidAmountDollar, paidAt, comment
    }

    let expense: ExpenseDetail
    let onSaved: (ExpenseDetail, _ clientEmailSent: Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var paidAmount = ""
    @State private var paidAmountDollar = ""
    @State private var paidAt = Date()
    @State private var comment = ""
    @State private var sendTelegram = false
    @State private var sendClientEmail = false

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        Form {
            ExpenseContextSection(expense: expense)

            Section {
                FormFieldRow(title: "ჩარიცხული თანხა (₾)", error: fieldErrors[.paidAmount]) {
                    TextField("0.00", text: $paidAmount)
                        .keyboardType(.decimalPad)
                }
                FormFieldRow(title: "ჩარიცხული თანხა ($)", isRequired: false, error: fieldErrors[.paidAmountDollar]) {
                    TextField("0.00", text: $paidAmountDollar)
                        .keyboardType(.decimalPad)
                }
                FormFieldRow(title: "ჩარიცხვის თარიღი", error: fieldErrors[.paidAt]) {
                    DatePicker("ჩარიცხვის თარიღი", selection: $paidAt, displayedComponents: .date)
                        .labelsHidden()
                }
                FormFieldRow(title: "კომენტარი", isRequired: false, error: fieldErrors[.comment]) {
                    TextField("კომენტარი", text: $comment, axis: .vertical)
                        .lineLimit(2...5)
                }
            }

            Section {
                Toggle("Telegram-ზე შეტყობინების გაგზავნა", isOn: $sendTelegram)
                Toggle("ელ-ფოსტაზე შეტყობინების გაგზავნა", isOn: $sendClientEmail)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ელ-ფოსტა ეგზავნება მხოლოდ პროექტზე მიბმულ კლიენტს, თუ მისი ელ-ფოსტა დადასტურებულია.")
                    if let errorMessage {
                        FormErrorBanner(message: errorMessage)
                    }
                }
                .padding(.top, 4)
            }

            Section {
                SubmitButton(title: "დამატება", isLoading: isSubmitting, action: submit)
            }
        }
        .navigationTitle("ჩარიცხვის დამატება")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("გაუქმება") { dismiss() }
                    .disabled(isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = [:]

        let lari = Double.parseMoney(paidAmount)
        let dollars = Double.parseMoney(paidAmountDollar)
        if lari == nil {
            fieldErrors[.paidAmount] = paidAmount.trimmingCharacters(in: .whitespaces).isEmpty ? "ჩარიცხული თანხა სავალდებულოა." : "თანხა არასწორია."
        } else if let lari, lari < 0 {
            fieldErrors[.paidAmount] = "თანხა არ შეიძლება იყოს უარყოფითი."
        }
        if !paidAmountDollar.trimmingCharacters(in: .whitespaces).isEmpty {
            if dollars == nil {
                fieldErrors[.paidAmountDollar] = "თანხა არასწორია."
            } else if let dollars, dollars < 0 {
                fieldErrors[.paidAmountDollar] = "თანხა არ შეიძლება იყოს უარყოფითი."
            }
        }
        guard fieldErrors.isEmpty, let lari else { return }

        let request = PaidAmountRequest(
            paidAmount: lari,
            paidAmountDollar: dollars,
            paidAt: DateFormatter.apiDay.string(from: paidAt),
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            sendTelegramNotification: sendTelegram,
            sendClientEmail: sendClientEmail
        )

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response: PaidAmountResponse = try await APIClient.shared.send(Endpoint(
                    method: .post,
                    path: "admin/expenses/\(expense.id)/paid-amounts",
                    body: request,
                    requiresAuth: true
                ))
                onSaved(response.expense, response.clientEmailSent)
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
}

/// The project the entry is added to (the web's `expenseContextCard` mixin).
private struct ExpenseContextSection: View {
    let expense: ExpenseDetail

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(expense.projectName)
                        .font(.headline)
                    Spacer()
                    ExpenseStatusBadge(status: expense.status)
                }
                HStack {
                    Text("ღირებულება: \(expense.totalAmount.webMoney())")
                    Spacer()
                    Text("ხარჯი: \(expense.totalExpenses.webMoney())")
                        .foregroundStyle(.red)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

/// A photo picked for upload: a small preview plus a downscaled JPEG to send.
private struct SelectedPhoto: Identifiable {
    let id = UUID()
    let preview: UIImage
    let jpegData: Data

    /// Longest side sent to the server; the backend makes its own 320px thumbnail.
    private static let maxDimension: CGFloat = 2048

    init?(data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, Self.maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        preview = resized
        jpegData = jpeg
    }
}

extension Double {
    /// Parses a typed amount, accepting both `12.5` and `12,5`. Empty or invalid text is nil.
    static func parseMoney(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
}
