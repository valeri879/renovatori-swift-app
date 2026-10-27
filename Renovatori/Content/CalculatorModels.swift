import Foundation

/// Body of `POST /calculator`. String flags are compared literally by the backend.
struct CalculationRequest: Encodable, Hashable {
    struct Room: Encodable, Hashable {
        let area: Double
        let perimeter: Double
        let electricalPoints: Double
        /// "laminate" or "tiles".
        let floorType: String
        /// "dryWall" or "french".
        let ceilingType: String
    }

    struct Bathroom: Encodable, Hashable {
        let area: Double
        let perimeter: Double
        let electricalPoints: Double
        let ceilingType: String
        /// "on" includes a built-in toilet; nil leaves the key out.
        let builtInToilet: String?
    }

    let phoneNumber: String
    /// Room height in centimeters.
    let height: Double
    let totalArea: Double
    let wetAreas: Int
    let doors: Int
    let boilers: Int
    let floor: Int?
    /// "passenger", "cargo" or "none".
    let elevator: String?
    /// "1" includes screeding, "0" does not.
    let screedingOption: String
    /// "on" includes demolition; nil leaves the key out.
    let removal: String?
    /// "green", "white", "black" or "old".
    let carcasType: String
    let rooms: [Room]
    let bathrooms: [Bathroom]
}

/// Response of `POST /calculator`.
struct CalculationResult: Decodable, Hashable, Identifiable {
    struct Info: Decodable, Hashable {
        let totalArea: Double?
        let wallsTotalArea: Double?
        let electricalPoints: Double?

        private enum CodingKeys: String, CodingKey {
            case totalArea, wallsTotalArea, electricalPoints
        }

        // `info` also echoes the request body, so numbers may arrive as strings.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            totalArea = container.lenientDouble(.totalArea)
            wallsTotalArea = container.lenientDouble(.wallsTotalArea)
            electricalPoints = container.lenientDouble(.electricalPoints)
        }
    }

    struct BreakdownItem: Decodable, Hashable, Identifiable {
        let label: String
        /// Bootstrap Icons class from the web (`bi-droplet`); see `symbolName`.
        let icon: String
        let amount: Double
        let percent: Double

        var id: String { label }

        /// SF Symbol matching the web icon.
        var symbolName: String {
            switch icon {
            case "bi-trash3": "trash"
            case "bi-bricks": "square.stack.3d.up"
            case "bi-paint-bucket": "paintbrush"
            case "bi-border-top": "rectangle.tophalf.inset.filled"
            case "bi-layers": "square.3.layers.3d"
            case "bi-grid-3x3": "square.grid.3x3"
            case "bi-grid-3x3-gap": "square.grid.3x3.fill"
            case "bi-droplet": "drop"
            case "bi-water": "water.waves"
            case "bi-lightning-charge": "bolt"
            case "bi-door-closed": "door.left.hand.closed"
            case "bi-thermometer-half": "thermometer.medium"
            default: "wrench.and.screwdriver"
            }
        }
    }

    let resultId: String
    let info: Info
    let breakdown: [BreakdownItem]
    let clientTotal: Double
    let clientPricePerArea: Double

    var id: String { resultId }
}

private extension KeyedDecodingContainer {
    func lenientDouble(_ key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let text = try? decodeIfPresent(String.self, forKey: key) {
            return Double(text)
        }
        return nil
    }
}

extension Double {
    /// `20 887.50 ₾`.
    var lariFormatted: String {
        formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "ka_GE"))) + " ₾"
    }
}

/// A finished calculation: what was sent and what came back, for the result screen.
struct CalculatorSubmission: Hashable, Identifiable {
    let request: CalculationRequest
    let result: CalculationResult
    var id: String { result.resultId }
}
