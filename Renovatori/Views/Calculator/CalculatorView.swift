import SwiftUI
import UIKit

/// "კალკულატორი" (`views/pages/calculator-page`): a six-step form that posts to `POST /calculator`.
struct CalculatorView: View {
    @StateObject private var form = CalculatorForm()
    @State private var isSubmitting = false
    @State private var submitError: APIError?
    @State private var submission: CalculatorSubmission?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                        .id(ScrollAnchor.top)
                    stepContent
                    if let submitError, form.isLastStep {
                        Label(submitError.message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: form.step) { _, _ in
                withAnimation { proxy.scrollTo(ScrollAnchor.top, anchor: .top) }
            }
        }
        .safeAreaInset(edge: .bottom) { stepButtons }
        .navigationTitle("კალკულატორი")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("მზადაა") { Self.dismissKeyboard() }
            }
        }
        .navigationDestination(item: $submission) { submission in
            CalculatorResultView(submission: submission)
        }
    }

    private enum ScrollAnchor: Hashable { case top }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(form.step.title)
                    .font(.title2.bold())
                Spacer()
                Text("\(form.step.rawValue) / \(CalculatorForm.Step.allCases.count)")
                    .font(.footnote.bold().monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemFill), in: Capsule())
            }
            ProgressView(value: form.progress)
                .accessibilityLabel("კალკულატორის ფორმის პროგრესი")
                .accessibilityValue("ნაბიჯი \(form.step.rawValue) \(CalculatorForm.Step.allCases.count)-დან")
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch form.step {
        case .contact: contactStep
        case .building: buildingStep
        case .installations: installationsStep
        case .demolition: demolitionStep
        case .rooms: roomsStep
        case .bathrooms: bathroomsStep
        }
    }

    private var contactStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            CalculatorField(
                title: "📱 თქვენი ტელეფონის ნომერი",
                hint: "ჩაწერე თქვენი აქტიური ტელეფონის ნომერი +995 ფორმატის გარეშე, მაგალითად 579123123",
                placeholder: "მაგ: 579123123",
                text: $form.phoneNumber,
                keyboard: .numberPad,
                error: form.phoneError
            )
            .onChange(of: form.phoneNumber) { _, value in
                let digits = String(value.filter(\.isNumber).prefix(9))
                if digits != value { form.phoneNumber = digits }
            }
            CalculatorField(
                title: "📐 სახლის ფართობი (გარდა აივნისა)",
                hint: "ჩაწერეთ თქვენი ბინის სრული ფართობი, იმ შეთხვევაში თუ გეგმავთ აბაზანის რემონტსაც - თუ არა, ჩაწერეთ აბაზანის ფართობის გამოკლებით.",
                helpBlogID: CalculatorForm.HelpBlog.area,
                placeholder: "მაგ: 55",
                text: $form.totalArea,
                keyboard: .decimalPad,
                error: form.numberError(form.totalArea)
            )
            CalculatorField(
                title: "🏢 სართული",
                hint: "ჩაწერეთ სართული, რომელზეც მდებარეობს ბინა. თუ პირველ სართულზეა, მიუთითეთ 1.",
                placeholder: "მაგ: 8",
                text: $form.floor,
                keyboard: .numberPad,
                error: form.integerError(form.floor)
            )
        }
    }

    private var buildingStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(title: "🛗 ლიფტი")
                FieldHint(text: "აირჩიეთ ლიფტის ტიპი თქვენს კორპუსში. თუ ლიფტი არ არის, მონიშნეთ „არა“.")
                Picker("ლიფტი", selection: $form.elevator) {
                    ForEach(CalculatorForm.Elevator.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            CalculatorField(
                title: "📏 ჭერის სიმაღლე (სანტიმეტრებში)",
                hint: "ჩაწერეთ სუფთა სიმაღლე სანტიმეტრებში, მაგალითად 280 ან 300.",
                placeholder: "მაგ: 290",
                text: $form.height,
                keyboard: .decimalPad,
                error: form.numberError(form.height)
            )
            CalculatorField(
                title: "🚰 სველი წერტილები",
                hint: "სველ წერტილებს წარმოადგენს, ცივი-ცხელი წყალი, კანალიზაცია, ტრაპი, შემრევი ონკანი, გათბობოის რადიატორი.",
                helpBlogID: CalculatorForm.HelpBlog.fields,
                placeholder: "მაგ: 3",
                text: $form.wetAreas,
                keyboard: .numberPad,
                error: form.integerError(form.wetAreas)
            )
        }
    }

    private var installationsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            CalculatorField(
                title: "🚪 შიდა კარი (MDF-ის შიდა კარი)",
                hint: "მიუთითეთ მხოლოდ შიდა MDF კარების რაოდენობა. თუ კარები არ იცვლება, ჩაწერეთ 0.",
                helpBlogID: CalculatorForm.HelpBlog.fields,
                placeholder: "მაგ: 3",
                text: $form.doors,
                keyboard: .numberPad,
                error: form.integerError(form.doors)
            )
            CalculatorField(
                title: "🔥 ბოილერი (ცენტრალური გათბობის ქვაბი(ები))",
                hint: "ჩაწერეთ ცენტრალური გათბობის ქვაბების რაოდენობა.",
                placeholder: "მაგ: 1",
                text: $form.boilers,
                keyboard: .numberPad,
                error: form.integerError(form.boilers)
            )
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(title: "🧩 იატაკის მოხვეწა (ტიაშკა)")
                FieldHint(text: "აირჩიეთ „კი“, თუ საჭიროა იატაკის მოხვეწის (ტიაშკის) შესრულება.")
                Picker("იატაკის მოხვეწა", selection: $form.screeding) {
                    Text("კი").tag(true)
                    Text("არა").tag(false)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var demolitionStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(title: "♻️ დემონტაჟი (იატაკის აყრა, კედლების ჩამოხევა, კაფელის დემონტაჟი)")
            FieldHint(text: "მონიშნეთ იმ შემთხვევაში, თუ გასაკეთებელია სრული დემონტაჟი, კედლები, აბაზანა, იატაკი, ჭერი")
            Toggle("დემონტაჟი", isOn: $form.removal)
                .padding(.top, 4)
        }
    }

    private var roomsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(title: "არსებული მდგომარეობა (მწვანე, თეთრი, შავი კარკასი)")
                FieldHint(text: "მონიშნეთ ბინის მიმდინარე მდგომარეობა, რათა სწორად დაითვალოს სამუშაოების მოცულობა.")
                VStack(spacing: 0) {
                    ForEach(CalculatorForm.CarcasType.allCases) { type in
                        CarcasTypeRow(type: type, isSelected: form.carcasType == type) {
                            form.carcasType = type
                        }
                        if type != CalculatorForm.CarcasType.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            ForEach(Array($form.rooms.enumerated()), id: \.element.id) { index, $room in
                RoomCard(
                    index: index,
                    room: $room,
                    form: form,
                    canRemove: form.rooms.count > 1
                ) {
                    withAnimation { form.removeRoom(room.id) }
                }
            }

            Button {
                withAnimation { form.addRoom() }
            } label: {
                Label("ოთახის დამატება", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }

    private var bathroomsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            if form.bathrooms.isEmpty {
                Text("აბაზანა არ არის დამატებული. თუ აბაზანის რემონტს არ გეგმავთ, შეგიძლიათ პირდაპირ გამოთვალოთ.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array($form.bathrooms.enumerated()), id: \.element.id) { index, $bathroom in
                BathroomCard(index: index, bathroom: $bathroom, form: form) {
                    withAnimation { form.removeBathroom(bathroom.id) }
                }
            }

            Button {
                withAnimation { form.addBathroom() }
            } label: {
                Label("აბაზანის დამატება", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }

    // MARK: Buttons

    private var stepButtons: some View {
        HStack(spacing: 12) {
            if !form.isFirstStep {
                Button {
                    Self.dismissKeyboard()
                    submitError = nil
                    withAnimation { form.goBack() }
                } label: {
                    Text("უკან")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                Self.dismissKeyboard()
                if form.isLastStep {
                    Task { await submit() }
                } else {
                    withAnimation { _ = form.goForward() }
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(form.isLastStep ? "ფასის დადგენა" : "შემდეგი")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)
        }
        .controlSize(.large)
        .padding()
        .background(.bar)
    }

    private func submit() async {
        guard let request = form.makeRequest() else { return }
        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }

        do {
            let result: CalculationResult = try await APIClient.shared.send(
                Endpoint(method: .post, path: "calculator", body: request)
            )
            submission = CalculatorSubmission(request: request, result: result)
        } catch let error as APIError {
            submitError = error
        } catch {
            submitError = .network
        }
    }

    private static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Building blocks

/// Bold label with the site's red asterisk for required fields.
private struct FieldLabel: View {
    let title: String
    var isRequired = true

    var body: some View {
        (Text(title) + Text(isRequired ? " *" : "").foregroundStyle(.red))
            .font(.subheadline.bold())
    }
}

private struct FieldHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

/// Opens the blog post that explains a field, like the site's "?" icons.
private struct HelpLink: View {
    let blogID: String

    var body: some View {
        NavigationLink(value: AppRoute.blogPost(blogID)) {
            Image(systemName: "questionmark.circle")
                .font(.subheadline)
        }
        .accessibilityLabel("დახმარება")
    }
}

private struct CalculatorField: View {
    let title: String
    var hint: String?
    var helpBlogID: String?
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .decimalPad
    var error: String?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                FieldLabel(title: title)
                if let helpBlogID {
                    HelpLink(blogID: helpBlogID)
                }
            }
            if let hint {
                FieldHint(text: hint)
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .focused($isFocused)
                .padding(10)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(error == nil ? Color.clear : Color.red, lineWidth: 1)
                }
                // The whole box focuses the field, not only the text line inside the padding.
                .contentShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture { isFocused = true }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct CarcasTypeRow: View {
    let type: CalculatorForm.CarcasType
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        HStack {
            Button(action: select) {
                HStack {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    Text(type.title)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            if let blogID = type.helpBlogID {
                HelpLink(blogID: blogID)
            }
        }
        .padding(.vertical, 12)
    }
}

private struct RoomCard: View {
    let index: Int
    @Binding var room: CalculatorForm.RoomInput
    @ObservedObject var form: CalculatorForm
    let canRemove: Bool
    let remove: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                CalculatorField(
                    title: "📐 ფართობი",
                    hint: "ჩაწერეთ ოთახის იატაკის ფართობი კვადრატულ მეტრებში.",
                    helpBlogID: CalculatorForm.HelpBlog.area,
                    placeholder: "მაგ: 18",
                    text: $room.area,
                    error: form.numberError(room.area)
                )
                VStack(alignment: .leading, spacing: 6) {
                    FieldLabel(title: "🧱 იატაკის ტიპი")
                    Picker("იატაკის ტიპი", selection: $room.floorType) {
                        ForEach(CalculatorForm.FloorType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                VStack(alignment: .leading, spacing: 6) {
                    FieldLabel(title: "🪜 ჭერის ტიპი")
                    Picker("ჭერის ტიპი", selection: $room.ceilingType) {
                        ForEach(CalculatorForm.CeilingType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                CalculatorField(
                    title: "📏 პერიმეტრი (მეტრებში)",
                    hint: "კედლების ჯამური სიგრძე, მაგალითად: 4მ + 3მ + 4მ + 3მ = 14 მეტრი პერიმეტრი",
                    helpBlogID: CalculatorForm.HelpBlog.fields,
                    placeholder: "მაგ: 15",
                    text: $room.perimeter,
                    error: form.numberError(room.perimeter)
                )
                CalculatorField(
                    title: "⚡️ ელექტრო წერტილები",
                    hint: "ელექტრო წერტილები შეიძლება იყოს: ნათურა, ჩამრთველი, შტეფსელი",
                    helpBlogID: CalculatorForm.HelpBlog.fields,
                    placeholder: "მაგ: 10",
                    text: $room.electricalPoints,
                    keyboard: .numberPad,
                    error: form.integerError(room.electricalPoints)
                )
                if canRemove {
                    Button("წაშლა", role: .destructive, action: remove)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
        } label: {
            Text("🛋️ ოთახი #\(index + 1)")
                .font(.headline)
        }
    }
}

private struct BathroomCard: View {
    let index: Int
    @Binding var bathroom: CalculatorForm.BathroomInput
    @ObservedObject var form: CalculatorForm
    let remove: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                CalculatorField(
                    title: "📐 ფართობი მ²",
                    hint: "ჩაწერეთ აბაზანის იატაკის ფართობი კვადრატულ მეტრებში.",
                    helpBlogID: CalculatorForm.HelpBlog.area,
                    placeholder: "მაგ: 5",
                    text: $bathroom.area,
                    error: form.numberError(bathroom.area)
                )
                VStack(alignment: .leading, spacing: 6) {
                    FieldLabel(title: "🪜 ჭერის ტიპი")
                    Picker("ჭერის ტიპი", selection: $bathroom.ceilingType) {
                        ForEach(CalculatorForm.CeilingType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                CalculatorField(
                    title: "📏 პერიმეტრი (მეტრებში)",
                    hint: "კედლების ჯამური სიგრძე, მაგალითად: 4მ + 3მ + 4მ + 3მ = 14 მეტრი პერიმეტრი",
                    helpBlogID: CalculatorForm.HelpBlog.fields,
                    placeholder: "მაგ: 9",
                    text: $bathroom.perimeter,
                    error: form.numberError(bathroom.perimeter)
                )
                CalculatorField(
                    title: "⚡️ ელექტრო წერტილები",
                    hint: "აბაზანის ელექტრო წერტილები შეიძლება იყოს: ნათურა, გამწოვი, ჩამრთველი, შტეფსელი",
                    helpBlogID: CalculatorForm.HelpBlog.fields,
                    placeholder: "მაგ: 3",
                    text: $bathroom.electricalPoints,
                    keyboard: .numberPad,
                    error: form.integerError(bathroom.electricalPoints)
                )
                Toggle(isOn: $bathroom.builtInToilet) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🚽 ჩასაშენებელი უნიტაზი")
                            .font(.subheadline.bold())
                        FieldHint(text: "მონიშნეთ მხოლოდ იმ შემთხვევაში, თუ იგეგმება ჩასაშენებელი უნიტაზის მონტაჟი.")
                    }
                }
                Button("წაშლა", role: .destructive, action: remove)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("🛁 აბაზანა #\(index + 1)")
                .font(.headline)
        }
    }
}

#Preview {
    NavigationStack {
        CalculatorView()
    }
}
