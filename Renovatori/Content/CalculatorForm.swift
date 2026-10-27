import Foundation

/// Inputs of the calculator form (`views/pages/calculator-page`), split into the site's six steps.
/// Text fields stay strings while editing; `makeRequest()` validates and converts them.
@MainActor
final class CalculatorForm: ObservableObject {
    enum Step: Int, CaseIterable {
        case contact = 1, building, installations, demolition, rooms, bathrooms

        var title: String {
            switch self {
            case .contact: "კონტაქტი და ფართობი"
            case .building: "შენობა"
            case .installations: "კარები და გათბობა"
            case .demolition: "დემონტაჟი"
            case .rooms: "მდგომარეობა და ოთახები"
            case .bathrooms: "აბაზანები"
            }
        }
    }

    enum Elevator: String, CaseIterable, Identifiable {
        case passenger, cargo, none
        var id: String { rawValue }
        var title: String {
            switch self {
            case .passenger: "სამგზავრო"
            case .cargo: "სატვირთო"
            case .none: "არა"
            }
        }
    }

    enum CarcasType: String, CaseIterable, Identifiable {
        case green, white, black, old
        var id: String { rawValue }
        var title: String {
            switch self {
            case .green: "მწვანე კარკასი"
            case .white: "თეთრი კარკასი"
            case .black: "შავი კარკასი"
            case .old: "ძველი რემონტი"
            }
        }

        /// Blog post explaining the state, as linked on the site.
        var helpBlogID: String? {
            switch self {
            case .green: "693e40002ed62d127ab05108"
            case .white: "693e40342ed62d127ab0510e"
            case .black: "693d8d61291bc84d00b6f427"
            case .old: nil
            }
        }
    }

    enum FloorType: String, CaseIterable, Identifiable {
        case laminate, tiles
        var id: String { rawValue }
        var title: String {
            switch self {
            case .laminate: "ლამინატი"
            case .tiles: "მეტლახი / გრანიტი"
            }
        }
    }

    enum CeilingType: String, CaseIterable, Identifiable {
        case french, dryWall
        var id: String { rawValue }
        var title: String {
            switch self {
            case .french: "გასაჭიმი (ფრანგული)"
            case .dryWall: "თაბაშირ მუყაო"
            }
        }
    }

    struct RoomInput: Identifiable {
        let id = UUID()
        var area = ""
        var floorType: FloorType = .laminate
        var ceilingType: CeilingType = .french
        var perimeter = ""
        var electricalPoints = ""
    }

    struct BathroomInput: Identifiable {
        let id = UUID()
        var area = ""
        var ceilingType: CeilingType = .french
        var perimeter = ""
        var electricalPoints = ""
        var builtInToilet = false
    }

    /// Blog posts the site links from the field labels.
    enum HelpBlog {
        static let area = "69a88631b50c341432263980"
        static let fields = "698c9a0229b6ab9da1589692"
    }

    @Published var step: Step = .contact
    /// Set after the user tries to leave a step with missing values, so errors show only then.
    @Published var showsErrors = false

    @Published var phoneNumber = ""
    @Published var totalArea = ""
    @Published var floor = ""
    @Published var elevator: Elevator = .passenger
    @Published var height = ""
    @Published var wetAreas = ""
    @Published var doors = ""
    @Published var boilers = ""
    @Published var screeding = false
    @Published var removal = false
    @Published var carcasType: CarcasType = .green
    @Published var rooms = [RoomInput()]
    @Published var bathrooms = [BathroomInput()]

    var isFirstStep: Bool { step == .contact }
    var isLastStep: Bool { step == .bathrooms }
    var progress: Double { Double(step.rawValue) / Double(Step.allCases.count) }

    // MARK: Validation

    static let requiredMessage = "სავალდებულო ველი"

    var phoneError: String? {
        guard showsErrors else { return nil }
        return phoneNumber.wholeMatch(of: /\d{9}/) == nil
            ? "გთხოვთ მიუთითოთ ტელეფონის ნომერი 9 ციფრის ფორმატში."
            : nil
    }

