import SwiftUI
import WebKit

/// "ზარის მოთხოვნა" (`views/pages/call-request-page`): phone links open it outside working hours.
/// Sent to `POST /call-requests` with the web form's math captcha; signed-in users get their phone
/// and email filled in.
struct CallRequestView: View {
    private enum Field: String {
        case phone, email, description, captchaInput
    }

    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.siteContacts) private var contacts
    @Environment(\.appNavigation) private var navigation

    @State private var phone = ""
    @State private var email = ""
    @State private var description = ""
    @State private var captchaAnswer = ""
    @State private var captcha: CallRequestCaptcha?
    @State private var isLoadingCaptcha = false

    @State private var fieldErrors: [Field: String] = [:]
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isSent = false

    var body: some View {
        Group {
            if isSent {
                sent
            } else {
                form
            }
        }
        .navigationTitle("ზარის მოთხოვნა")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            fillInUser()
            if captcha == nil {
                await loadCaptcha()
            }
        }
    }

    // MARK: Form

    private var form: some View {
        Form {
            Section {
                hoursNotice
            }

            if !contacts.workingHours.isEmpty {
                Section("სამუშაო საათები") {
                    ForEach(contacts.workingHours) { hours in
                        Text("\(hours.daysLabel), ") + Text("\(hours.opensAt)-\(hours.closesAt)").bold()
                    }
                }
            }

            Section {
                FormFieldRow(title: "ტელეფონი", error: fieldErrors[.phone]) {
                    TextField("მაგ: 579123123", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                FormFieldRow(title: "ელ-ფოსტა", isRequired: false, error: fieldErrors[.email]) {
                    // Verbatim, or the example address would be styled as a link.
                    TextField(text: $email, prompt: Text(verbatim: "მაგ: name@example.com")) { Text("ელ-ფოსტა") }
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                FormFieldRow(title: "აღწერა", isRequired: false, error: fieldErrors[.description]) {
                    TextField("მოკლედ აღწერეთ, რა საკითხზე გსურთ დაკავშირება", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section {
                FormFieldRow(title: "ამოხსენით მაგალითი", error: fieldErrors[.captchaInput]) {
                    HStack(spacing: 12) {
                        captchaImage
                        Button {
                            Task { await loadCaptcha() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .disabled(isLoadingCaptcha)
                        .accessibilityLabel("ახალი მაგალითი")
                    }
                    TextField("პასუხი", text: $captchaAnswer)
                        .keyboardType(.numberPad)
                }
            } footer: {
                if let errorMessage {
                    FormErrorBanner(message: errorMessage)
                        .padding(.top, 4)
                }
            }

            Section {
                SubmitButton(title: "ზარის მოთხოვნა", isLoading: isSubmitting, action: submit)
            }
        }
    }

    /// During working hours the main phone can be called right away; otherwise the team calls back.
    @ViewBuilder
    private var hoursNotice: some View {
        if contacts.isOpen(), let mainPhone = contacts.mainPhone {
            VStack(alignment: .leading, spacing: 6) {
                Label("ახლა სამუშაო საათებია — შეგიძლიათ პირდაპირ დაგვირეკოთ:", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                ContactButton(action: .call(mainPhone)) {
                    Text(mainPhone.display)
                        .bold()
                }
            }
            .font(.subheadline)
        } else {
            Label("ახლა არასამუშაო საათებია. დატოვეთ ნომერი და სამუშაო საათებში დაგირეკავთ.", systemImage: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var captchaImage: some View {
        if let captcha {
            CaptchaImage(svg: captcha.svg)
                .frame(width: 200, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .accessibilityLabel("მათემატიკური მაგალითი")
        } else if isLoadingCaptcha {
            ProgressView()
                .frame(width: 200, height: 60)
        } else {
            Text("მაგალითი ვერ ჩაიტვირთა")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(height: 60)
        }
    }

    private var sent: some View {
        ContentUnavailableView {
            Label("მოთხოვნა მიღებულია", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } description: {
            Text("მოთხოვნა მიღებულია. სამუშაო საათებში დაგიკავშირდებით.")
        } actions: {
            Button("მთავარ გვერდზე დაბრუნება") {
                navigation.goHome()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Actions

    /// Like the web form, a signed-in user starts with their phone and email.
    private func fillInUser() {
        guard let user = auth.currentUser else { return }
        if phone.isEmpty {
            phone = user.phoneNumber
        }
        if email.isEmpty {
            email = user.email
        }
    }

    private func loadCaptcha() async {
        isLoadingCaptcha = true
        defer { isLoadingCaptcha = false }
        captchaAnswer = ""
        let response = try? await APIClient.shared.send(
            Endpoint(method: .get, path: "call-requests/captcha"),
            as: CallRequestCaptchaResponse.self
        )
        captcha = response?.captcha
    }

    /// Mirrors the backend's validation so most mistakes never reach the server.
    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        let digits = phone.filter(\.isNumber)
        // 9 digits, or 12 starting with the 995 country code (`+995 579 12 31 23`).
        if digits.count != 9, !(digits.count == 12 && digits.hasPrefix("995")) {
            errors[.phone] = "ტელეფონი უნდა იყოს 9-ნიშნა (მაგ: 579123123) ან +995-ით დაწყებული"
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if !trimmedEmail.isEmpty, trimmedEmail.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]+/) == nil {
            errors[.email] = "ელ-ფოსტის ფორმატი არასწორია"
        }
        if description.count > 1000 {
            errors[.description] = "აღწერა არ უნდა აღემატებოდეს 1000 სიმბოლოს"
        }
        if captchaAnswer.trimmingCharacters(in: .whitespaces).isEmpty {
            errors[.captchaInput] = "ჩაწერეთ მაგალითის პასუხი"
        }
        return errors
    }

    private func submit() {
        errorMessage = nil
        fieldErrors = validate()
        guard fieldErrors.isEmpty else { return }
        guard let captcha else {
            errorMessage = "მაგალითი ვერ ჩაიტვირთა. სცადეთ ხელახლა."
            return
        }

        let body = CallRequestBody(
            phone: phone.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            captchaInput: captchaAnswer.trimmingCharacters(in: .whitespaces),
            captchaHash: captcha.hash
        )

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                // A signed-in user's request is linked to their account, as on the web.
                _ = try await APIClient.shared.send(
                    Endpoint(method: .post, path: "call-requests", body: body, requiresAuth: auth.currentUser != nil),
                    as: CallRequestResponse.self
                )
                isSent = true
            } catch let error as APIError where error.code == APIError.sessionExpiredCode {
                await auth.logout()
                errorMessage = error.message
            } catch let error as APIError {
                for (key, message) in error.details ?? [:] {
                    if let field = Field(rawValue: key) {
                        fieldErrors[field] = message
                    }
                }
                // A wrong answer needs a new expression to solve.
                if fieldErrors[.captchaInput] != nil {
                    await loadCaptcha()
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

/// Draws the captcha's SVG markup. The web shows it on a white card, so it stays white in dark mode.
private struct CaptchaImage: UIViewRepresentable {
    let svg: String

    final class Coordinator {
        var loadedSVG: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .white
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Typing in the form updates this view too; reload only for a new captcha.
        guard context.coordinator.loadedSVG != svg else { return }
        context.coordinator.loadedSVG = svg
        webView.loadHTMLString("""
            <!doctype html>
            <html><head><meta name="viewport" content="width=200, initial-scale=1">
            <style>html, body { margin: 0; background: #fff; } svg { display: block; }</style>
            </head><body>\(svg)</body></html>
            """, baseURL: nil)
    }
}

#Preview {
    NavigationStack {
        CallRequestView()
    }
    .environmentObject(AuthViewModel())
}
