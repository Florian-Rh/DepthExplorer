import Foundation

/// Identifies a skill family. Each family is a linear chain of levels.
enum SkillFamily: String, Codable, CaseIterable {
    case breathingTechniques
    case finKicking
    case coldResistance
    case stressManagement
    case negotiator
    case multiGasManagement

    var displayName: String {
        switch self {
        case .breathingTechniques: "Breathing"
        case .finKicking: "Fin Kicking"
        case .coldResistance: "Cold Resistance"
        case .stressManagement: "Stress Management"
        case .negotiator: "Negotiator"
        case .multiGasManagement: "Multi-Gas Management"
        }
    }

    var icon: String {
        switch self {
        case .breathingTechniques: "lungs.fill"
        case .finKicking: "figure.pool.swim"
        case .coldResistance: "snowflake"
        case .stressManagement: "brain.head.profile"
        case .negotiator: "dollarsign.ring.dashed"
        case .multiGasManagement: "gauge.with.dots.needle.67percent"
        }
    }

    /// Minimum player level before this skill family is revealed.
    /// Below this level the family is shown redacted ("???").
    var minimumLevel: Int? {
        switch self {
        case .coldResistance: 3
        case .stressManagement: 5
        case .negotiator: 8
        case .multiGasManagement: 10
        case .breathingTechniques, .finKicking: nil
        }
    }
}

/// The concrete gameplay effect of a single skill.
enum SkillModifier {
    /// Multiplier applied to the SAC rate. Values < 1 reduce consumption.
    case sacRateMultiplier(Double)
    /// Multiplier applied to movement speed. Values > 1 increase speed.
    case movementSpeedMultiplier(Double)
    /// Multiplier applied to warning thresholds, pushing fatal/critical limits further.
    /// Values > 1 mean the diver tolerates more before warnings escalate.
    case warningThresholdMultiplier(Double)
    /// Multiplier applied to the safe ascent speed. Values > 1 increase the
    /// safe speed, allowing the diver to ascend faster without triggering DCS warnings.
    case safeAscentSpeedMultiplier(Double)
    /// Multiplier applied to the cooling rate. Values < 1 reduce cooling
    case coldResistanceMultiplier(Double)
    /// Multiplier applied to the earnings through trash collection. Values > 1 increase the
    /// amount of Sand Dollars per trash item
    case earningsMuliplier(Double)
}

/// A single skill within a family, at a specific level.
struct SkillDefinition: Identifiable {
    let id: String
    let family: SkillFamily
    let level: Int
    let name: String
    let description: String
    let modifier: SkillModifier

    /// The skill that must be acquired before this one (`nil` for level-1 skills).
    var prerequisiteID: String? {
        level > 1 ? "\(family.rawValue).\(level - 1)" : nil
    }

    /// A short description of the modifier for UI display.
    var effectDescription: String {
        switch modifier {
        case .sacRateMultiplier(let m):
            let percent = Int((1.0 - m) * 100)
            return "−\(percent)% air consumption"
        case .movementSpeedMultiplier(let m):
            let percent = Int((m - 1.0) * 100)
            return "+\(percent)% movement speed"
        case .warningThresholdMultiplier(let m):
            let percent = Int((m - 1.0) * 100)
            return "+\(percent)% warning tolerance"
        case .safeAscentSpeedMultiplier(let m):
            let percent = Int((m - 1.0) * 100)
            return "+\(percent)% safe ascent speed"
        case .coldResistanceMultiplier(let m):
            let percent = Int((1.0 - m) * 100)
            return "\(percent)% slower cooling"
        case .earningsMuliplier(let m):
            let percent = Int((m - 1.0) * 100)
            return "+\(percent)% more Sand Dollars for collected trash"
        }
    }

    // MARK: - Catalog

