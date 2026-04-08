import Foundation

/// Pure, stateless calculator for the player's level and progress toward the next level.
///
/// Level 1 starts at 0 XP. Each subsequent level requires progressively more XP,
/// following a polynomial curve: `baseLevelUpXP × level^levelUpExponent`.
struct LevelProgression {
    /// The player's current level (1-based).
    let level: Int
    /// XP accumulated toward the *next* level.
    let currentLevelXP: Int
    /// Total XP required to advance from the current level to the next.
    let requiredLevelXP: Int

    /// Fractional progress toward the next level (0…1).
    var progress: Double {
        guard requiredLevelXP > 0 else { return 0 }
        return min(1, Double(currentLevelXP) / Double(requiredLevelXP))
    }

    /// XP still needed to reach the next level.
    var xpToNextLevel: Int {
        max(0, requiredLevelXP - currentLevelXP)
    }

    /// Total XP needed to reach the start of a given level.
    static func totalXP(forLevel target: Int) -> Int {
        guard target > 1 else { return 0 }
        let baseXP = GameConstants.baseLevelUpXP
        let scale = GameConstants.levelUpExponent
        var total = 0
        for lvl in 1..<target {
            total += Int(Double(baseXP) * pow(Double(lvl), scale))
        }
        return total
    }

    /// Compute the player's level progression from their total XP.
    static func from(totalXP: Int) -> LevelProgression {
        let baseXP = GameConstants.baseLevelUpXP
        let scale = GameConstants.levelUpExponent

        var level = 1
        var remaining = totalXP
        var threshold = baseXP

        while remaining >= threshold {
            remaining -= threshold
            level += 1
            threshold = Int(Double(baseXP) * pow(Double(level), scale))
        }

        return LevelProgression(
            level: level,
            currentLevelXP: remaining,
            requiredLevelXP: threshold
        )
    }
}