    /// Error for a required decimal field (area, height, perimeter...).
    func numberError(_ text: String) -> String? {
        guard showsErrors else { return nil }
        return Self.number(text) == nil ? Self.requiredMessage : nil
    }

    /// Error for a required whole-number field (doors, boilers, floor...).
    func integerError(_ text: String) -> String? {
        guard showsErrors else { return nil }
        return Self.integer(text) == nil ? Self.requiredMessage : nil
    }

    private func isValid(_ step: Step) -> Bool {
        switch step {
        case .contact:
            phoneNumber.wholeMatch(of: /\d{9}/) != nil && Self.number(totalArea) != nil && Self.integer(floor) != nil
        case .building:
            Self.number(height) != nil && Self.integer(wetAreas) != nil
        case .installations:
            Self.integer(doors) != nil && Self.integer(boilers) != nil
        case .demolition:
            true
        case .rooms:
            !rooms.isEmpty && rooms.allSatisfy { room in
                Self.number(room.area) != nil && Self.number(room.perimeter) != nil && Self.integer(room.electricalPoints) != nil
            }
        case .bathrooms:
            bathrooms.allSatisfy { bathroom in
                Self.number(bathroom.area) != nil && Self.number(bathroom.perimeter) != nil && Self.integer(bathroom.electricalPoints) != nil
            }
        }
    }

    // MARK: Navigation

    /// Moves to the next step when the current one is complete; otherwise reveals its errors.
    @discardableResult
    func goForward() -> Bool {
        guard isValid(step) else {
            showsErrors = true
            return false
        }
        showsErrors = false
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
        return true
    }

    func goBack() {
        showsErrors = false
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    func addRoom() { rooms.append(RoomInput()) }
    func removeRoom(_ id: RoomInput.ID) { rooms.removeAll { $0.id == id } }
    func addBathroom() { bathrooms.append(BathroomInput()) }
    func removeBathroom(_ id: BathroomInput.ID) { bathrooms.removeAll { $0.id == id } }

    // MARK: Request

    /// The request body, or nil (jumping to the first incomplete step) when something is missing.
    func makeRequest() -> CalculationRequest? {
        if let incomplete = Step.allCases.first(where: { !isValid($0) }) {
            step = incomplete
            showsErrors = true
            return nil
        }

        return CalculationRequest(
            phoneNumber: phoneNumber,
            height: Self.number(height) ?? 0,
            totalArea: Self.number(totalArea) ?? 0,
            wetAreas: Self.integer(wetAreas) ?? 0,
            doors: Self.integer(doors) ?? 0,
            boilers: Self.integer(boilers) ?? 0,
            floor: Self.integer(floor),
            elevator: elevator.rawValue,
            screedingOption: screeding ? "1" : "0",
            removal: removal ? "on" : nil,
            carcasType: carcasType.rawValue,
            rooms: rooms.map { room in
                CalculationRequest.Room(
                    area: Self.number(room.area) ?? 0,
                    perimeter: Self.number(room.perimeter) ?? 0,
                    electricalPoints: Double(Self.integer(room.electricalPoints) ?? 0),
                    floorType: room.floorType.rawValue,
                    ceilingType: room.ceilingType.rawValue
                )
            },
            bathrooms: bathrooms.map { bathroom in
                CalculationRequest.Bathroom(
                    area: Self.number(bathroom.area) ?? 0,
                    perimeter: Self.number(bathroom.perimeter) ?? 0,
                    electricalPoints: Double(Self.integer(bathroom.electricalPoints) ?? 0),
                    ceilingType: bathroom.ceilingType.rawValue,
                    builtInToilet: bathroom.builtInToilet ? "on" : nil
                )
            }
        )
    }

    /// Non-negative decimal; accepts a comma as the decimal separator.
    static func number(_ text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0, value.isFinite else { return nil }
        return value
    }

    static func integer(_ text: String) -> Int? {
        guard let value = Int(text.trimmingCharacters(in: .whitespaces)), value >= 0 else { return nil }
        return value
    }
}
