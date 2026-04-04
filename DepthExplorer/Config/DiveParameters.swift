import Foundation

/// Describes how the diver is breathing and protected during a dive.
enum DiveMode: Equatable {
    /// Breath-hold diving — no equipment, lungs only.
    case apnoe
    /// Standard scuba equipment — compressed gas, pressure-sensitive consumption.
    case scuba
    /// Atmospheric diving suit — hard suit with battery power and depth rating.
    case ads
}

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

    let coolingRate: Double

    let earningsFactor: Double

    /// The active dive mode for this loadout.
    let diveMode: DiveMode

    /// Multiplier for safe ascent speed (1.0 = default, >1.0 = faster ascent allowed).
    /// Driven by the Multi-Gas Management skill tree.
    let safeAscentSpeedMultiplier: Double

    let pressureRating: Double

    let batteryMinutes: Double

    /// Maximum number of trash items the diver can carry per dive.
    let carryCapacity: Int

    /// Convenience: whether the diver has scuba gear equipped (vs. apnoe or ADS).
    var hasScubaGear: Bool { diveMode == .scuba }

    /// Convenience: whether the diver is using an atmospheric diving suit.
    var hasADS: Bool { if case .ads = diveMode { return true } else { return false } }

    /// Compute effective dive parameters from the current profile state.
    ///
    /// 1. Start from apnoe (no-gear) base values
    /// 2. Apply gear modifiers (absolute replacements)
    /// 3. Apply skill modifiers (multiplicative, highest level per family only)
    static func from(profile: PlayerProfile) -> DiveParameters {
        // Start with apnoe (no-gear) defaults
        var scrollSpeed = GameConstants.apnoeScrollSpeed
        var horizontalSpeed = GameConstants.apnoeHorizontalSpeed
        var coolingRate = GameConstants.coolingRate
        var earningsMultiplier = 1.0
        var airCapacity = 0.0
        var sacRate = GameConstants.sacRate
        var thermalProtection = 0.0
        var warningTolerance = 1.0
        var safeAscentMultiplier = 1.0
        var carryCapacity = GameConstants.defaultCarryCapacity
        var pressureRating: Double = 0.0
        var batteryMinutes: Double = 0.0

        var diveMode: DiveMode = .apnoe
        // Apply equipped gear
        for (_, gearID) in profile.equippedGearIDs {
            guard let gear = GearDefinition.allGear.first(where: { $0.id == gearID }) else { continue }
            switch gear.modifier {
            case .movementSpeed(let scroll, let horiz):
                scrollSpeed += scroll
                horizontalSpeed += horiz
            case .thermalProtection(let factor):
                thermalProtection = factor
            case .airCapacity(let bar):
                airCapacity += bar
                diveMode = .scuba
            case .carryCapacity(let count):
                carryCapacity = count
            case .atmosphericDivingSuit(let air, let battery, let pressure):
                airCapacity += air
                pressureRating = pressure
                batteryMinutes = battery
                diveMode = .ads
            }
        }

        if diveMode == .apnoe {
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
            case .safeAscentSpeedMultiplier(let multiplier):
                safeAscentMultiplier *= multiplier
            case .coldResistanceMultiplier(let multiplier):
                coolingRate *= multiplier
            case .earningsMuliplier(let multiplier):
                earningsMultiplier *= multiplier
            }
        }

        return DiveParameters(
            scrollSpeed: scrollSpeed,
            diverHorizontalSpeed: horizontalSpeed,
            airCapacity: airCapacity,
            sacRate: sacRate,
            thermalProtectionFactor: thermalProtection,
            warningThresholdTolerance: warningTolerance,
            coolingRate: coolingRate,
            earningsFactor: earningsMultiplier,
            diveMode: diveMode,
            safeAscentSpeedMultiplier: safeAscentMultiplier,
            pressureRating: pressureRating,
            batteryMinutes: batteryMinutes,
            carryCapacity: carryCapacity
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
        coolingRate: GameConstants.coolingRate,
        earningsFactor: 1.0,
        diveMode: .apnoe,
        safeAscentSpeedMultiplier: 1.0,
        pressureRating: 0.0,
        batteryMinutes: 0.0,
        carryCapacity: GameConstants.defaultCarryCapacity
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
