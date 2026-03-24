import Foundation

/// Computed gameplay parameters for a single dive, derived from
/// base constants + equipped gear + acquired skills.
///
/// Created when a dive session begins (or when the player changes loadout).
/// Passed into limitation models and movement systems. Pure value type.
struct DiveParameters {
    /// Vertical scroll speed (pts per frame at full joystick deflection).
    let scrollSpeed: CGFloat
    /// Horizontal movement speed (pts per frame at full joystick deflection).
    let diverHorizontalSpeed: CGFloat
    /// Air capacity in bar (scuba gear cylinder or lungs when apnoe).
    let airCapacity: Double
    /// Surface air consumption rate in bar per simulated minute.
    let sacRate: Double
    /// Thermal protection factor (0 = none, 1 = full insulation).
    let thermalProtectionFactor: Double
    /// Warning threshold tolerance multiplier (1.0 = default, >1.0 = more tolerant).
    /// Shifts caution/critical/fatal thresholds to give the diver more margin.
    let warningThresholdTolerance: Double

    /// Whether the diver has scuba gear equipped (vs. apnoe / breath-hold diving).
    let hasScubaGear: Bool

    /// Compute effective dive parameters from the current profile state.
    ///
    /// 1. Start from apnoe (no-gear) base values
    /// 2. Apply gear modifiers (absolute replacements)
    /// 3. Apply skill modifiers (multiplicative, highest level per family only)
    static func from(profile: PlayerProfile) -> DiveParameters {
        // Start with apnoe (no-gear) defaults
        var scrollSpeed = GameConstants.apnoeScrollSpeed
        var horizontalSpeed = GameConstants.apnoeHorizontalSpeed
        var airCapacity = 0.0
        var sacRate = GameConstants.sacRate
        var thermalProtection = 0.0
        var warningTolerance = 1.0
        var hasScubaGear = false

        // Apply equipped gear
        for (_, gearID) in profile.equippedGearIDs {
            guard let gear = GearDefinition.allGear.first(where: { $0.id == gearID }) else { continue }
            switch gear.modifier {
            case .movementSpeed(let scroll, let horiz):
                scrollSpeed = scroll
                horizontalSpeed = horiz
            case .thermalProtection(let factor):
                thermalProtection = factor
            case .airCapacity(let bar):
                airCapacity += bar
                hasScubaGear = true
            }
        }
        if !hasScubaGear {
            airCapacity += GameConstants.apnoeLungCapacity
        }

        // Apply skills (highest level per family only)
        let effectiveSkills = Self.effectiveSkills(from: profile.acquiredSkillIDs)
        for skill in effectiveSkills {
            switch skill.modifier {
            case .sacRateMultiplier(let multiplier):
                sacRate *= multiplier
            case .movementSpeedMultiplier(let multiplier):
                scrollSpeed *= multiplier
                horizontalSpeed *= multiplier
            case .warningThresholdMultiplier(let multiplier):
                warningTolerance *= multiplier
            }
        }

        return DiveParameters(
            scrollSpeed: scrollSpeed,
            diverHorizontalSpeed: horizontalSpeed,
            airCapacity: airCapacity,
            sacRate: sacRate,
            thermalProtectionFactor: thermalProtection,
            warningThresholdTolerance: warningTolerance,
            hasScubaGear: hasScubaGear
        )
    }

    /// Default parameters with no gear or skills (apnoe diving).
    static let defaults = DiveParameters(
        scrollSpeed: GameConstants.apnoeScrollSpeed,
        diverHorizontalSpeed: GameConstants.apnoeHorizontalSpeed,
        airCapacity: GameConstants.apnoeLungCapacity,
        sacRate: GameConstants.sacRate,
        thermalProtectionFactor: 0,
        warningThresholdTolerance: 1.0,
        hasScubaGear: false
    )

    // MARK: - Private

    /// Returns the single highest-level acquired skill per family.
    private static func effectiveSkills(from ids: Set<String>) -> [SkillDefinition] {
        var bestPerFamily: [SkillFamily: SkillDefinition] = [:]
        for id in ids {
            guard let skill = SkillDefinition.allSkills.first(where: { $0.id == id }) else { continue }
            if let existing = bestPerFamily[skill.family], existing.level >= skill.level {
                continue
            }
            bestPerFamily[skill.family] = skill
        }
        return Array(bestPerFamily.values)
    }
}
