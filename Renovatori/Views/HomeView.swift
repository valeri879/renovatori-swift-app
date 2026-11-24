import SwiftUI

/// The app's tabs. Each keeps its own navigation stack.
enum AppTab: Hashable, CaseIterable {
    case home, calculator, consultation, profile
}

/// Root of the app: a tab bar with the main page, the calculator, the consultation and the profile.
/// Every tab has its own stack; links, push notifications and the menu go through `open(_:)`, which
/// switches to a tab for its own screen and otherwise pushes onto the current tab.
struct HomeView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject private var push = PushNotifications.shared
    @State private var selectedTab: AppTab = .home
    @State private var paths: [AppTab: [AppRoute]] = [:]
    @State private var isShowingLogin = false
    /// Where to go after the login sheet signs the user in (the profile when nil).
    @State private var destinationAfterSignIn: AppRoute?
    @State private var webPage: WebPage?

    var body: some View {
        TabView(selection: tabSelection) {
            stack(.home) {
                MainPageView(open: open, signIn: { selectedTab = .profile })
            }
            .tabItem { Label("მთავარი", systemImage: "house") }
            .tag(AppTab.home)

            stack(.calculator) {
                CalculatorView()
            }
            .tabItem { Label("კალკულატორი", systemImage: "plus.forwardslash.minus") }
            .tag(AppTab.calculator)

            stack(.consultation) {
                ConsultationView()
            }
            .tabItem { Label("კონსულტაცია", systemImage: "bubble.left.and.bubble.right") }
            .tag(AppTab.consultation)

            stack(.profile) {
                if auth.currentUser != nil {
                    ProfileView()
                } else {
                    LoginView()
                }
            }
            .tabItem { Label("პროფილი", systemImage: "person.crop.circle") }
            .tag(AppTab.profile)
        }
        .environment(\.appNavigation, AppNavigation(
            open: open,
            signIn: { destination in showSignIn(then: destination) },
            goHome: {
                paths[.home] = []
                selectedTab = .home
            }
        ))
        // renovatori.ge pages the app has (e.g. links in FAQ answers) open as app screens; other web links
        // stay in the in-app browser; phone and email links go to the system.
        .environment(\.openURL, OpenURLAction { url in
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
                return .systemAction
            }
            if let route = AppRoute(siteURL: url) {
                open(route)
                return .handled
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
            show(route)
            push.pendingRoute = nil
        }
        // renovatori.ge links (Universal Links, Safari's "open in app" banner) open the same page here.
        .onOpenURL { url in
            if let route = AppRoute(siteURL: url) {
                show(route)
            } else {
                paths[.home] = []
                selectedTab = .home
            }
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
            if newID != nil, oldID == nil {
                if isShowingLogin {
                    // Logged in from the sheet: close it and continue where the user was headed.
                    let destination = destinationAfterSignIn ?? .profile
                    isShowingLogin = false
                    // The screen that asked for sign-in may already be on top (e.g. the booking form).
                    if currentPath.last != destination {
                        open(destination)
                    }
                } else {
                    // Logged in on the profile tab: leave the sign-up screens, the tab now shows the profile.
                    paths[.profile] = []
                }
            } else if newID == nil {
                // Logged out (or the session expired): leave the screens that need an account.
                for tab in AppTab.allCases {
                    paths[tab]?.removeAll(where: \.requiresAccount)
                }
            }
        }
    }
}

extension HomeView {
    /// Tapping the selected tab again goes back to its first screen, as in system apps.
    private var tabSelection: Binding<AppTab> {
        Binding {
            selectedTab
        } set: { tab in
            if tab == selectedTab {
                paths[tab] = []
            }
            selectedTab = tab
        }
    }

    private var currentPath: [AppRoute] {
        paths[selectedTab] ?? []
    }

    private func path(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding {
            paths[tab] ?? []
        } set: { newValue in
            paths[tab] = newValue
        }
    }

    /// One tab's navigation stack, with every app screen as a destination and the admin's
    /// floating "ხარჯები" button above the tab bar.
    private func stack<Root: View>(_ tab: AppTab, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: path(for: tab)) {
            root()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(route)
                }
        }
        // The web's admin quick action (`components/quick-actions`).
        .overlay(alignment: .bottomTrailing) {
            if auth.currentUser?.isAdmin == true, !hidesQuickAction(on: tab) {
                Button(action: openExpenses) {
                    Label("ხარჯები", systemImage: "banknote")
                        .font(.subheadline.bold())
                }
                .primaryButtonStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .shadow(radius: 6, y: 3)
                .padding(20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: paths[tab])
    }

    /// The floating "ხარჯები" button is hidden on the expense screens, which already lead to the
    /// expenses, and on screens with their own buttons at the bottom it would cover.
    private func hidesQuickAction(on tab: AppTab) -> Bool {
        guard let top = paths[tab]?.last else {
            return tab == .calculator
        }
        switch top {
        case .expenses, .expenseDetail, .calculator: return true
        default: return false
        }
    }

    /// Opens a screen: the calculator, the consultation and the profile are tabs; everything else is
    /// pushed onto the current tab.
    private func open(_ route: AppRoute) {
        switch route {
        case .calculator:
            selectedTab = .calculator
        case .consultation:
            selectedTab = .consultation
        case .profile:
            selectedTab = .profile
        default:
            paths[selectedTab, default: []].append(route)
        }
    }

    /// Shows a screen from outside the app (a link or a notification) on a fresh stack.
    private func show(_ route: AppRoute) {
        switch route {
        case .calculator, .consultation, .profile:
            open(route)
        default:
            paths[.home] = [route]
            selectedTab = .home
        }
    }

    /// Goes back to the expenses list when it is already open further down the stack, otherwise pushes it.
    private func openExpenses() {
        var path = currentPath
        if let index = path.lastIndex(of: .expenses) {
            path.removeSubrange(path.index(after: index)...)
        } else {
            path.append(.expenses)
        }
        paths[selectedTab] = path
    }

    private func showSignIn(then destination: AppRoute?) {
        destinationAfterSignIn = destination
        isShowingLogin = true
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .about:
            AboutView { open(.prices) }
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
        case .calculatorResult(let submission):
            CalculatorResultView(submission: submission)
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
        case .accountDeletion:
            AccountDeletionView()
        case .myProjects:
            MyProjectsView()
        case .expenses:
            ExpensesListView()
        case .expenseDetail(let id):
            ExpenseDetailView(id: id)
        }
    }
}

/// Main page of renovatori.ge (`views/pages/main-page/main-page.pug`), built from standard SwiftUI components.
private struct MainPageView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.appNavigation) private var navigation
    let open: (AppRoute) -> Void
    let signIn: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ContactBar()
                    CoverView { open(.prices) }
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
        // Hidden behind the principal toolbar item; it names the back button on subpages.
        .navigationTitle("მთავარი")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigation.goHome()
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
                    open: open,
                    signIn: signIn
                )
            }
        }
    }
}

/// The site's navbar links, collapsed into a toolbar menu.
/// Items with a route open an in-app screen; the rest open renovatori.ge.
/// The calculator and the consultation are tabs, so the menu leaves them out.
private struct MainMenu: View {
    let isSignedIn: Bool
    /// Admins and moderators also get the admin section (like the web's admin menu).
    let isStaff: Bool
    let open: (AppRoute) -> Void
    let signIn: () -> Void

    private var items: [NavItem] {
        MainPageData.menu.filter { $0.route != .calculator && $0.route != .consultation }
    }

    var body: some View {
        Menu {
            ForEach(items) { item in
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
