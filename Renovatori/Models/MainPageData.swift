import Foundation

/// Contact details and links shared by the header, cover and footer.
enum SiteInfo {
    static let baseURL = URL(string: "https://renovatori.ge")!
    static let phoneDisplay = "+995 579 37 33 73"
    static let phoneURL = URL(string: "tel:+995579373373")!
    static let email = "info@renovatori.ge"
    static let emailURL = URL(string: "mailto:info@renovatori.ge")!
    static let facebookURL = URL(string: "https://www.facebook.com/profile.php?id=61582501894965")!
    static let instagramURL = URL(string: "https://www.instagram.com/renovatori/")!
    static let tiktokURL = URL(string: "https://www.tiktok.com/@renovatori")!

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
    case emailVerification
    case passwordChange
    /// Admin: expense projects (`/admin/expenses-list`). Staff only.
    case expenses
    /// Admin: one expense project. Staff only.
    case expenseDetail(String)

    /// Screens that need a signed-in account; they are closed when the session ends.
    var requiresAccount: Bool {
        switch self {
        case .profile, .emailVerification, .passwordChange, .expenses, .expenseDetail: true
        default: false
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

struct Project: Identifiable {
    let image: String
    let title: String
    let text: String
    var id: String { image }
}

struct PricePackage: Identifiable {
    let title: String
    let pricePerSquareMeter: Int
    let url: URL
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

struct BlogPost: Identifiable {
    let title: String
    let summary: String
    let date: String
    let imageURL: URL?
    var id: String { title }
}

struct FAQItem: Identifiable {
    let id: String
    let question: String
    let answer: AttributedString
}

extension FAQItem {
    /// Plain-text entry for the static main page snapshot.
    init(question: String, answer: String) {
        self.init(id: question, question: question, answer: AttributedString(answer))
    }
}

/// Static demo content mirroring `views/pages/main-page/main-page.pug` and its components.
/// Team, blog and FAQ entries are a snapshot of what renovatori.ge loads from the database.
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

    static let footerLinks: [NavItem] = [
        NavItem(title: "მთავარი", path: "/"),
        NavItem(title: "კონსულტაცია", path: "/consultation"),
        NavItem(title: "ჩვენ შესახებ", path: "/about"),
        NavItem(title: "ფასები", path: "/prices"),
        NavItem(title: "ბლოგი", path: "/blog-list"),
        NavItem(title: "ხ.დ.კ.", path: "/faq"),
        NavItem(title: "კონტაქტი", path: "/contact"),
        NavItem(title: "ქუქის პოლიტიკა", path: "/cookies-policy"),
        NavItem(title: "კონფიდენციალურობა", path: "/privacy-policy"),
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

    static let projects: [Project] = [
        Project(
            image: "order-1",
            title: "პროფესიული მონტაჟი და აწყობა",
            text: "პროფესიონალური მონტაჟი — ავეჯი, ტექნიკა და ელემენტების აწყობა ზუსტი ზომებით და ხარისხიანი შესრულებით."
        ),
        Project(
            image: "order-2",
            title: "პროექტის მენეჯმენტი",
            text: "ვაკონტროლებთ ვადებს, ხშირად ვაწვდით პროგრესის ანგარიშს და ვმართავთ პროექტს სრულად, რათა ყველაფერი დროულად და შესაბამისად დაგეგმოს."
        ),
        Project(
            image: "order-3",
            title: "გარანტია და შემდგომი მომსახურება",
            text: "ვაძლევთ ხარისხის გარანტიას და ვატარებთ საჭირო შემდგომ მომსახურებას პრობლემების სწრაფად მოგვარებისთვის."
        ),
    ]

    static let pricePackages: [PricePackage] = [
        PricePackage(title: "მწვანე კარკასი", pricePerSquareMeter: 550, url: URL(string: "https://renovatori.ge/blog/693e40002ed62d127ab05108")!),
        PricePackage(title: "თეთრი კარკასი", pricePerSquareMeter: 600, url: URL(string: "https://renovatori.ge/blog/693e40342ed62d127ab0510e")!),
        PricePackage(title: "შავი კარკასი", pricePerSquareMeter: 700, url: URL(string: "https://renovatori.ge/blog/693d8d61291bc84d00b6f427")!),
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

    static let blogs: [BlogPost] = [
        BlogPost(
            title: "როგორ ითვლება რემონტის სავარაუდო ღირებულება?",
            summary: "რემონტის კალკულატორი — გაიგეთ როგორ ითვლება რემონტის სავარაუდო ფასი ფართობის, ელექტროობის და სხვა დეტალების მიხედვით.",
            date: "12/06/2026",
            imageURL: upload("1779953226961-17957373.jpg")
        ),
        BlogPost(
            title: "რატომ არის ინტერიერის დიზაინი მნიშვნელოვანი რემონტის პროცესში?",
            summary: "ინტერიერის დიზაინის მნიშვნელობა რემონტში — ტექნიკური ნახაზები, ვადები, ხარჯების დაზოგვა და საბოლოო შედეგის წინასწარ დაგეგმვა.",
            date: "12/06/2026",
            imageURL: upload("1779821870198-193890095.jpg")
        ),
        BlogPost(
            title: "რა ჯდება აბაზანის რემონტი?",
            summary: "აბაზანის რემონტის ფასი დამოკიდებულია ფილებზე, სანტექნიკაზე, დემონტაჟსა და სხვა მნიშვნელოვან დეტალებზე.",
            date: "12/06/2026",
            imageURL: upload("1779223268316-274187398.jpg")
        ),
    ]

    static let faqs: [FAQItem] = [
        FAQItem(
            question: "რა არის რემონტის კალკულატორი?",
            answer: "რემონტის კალკულატორი არის ონლაინ ინსტრუმენტი, რომელიც დაგეხმარებათ წინასწარ დააანგარიშოთ ბინის, სახლის ან კომერციული ფართის რემონტის სავარაუდო ღირებულება. კალკულატორი ითვალისწინებს სხვადასხვა ტიპის სამუშაოებს — როგორიცაა ელექტროობა, სანტექნიკა, ლესვა, მოპირკეთება, ჭერის მოწყობა, იატაკი, აბაზანა და სხვა სარემონტო პროცესები."
        ),
        FAQItem(
            question: "რას მოიცავს რემონტის კონსულტაცია?",
            answer: "რემონტის კონსულტაცია არის პროფესიონალური მომსახურება, რომელიც დაგეხმარებათ რემონტის სწორად დაგეგმვაში, ბიუჯეტის განსაზღვრასა და ტექნიკური გადაწყვეტილებების მიღებაში. კონსულტაციის ფარგლებში ხდება ობიექტის შეფასება, საჭირო სამუშაოების განსაზღვრა და დეტალური რეკომენდაციების გაცემა, რათა თავიდან აიცილოთ გაუთვალისწინებელი ხარჯები და არასწორი დაგეგმვა."
        ),
        FAQItem(
            question: "როგორი მასალებით ვმუშაობთ?",
            answer: "ჩვენ ვირჩევთ მხოლოდ მაღალხარისხიან მასალებს, რომლებიც კარგად გამოცდილია ბაზარზე და უზრუნველყოფენ პროექტის გრძელვადიან, ხარისხიან შესრულებას.\nჩვენი მიზანია, მომხმარებელი მიიღოს რემონტი, რომელიც არა მხოლოდ ლამაზია, არამედ გამძლე."
        ),
        FAQItem(
            question: "ჩვენი მომსახურების არეალი",
            answer: "ჩვენი კომპანია მომსახურებას უზრუნველყოფს თბილისის ტერიტორიაზე და მის შემოგარენში.\nსაჭიროების შემთხვევაში შესაძლებელია შეთანხმებით სხვა რაიონებში ვიზიტი."
        ),
        FAQItem(
            question: "რა დრო სჭირდება პროექტის ჩაბარებას?",
            answer: "პროექტის დასრულების დრო დამოკიდებულია მისი სირთულეზე და მოცულობაზე.\nმარტივი სამუშაოების დასრულება შეიძლება მოკლე დროში, რთული პროექტებისთვის კი დროის აღება საჭირო ხდება დეტალური დაგეგმვით, რათა შედეგი იყოს მაღალი ხარისხის."
        ),
        FAQItem(
            question: "გადახდის მეთოდები",
            answer: "ჩვენი მომსახურების გადახდა მიმდინარეობს სამ ნაწილად: წინასწარი ვადით (პროექტის დაწყებამდე), პროცესში და ბოლო ნაწილი – სამუშაოების სრული დასრულების შემდეგ.\nეს მიდგომა უზრუნველყოფს კომფორტს მომხმარებლისთვის და მუშაობის გამჭვირვალობას."
        ),
        FAQItem(
            question: "რა ღირს ჩვენი მომსახურება?",
            answer: "ჩვენი მომსახურების ღირებულება მთლიანად დამოკიდებულია კონკრეტულ პროექტზე და მის სირთულეზე. თითოეული შეკვეთა განსხვავებულია – მასში შედის სამუშაოების მოცულობა, საჭირო მასალები, პროექტის სპეციფიკა და სხვა ფაქტორები, ამიტომ ფასის საბოლოო გამოთვლა ხდება ინდივიდუალურად.\nსაორიენტაციო ფასების გასაგებად შეგიძლიათ ეწვიოთ ჩვენი რემონტის ფასების გვერდს."
        ),
    ]

    private static func upload(_ fileName: String) -> URL {
        SiteInfo.page("/uploads/small/\(fileName)")
    }
}
