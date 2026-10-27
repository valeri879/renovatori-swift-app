import SwiftUI

/// Main page of renovatori.ge (`views/pages/main-page/main-page.pug`), built from standard SwiftUI components.
struct HomeView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var path: [AppRoute] = []
    @State private var isShowingLogin = false
    /// Where to go after the login sheet signs the user in (the profile when nil).
    @State private var destinationAfterSignIn: AppRoute?
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
            // Hidden behind the principal toolbar item; it names the back button on subpages.
            .navigationTitle("მთავარი")
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
                    MainMenu(
                        isSignedIn: auth.currentUser != nil,
                        open: { route in path.append(route) },
                        signIn: { showSignIn(then: nil) }
                    )
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .about:
                    AboutView { path.append(.prices) }
                case .prices:
                    PricesView()
                case .faq:
                    FAQView()
                case .profile:
                    ProfileView()
                case .projects:
                    ProjectsListView()
                case .project(let id):
                    ProjectDetailView(id: id)
                case .blog:
                    BlogListView()
                case .blogPost(let id):
                    BlogDetailView(id: id)
                case .calculator:
                    CalculatorView()
                case .consultation:
                    ConsultationView()
                case .consultationOrder(let consultationType):
                    ConsultationOrderView(consultationType: consultationType)
                case .contact:
                    ContactView()
                case .emailVerification:
                    EmailVerificationView()
                case .passwordChange:
                    PasswordChangeView()
                }
            }
        }
        .environment(\.appNavigation, AppNavigation(
            open: { route in path.append(route) },
            signIn: { destination in showSignIn(then: destination) }
        ))
        .sheet(isPresented: $isShowingLogin, onDismiss: { destinationAfterSignIn = nil }) {
            NavigationStack {
                LoginView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("დახურვა") { isShowingLogin = false }
                        }
                    }
            }
        }
        .onChange(of: auth.currentUser?.id) { oldID, newID in
            if newID != nil, oldID == nil, isShowingLogin {
                // Just logged in or signed up: close the sheet and continue where the user was headed.
                let destination = destinationAfterSignIn ?? .profile
                isShowingLogin = false
                // The screen that asked for sign-in may already be on top (e.g. the booking form).
                if path.last != destination {
                    path.append(destination)
                }
            } else if newID == nil {
                // Logged out (or the session expired): leave the screens that need an account.
                path.removeAll { [.profile, .emailVerification, .passwordChange].contains($0) }
            }
        }
    }
}

extension HomeView {
    private func showSignIn(then destination: AppRoute?) {
        destinationAfterSignIn = destination
        isShowingLogin = true
    }
}

/// Sections other parts of the page can scroll to.
enum HomeSection: Hashable {
    case prices
}

/// The site's navbar links, collapsed into a toolbar menu.
/// Items with a route open an in-app screen; the rest open renovatori.ge.
private struct MainMenu: View {
    let isSignedIn: Bool
    let open: (AppRoute) -> Void
    let signIn: () -> Void

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
            if isSignedIn {
                Button {
                    open(.profile)
                } label: {
                    Label("ჩემი პროფილი", systemImage: "person.crop.circle")
                }
            } else {
                Button(action: signIn) {
                    Label("შესვლა", systemImage: "person.crop.circle")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
        }
        .accessibilityLabel("მენიუ")
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
