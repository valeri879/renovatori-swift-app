import Foundation

/// The website the app mirrors. Phones, emails and social links come from `SiteContacts`.
enum SiteInfo {
    static let baseURL = URL(string: "https://renovatori.ge")!

    static func page(_ path: String) -> URL {
        baseURL.appending(path: path)
    }
}

/// Screens that exist inside the app; other menu items open renovatori.ge.
enum AppRoute: Hashable {
    case about
    case prices
    case faq
    case profile
    case projects
    case project(String)
    case blog
    case blogPost(String)
    case calculator
    case consultation
    /// Booking form, preselected with a package name from `ConsultationPageData.packages`.
    case consultationOrder(String)
    case contact
    /// "ზარის მოთხოვნა": phone links open it outside working hours.
    case callRequest
    case emailVerification
    case passwordChange
    /// "ჩემი პროექტები": projects linked to the signed-in user.
    case myProjects
    /// Admin: expense projects (`/admin/expenses-list`). Staff only.
    case expenses
    /// Admin: one expense project. Staff only.
    case expenseDetail(String)

    /// Screens that need a signed-in account; they are closed when the session ends.
    var requiresAccount: Bool {
        switch self {
        case .profile, .emailVerification, .passwordChange, .myProjects, .expenses, .expenseDetail: true
        default: false
        }
    }

    /// The in-app screen for a renovatori.ge link (`/blog/:id`, `/project/:id`, …), so links inside
    /// blog posts stay in the app. Nil for other sites and for pages the app does not have.
    init?(siteURL url: URL) {
        let siteHosts = [SiteInfo.baseURL.host(), APIConfig.origin.host()].compactMap { $0 }
        guard let host = url.host()?.lowercased() else { return nil }
        let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        guard siteHosts.contains(bareHost) else { return nil }

        let parts = url.pathComponents.filter { $0 != "/" }
        switch (parts.first, parts.count) {
        case ("blog", 2): self = .blogPost(parts[1])
        case ("blog-list", 1): self = .blog
        case ("project", 2): self = .project(parts[1])
        case ("projects", 1): self = .projects
        case ("faq", 1): self = .faq
        case ("prices", 1): self = .prices
        case ("about", 1): self = .about
        case ("calculator", 1): self = .calculator
        case ("consultation", 1): self = .consultation
        case ("contact", 1): self = .contact
        case ("call-request", 1): self = .callRequest
        default: return nil
        }
    }
}

struct NavItem: Identifiable {
    let title: String
    let path: String
    var symbol: String?
    /// When set, the item opens this in-app screen instead of the website page.
    var route: AppRoute?
    var id: String { path }
}

struct Service: Identifiable {
    let icon: String
    let title: String
    let text: String
    var id: String { icon }
}

struct PricePackage: Identifiable {
    let title: String
    let pricePerSquareMeter: Int
    /// The package's article, opened with the app's native blog screen.
    let blogID: String
    var id: String { title }

    /// "მწვანე კარკასი" -> "მწვანე", for the narrow comparison columns.
    var shortTitle: String {
        title.split(separator: " ").first.map(String.init) ?? title
    }
}

/// One `tbody` row of the package comparison table.
enum PriceRow {
    case category(String)
    case option(String, included: [Bool])
}

struct Partner: Identifiable {
    let name: String
    let profession: String
    let imageURL: URL?
    var id: String { name }
}

struct FAQItem: Identifiable {
    let id: String
    let question: String
    let answer: AttributedString
}

/// Static demo content mirroring `views/pages/main-page/main-page.pug` and its components.
/// Team entries are a snapshot of what renovatori.ge loads from the database.
enum MainPageData {
    static let menu: [NavItem] = [
        NavItem(title: "კონსულტაცია", path: "/consultation", symbol: "bubble.left.and.bubble.right", route: .consultation),
        NavItem(title: "კალკულატორი", path: "/calculator", symbol: "plus.forwardslash.minus", route: .calculator),
        NavItem(title: "ჩვენ შესახებ", path: "/about", symbol: "info.circle", route: .about),
        NavItem(title: "ფასები", path: "/prices", symbol: "tag", route: .prices),
        NavItem(title: "ბლოგი", path: "/blog-list", symbol: "newspaper", route: .blog),
        NavItem(title: "პროექტები", path: "/projects", symbol: "hammer", route: .projects),
        NavItem(title: "ხშირად დასმული კითხვები", path: "/faq", symbol: "questionmark.circle", route: .faq),
        NavItem(title: "კონტაქტი", path: "/contact", symbol: "phone", route: .contact),
    ]

