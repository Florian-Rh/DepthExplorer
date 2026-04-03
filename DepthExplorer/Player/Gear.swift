import Foundation

/// A category of gear. Each category has exactly one equip slot.
enum GearCategory: String, Codable, CaseIterable {
    case fins
    case suit
    case meshBag
    /// Cylinder + regulator + BCD as a single equip slot.
    case scubaGear = "tank"
    case stageBottle
    case dpv

    var displayName: String {
        switch self {
        case .fins: "Fins"
        case .suit: "Exposure Suit"
        case .scubaGear: "Scuba Gear"
        case .stageBottle: "Stage Bottles"
        case .dpv: "Dive Propulsion Vehicle"
        case .meshBag: "Mesh Bag"
        }
    }

    var icon: String {
        switch self {
        case .fins: "shoe.2.fill"
        case .suit: "tshirt.fill"
        case .scubaGear: "cylinder.fill"
        case .stageBottle: "cylinder.fill"
        case .dpv: "arrow.right.circle.fill"
        case .meshBag: "bag"
        }
    }

    /// Description of what the default (no gear) provides.
    var defaultDescription: String {
        switch self {
        case .fins: "Barefoot — reduced swim speed"
        case .suit: "No suit — no thermal protection"
        case .scubaGear: "Apnoe — lungs only (\(Int(GameConstants.apnoeLungCapacity)) bar)"
        case .stageBottle: "No stage bottles"
        case .dpv: "No DPV — swim under your own power"
        case .meshBag: "No bag — carry up to \(GameConstants.defaultCarryCapacity) items"
        }
    }

    var minimumRank: DiverRank {
        switch self {
        case .fins, .suit, .meshBag:
            return .freeDiver
        case .scubaGear:
            return .scubaDiver
        case .stageBottle, .dpv:
            return .techDiver
        }
    }
}

