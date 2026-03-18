import Foundation

/// Tracks the diver's remaining air supply in bar.
/// Consumption increases with depth following Boyle's law:
/// actual consumption = SAC rate × ambient pressure.
class AirSupplyModel: ObservableObject, DiveLimitationModel {
    @Published private(set) var remainingBar: Double

    private let capacity: Double
    private let sacRate: Double
    /// Warning threshold tolerance (1.0 = default, >1.0 = thresholds shift down, more tolerant).
    private let warningTolerance: Double

    init(capacity: Double = GameConstants.tankCapacity, sacRate: Double = GameConstants.sacRate, warningTolerance: Double = 1.0) {
        self.capacity = capacity
        self.sacRate = sacRate
        self.warningTolerance = warningTolerance
        self.remainingBar = capacity
    }

    /// Fraction of air remaining (0.0–1.0), clamped for display.
    var fraction: Double {
        max(0, remainingBar) / capacity
    }

    /// The bar value shown to the player. Clamps at 0 even when the internal
    /// value is negative (breath-hold zone from stress management skill).
    var displayBar: Double {
        max(0, remainingBar)
    }

    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        consume(simulatedSeconds: context.simulatedSeconds, depthMeters: context.depthMeters)
        return evaluateWarnings(warningSystem: warningSystem)
    }

    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.remainingBar = displayBar
        vitals.airFraction = fraction
    }

    func reset() {
        remainingBar = capacity
    }

    // MARK: - Private

    /// Consume air for a given simulated time increment at the specified depth.
    private func consume(simulatedSeconds: Int, depthMeters: Int) {
        let ambientPressure = 1.0 + Double(depthMeters) / 10.0
        let consumptionPerMinute = sacRate * ambientPressure
        let consumed = consumptionPerMinute * (Double(simulatedSeconds) / 60.0)
        remainingBar -= consumed
    }

    /// Evaluate current air level and update the warning system accordingly.
    private func evaluateWarnings(warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        // Tolerance > 1 pushes thresholds lower, giving the diver more margin.
        let criticalThreshold = GameConstants.airCriticalThreshold / warningTolerance
        let warningThreshold = GameConstants.airWarningThreshold / warningTolerance

        // With stress management, the diver can "hold their breath" after the tank
        // empties. The fatal threshold shifts below 0 proportionally to the tolerance
        // beyond 1.0. At tolerance 1.0 → fatal at 0. At 1.3 → fatal at -0.3 × critical.
        let breathHoldBuffer = GameConstants.airCriticalThreshold * (warningTolerance - 1.0)
        let fatalThreshold = -breathHoldBuffer

        if remainingBar <= fatalThreshold {
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .fatal,
                message: "Out of air!"
            ))
            return .rescue("Out of air")
        } else if remainingBar <= 0 {
            // Breath-hold zone: tank reads 0 but diver is still going
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .critical,
                message: "Holding breath!"
            ))
        } else if remainingBar <= criticalThreshold {
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .critical,
                message: "\(Int(remainingBar)) bar remaining"
            ))
        } else if remainingBar <= warningThreshold {
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .caution,
                message: "\(Int(remainingBar)) bar remaining"
            ))
        } else {
            warningSystem.clear(.airSupply)
        }
        return .ok
    }
}
