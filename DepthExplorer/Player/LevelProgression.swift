import Foundation

/// Pure, stateless calculator for the player's level and progress toward the next level.
///
/// Level 1 starts at 0 XP. Each subsequent level requires progressively more XP,
/// scaled by `GameConstants.levelUpScalingFactor`.
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

    /// Compute the player's level progression from their total XP.
    static func from(totalXP: Int) -> LevelProgression {
        let baseXP = GameConstants.baseLevelUpXP
        let scale = GameConstants.levelUpScalingFactor

//        let nextLevelEntry = GameConstants.levelDefinitions.first(where: { $0.value > totalXP})!
//        let currentLevel = nextLevelEntry.key - 1
//        let currentLevelXp = GameConstants.levelDefinitions[currentLevel]!
//
//        return LevelProgression(
//            level: currentLevel,
//            currentLevelXP: currentLevelXp,
//            requiredLevelXP: nextLevelEntry.value
//        )

        var level = 1
        var remaining = totalXP
        var threshold = baseXP

        while remaining >= threshold {
            remaining -= threshold
            level += 1
            threshold = Int(Double(baseXP) * pow(scale, Double(level - 1)))
        }

        return LevelProgression(
            level: level,
            currentLevelXP: remaining,
            requiredLevelXP: threshold
        )
    }
}