/// The concrete gameplay effect of a gear item.
enum GearModifier {
    /// Absolute movement speed values (replaces base constants).
    case movementSpeed(scrollSpeed: CGFloat, horizontalSpeed: CGFloat)
    /// Thermal protection factor (0 = none, 1 = full insulation).
    case thermalProtection(factor: Double)
    /// Scuba gear air capacity in bar (replaces base constant).
    case airCapacity(bar: Double)
    /// Trash carry capacity (number of items per dive).
    case carryCapacity(count: Int)
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
        case .carryCapacity(let count):
            return "Carry up to \(count) items"
        }
    }

    // MARK: - Catalog

    static let allGear: [GearDefinition] = [
        // Fins
        GearDefinition(
            id: "fins.basic",
            category: .fins,
            name: "Basic Fins",
            description: "Standard rubber fins for recreational diving.",
            icon: "shoe.2.fill",
            price: 15,
            requiredLevel: 1,
            modifier: .movementSpeed(scrollSpeed: GameConstants.scrollSpeed, horizontalSpeed: GameConstants.diverHorizontalSpeed)
        ),
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
            id: "suit.3mm",
            category: .suit,
            name: "3mm Wetsuit",
            description: "Basic neoprene wetsuit for warm water diving.",
            icon: "tshirt.fill",
            price: 15,
            requiredLevel: 1,
            modifier: .thermalProtection(factor: 0.1)
        ),
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
            description: "Heavy-duty wetsuit for longer and deeper diving.",
            icon: "tshirt.fill",
            price: 100,
            requiredLevel: 4,
            modifier: .thermalProtection(factor: 0.5)
        ),
        GearDefinition(
            id: "suit.dry",
            category: .suit,
            name: "Drysuit",
            description: "Sealed suit with insulating undergarments. Essential for deep, cold water.",
            icon: "tshirt.fill",
            price: 250,
            requiredLevel: 8,
            modifier: .thermalProtection(factor: 0.8)
        ),
        GearDefinition(
            id: "suit.dry.heated",
            category: .suit,
            name: "Heated Drysuit",
            description: "Sealed suit with an integrated electric heating vest. With this system, the cold has very little effect on you.",
            icon: "tshirt.fill",
            price: 400,
            requiredLevel: 10,
            modifier: .thermalProtection(factor: 0.95)
        ),

        // Mesh Bags
        GearDefinition(
            id: "bag.small",
            category: .meshBag,
            name: "Small Mesh Bag",
            description: "A basic collection bag for small debris.",
            icon: "bag",
            price: 15,
            requiredLevel: 1,
            modifier: .carryCapacity(count: 5)
        ),
        GearDefinition(
            id: "bag.medium",
            category: .meshBag,
            name: "Medium Mesh Bag",
            description: "Reinforced bag with room for more trash.",
            icon: "bag.fill",
            price: 40,
            requiredLevel: 3,
            modifier: .carryCapacity(count: 10)
        ),
        GearDefinition(
            id: "bag.large",
            category: .meshBag,
            name: "Large Mesh Bag",
            description: "Professional-grade collection bag for serious cleanup dives.",
            icon: "bag.fill",
            price: 100,
            requiredLevel: 6,
            modifier: .carryCapacity(count: 15)
        ),
        GearDefinition(
            id: "liftBag.medium",
            category: .meshBag,
            name: "Lift Bag",
            description: "A lift bag can be filled with air, which offsets the weight of the collected items, allowing you to carry more",
            icon: "bag.fill",
            price: 150,
            requiredLevel: 8,
            modifier: .carryCapacity(count: 20)
        ),
        GearDefinition(
            id: "liftBag.large",
            category: .meshBag,
            name: "Large Lift Bag",
            description: "Even larger lift bag for maximum payload.",
            icon: "bag.fill",
            price: 200,
            requiredLevel: 10,
            modifier: .carryCapacity(count: 25)
        ),

        // Scuba Gear (cylinder + regulator + BCD)
        GearDefinition(
            id: "tank.standard",
            category: .scubaGear,
            name: "Standard Scuba Gear",
            description: "A 200 bar cylinder with single-stage regulator and basic BCD.",
            icon: "cylinder.fill",
            price: 100,
            requiredLevel: 5,
            modifier: .airCapacity(bar: 200)
        ),
        GearDefinition(
            id: "tank.double",
            category: .scubaGear,
            name: "Twinset Scuba Gear",
            description: "Twin cylinders in a manifold with redundant regulators for extended dive time.",
            icon: "cylinder.fill",
            price: 200,
            requiredLevel: 7,
            modifier: .airCapacity(bar: 400)
        ),
        GearDefinition(
            id: "rebreather",
            category: .scubaGear,
            name: "Closed-Circuit Rebreather",
            description: "Did you know that the air you exhale still contains around 17% oxygen? Why let that go to waste?! A semi-closed rebreather scrubs the carbondioxide from the air you exhale and replentishes the oxygen, allowing for a much longer dive time.",
            icon: "cylinder.fill",
            price: 400,
            requiredLevel: 11,
            modifier: .airCapacity(bar: 600)
        ),

        // Stage Bottles
        GearDefinition(
            id: "stage.single",
            category: .stageBottle,
            name: "Single Stage Bottle",
            description: "One side-mounted extra tank for longer dives.",
            icon: "cylinder.fill",
            price: 200,
            requiredLevel: 10,
            modifier: .airCapacity(bar: 200)
        ),
        GearDefinition(
            id: "stage.double",
            category: .stageBottle,
            name: "Double Stage Bottles",
            description: "Two side-mounted tanks for maximum air supply.",
            icon: "cylinder.fill",
            price: 400,
            requiredLevel: 12,
            modifier: .airCapacity(bar: 400)
        ),

        // DPV (Diver Propulsion Vehicle)
        GearDefinition(
            id: "dpv.basic",
            category: .dpv,
            name: "Basic Scooter",
            description: "A handheld diver propulsion vehicle for faster cruising.",
            icon: "arrow.right.circle.fill",
            price: 300,
            requiredLevel: 10,
            modifier: .movementSpeed(scrollSpeed: 6, horizontalSpeed: 3)
        ),
        GearDefinition(
            id: "dpv.advanced",
            category: .dpv,
            name: "Advanced Scooter",
            description: "High-performance DPV with dual thrusters for serious speed.",
            icon: "arrow.right.circle.fill",
            price: 500,
            requiredLevel: 13,
            modifier: .movementSpeed(scrollSpeed: 12, horizontalSpeed: 6)
        ),
    ]
}