    static let allSkills: [SkillDefinition] = [
        // Breathing Techniques
        SkillDefinition(
            id: "breathingTechniques.1",
            family: .breathingTechniques,
            level: 1,
            name: "Diaphragmatic Breathing",
            description: "Slow, controlled breaths from the diaphragm reduce air consumption.",
            modifier: .sacRateMultiplier(0.90)
        ),
        SkillDefinition(
            id: "breathingTechniques.2",
            family: .breathingTechniques,
            level: 2,
            name: "Skip Breathing",
            description: "Brief breath-holds between inhales conserve gas at depth.",
            modifier: .sacRateMultiplier(0.80)
        ),
        SkillDefinition(
            id: "breathingTechniques.3",
            family: .breathingTechniques,
            level: 3,
            name: "Zen Breathing",
            description: "Total respiratory control minimizes oxygen demand.",
            modifier: .sacRateMultiplier(0.70)
        ),

        // Fin Kicking Techniques
        SkillDefinition(
            id: "finKicking.1",
            family: .finKicking,
            level: 1,
            name: "Flutter Kick",
            description: "A basic alternating kick that improves propulsion efficiency.",
            modifier: .movementSpeedMultiplier(1.10)
        ),
        SkillDefinition(
            id: "finKicking.2",
            family: .finKicking,
            level: 2,
            name: "Frog Kick",
            description: "A powerful simultaneous kick that covers more distance per stroke.",
            modifier: .movementSpeedMultiplier(1.20)
        ),
        SkillDefinition(
            id: "finKicking.3",
            family: .finKicking,
            level: 3,
            name: "Modified Flutter",
            description: "An advanced technique combining flutter and frog for maximum speed.",
            modifier: .movementSpeedMultiplier(1.30)
        ),

        // Cold Resistance
        SkillDefinition(
            id: "coldResistance.1",
            family: .coldResistance,
            level: 1,
            name: "Thermal Acclimatization",
            description: "Adapting to cooler waters with reduced discomfort",
            modifier: .coldResistanceMultiplier(0.9)
        ),
        SkillDefinition(
            id: "coldResistance.2",
            family: .coldResistance,
            level: 2,
            name: "Coldwater training",
            description: "Maintaining performance and composure in frigid conditions",
            modifier: .coldResistanceMultiplier(0.8)
        ),
        SkillDefinition(
            id: "coldResistance.3",
            family: .coldResistance,
            level: 3,
            name: "Warm thoughts",
            description: "Staying warm through sheer power of will",
            modifier: .coldResistanceMultiplier(0.7)
        ),

        // Stress Management
        SkillDefinition(
            id: "stressManagement.1",
            family: .stressManagement,
            level: 1,
            name: "Calm Awareness",
            description: "Staying calm under pressure delays panic responses to warning signs.",
            modifier: .warningThresholdMultiplier(1.10)
        ),
        SkillDefinition(
            id: "stressManagement.2",
            family: .stressManagement,
            level: 2,
            name: "Focused Composure",
            description: "Trained composure allows you to push through situations that would rattle most divers.",
            modifier: .warningThresholdMultiplier(1.20)
        ),
        SkillDefinition(
            id: "stressManagement.3",
            family: .stressManagement,
            level: 3,
            name: "Ice Veins",
            description: "Total mental control. Critical situations feel routine.",
            modifier: .warningThresholdMultiplier(1.30)
        ),

        // Negotiator
        SkillDefinition(
            id: "negotiator.1",
            family: .negotiator,
            level: 1,
            name: "Haggler",
            description: "Get slightly better deals through basic bargaining.",
            modifier: .earningsMuliplier(1.3)
        ),
        SkillDefinition(
            id: "negotiator.2",
            family: .negotiator,
            level: 2,
            name: "Market Knowledge",
            description: "Knowing the local market can help you get better deals.",
            modifier: .earningsMuliplier(1.5)
        ),
        SkillDefinition(
            id: "negotiator.3",
            family: .negotiator,
            level: 3,
            name: "Silver Tongue",
            description: "Convince people to pay way more than they should.",
            modifier: .earningsMuliplier(2.0)
        ),

        // Multi-Gas Management
        SkillDefinition(
            id: "multiGasManagement.1",
            family: .multiGasManagement,
            level: 1,
            name: "Nitrox Switching",
            description: "Switch to oxygen-enriched nitrox during ascent to accelerate off-gassing.",
            modifier: .safeAscentSpeedMultiplier(1.15)
        ),
        SkillDefinition(
            id: "multiGasManagement.2",
            family: .multiGasManagement,
            level: 2,
            name: "Trimix Planning",
            description: "Plan helium-based mixes for the bottom phase and switch to nitrox for decompression.",
            modifier: .safeAscentSpeedMultiplier(1.30)
        ),
        SkillDefinition(
            id: "multiGasManagement.3",
            family: .multiGasManagement,
            level: 3,
            name: "Hypoxic Protocols",
            description: "Master hypoxic travel mixes and multi-stage decompression for maximum efficiency.",
            modifier: .safeAscentSpeedMultiplier(1.50)
        ),
    ]
}
