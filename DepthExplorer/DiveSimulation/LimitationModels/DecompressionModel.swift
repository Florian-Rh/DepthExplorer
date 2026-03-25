import Foundation

/// Models decompression sickness (DCS) risk based on ascent speed.
///
/// Tracks a smoothed ascent speed and compares it against a safe threshold.
/// Ascending too quickly triggers escalating warnings and ultimately a rescue.
class DecompressionModel: ObservableObject, DiveLimitationModel {
    /// Smoothed ascent speed in meters per real second. Positive = ascending.
    @Published private(set) var ascentSpeed: Double = 0
    /// Warning threshold tolerance (1.0 = default, >1.0 = thresholds shift up, more tolerant).
    private let warningTolerance: Double
    /// Multiplier for safe ascent speed (1.0 = default, >1.0 = faster ascent allowed).
    private let safeAscentSpeedMultiplier: Double

    init(warningTolerance: Double = 1.0, safeAscentSpeedMultiplier: Double = 1.0) {
        self.warningTolerance = warningTolerance
        self.safeAscentSpeedMultiplier = safeAscentSpeedMultiplier
    }

    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        updateAscentSpeed(instantaneousSpeed: context.instantaneousAscentSpeed)

        if ascentSpeed > 0 {
            return evaluateWarning(depthMeters: Double(context.depthMeters), warningSystem: warningSystem)
        } else {
            warningSystem.clear(.decompression)
            return .ok
        }
    }

    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.ascentSpeed = ascentSpeed
    }

    func reset() {
        ascentSpeed = 0
    }

    // MARK: - Private

    /// Returns a multiplier (≥ 1.0) for the safe ascent speed based on current depth.
    /// Deeper = higher multiplier = more forgiving.
    /// At the surface the multiplier is 1.0 (baseline).
    private func depthLeniencyMultiplier(depth: Double) -> Double {
        guard depth > 0 else { return 1.0 }
        let normalised = depth / GameConstants.dcsReferenceDepth
        let curved = pow(normalised, GameConstants.dcsDepthExponent)
        return 1.0 + GameConstants.dcsDepthScale * curved
    }

    private func updateAscentSpeed(instantaneousSpeed: Double) {
        if instantaneousSpeed > 0 {
            // Ascending: blend toward instantaneous speed
            ascentSpeed += (instantaneousSpeed - ascentSpeed) * GameConstants.ascentSpeedBuildupRate
        } else {
            // Stopped or descending: decay toward 0
            ascentSpeed *= (1.0 - GameConstants.ascentSpeedDecayRate)
            if ascentSpeed < 0.5 { ascentSpeed = 0 }
        }
    }

    private func evaluateWarning(depthMeters: Double, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        let safeSpeed = GameConstants.safeAscentSpeed * safeAscentSpeedMultiplier * depthLeniencyMultiplier(depth: depthMeters)
        let ratio = ascentSpeed / safeSpeed

        // Tolerance > 1 multiplies the fraction thresholds, requiring higher speed to trigger.
        if ratio >= GameConstants.dcsFatalFraction * warningTolerance {
            warningSystem.set(DiveWarning(
                kind: .decompression,
                severity: .fatal,
                message: "Ascending way too fast! (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
            return .rescue("Decompression sickness")
        } else if ratio >= GameConstants.dcsCriticalFraction * warningTolerance {
            warningSystem.set(DiveWarning(
                kind: .decompression,
                severity: .critical,
                message: "Ascending too fast! (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
        } else if ratio >= GameConstants.dcsWarningFraction * warningTolerance {
            warningSystem.set(DiveWarning(
                kind: .decompression,
                severity: .caution,
                message: "Slow your ascent (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
        } else {
            warningSystem.clear(.decompression)
        }
        return .ok
    }
}
