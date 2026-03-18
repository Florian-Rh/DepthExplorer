import Foundation

/// A category of gear. Each category has exactly one equip slot.
enum GearCategory: String, Codable, CaseIterable {
    case fins
    case suit
    case tank

    var displayName: String {
        switch self {
        case .fins: "Fins"
        case .suit: "Exposure Suit"
        case .tank: "Tank"
        }
    }

    var icon: String {
        switch self {
        case .fins: "shoe.2.fill"
        case .suit: "tshirt.fill"
        case .tank: "cylinder.fill"
        }
    }

    /// Description of what the default (no gear) provides.
    var defaultDescription: String {
        switch self {
        case .fins: "Basic fins — standard speed"
        case .suit: "3mm Wetsuit — minimal thermal protection"
        case .tank: "Standard Tank — 200 bar capacity"
        }
    }
}

/// The concrete gameplay effect of a gear item.
enum GearModifier {
    /// Absolute movement speed values (replaces base constants).
    case movementSpeed(scrollSpeed: CGFloat, horizontalSpeed: CGFloat)
    /// Thermal protection factor (0 = none, 1 = full insulation).
    case thermalProtection(factor: Double)
    /// Tank air capacity in bar (replaces base constant).
    case airCapacity(bar: Double)
}

/// A specific gear item available for purchase and equipping.
struct GearDefinition: Identifiable {
    let id: String
    let category: GearCategory
    let name: String
    let description: String
    let icon: String
    let price: Int
    let requiredLevel: Int
    let modifier: GearModifier

    /// A short description of the modifier for UI display.
    var effectDescription: String {
        switch modifier {
        case .movementSpeed:
            return "Increased swim speed"
        case .thermalProtection(let factor):
            let percent = Int(factor * 100)
            return "\(percent)% thermal protection"
        case .airCapacity(let bar):
            return "\(Int(bar)) bar capacity"
        }
    }

    // MARK: - Catalog

    static let allGear: [GearDefinition] = [
        // Fins
        GearDefinition(
            id: "fins.advanced",
            category: .fins,
            name: "Advanced Fins",
            description: "Stiffer blades and split-fin design for better propulsion.",
            icon: "shoe.2.fill",
            price: 50,
            requiredLevel: 3,
            modifier: .movementSpeed(scrollSpeed: 10, horizontalSpeed: 5)
        ),
        GearDefinition(
            id: "fins.pro",
            category: .fins,
            name: "Pro Fins",
            description: "Competition-grade carbon fiber fins for maximum thrust.",
            icon: "shoe.2.fill",
            price: 150,
            requiredLevel: 6,
            modifier: .movementSpeed(scrollSpeed: 12, horizontalSpeed: 6)
        ),

        // Suits
        GearDefinition(
            id: "suit.5mm",
            category: .suit,
            name: "5mm Wetsuit",
            description: "Thicker neoprene for cooler waters.",
            icon: "tshirt.fill",
            price: 40,
            requiredLevel: 2,
            modifier: .thermalProtection(factor: 0.3)
        ),
        GearDefinition(
            id: "suit.7mm",
            category: .suit,
            name: "7mm Wetsuit",
            description: "Heavy-duty wetsuit for cold water diving.",
            icon: "tshirt.fill",
            price: 100,
            requiredLevel: 4,
            modifier: .thermalProtection(factor: 0.5)
        ),
        GearDefinition(
            id: "suit.dry",
            category: .suit,
            name: "Drysuit",
            description: "Sealed suit with insulating undergarments. Essential for deep cold water.",
            icon: "tshirt.fill",
            price: 250,
            requiredLevel: 7,
            modifier: .thermalProtection(factor: 0.8)
        ),

        // Tanks
        GearDefinition(
            id: "tank.double",
            category: .tank,
            name: "Double Tank",
            description: "Twin cylinders mounted in a manifold for extended dive time.",
            icon: "cylinder.fill",
            price: 200,
            requiredLevel: 5,
            modifier: .airCapacity(bar: 350)
        ),
    ]
}
