import Foundation

/// Classifies gear categories into mutually exclusive equipment classes.
/// Equipping gear from one class automatically unequips gear from conflicting classes.
enum EquipmentClass {
    /// Standard scuba diving equipment (fins, suit, scuba gear, stage bottles, DPV).
    case scuba
    /// Specialist deep-sea equipment (atmospheric diving suits).
    case submersible
}

/// A category of gear. Each category has exactly one equip slot.
enum GearCategory: String, Codable, CaseIterable {
    case fins
    case suit
    case meshBag
    /// Cylinder + regulator + BCD as a single equip slot.
    case scubaGear = "tank"
    case stageBottle
    case dpv
    case atmosphericSuit = "ads"
    case submersibleBattery
    case submersibleThruster
    case submersibleStorage

    var displayName: String {
        switch self {
        case .fins: "Fins"
        case .suit: "Exposure Suit"
        case .scubaGear: "Scuba Gear"
        case .stageBottle: "Stage Bottles"
        case .dpv: "Dive Propulsion Vehicle"
        case .meshBag: "Mesh Bag"
        case .atmosphericSuit: "Atmospheric Diving Suit"
        case .submersibleBattery: "Extra Battery"
        case .submersibleThruster: "Thrusters"
        case .submersibleStorage: "Storage compartments"
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
        case .atmosphericSuit: "shield.checkered"
        case .submersibleBattery: "battery.100percent.bolt"
        case .submersibleThruster: "arrow.right.circle.fill"
        case .submersibleStorage: "bag"
        }
    }

    /// Description of what the default (no gear) provides.
    var defaultDescription: String {
        switch self {
        case .fins: "Barefoot — reduced swim speed"
        case .suit: "No suit — no thermal protection"
        case .scubaGear: "Apnoe — lungs only"
        case .stageBottle: "No stage bottles"
        case .dpv: "No DPV — swim under your own power"
        case .meshBag: "No bag — carry up to \(GameConstants.defaultCarryCapacity) items"
        case .atmosphericSuit: "No ADS — use standard diving equipment"
        case .submersibleBattery: "No extra battery"
        case .submersibleThruster: "No thruster upgrades"
        case .submersibleStorage: "No extra storage"
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
        case .atmosphericSuit, .submersibleBattery, .submersibleStorage, .submersibleThruster:
            return .marineSpecialist
        }
    }

    var equipmentClass: EquipmentClass {
        switch self {
        case .fins, .suit, .scubaGear, .stageBottle, .dpv, .meshBag:
            return .scuba
        case .atmosphericSuit, .submersibleBattery, .submersibleStorage, .submersibleThruster:
            return .submersible
        }
    }
}

