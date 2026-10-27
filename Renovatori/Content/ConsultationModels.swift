import Foundation

/// A consultation package from `views/pages/consultation-page`. `name` must match the backend's
/// `consultationTypes` exactly, because it is sent as `consultationType`.
struct ConsultationPackage: Identifiable, Hashable {
    let name: String
    let price: Double
    let features: [String]
    /// The site draws this package with a primary border and a filled button.
    var isHighlighted = false
    var id: String { name }

    /// `150 ₾`, like the site's `formatMoney(150)`.
    var priceFormatted: String {
        "\(Int(price)) ₾"
    }
}

/// Body of `POST /consultations`.
struct ConsultationRequest: Encodable {
    let consultationType: String
    let address: String
    /// `YYYY-MM-DD`, like the web form's date input.
    let visitDate: String
    let comment: String
}

/// A consultation request as the API returns it.
struct Consultation: Decodable, Identifiable, Hashable {
    let id: String
    let consultationType: String
    let address: String
    let comment: String
    let visitDate: Date?
    let status: String
    let createdAt: Date?
}

struct ConsultationResponse: Decodable {
    let consultation: Consultation
}

/// Static content of `consultation-page.pug`.
enum ConsultationPageData {
    static let eyebrow = "რემონტის კონსულტაცია"
    static let title = "ზუსტი ხარჯთაღრიცხვა და პროფესიონალური რჩევები"
    static let intro = "ჩვენი სპეციალისტი ეწვევა თქვენს ობიექტს, მოისმენს თქვენს საჭიროებებს და დაგეხმარებათ სწორი გადაწყვეტილების მიღებაში — სანამ დაიწყებთ რემონტს."

    static let benefitsTitle = "რატომ ღირს წინასწარი კონსულტაცია?"
    /// Emoji are kept from the site; `title` includes them.
    static let benefits: [InfoItem] = [
        InfoItem(title: "💰 ბიუჯეტის განსაზღვრა", text: "თავიდან აიცილეთ ზედმეტი ხარჯები."),
        InfoItem(title: "🧠 პროფესიონალის რჩევები", text: "მიიღეთ გადაწყვეტილება გამოცდილების საფუძველზე."),
        InfoItem(title: "🏠 შეფასება ადგილზე", text: "რეალურ პირობებში ვაანალიზებთ ყველაფერს."),
        InfoItem(title: "📋 დეტალური ხარჯთაღრიცხვა", text: "მიიღეთ გამჭვირვალე, გასაგები და სანდო დოკუმენტი სამუშაოების ჩამონათვალითა და ფასებით."),
        InfoItem(title: "⏱ დროის დაზოგვა", text: "თავიდან იცილებთ შეცდომებს, რომლებიც გრაფიკს დაგიგრძელებთ."),
        InfoItem(title: "🤝 ნდობა და გამჭვირვალობა", text: "თქვენ ზუსტად იცით, რაში იხარჯება თანხა და რა შედეგს უნდა ელოდოთ."),
    ]

    static let stepsTitle = "როგორ მუშაობს სერვისი?"
    static let steps: [InfoItem] = [
        InfoItem(title: "დაჯავშნა", text: "აირჩით სასურველი დრო ონლაინ ან სატელეფონო კონტაქტით."),
        InfoItem(title: "ვიზიტი ადგილზე", text: "სპეციალისტი ახორციელებს საჭირო წარმოჩენას და ზომებს."),
        InfoItem(title: "მოსმენა და ანალიზი", text: "თქვენი მოთხოვნების და პრიორიტეტების გამოკვლევა."),
        InfoItem(title: "დეტალური ხარჯთაღრიცხვა", text: "PDF/Excel- ფორმატში; სამუშაოების ეტაპობრივი გეგმა."),
    ]

    static let pricingTitle = "ფასი და პირობები"
    static let packages: [ConsultationPackage] = [
        ConsultationPackage(
            name: "სტარტ პაკეტი",
            price: 150,
            features: ["📋 ობიექტზე ვიზიტი", "📐 სარემონტო სივრცის აზომვა", "🧰 ძირითადი ხარჯთაღრიცხვა", "💬 მოკლე რეკომენდაციები"]
        ),
        ConsultationPackage(
            name: "სტანდარტ პაკეტი",
            price: 250,
            features: ["📋 ობიექტის ვიზიტი და კონსულტაცია", "📐 სარემონტო სივრცის აზომვა", "📊 დეტალური ხარჯთაღრიცხვა (PDF)", "📸 ფოტო დოკუმენტაცია", "🕒 შედეგები 48 საათში"],
            isHighlighted: true
        ),
        ConsultationPackage(
            name: "პრემიუმ პაკეტი",
            price: 400,
            features: ["🏠 სრული ობიექტის ანალიზი", "📐 სარემონტო სივრცის აზომვა", "📊 ზუსტი ხარჯთაღრიცხვა და მასალების სია", "📅 სამუშაო გეგმა + შემდგომი კონსულტაცია"]
        ),
    ]

    static let refundNote = "თუ სარემონტო მომსახურებას რენოვატორის გუნდს მიანდობთ, კონსულტაციის ფასი ავტომატურად ჩაითვლება მომსახურებაში და დამატებით არაფერს გადაიხდით."
}
