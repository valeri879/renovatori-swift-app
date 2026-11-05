import SwiftUI

/// Main page of renovatori.ge (`views/pages/main-page/main-page.pug`), built from standard SwiftUI components.
struct HomeView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject private var push = PushNotifications.shared
    @State private var path: [AppRoute] = []
    @State private var isShowingLogin = false
    /// Where to go after the login sheet signs the user in (the profile when nil).
    @State private var destinationAfterSignIn: AppRoute?
    @State private var webPage: WebPage?
    @State private var isKeyboardVisible = false
    @State private var quickLinksHeight: CGFloat = 0

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        ContactBar()
                        CoverView { path.append(.prices) }
                    }
                    ServicesSection()
                    ProjectsSection()
                    PricesSection()
                    TeamSection()
                    BlogsSection()
                    FAQSection()
                    FooterView()
                }
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { quickLinks(on: nil) }
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
                        isStaff: auth.currentUser?.isStaff == true,
                        open: { route in path.append(route) },
                        signIn: { showSignIn(then: nil) }
                    )
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(route)
                    .safeAreaInset(edge: .bottom, spacing: 0) { quickLinks(on: route) }
            }
        }
        // The web's admin quick action (`components/quick-actions`): a floating "ხარჯები" button on every screen.
        .overlay(alignment: .bottomTrailing) {
            if auth.currentUser?.isAdmin == true, !hidesQuickAction {
                Button(action: openExpenses) {
                    Label("ხარჯები", systemImage: "banknote")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .shadow(radius: 6, y: 3)
                .padding(20)
                // Above the calculator/consultation bar, like the web.
                .padding(.bottom, showsQuickLinks(on: path.last) ? quickLinksHeight : 0)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: hidesQuickAction)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .environment(\.appNavigation, AppNavigation(
            open: { route in path.append(route) },
            signIn: { destination in showSignIn(then: destination) },
            goHome: { path.removeAll() }
        ))
        // Web links stay in the in-app browser; phone and email links go to the system.
        .environment(\.openURL, OpenURLAction { url in
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
                return .systemAction
            }
            webPage = WebPage(url: url)
            return .handled
        })
        .fullScreenCover(item: $webPage) { page in
            SafariView(url: page.url)
                .ignoresSafeArea()
        }
        // A tapped push notification opens its screen (e.g. the project a history entry was added to).
        .onChange(of: push.pendingRoute, initial: true) { _, route in
            guard let route else { return }
            path = [route]
            push.pendingRoute = nil
        }
        // renovatori.ge links (Universal Links, Safari's "open in app" banner) open the same page here.
        .onOpenURL { url in
            path = AppRoute(siteURL: url).map { [$0] } ?? []
        }
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
                path.removeAll(where: \.requiresAccount)
            }
        }
    }
}

extension HomeView {
    /// Screens where the floating "ხარჯები" button is hidden: the expense screens already lead to the
    /// expenses (back button), and these screens have their own buttons at the bottom it would cover.
    private var hidesQuickAction: Bool {
        switch path.last {
        case .expenses, .expenseDetail, .calculator: true
        default: false
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
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
        case .callRequest:
            CallRequestView()
        case .emailVerification:
            EmailVerificationView()
        case .passwordChange:
            PasswordChangeView()
        case .myProjects:
            MyProjectsView()
        case .expenses:
            ExpensesListView()
        case .expenseDetail(let id):
            ExpenseDetailView(id: id)
        }
    }

    /// The web's phone bar (`components/mobile-cta`): calculator and consultation on every screen.
    /// Each screen gets its own, so lists and scroll views make room for it.
    @ViewBuilder
    private func quickLinks(on route: AppRoute?) -> some View {
        if showsQuickLinks(on: route) {
            QuickLinksBar(open: openQuickLink)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { quickLinksHeight = $0 }
        }
    }

    /// The calculator and the expense project have their own buttons at the bottom; while typing the
    /// bar would sit on top of the keyboard.
    private func showsQuickLinks(on route: AppRoute?) -> Bool {
        if isKeyboardVisible { return false }
        switch route {
        case .calculator, .expenseDetail: return false
        default: return true
        }
    }

    /// Opens a quick link unless its screen is already the one on top.
    private func openQuickLink(_ route: AppRoute) {
        if path.last != route {
            path.append(route)
        }
    }

    /// Goes back to the expenses list when it is already open further down the stack, otherwise pushes it.
    private func openExpenses() {
        if let index = path.lastIndex(of: .expenses) {
            path.removeSubrange(path.index(after: index)...)
        } else {
            path.append(.expenses)
        }
    }

    private func showSignIn(then destination: AppRoute?) {
        destinationAfterSignIn = destination
        isShowingLogin = true
    }
}

/// The web's pinned phone bar (`components/mobile-cta`): calculator and consultation shortcuts.
private struct QuickLinksBar: View {
    let open: (AppRoute) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button { open(.calculator) } label: {
                Label("კალკულატორი", systemImage: "plus.forwardslash.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button { open(.consultation) } label: {
                Label("კონსულტაცია", systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .font(.subheadline.weight(.semibold))
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

/// The site's navbar links, collapsed into a toolbar menu.
/// Items with a route open an in-app screen; the rest open renovatori.ge.
private struct MainMenu: View {
    let isSignedIn: Bool
    /// Admins and moderators also get the admin section (like the web's admin menu).
    let isStaff: Bool
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
            if isStaff {
                Section("ადმინისტრირება") {
                    Button {
                        open(.expenses)
                    } label: {
                        Label("ხარჯები", systemImage: "banknote")
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
                Button {
                    open(.myProjects)
                } label: {
                    Label("ჩემი პროექტები", systemImage: "hammer")
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
