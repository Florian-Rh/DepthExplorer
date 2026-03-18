import Foundation

/// Identifies a skill family. Each family is a linear chain of levels.
enum SkillFamily: String, Codable, CaseIterable {
    case breathingTechniques
    case finKicking
    case stressManagement

    var displayName: String {
        switch self {
        case .breathingTechniques: "Breathing"
        case .finKicking: "Fin Kicking"
        case .stressManagement: "Stress Mgmt"
        }
    }

    var icon: String {
        switch self {
        case .breathingTechniques: "lungs.fill"
        case .finKicking: "figure.pool.swim"
        case .stressManagement: "brain.head.profile"
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
    ]
}
