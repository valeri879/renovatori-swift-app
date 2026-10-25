import SwiftUI

/// Main page of renovatori.ge (`views/pages/main-page/main-page.pug`), built from standard SwiftUI components.
struct HomeView: View {
    @State private var path: [AppRoute] = []
    /// Section to scroll to once the main page is visible.
    @State private var scrollTarget: HomeSection?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        ContactBar()
                        CoverView { scrollTarget = .prices }
                        ServicesSection()
                        ProjectsSection()
                        PricesSection()
                            .id(HomeSection.prices)
                        TeamSection()
                        BlogsSection()
                        FAQSection()
                        FooterView()
                    }
                    .padding(.bottom, 16)
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    scrollTarget = nil
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        path.removeAll()
                    } label: {
                        Image(resource: "favicon")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("რენოვატორი")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    MainMenu { route in path.append(route) }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .about:
                    AboutView(showPrices: showPricesFromSubpage)
                }
            }
        }
    }

    /// Pops back to the main page, then scrolls once the pop animation has finished.
    private func showPricesFromSubpage() {
        path.removeAll()
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            scrollTarget = .prices
        }
    }
}

/// Sections other parts of the page can scroll to.
enum HomeSection: Hashable {
    case prices
}

/// The site's navbar links, collapsed into a toolbar menu.
/// Items with a route open an in-app screen; the rest open renovatori.ge.
private struct MainMenu: View {
    let open: (AppRoute) -> Void

    var body: some View {
        Menu {
            ForEach(MainPageData.menu) { item in
                if let route = item.route {
                    Button {
                        open(route)
                    } label: {
                        Label(item.title, systemImage: item.symbol ?? "link")
                    }
                } else {
                    Link(destination: SiteInfo.page(item.path)) {
                        Label(item.title, systemImage: item.symbol ?? "link")
                    }
                }
            }
            Divider()
            Link(destination: SiteInfo.page("/login")) {
                Label("შესვლა", systemImage: "person.crop.circle")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
        }
        .accessibilityLabel("მენიუ")
    }
}

#Preview {
    HomeView()
}
