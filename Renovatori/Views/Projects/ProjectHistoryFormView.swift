import PhotosUI
import SwiftUI

/// "ისტორიის დამატება / რედაქტირება" (`views/pages/add-project-history-page`, `edit-project-history-page`),
/// sent as multipart to `POST /admin/projects/:id/history` or `PUT /admin/project-history/:id` so photos
/// can go with it. Admins only.
struct ProjectHistoryFormView: View {
    private enum Field: String {
        case comment, timestamp, clientId
    }

    let project: ProjectDetail
    /// The entry being edited; nil adds a new one.
    let entry: ProjectHistoryEntry?
    let onSaved: (_ history: [ProjectHistoryEntry], _ clientEmailSent: Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var comment: String
    @State private var timestamp: Date
    @State private var clientId: String
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photos: [SelectedPhoto] = []
    @State private var sendClientEmail = false

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    init(project: ProjectDetail, entry: ProjectHistoryEntry? = nil, onSaved: @escaping (_ history: [ProjectHistoryEntry], _ clientEmailSent: Bool) -> Void) {
        self.project = project
        self.entry = entry
        self.onSaved = onSaved
        _comment = State(initialValue: entry?.comment ?? "")
        _timestamp = State(initialValue: entry?.timestamp ?? Date())
        // New entries are addressed to the project's client, like the web form's default.
        _clientId = State(initialValue: entry.map { $0.clientId ?? "" } ?? project.clientId ?? "")
    }

    var body: some View {
        Form {
            Section {
                Text(project.title)
                    .font(.headline)
            }

            Section {
                if let existing = entry?.images, !existing.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(existing.enumerated()), id: \.offset) { _, image in
                                RemoteImage(url: APIConfig.imageURL(image.thumbUrl))
                                    .frame(width: 72, height: 54)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
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
                Text(entry == nil ? "სურათები" : "ახალი სურათები")
            } footer: {
                if entry != nil {
                    Text("ახალი სურათები არსებულს დაემატება.")
                }
            }

            Section {
                FormFieldRow(title: "კომენტარი", isRequired: false, error: fieldErrors[.comment]) {
                    TextField("ისტორიის აღწერა", text: $comment, axis: .vertical)
                        .lineLimit(3...8)
                }
                FormFieldRow(title: "თარიღი / დრო", isRequired: false, error: fieldErrors[.timestamp]) {
                    DatePicker("თარიღი / დრო", selection: $timestamp)
                        .labelsHidden()
                }
                FormFieldRow(title: "მომხმარებლის ID", isRequired: entry == nil, error: fieldErrors[.clientId]) {
                    TextField("მაგ: 67c8f3d4b9c9a1f3a4b5c6d7", text: $clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .monospaced()
                }
            } footer: {
                Text("მომხმარებლის ID იპოვი საიტის გვერდზე /users: დააჭირე „რედაქტირება“ და იქ ნახავ „მომხმარებლის ID“-ს. ჩანაწერს ხედავს მხოლოდ ეს მომხმარებელი და ადმინისტრატორი.")
            }

            Section {
                Toggle("კლიენტისთვის შეტყობინების გაგზავნა (ელ-ფოსტა და აპლიკაცია)", isOn: $sendClientEmail)
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: entry == nil ? "ისტორიის დამატება" : "შენახვა", isLoading: isSubmitting, action: submit)
            }
        }
        .navigationTitle(entry == nil ? "ისტორიის დამატება" : "ისტორიის რედაქტირება")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("გაუქმება") { dismiss() }
                    .disabled(isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
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

    private func submit() {
        errorMessage = nil
        fieldErrors = [:]
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        if entry == nil, trimmedClientId.isEmpty {
            fieldErrors[.clientId] = "მომხმარებლის ID სავალდებულოა."
            return
        }

        var form = MultipartForm()
        form.fields = [
            ("comment", comment.trimmingCharacters(in: .whitespacesAndNewlines)),
            ("timestamp", ISO8601DateFormatter().string(from: timestamp)),
            ("clientId", trimmedClientId),
            ("sendClientEmail", sendClientEmail ? "true" : "false"),
        ]
        form.files = photos.enumerated().map { index, photo in
            MultipartForm.File(field: "images", fileName: "photo-\(index + 1).jpg", mimeType: "image/jpeg", data: photo.jpegData)
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response: ProjectHistoryResponse = try await APIClient.shared.send(Endpoint(
                    method: entry == nil ? .post : .put,
                    path: entry.map { "admin/project-history/\($0.id)" } ?? "admin/projects/\(project.id)/history",
                    form: form,
                    requiresAuth: true
                ))
                onSaved(response.history, response.clientEmailSent ?? false)
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
