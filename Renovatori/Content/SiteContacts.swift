import SwiftUI

/// The site's contacts from `GET /site-contacts` (managed in the web admin at `/admin/contacts`).
struct SiteContacts: Decodable, Equatable {
    struct Phone: Decodable, Hashable, Identifiable {
        let id: String
        let number: String
        /// `+995 579 37 33 73`.
        let display: String
        /// International number to dial, e.g. `+995579373373`.
        let dial: String
        let label: String
        let isMainPhone: Bool
    }

    struct Email: Decodable, Hashable, Identifiable {
        let id: String
        let email: String
        let label: String
        let isMainEmail: Bool
    }

    struct SocialLink: Decodable, Hashable, Identifiable {
        let id: String
        let title: String
        let url: String

        var link: URL? { URL(string: url) }

        /// The site's own monochrome icon for the networks it ships with; the API's icons are SVG files.
        var assetName: String? {
            let text = "\(title) \(url)".lowercased()
            if text.contains("facebook") { return "facebook-black" }
            if text.contains("instagram") { return "instagram-black" }
            if text.contains("tiktok") { return "tiktok-black" }
            return nil
        }
    }

    struct WorkingHours: Decodable, Hashable, Identifiable {
        let id: String
        /// 1 = Monday … 7 = Sunday.
        let weekdays: [Int]
        /// `ორშაბათი - პარასკევი`.
        let daysLabel: String
        /// `ორშ-პარ`.
        let daysShortLabel: String
        /// `HH:MM`, Georgian time.
        let opensAt: String
        let closesAt: String
    }

    let phones: [Phone]
    let emails: [Email]
    let socialLinks: [SocialLink]
    let workingHours: [WorkingHours]

    var mainPhone: Phone? { phones.first(where: \.isMainPhone) ?? phones.first }
    var mainEmail: Email? { emails.first(where: \.isMainEmail) ?? emails.first }

    /// Whether it is working time in Georgia, whatever time zone the phone is in. Like the web,
    /// phone links call only then and open the call request form otherwise.
    func isOpen(at date: Date = .now) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tbilisi") ?? .current
        let now = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = now.weekday, let hour = now.hour, let minute = now.minute else { return true }
        // Calendar counts Sunday as 1; the site counts Monday as 1 and Sunday as 7.
        let siteWeekday = (weekday + 5) % 7 + 1
        let time = String(format: "%02d:%02d", hour, minute)
        // "HH:MM" strings compare in time order; closing time itself is already outside the hours.
        return workingHours.contains { hours in
            hours.weekdays.contains(siteWeekday) && time >= hours.opensAt && time < hours.closesAt
        }
    }

    /// The contacts the site showed before they moved to its database. Used until the API answers,
    /// and when the server is offline or does not have the contacts API yet.
    static let fallback = SiteContacts(
        phones: [Phone(id: "phone", number: "579373373", display: "+995 579 37 33 73", dial: "+995579373373", label: "", isMainPhone: true)],
        emails: [Email(id: "email", email: "info@renovatori.ge", label: "", isMainEmail: true)],
        socialLinks: [
            SocialLink(id: "facebook", title: "Facebook", url: "https://www.facebook.com/profile.php?id=61582501894965"),
            SocialLink(id: "instagram", title: "Instagram", url: "https://www.instagram.com/renovatori/"),
            SocialLink(id: "tiktok", title: "TikTok", url: "https://www.tiktok.com/@renovatori"),
        ],
        workingHours: [WorkingHours(id: "hours", weekdays: [1, 2, 3, 4, 5], daysLabel: "ორშაბათი - პარასკევი", daysShortLabel: "ორშ-პარ", opensAt: "10:00", closesAt: "18:00")]
    )
}

struct SiteContactsResponse: Decodable {
    let contacts: SiteContacts
}

/// Loads the site's contacts; screens show `SiteContacts.fallback` until then.
@MainActor
final class SiteContactsStore: ObservableObject {
    @Published private(set) var contacts = SiteContacts.fallback

    func load() async {
        guard let response = try? await APIClient.shared.send(
            Endpoint(method: .get, path: "site-contacts"),
            as: SiteContactsResponse.self
        ) else { return }
        contacts = response.contacts
    }
}

private struct SiteContactsKey: EnvironmentKey {
    static let defaultValue = SiteContacts.fallback
}

extension EnvironmentValues {
    var siteContacts: SiteContacts {
        get { self[SiteContactsKey.self] }
        set { self[SiteContactsKey.self] = newValue }
    }
}

/// A social network's icon: the site's own asset for the networks it ships with, a link symbol otherwise.
struct SocialIcon: View {
    let link: SiteContacts.SocialLink
    var size: CGFloat = 16

    var body: some View {
        if let asset = link.assetName {
            AssetIcon(name: asset, size: size)
        } else {
            Image(systemName: "link")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
