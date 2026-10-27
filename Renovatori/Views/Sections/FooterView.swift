import SwiftUI

/// Page links, theme picker, credits and version.
struct FooterView: View {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system
    @AppStorage(APIEnvironment.storageKey) private var apiEnvironment: APIEnvironment = .local

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var year: String {
        String(Calendar.current.component(.year, from: .now))
    }

    var body: some View {
        VStack(spacing: 20) {
            Divider()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 10) {
                ForEach(MainPageData.footerLinks) { item in
                    Link(item.title, destination: SiteInfo.page(item.path))
                        .font(.subheadline)
                }
            }

            Picker("თემა", selection: $theme) {
                ForEach(ThemePreference.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            #if DEBUG
            // Temporary: switches the backend between the local server and renovatori.ge.
            Toggle(isOn: Binding(
                get: { apiEnvironment == .production },
                set: { apiEnvironment = $0 ? .production : .local }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("პროდაქშენის ბაზა")
                    Text(APIConfig.origin.absoluteString)
                        .font(.caption)
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.red)
            #endif

            VStack(spacing: 4) {
                Text("პროგრამულ მხარდაჭერას უზრუნველყოფს [Val Do](https://val-do.com)")
                Text("©Renovatori.ge \(year) წელი")
                Text("ვერსია \(appVersion)")
                    .monospaced()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}
