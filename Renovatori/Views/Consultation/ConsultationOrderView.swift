import SwiftUI

/// "კონსულტაციის დაჯავშნა" form (`views/pages/consultation-order-page`), sent to `POST /consultations`.
struct ConsultationOrderView: View {
    private enum Field: String {
        case consultationType, address, visitDate, comment
    }

    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.appNavigation) private var navigation

    @State private var consultationType: String
    @State private var address = ""
    @State private var visitDate = Calendar.current.startOfDay(for: .now)
    @State private var comment = ""

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var bookedConsultation: Consultation?

    init(consultationType: String?) {
        let names = ConsultationPageData.packages.map(\.name)
        // Unknown or missing package falls back to the first one, like the web form.
        _consultationType = State(initialValue: consultationType.flatMap { names.contains($0) ? $0 : nil } ?? names[0])
    }

    var body: some View {
        Group {
            if auth.currentUser == nil {
                signedOut
            } else if let bookedConsultation {
                success(bookedConsultation)
            } else {
                form
            }
        }
        .navigationTitle("კონსულტაციის დაჯავშნა")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Form

    private var form: some View {
        Form {
            Section {
                FormFieldRow(title: "კონსულტაციის ტიპი", error: fieldErrors[.consultationType]) {
                    Picker("კონსულტაციის ტიპი", selection: $consultationType) {
                        ForEach(ConsultationPageData.packages) { package in
                            Text("\(package.name) — \(package.priceFormatted)").tag(package.name)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                FormFieldRow(title: "მისამართი", error: fieldErrors[.address]) {
                    TextField("ქალაქი, ქუჩა, ნომერი", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                }

                FormFieldRow(title: "ვიზიტის თარიღი", error: fieldErrors[.visitDate]) {
                    DatePicker("ვიზიტის თარიღი", selection: $visitDate, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                        .labelsHidden()
                }

                FormFieldRow(title: "კომენტარი", isRequired: false, error: fieldErrors[.comment]) {
                    TextField("დამატებითი ინფორმაცია (არასავალდებულო)", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: "მოთხოვნის გაგზავნა", isLoading: isSubmitting, action: submit)
            }
        }
    }

    private var signedOut: some View {
        ContentUnavailableView {
            Label("საჭიროა ავტორიზაცია", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text("კონსულტაციის დასაჯავშნად შედით ანგარიშში.")
        } actions: {
            Button("შესვლა") {
                navigation.signIn(.consultationOrder(consultationType))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func success(_ consultation: Consultation) -> some View {
        ContentUnavailableView {
            Label("მოთხოვნა გაიგზავნა", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } description: {
            VStack(spacing: 6) {
                Text("კონსულტაციის მოთხოვნა წარმატებით გაიგზავნა. ჩვენი გუნდი მალე დაგიკავშირდებათ.")
                Text("\(consultation.consultationType) · \(consultation.address)")
                if let visitDate = consultation.visitDate {
                    Text("ვიზიტი: \(visitDate.formatted(.dateTime.day().month().year()))")
                }
            }
        } actions: {
            Button("ახალი მოთხოვნა") {
                bookedConsultation = nil
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: Submit

    private var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Mirrors the backend's validation so most mistakes never reach the server.
    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        if trimmedAddress.isEmpty {
            errors[.address] = "მისამართის ველის შევსება სავალდებულოა."
        } else if trimmedAddress.count < 2 || trimmedAddress.count > 500 {
            errors[.address] = "მისამართი უნდა იყოს 2-დან 500 სიმბოლომდე."
        }
        if comment.count > 2000 {
            errors[.comment] = "კომენტარი არ უნდა აღემატებოდეს 2000 სიმბოლოს."
        }
        return errors
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = validate()
        guard fieldErrors.isEmpty else { return }

        let request = ConsultationRequest(
            consultationType: consultationType,
            address: trimmedAddress,
            visitDate: Self.dayFormatter.string(from: visitDate),
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let response: ConsultationResponse = try await APIClient.shared.send(Endpoint(
                    method: .post,
                    path: "consultations",
                    body: request,
                    requiresAuth: true
                ))
                address = ""
                comment = ""
                bookedConsultation = response.consultation
            } catch let error as APIError where error.code == APIError.sessionExpiredCode {
                // The refresh token was rejected too: the user must sign in again.
                await auth.logout()
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

    /// `YYYY-MM-DD` in the user's calendar day, matching the web form's date input.
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    NavigationStack {
        ConsultationOrderView(consultationType: "სტანდარტ პაკეტი")
    }
    .environmentObject(AuthViewModel())
}
