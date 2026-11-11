# App Store-ზე ატვირთვა

## რა არის მზად (აპის მხარე)

- **ხელმოწერა.** ფასიანი Individual Team `4MZ5C2SL39`, Automatic signing, bundle ID `com.renovatori.Renovatori`.
- **ბილდი.** მხოლოდ iPhone, iOS 17+. სახელი: **Renovatori**, ვერსია **1.0 (1)**.
- **Entitlements.** Push და `applinks:renovatori.ge`. App Store-ის ხელმოწერისას `aps-environment` ავტომატურად `production` ხდება.
- **`PrivacyInfo.xcprivacy`.** Tracking არ არის. აღწერილია UserDefaults (`CA92.1`) და შეგროვებული მონაცემები.
- **დაშიფვრა.** `ITSAppUsesNonExemptEncryption = NO`, ამიტომ App Store Connect ამ კითხვას აღარ დასვამს.
- **ანგარიშის წაშლა** ხდება პროფილიდან.
- **კონფიდენციალურობის პოლიტიკის ბმული** არის მთავარი გვერდის footer-ში.
- **Release ბილდი** ყოველთვის `https://renovatori.ge`-ს იყენებს. Backend-ის სვიჩი მხოლოდ Debug-შია.

## 1. Backend (renovatori repo) — ატვირთვამდე

1. Commit და deploy გაუკეთე ცვლილებებს. მათ გარეშე ზარის მოთხოვნა და კონტაქტები აპში არ იმუშავებს.
   - `/api/v1/site-contacts`
   - `/api/v1/call-requests`
   - `/call-request` AASA-ში
2. Push შეტყობინებებისთვის:
   - developer.apple.com → Certificates, IDs & Profiles → **Keys**-ში შექმენი APNs გასაღები (`.p8`).
   - სერვერზე დააყენე `APNS_KEY_ID`, `APNS_TEAM_ID=4MZ5C2SL39` და `APNS_KEY_PATH` (გზა `.p8` ფაილამდე).
   - გასაღების გარეშე სერვერი Push-ს უბრალოდ გამოტოვებს.
3. შეამოწმე, რომ ბრაუზერში იხსნება ორივე ბმული:
   - `https://renovatori.ge/.well-known/apple-app-site-association` (`/call-request`-ს უნდა შეიცავდეს)
   - `https://renovatori.ge/privacy-policy`

## 2. App Store Connect — აპის ჩანაწერი

appstoreconnect.apple.com → **Apps → + → New App**:

- **Platform:** iOS
- **Name:** Renovatori. თუ სახელი დაკავებულია, მაგალითად „Renovatori — რემონტი".
- **Primary language:** Georgian
- **Bundle ID:** `com.renovatori.Renovatori`
- **SKU:** ნებისმიერი, მაგალითად `renovatori-ios`

## 3. ატვირთვა

1. Xcode → **Window → Organizer → Archives**-ში აირჩიე **Renovatori 1.0 (1)**.
2. დააჭირე **Distribute App → App Store Connect → Upload**.
3. რამდენიმე წუთში ბილდი App Store Connect-ის **TestFlight** ჩანართში გამოჩნდება.

ახალი ბილდის ასაწყობად:
- Xcode → **Product → Archive**;
- ყოველ შემდეგ ატვირთვაზე გაზარდე **Build** (`CURRENT_PROJECT_VERSION`).

## 4. ვერსიის გვერდი (1.0)

- **Screenshots** — iPhone 6.9″ (1320×2868 ან 1290×2796). iPhone 15/16 Pro Max სიმულატორის screenshot-ები გამოდგება. მინიმუმ 3 სურათი:
  - მთავარი გვერდი
  - კალკულატორი
  - პროექტები
  - ფასები
  - ბლოგი
- **Description, Keywords, Promotional text** — ქართულად.
- **Support URL:** `https://renovatori.ge/contact`
- **Marketing URL:** `https://renovatori.ge`
- **Privacy Policy URL:** `https://renovatori.ge/privacy-policy`
- **Category:** Lifestyle (ან House & Home ტიპის Lifestyle). მეორე: Productivity.
- **Age rating:** კითხვარში ყველაფერზე „None" → 4+.
- **Copyright:** `2026 Renovatori.ge`

## 5. App Privacy (კითხვარი)

**Data collection: Yes.** ქვემოთ ჩამოთვლილი ყველა ტიპი: *Linked to user*, *App Functionality*, **Tracking: No**.

| კატეგორია | ტიპი | საიდან |
|---|---|---|
| Contact Info | Name, Email Address, Phone Number | რეგისტრაცია, პროფილი, ზარის მოთხოვნა, კონსულტაცია |
| Identifiers | User ID, Device ID | ანგარიში, Push-ის device token |
| User Content | Photos, Other User Content | პროექტის ისტორიის/ხარჯის ფოტოები, მოთხოვნის აღწერა |

## 6. App Review Information

- **Sign-in required:** Yes.
- **სატესტო ანგარიში.** შექმენი production ბაზაში ჩვეულებრივი, არა ადმინის ანგარიში. მასზე ხილული უნდა იყოს „ჩემი პროექტები" და ანგარიშის წაშლა. მონაცემები ჩაწერე Review-ის ველებში.
- **Notes**, მაგალითად:
  > The app mirrors renovatori.ge. Browsing is public; the account (menu ☰ → შესვლა) shows the
  > client's own renovation projects. Account deletion: Profile → ანგარიშის წაშლა.

## 7. გაგზავნა

1. ვერსიის გვერდზე **Build**-ში აირჩიე ატვირთული ბილდი.
2. დააჭირე **Add for Review → Submit**.

TestFlight-ით ჯერ რეალურ iPhone-ზე შემოწმება გირჩევ: Push, საიტის ბმულები, ზარი და მეილი.
