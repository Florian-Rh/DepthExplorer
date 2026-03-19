import Foundation

/// Information about a single item discovered during a dive.
struct DiscoveredItemInfo {
    let name: String
    let depthMeters: Double
}

/// Input parameters describing a completed dive, used to calculate XP.
struct DiveResult {
    let maxDepthMeters: Int
    let diveTimeSeconds: Int
    let discoveredItems: [DiscoveredItemInfo]
    /// Previous personal depth record in meters. `nil` if this was the first dive.
    let previousRecordDepth: Int?
    /// Previous personal time record in simulated seconds. `nil` if this was the first dive.
    let previousRecordTime: Int?
}

/// Itemized XP breakdown returned by the calculator.
struct ExperienceBreakdown {
    /// XP earned from dive depth and duration combined.
    let diveProfileXP: Int
    /// Bonus XP for breaking personal records.
    let personalRecordXP: Int
    /// XP earned from discovered Knowledgeable Items.
    let discoveryXP: Int

    /// Per-item detail for UI display.
    let itemDetails: [(name: String, xp: Int)]
    /// Whether the diver broke their depth record on this dive.
    let brokeDepthRecord: Bool
    /// Whether the diver broke their time record on this dive.
    let brokeTimeRecord: Bool

    /// Total XP earned this dive.
    var totalXP: Int { diveProfileXP + personalRecordXP + discoveryXP }
}

/// Pure, stateless XP calculator. Takes dive parameters in, returns XP breakdown out.
///
/// All tuning constants are grouped here so they can be adjusted independently
/// without touching the rest of the codebase. Designed for easy unit testing.
struct ExperienceCalculator {

    // MARK: - Tuning Constants

    /// XP awarded per meter of max depth reached.
    static let depthXPPerMeter: Double = 0.5

    /// XP awarded per simulated minute of dive time.
    static let durationXPPerMinute: Double = 1.0

    /// Minimum percentage improvement over the previous record to qualify for a bonus.
    /// e.g. 5.0 means the record must be beaten by at least 5%.
    static let recordMinimumImprovementPercent: Double = 5.0

    /// Bonus XP for breaking the personal depth record.
    static let depthRecordBonus: Int = 50

    /// Bonus XP for breaking the personal time record.
    static let timeRecordBonus: Int = 50

    /// Base XP for each Knowledgeable Item discovered.
    static let baseItemXP: Int = 50

    /// Additional XP per meter of depth at which the item was found.
    static let itemDepthBonusPerMeter: Double = 0.1

    // MARK: - Calculation

    func calculate(from result: DiveResult) -> ExperienceBreakdown {
        // Dive profile: depth contributes more than duration
        let depthXP = Int(Double(result.maxDepthMeters) * Self.depthXPPerMeter)
        let durationMinutes = Double(result.diveTimeSeconds) / 60.0
        let durationXP = Int(durationMinutes * Self.durationXPPerMinute)
        let diveProfileXP = depthXP + durationXP

        // Personal records — percentage-based scaling with minimum threshold.
        // The record must be beaten by at least `recordMinimumImprovementPercent` to qualify.
        // XP is rewarded based on the margin by which the record was broken
        var personalRecordXP = 0
        let brokeDepth: Bool
        if let previousDepth = result.previousRecordDepth, previousDepth > 0 {
            let improvementPercent = Double(result.maxDepthMeters - previousDepth) / Double(previousDepth) * 100.0
            if improvementPercent >= Self.recordMinimumImprovementPercent {
                personalRecordXP += result.maxDepthMeters - previousDepth // Int(improvementPercent * Self.depthRecordXPPerPercent)
                brokeDepth = true
            } else {
                brokeDepth = false
            }
        } else {
            brokeDepth = false
        }

        let brokeTime: Bool
        if let previousTime = result.previousRecordTime, previousTime > 0 {
            let improvementPercent = Double(result.diveTimeSeconds - previousTime) / Double(previousTime) * 100.0
            if improvementPercent >= Self.recordMinimumImprovementPercent {
                personalRecordXP += (result.diveTimeSeconds - previousTime) / 12 // Int(improvementPercent * Self.timeRecordXPPerPercent)
                brokeTime = true
            } else {
                brokeTime = false
            }
        } else {
            brokeTime = false
        }

        // Discovered items — deeper items are worth more
        var itemDetails: [(name: String, xp: Int)] = []
        var discoveryXP = 0
        for item in result.discoveredItems {
            let xp = Self.baseItemXP + Int(item.depthMeters * Self.itemDepthBonusPerMeter)
            itemDetails.append((name: item.name, xp: xp))
            discoveryXP += xp
        }

        return ExperienceBreakdown(
            diveProfileXP: diveProfileXP,
            personalRecordXP: personalRecordXP,
            discoveryXP: discoveryXP,
            itemDetails: itemDetails,
            brokeDepthRecord: brokeDepth,
            brokeTimeRecord: brokeTime
        )
    }
}
