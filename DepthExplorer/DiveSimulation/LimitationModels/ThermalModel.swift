import Foundation

/// Models the diver's thermal state during a dive.
///
/// Water temperature decreases with depth following a simplified thermocline.
/// The diver's body temperature drops over time proportionally to the temperature
/// difference between the body and the water. Gear (dry suit) will provide a
/// protection factor in Phase 2.
class ThermalModel: ObservableObject, DiveLimitationModel {
    @Published private(set) var bodyTemperature: Double

    /// Normal body temperature in °C.
    private let normalTemperature: Double = GameConstants.normalBodyTemperature

    /// Thermal protection from gear (0 = none, 1 = full insulation).
    private let protectionFactor: Double
    /// Warning threshold tolerance (1.0 = default, >1.0 = thresholds shift down, more tolerant).
    private let warningTolerance: Double

    private let baseCoolingRate: Double

    init(protectionFactor: Double = 0, coolingRate: Double = GameConstants.coolingRate, warningTolerance: Double = 1.0) {
        self.protectionFactor = protectionFactor
        self.warningTolerance = warningTolerance
        self.baseCoolingRate = coolingRate
        bodyTemperature = GameConstants.normalBodyTemperature
    }

    /// Water temperature in °C at a given depth.
    /// Simplified thermocline: surface temperature decreases linearly with depth,
    /// clamped at a minimum deep-water temperature.
    static func waterTemperature(atDepth depthMeters: Int) -> Double {
        let surface = GameConstants.surfaceWaterTemperature
        let minimum = GameConstants.deepWaterTemperature
        let cooled = surface - Double(depthMeters) * GameConstants.temperatureDropPerMeter
        return max(minimum, cooled)
    }

    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        update(simulatedSeconds: context.simulatedSeconds, depthMeters: context.depthMeters)
        return evaluateWarnings(warningSystem: warningSystem)
    }

    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.bodyTemperature = bodyTemperature
    }

    func reset() {
        bodyTemperature = normalTemperature
    }

    // MARK: - Private

    /// Update body temperature for this tick.
    private func update(simulatedSeconds: Int, depthMeters: Int) {
        let waterTemp = Self.waterTemperature(atDepth: depthMeters)
        let difference = bodyTemperature - waterTemp // positive when body is warmer than water

        guard difference > 0 else { return } // water is warmer; no cooling

        let effectiveCoolingRate = baseCoolingRate * (1.0 - protectionFactor)
        let coolingPerMinute = difference * effectiveCoolingRate
        let cooling = coolingPerMinute * (Double(simulatedSeconds) / 60.0)
        bodyTemperature = max(waterTemp, bodyTemperature - cooling)
    }

    /// Evaluate current body temperature and update the warning system accordingly.
    private func evaluateWarnings(warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        // Tolerance > 1 pushes thresholds further from normal body temperature.
        // e.g. normal=37, fatal=34 → distance=3 → at 1.2× tolerance → fatal=37-3*1.2=33.4
        let normal = GameConstants.normalBodyTemperature
        let fatalThreshold = normal - (normal - GameConstants.hypothermiaFatalThreshold) * warningTolerance
        let criticalThreshold = normal - (normal - GameConstants.hypothermiaCriticalThreshold) * warningTolerance
        let warningThreshold = normal - (normal - GameConstants.hypothermiaWarningThreshold) * warningTolerance

        if bodyTemperature <= fatalThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .fatal,
                message: "Severe hypothermia! (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
            return .rescue("Hypothermia")
        } else if bodyTemperature <= criticalThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .critical,
                message: "Hypothermia setting in (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
        } else if bodyTemperature <= warningThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .caution,
                message: "Getting cold (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
        } else {
            warningSystem.clear(.thermal)
        }
        return .ok
    }
}
