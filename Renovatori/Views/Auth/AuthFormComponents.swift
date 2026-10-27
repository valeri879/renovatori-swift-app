import SwiftUI

/// A form row: title (with a red asterisk when required), the input, and an optional red error below it.
struct FormFieldRow<Field: View>: View {
    let title: String
    var isRequired = true
    var error: String?
    @ViewBuilder let field: Field

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text(title) + Text(isRequired ? " *" : "").foregroundColor(.red))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            field
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Full-width submit button that shows a spinner while `isLoading`.
struct SubmitButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isLoading)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

/// A form-level error (e.g. wrong credentials or no connection).
struct FormErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
    }
}
