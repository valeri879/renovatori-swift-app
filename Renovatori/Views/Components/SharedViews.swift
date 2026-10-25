import SwiftUI
import UIKit

extension Image {
    /// Loads a loose file from `Resources/Images` (e.g. `sofa@3x.png`, `cover.jpg`).
    /// Images are kept out of the asset catalog because compiling one needs a simulator
    /// runtime matching the SDK, which this machine does not have installed.
    init(resource name: String) {
        self.init(uiImage: UIImage(named: name) ?? UIImage())
    }
}

/// A monochrome icon from the renovatori web project, tinted by the current foreground style.
struct AssetIcon: View {
    let name: String
    var size: CGFloat = 20

    var body: some View {
        Image(resource: name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

/// How to reach the company, with the copy shown when the device can't handle the link.
enum ContactAction {
    case call, email

    var url: URL {
        switch self {
        case .call: SiteInfo.phoneURL
        case .email: SiteInfo.emailURL
        }
    }

    var value: String {
        switch self {
        case .call: SiteInfo.phoneDisplay
        case .email: SiteInfo.email
        }
    }

    var failureTitle: String {
        switch self {
        case .call: "დარეკვა ვერ მოხერხდა"
        case .email: "ელ-ფოსტა ვერ გაიხსნა"
        }
    }

    var failureMessage: String {
        switch self {
        case .call: "ამ მოწყობილობიდან ზარის განხორციელება შეუძლებელია. დაგვიკავშირდით ნომერზე \(value)."
        case .email: "ამ მოწყობილობაზე ელ-ფოსტის აპი არ არის დაყენებული. მოგვწერეთ მისამართზე \(value)."
        }
    }

    var copyTitle: String {
        switch self {
        case .call: "ნომრის კოპირება"
        case .email: "მისამართის კოპირება"
        }
    }
}

/// Opens the dialer (`tel:`) or a new message in the mail app (`mailto:`). iOS confirms a call itself.
/// When nothing can handle the link (the simulator, an iPad without calling, no mail app),
/// an alert shows the number or address with a copy button instead.
struct ContactButton<Content: View>: View {
    let action: ContactAction
    @ViewBuilder let label: Content

    @Environment(\.openURL) private var openURL
    @State private var isUnavailable = false

    var body: some View {
        Button {
            openURL(action.url) { accepted in
                if !accepted {
                    isUnavailable = true
                }
            }
        } label: {
            label
        }
        .alert(action.failureTitle, isPresented: $isUnavailable) {
            Button(action.copyTitle) {
                UIPasteboard.general.string = action.value
            }
            Button("დახურვა", role: .cancel) {}
        } message: {
            Text(action.failureMessage)
        }
    }
}

/// Title and subtitle shown above each part of the page.
struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Remote photo that fills its frame, with a neutral placeholder while loading
/// and `fallbackAsset` when there is no URL or the download fails.
struct RemoteImage: View {
    let url: URL?
    var fallbackAsset: String?

    var body: some View {
        Color(.secondarySystemFill)
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            fallback
                        default:
                            ProgressView()
                        }
                    }
                } else {
                    fallback
                }
            }
            .clipped()
    }

    @ViewBuilder
    private var fallback: some View {
        if let fallbackAsset {
            Image(resource: fallbackAsset).resizable().scaledToFill()
        }
    }
}
