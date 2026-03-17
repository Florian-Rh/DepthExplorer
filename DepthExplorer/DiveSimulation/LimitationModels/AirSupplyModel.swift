import Foundation

/// Tracks the diver's remaining air supply in bar.
/// Consumption increases with depth following Boyle's law:
/// actual consumption = SAC rate × ambient pressure.
class AirSupplyModel: ObservableObject, DiveLimitationModel {
    @Published private(set) var remainingBar: Double

    private let capacity: Double

    init(capacity: Double = GameConstants.tankCapacity) {
        self.capacity = capacity
        self.remainingBar = capacity
    }

    /// Fraction of air remaining (0.0–1.0).
    var fraction: Double {
        remainingBar / capacity
    }

    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        consume(simulatedSeconds: context.simulatedSeconds, depthMeters: context.depthMeters)
        return evaluateWarnings(warningSystem: warningSystem)
    }

    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.remainingBar = remainingBar
        vitals.airFraction = fraction
    }

    func reset() {
        remainingBar = capacity
    }

    // MARK: - Private

    /// Consume air for a given simulated time increment at the specified depth.
    private func consume(simulatedSeconds: Int, depthMeters: Int) {
        let ambientPressure = 1.0 + Double(depthMeters) / 10.0
        let consumptionPerMinute = GameConstants.sacRate * ambientPressure
        let consumed = consumptionPerMinute * (Double(simulatedSeconds) / 60.0)
        remainingBar = max(0, remainingBar - consumed)
    }

    /// Evaluate current air level and update the warning system accordingly.
    private func evaluateWarnings(warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        if remainingBar <= 0 {
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .fatal,
                message: "Out of air!"
            ))
            return .rescue("Out of air")
        } else if remainingBar <= GameConstants.airCriticalThreshold {
            warningSystem.set(DiveWarning(
                kind: .airSupply,
                severity: .critical,
                message: "\(Int(remainingBar)) bar remaining"
            ))
        } else if remainingBar <= GameConstants.airWarningThreshold {
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
