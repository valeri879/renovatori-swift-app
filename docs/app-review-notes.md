# App Review — Guideline 2.1 პასუხი

ეს ტექსტი ჩასვი App Store Connect-ში: ვერსია 1.0 → **App Review Information → Notes**. Notes ველი მაქსიმუმ 4000 სიმბოლოს იღებს.
ვიდეო: https://youtu.be/ZDljoRitYSU (YouTube-ზე Unlisted უნდა იყოს, არა Private).

---

```
1. SCREEN RECORDING
Video (three recordings joined) from a physical iPhone running iOS 27, TestFlight build 1.0 (1):
https://youtu.be/ZDljoRitYSU
- Part 1: app launch, registration, email verification, calculator, consultation request.
- Part 2: profile, password change, sign-out, sign-in, account deletion.
- Part 3: staff account features (expenses, project editing).

2. PURPOSE AND AUDIENCE
Renovatori is the official app of Renovatori.ge, an apartment and house renovation company in Georgia. It is for homeowners in Georgia who plan a renovation, and for the company's existing clients.
Problem it solves: renovation costs are hard to estimate and clients rarely see how their project is going. The app lets people:
- browse renovation services, price lists, completed projects, FAQ and a blog;
- estimate the cost of a renovation with a calculator (rooms, area, works);
- request a free consultation or a call back;
- as a client, sign in and follow their own project: progress history with photos, dates and status.
The app is free. There are no purchases, subscriptions, ads or paid content.

3. HOW TO USE THE APP
The UI is in Georgian. Browsing does not need an account.
- Main features: open the menu (☰, top right) for Consultation, Calculator, About, Prices, Blog, Projects, FAQ and Contact. The bar at the bottom opens Calculator and Consultation. The home page links to the same sections.
- Calculator: menu ☰ → კალკულატორი. Add rooms and works; the total updates live.
- Call request: menu ☰ → კონტაქტი → ზარის მოთხოვნა. Enter a phone number and solve the math captcha.
- Sign in: menu ☰ → შესვლა. Use the demo account from Sign-In Information. It is a regular client account.
- Client area: after sign-in, menu ☰ → ჩემი პროექტები shows the client's projects and their history.
- Registration: menu ☰ → შესვლა → რეგისტრაცია (name, email, phone, password). A verification code is emailed.
- Account deletion: menu ☰ → ჩემი პროფილი → ანგარიშის წაშლა. Enter the current password and confirm. The account and its personal data are deleted permanently on the server.
User-generated content: users cannot post anything visible to other users. Requests (call back, consultation) go only to the company. Project history and photos are added only by company staff, so no reporting or blocking mechanism is needed.
Account types: client (self sign-up) and staff (company employees; roles are given only by the company and add internal tools: expenses and project history, shown in Part 3).

4. EXTERNAL SERVICES
- renovatori.ge: the company's own backend (Node.js, MongoDB). It handles content, accounts and authentication with email and password, and requests. No third-party sign-in.
- Apple Push Notification service: notifications about the client's project.
- Resend: transactional email (verification codes, password reset, deletion confirmation), sent by the server.
- Telegram Bot API: the server notifies company staff about new requests. Users never interact with it.
- Links to the company's Facebook, Instagram and TikTok pages open outside the app.
There are no payment processors, analytics, advertising, tracking or AI services.

5. REGIONAL DIFFERENCES
The app is distributed only in Georgia, where the company works. Content is in Georgian and prices are in GEL. Features and content are the same for every user and region.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Renovation is not a highly regulated industry for this app: it gives information and takes requests, with no contracts or payments. All texts, photos and project content belong to Renovatori.ge. The app is published by Valeriani Kharitonashvili, the owner of Renovatori.ge; Val Do (credited in the footer) is also the owner's own brand.
```

---

## Screen recording — როგორ ჩავწეროთ

1. **TestFlight.** App Store Connect → Renovatori → **TestFlight** → **Internal Testing** → **+** ჯგუფი → დაამატე შენი Apple ID და ბილდი **1.0 (1)**.
2. iPhone-ზე დააყენე **TestFlight** App Store-დან, იმავე Apple ID-ით. მოსულ მოწვევაზე დააჭირე **Install**.
3. ჩართე ჩაწერა: Settings → Control Center → **Screen Recording**.
4. ჩაწერის დაწყებისას აპი დახურული უნდა იყოს. ჩართე ჩაწერა და აპი ეკრანზე ხატულიდან გახსენი.
5. თანმიმდევრობა:
   - მთავარი გვერდი და ☰ მენიუ;
   - ფასები, კალკულატორი, პროექტები, ბლოგი;
   - **რეგისტრაცია** ახალი ელ-ფოსტით, მერე ელ-ფოსტის დადასტურება;
   - **შესვლა** და პროფილი;
   - ზარის მოთხოვნა;
   - **ანგარიშის წაშლა**: პაროლი, დადასტურება, ეკრანი „ანგარიში წაიშალა";
   - სურვილისამებრ: შესვლა demo ანგარიშით და „ჩემი პროექტები".
6. **ვიდეოს გაგზავნა.** ორი გზა გაქვს:
   - ატვირთე YouTube-ზე (**Unlisted**) ან iCloud/Google Drive-ზე საჯარო ბმულით და ბმული ჩასვი Notes-ის პირველ პუნქტში;
   - ან ფაილი დაურთე App Review გვერდზე, პასუხის შეტყობინებას.
