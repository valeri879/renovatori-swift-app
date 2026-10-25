import Foundation

/// A titled paragraph used by the value, feature and process lists.
struct InfoItem: Identifiable {
    let title: String
    let text: String
    /// Asset icon name; only the "who we are" features have one.
    var icon: String?
    var id: String { title }
}

/// Static content of `views/pages/about-page/about-page.pug`.
enum AboutPageData {
    static let heroEyebrow = "რენოვატორი"
    static let heroTitle = "რემონტი, რომელსაც თავიდან ბოლომდე აკონტროლებთ"
    static let heroText = "ვეხმარებით მომხმარებლებს ბინის, სახლისა და კომერციული სივრცის რემონტში ისე, რომ პროცესი იყოს დაგეგმილი, ხარჯები გამჭვირვალე და შედეგი შეთანხმებულ ხარისხთან ახლოს."
    static let ideaLabel = "სერვისის იდეა"
    static let ideaText = "რემონტი არ უნდა იყოს გაურკვეველი, დაუსრულებელი და სტრესული პროცესი."

    static let values: [InfoItem] = [
        InfoItem(title: "დაგეგმვა", text: "სამუშაოს დაწყებამდე ვადგენთ ეტაპებს, ვადებს და ბიუჯეტს."),
        InfoItem(title: "გამჭვირვალობა", text: "მომხმარებელი ხედავს რა კეთდება, რატომ კეთდება და რა ჯდება."),
        InfoItem(title: "კონტროლი", text: "პროცესი, ხარჯები, გადახდები და ისტორია ერთ სივრცეში იყრის თავს."),
    ]

    static let whoLabel = "ვინ ვართ ჩვენ"
    static let whoTitle = "სარემონტო გუნდი, რომელიც პროცესს თავიდან ბოლომდე მართავს"
    static let whoText = "რენოვატორი შეიქმნა ერთი მარტივი მიზეზით: რემონტი არ უნდა იყოს გაურკვეველი, დაუსრულებელი და სტრესული პროცესი. ჩვენ ვაერთიანებთ დაგეგმვას, ხარჯთაღრიცხვას, სამუშაოების კოორდინაციას და ხარისხის კონტროლს ერთ სისტემურ სერვისში."

    static let differences: [InfoItem] = [
        InfoItem(title: "შეთანხმებული ვადები", text: "დეტალური გრაფიკი გვეხმარება, სამუშაოები პროგნოზირებადად და ორგანიზებულად წარიმართოს.", icon: "clock"),
        InfoItem(title: "გამჭვირვალე ხარჯები", text: "წინასწარ ჩანს სამუშაოების მოცულობა, მასალები და თითოეული ეტაპის ღირებულება.", icon: "calculator"),
        InfoItem(title: "პასუხისმგებლიანი გუნდი", text: "თითოეულ ობიექტს ვუდგებით ისე, როგორც სივრცეს, სადაც მომავალში ადამიანმა კომფორტულად უნდა იცხოვროს.", icon: "helmet"),
        InfoItem(title: "მუდმივი კომუნიკაცია", text: "მომხმარებელი პროცესის მიღმა არ რჩება: გადაწყვეტილებები, ცვლილებები და პროგრესი შეთანხმებულად მიდის.", icon: "phone"),
    ]

    static let clientLabel = "კლიენტის სივრცე"
    static let clientTitle = "პროექტის ისტორია და ხარჯები ერთ ადგილზე"
    static let clientText = "რემონტის პროცესში კლიენტს არ უნდა უწევდეს ინფორმაციის გამოცნობა. ამიტომ პროექტის დეტალურ გვერდზე ვაჩვენებთ იმ მონაცემებს, რაც რეალურ კონტროლს ქმნის: ფინანსურ მდგომარეობას, გადახდებს, ვადებს და შესრულებული სამუშაოების ისტორიას."
    static let dashboardBadge = "ხილულია მხოლოდ კლიენტისთვის"
    static let dashboardTitle = "პროექტის გამჭვირვალე მართვა"
    static let dashboardProgressLabel = "პროექტის დასრულების პროგრესი"
    static let dashboardProgressNote = "შეთანხმებული ვადებით"
    /// Sample value shown in the illustrative progress bar.
    static let dashboardProgress = 0.68

    /// Here `title` is the small caption and `text` the bold value, as on the site.
    static let dashboardCards: [InfoItem] = [
        InfoItem(title: "ფინანსები და პროგრესი", text: "ჯამური ღირებულება, ჩასარიცხი თანხა და გადახდები"),
        InfoItem(title: "ჩარიცხვების ისტორია", text: "თითოეული გადახდა თარიღით"),
        InfoItem(title: "პროექტის ისტორია", text: "კომენტარები და ფოტო განახლებები"),
        InfoItem(title: "პირადი ინფორმაცია", text: "დაშვებული მომხმარებლებისთვის"),
    ]

    static let processLabel = "პროცესი"
    static let processTitle = "როგორ ვმუშაობთ"
    static let processText = "ჩვენი პროცესი მარტივია, მაგრამ მკაფიო. ჯერ ვარკვევთ საჭიროებებს, შემდეგ ვგეგმავთ სამუშაოებს და მხოლოდ ამის შემდეგ იწყება შესრულება."

    static let processSteps: [InfoItem] = [
        InfoItem(title: "კონსულტაცია და დათვალიერება", text: "ვისმენთ მოთხოვნებს, ვაფასებთ სივრცეს და ვადგენთ საწყის სამუშაო მოცულობას."),
        InfoItem(title: "ხარჯთაღრიცხვა და გრაფიკი", text: "ვამზადებთ ბიუჯეტს, ეტაპებს და ვადებს, რომ გადაწყვეტილება ინფორმირებულად მიიღოთ."),
        InfoItem(title: "სამუშაოების მართვა", text: "ვაკოორდინირებთ გუნდს, მასალებს და შესრულების ხარისხს შეთანხმებული გეგმის მიხედვით."),
        InfoItem(title: "ხარისხის შემოწმება და ჩაბარება", text: "დასრულებულ პროექტს ვამოწმებთ დეტალებში და მომხმარებელთან ერთად ვაბარებთ შედეგს."),
    ]

    static let ctaTitle = "გეგმავთ რემონტს?"
    static let ctaText = "მოგვწერეთ ან დაგვიტოვეთ მოთხოვნა. დაგეხმარებით რეალური ბიუჯეტის, ვადებისა და სამუშაო მოცულობის წინასწარ განსაზღვრაში."
}