    static let services: [Service] = [
        Service(
            icon: "calculator",
            title: "ხარჯთაღრიცხვა და კონსულტაცია",
            text: "გთავაზობთ პროფესიონალურ კონსულტაციას და დეტალურ ხარჯთაღრიცხვას — დაგეხმარებით ბიუჯეტის სწორ დაგეგმვაში და ყველაზე ეფექტური გადაწყვეტილების მიღებაში."
        ),
        Service(
            icon: "palete",
            title: "დიზაინი და დაგეგმარება",
            text: "დაგეხმარებით ინტერიერის ფუნქციურად და გემოვნებით მოწყობაში — ვქმნით ბალანსს კომფორტსა და თანამედროვე სტილს შორის."
        ),
        Service(
            icon: "helmet",
            title: "შიდა მოპირკეთება და სარემონტო სამუშაოები",
            text: "გთავაზობთ შიდა სარემონტო სამუშაოებს — შპალერი, საღებავი, გიფსოკარდონი, იატაკის მოპირკეთება და სხვა. შედეგი — ესთეტიკური, კომფორტული და დახვეწილი ინტერიერი."
        ),
        Service(
            icon: "paint-roll",
            title: "კოსმეტიკური რემონტი და განახლება",
            text: "თუ გსურთ უბრალოდ განაახლოთ უკვე გაკეთებული სივრცე — შევასრულებთ კოსმეტიკურ რემონტს სწრაფად, სუფთად და ხარისხიანად."
        ),
        Service(
            icon: "electric",
            title: "ელექტრო და სანტექნიკური სამუშაოები",
            text: "პროფესიონალი ოსტატების გუნდი უზრუნველყოფს ელექტრო და სანტექნიკური სისტემების მონტაჟს, შეცვლას და გამართულ მუშაობას უსაფრთხოების ყველა ნორმის დაცვით."
        ),
        Service(
            icon: "sofa",
            title: "ავეჯის დამზადება და მონტაჟი",
            text: "ვქმნით ინდივიდუალურ ავეჯს თქვენი სივრცისა და სტილის მიხედვით — სამზარეულოები, კარადები, თაროები და სხვა. ვუზრუნველყოფთ ზუსტ ზომებს, ხარისხიან მასალას და სუფთა მონტაჟს."
        ),
    ]

    static let pricePackages: [PricePackage] = [
        PricePackage(title: "მწვანე კარკასი", pricePerSquareMeter: 550, blogID: "693e40002ed62d127ab05108"),
        PricePackage(title: "თეთრი კარკასი", pricePerSquareMeter: 600, blogID: "693e40342ed62d127ab0510e"),
        PricePackage(title: "შავი კარკასი", pricePerSquareMeter: 700, blogID: "693d8d61291bc84d00b6f427"),
    ]

    static let priceRows: [PriceRow] = [
        .category("ელექტრო სამონტაჟო მომსახურება"),
        .option("დაკაბელება", included: [false, true, true]),
        .option("დენცქვიტები (ყუთები)", included: [true, true, true]),
        .option("რევერსული ჩამრთველები (ყუთები)", included: [false, true, true]),
        .option("ორ ან მეტ კლავიშიანი შუქის ასანთები (ყუთები)", included: [true, true, true]),
        .option("ინტერნეტ კაბელის გაყვანა ოთახებში", included: [false, true, true]),

        .category("სანტექნიკა / წყალმომარაგება"),
        .option("მილსადენების გაყვანა", included: [false, true, true]),
        .option("ტრაპის და საკანალიზაციო სისტემის გაკეთება", included: [false, true, true]),
        .option("გათბობის ქვაბის მონტაჟი", included: [true, true, true]),
        .option("რადიატორების მონტაჟი", included: [true, true, true]),
        .option("იატაკის გათბობის მონტაჟი", included: [false, true, true]),
        .option("საშრობის მონტაჟი", included: [true, true, true]),
        .option("ხელსაბანის მონტაჟი", included: [true, true, true]),
        .option("დუშის შემრევი ონკანის მონტაჟი", included: [true, true, true]),

        .category("იატაკი"),
        .option("იატაკის მოხვეწა", included: [false, false, true]),
        .option("ლამინირებული იატაკის დაგება", included: [true, true, true]),
        .option("კაფელი / მეტლახი / გრანიტის მონტაჟი", included: [true, true, true]),
        .option("პლასტმასის / მდფ-ის პლინტუსის მონტაჟი", included: [true, true, true]),

        .category("კედლები"),
        .option("შიდა კედლების (ტიხრების) აშენება", included: [false, false, true]),
        .option("ლესვა (გიპერი)", included: [false, false, true]),
        .option("ცემენტით ლესვა აბაზანაში", included: [true, true, true]),
        .option("ფითხის სამუშაოები", included: [true, true, true]),
        .option("ჭერსა და კედელს შორისი ქაფის დაყენება", included: [true, true, true]),
        .option("სამღებრო სამუშაოები", included: [true, true, true]),
        .option("შპალერის სამუშაოები", included: [true, true, true]),

        .category("ჭერი"),
        .option("თაბაშირ მუყაოს მონტაჟი", included: [true, true, true]),
        .option("ფრანგული გასაჭიმი ჭერის მონტაჟი", included: [true, true, true]),

        .category("კარები"),
        .option("MDF კარის მონტაჟი", included: [true, true, true]),
        .option("კარის ჩამკეტის მონტაჟი", included: [true, true, true]),
    ]

    static let partners: [Partner] = [
        Partner(name: "ვალერი", profession: "პროექტის ხელმძღვანელი", imageURL: upload("1778940432071-768714604.jpg")),
        Partner(name: "გიგა", profession: "პროექტის ხელმძღვანელი", imageURL: upload("1778940904146-256162493.jpg")),
        Partner(name: "კოტე", profession: "პროექტის ხელმძღვანელი", imageURL: upload("1778940672827-574297705.jpg")),
        Partner(name: "სალომე", profession: "ინტერიერის დიზაინერი", imageURL: upload("1778939888551-94502995.jpg")),
        Partner(name: "გიორგი", profession: "სანტექნიკი, ბოილერის სპეციალისტი, ჩასაშენებელი უნიტაზის სპეციალისტი", imageURL: nil),
        Partner(name: "ზურა", profession: "ფრანგული ჭერის სპეციალისტი", imageURL: upload("1776793971446-594387919.jpg")),
        Partner(name: "თორნიკე", profession: "ელექტრიკოსი", imageURL: nil),
    ]

    private static func upload(_ fileName: String) -> URL {
        SiteInfo.page("/uploads/small/\(fileName)")
    }
}
