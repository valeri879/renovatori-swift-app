import SwiftUI

/// Page links, theme picker, credits and version.
struct FooterView: View {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

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