/// The concrete gameplay effect of a gear item.
enum GearModifier {
    /// Absolute movement speed values (replaces base constants).
    case movementSpeed(scrollSpeed: CGFloat, horizontalSpeed: CGFloat)
    /// Thermal protection factor (0 = none, 1 = full insulation).
    case thermalProtection(factor: Double)
    /// Air capacity in bar (replaces base constant).
    case airCapacity(bar: Double)
    /// Trash carry capacity (number of items per dive).
    case carryCapacity(count: Int)
    /// Atmospheric diving suit: self-contained hard suit with own air, battery, depth rating, and built-in storage.
    case atmosphericDivingSuit(airCapacity: Double, baseBatteryMinutes: Double, pressureRating: Double, baseStorage: Int, baseSpeed: Double)
    /// Extra battery capacity for submersibles
    case batteryCapacity(minutes: Double)
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
        case .atmosphericDivingSuit(let airCapacity, let batteryMinutes, let pressureRating, let storage, let speed):
            return "\(Int(airCapacity)) bar air · \(Int(batteryMinutes)) min battery · \(Int(pressureRating)) bar rated · \(storage) storage · speed \(Int(speed))"
        case .batteryCapacity(let minutes):
            return "Increases the suits battery capacity by \(Int(minutes)) minutes"
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
            price: 10,
            requiredLevel: 1,
            modifier: .movementSpeed(scrollSpeed: 4, horizontalSpeed: 4)
        ),
        GearDefinition(
            id: "fins.advanced",
            category: .fins,
            name: "Advanced Fins",
            description: "Stiffer blades and split-fin design for better propulsion.",
            icon: "shoe.2.fill",
            price: 50,
            requiredLevel: 3,
            modifier: .movementSpeed(scrollSpeed: 6, horizontalSpeed: 5)
        ),
        GearDefinition(
            id: "fins.pro",
            category: .fins,
            name: "Pro Fins",
            description: "Competition-grade carbon fiber fins for maximum thrust.",
            icon: "shoe.2.fill",
            price: 150,
            requiredLevel: 6,
            modifier: .movementSpeed(scrollSpeed: 8, horizontalSpeed: 6)
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
            price: 200,
            requiredLevel: 8,
            modifier: .thermalProtection(factor: 0.8)
        ),
        GearDefinition(
            id: "suit.dry.heated",
            category: .suit,
            name: "Heated Drysuit",
            description: "Sealed suit with an integrated electric heating vest. With this system, the cold has very little effect on you.",
            icon: "tshirt.fill",
            price: 300,
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
            price: 10,
            requiredLevel: 1,
            modifier: .carryCapacity(count: 5)
        ),
        GearDefinition(
            id: "bag.medium",
            category: .meshBag,
            name: "Medium Mesh Bag",
            description: "Reinforced bag with room for more trash.",
            icon: "bag.fill",
            price: 30,
            requiredLevel: 3,
            modifier: .carryCapacity(count: 10)
        ),
        GearDefinition(
            id: "bag.large",
            category: .meshBag,
            name: "Large Mesh Bag",
            description: "Professional-grade collection bag for serious cleanup dives.",
            icon: "bag.fill",
            price: 80,
            requiredLevel: 6,
            modifier: .carryCapacity(count: 15)
        ),
        GearDefinition(
            id: "liftBag.medium",
            category: .meshBag,
            name: "Lift Bag",
            description: "A lift bag can be filled with air, which offsets the weight of the collected items, allowing you to carry more",
            icon: "bag.fill",
            price: 120,
            requiredLevel: 8,
            modifier: .carryCapacity(count: 20)
        ),
        GearDefinition(
            id: "liftBag.large",
            category: .meshBag,
            name: "Large Lift Bag",
            description: "Even larger lift bag for maximum payload.",
            icon: "bag.fill",
            price: 180,
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
            price: 80,
            requiredLevel: 5,
            modifier: .airCapacity(bar: 200)
        ),
        GearDefinition(
            id: "tank.double",
            category: .scubaGear,
            name: "Twinset Scuba Gear",
            description: "Twin cylinders in a manifold with redundant regulators for extended dive time.",
            icon: "cylinder.fill",
            price: 180,
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

        // Atmospheric Diving Suits
        GearDefinition(
            id: "ads.jims",
            category: .atmosphericSuit,
            name: "JIM Suit",
            description: "The original atmospheric diving suit. A one-atmosphere hard suit that protects against external pressure, allowing dives without decompression.",
            icon: "shield.checkered",
            price: 800,
            requiredLevel: 15,
            modifier: .atmosphericDivingSuit(airCapacity: 400, baseBatteryMinutes: 45, pressureRating: 200, baseStorage: 10, baseSpeed: 12)
        ),
        GearDefinition(
            id: "ads.newtsuit",
            category: .atmosphericSuit,
            name: "Newtsuit",
            description: "A modern rotary-joint ADS with improved mobility and deeper depth rating. The articulated limbs allow more precise work at extreme depths.",
            icon: "shield.checkered",
            price: 1500,
            requiredLevel: 17,
            modifier: .atmosphericDivingSuit(airCapacity: 600, baseBatteryMinutes: 60, pressureRating: 300, baseStorage: 15, baseSpeed: 16)
        ),
        GearDefinition(
            id: "ads.exosuit",
            category: .atmosphericSuit,
            name: "Exosuit",
            description: "A state-of-the-art exoskeleton diving suit with thruster packs and extended life support. Rated for the deepest operational dives.",
            icon: "shield.checkered",
            price: 3000,
            requiredLevel: 19,
            modifier: .atmosphericDivingSuit(airCapacity: 800, baseBatteryMinutes: 90, pressureRating: 400, baseStorage: 20, baseSpeed: 20)
        ),

        // Submersible Batteries
        GearDefinition(
            id: "sub.battery.standard",
            category: .submersibleBattery,
            name: "Standard Battery Pack",
            description: "An additional lithium-ion battery pack that extends operational time underwater.",
            icon: "battery.100percent.bolt",
            price: 600,
            requiredLevel: 16,
            modifier: .batteryCapacity(minutes: 20)
        ),
        GearDefinition(
            id: "sub.battery.extended",
            category: .submersibleBattery,
            name: "Extended Battery Pack",
            description: "A high-density battery array providing significantly longer dive endurance.",
            icon: "battery.100percent.bolt",
            price: 1200,
            requiredLevel: 18,
            modifier: .batteryCapacity(minutes: 45)
        ),

        // Submersible Thrusters
        GearDefinition(
            id: "sub.thruster.standard",
            category: .submersibleThruster,
            name: "Auxiliary Thrusters",
            description: "A pair of bolt-on electric thrusters that increase suit maneuverability.",
            icon: "arrow.right.circle.fill",
            price: 700,
            requiredLevel: 16,
            modifier: .movementSpeed(scrollSpeed: 4, horizontalSpeed: 2)
        ),
        GearDefinition(
            id: "sub.thruster.advanced",
            category: .submersibleThruster,
            name: "High-Output Thrusters",
            description: "Powerful vectored thrusters with variable nozzles for rapid repositioning at depth.",
            icon: "arrow.right.circle.fill",
            price: 1400,
            requiredLevel: 18,
            modifier: .movementSpeed(scrollSpeed: 8, horizontalSpeed: 4)
        ),

        // Submersible Storage
        GearDefinition(
            id: "sub.storage.standard",
            category: .submersibleStorage,
            name: "External Cargo Rack",
            description: "A frame-mounted rack that adds external storage capacity to the suit.",
            icon: "bag",
            price: 500,
            requiredLevel: 16,
            modifier: .carryCapacity(count: 10)
        ),
        GearDefinition(
            id: "sub.storage.large",
            category: .submersibleStorage,
            name: "Heavy-Duty Cargo Pod",
            description: "A sealed cargo pod with hydraulic clamps, designed for hauling large debris from the deep.",
            icon: "bag.fill",
            price: 1100,
            requiredLevel: 18,
            modifier: .carryCapacity(count: 20)
        ),
    ]
}
