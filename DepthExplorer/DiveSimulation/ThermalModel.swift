import Foundation

/// Models the diver's thermal state during a dive.
///
/// Water temperature decreases with depth following a simplified thermocline.
/// The diver's body temperature drops over time proportionally to the temperature
/// difference between the body and the water. Gear (dry suit) will provide a
/// protection factor in Phase 2.
class ThermalModel: ObservableObject {
    @Published private(set) var bodyTemperature: Double

    /// Normal body temperature in °C.
    private let normalTemperature: Double = GameConstants.normalBodyTemperature

    init() {
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

    /// Update body temperature for this tick.
    /// - Parameters:
    ///   - simulatedSeconds: Number of simulated seconds elapsed this tick.
    ///   - depthMeters: Current depth in meters.
    ///   - protectionFactor: Thermal protection from gear (0 = none, 1 = full insulation). Phase 2.
    func update(simulatedSeconds: Int, depthMeters: Int, protectionFactor: Double = 0) {
        let waterTemp = Self.waterTemperature(atDepth: depthMeters)
        let difference = bodyTemperature - waterTemp // positive when body is warmer than water

        guard difference > 0 else { return } // water is warmer; no cooling

        let effectiveCoolingRate = GameConstants.coolingRate * (1.0 - protectionFactor)
        let coolingPerMinute = difference * effectiveCoolingRate
        let cooling = coolingPerMinute * (Double(simulatedSeconds) / 60.0)
        bodyTemperature = max(waterTemp, bodyTemperature - cooling)
    }

    /// Evaluate current body temperature and update the warning system accordingly.
    func evaluateWarnings(warningSystem: DiveWarningSystem) {
        if bodyTemperature <= GameConstants.hypothermiaFatalThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .fatal,
                message: "Severe hypothermia! (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
        } else if bodyTemperature <= GameConstants.hypothermiaCriticalThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .critical,
                message: "Hypothermia setting in (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
        } else if bodyTemperature <= GameConstants.hypothermiaWarningThreshold {
            warningSystem.set(DiveWarning(
                kind: .thermal,
                severity: .caution,
                message: "Getting cold (\(String(format: "%.1f", bodyTemperature))°C)"
            ))
        } else {
            warningSystem.clear(.thermal)
        }
    }

    /// Reset to normal body temperature for a new dive.
    func reset() {
        bodyTemperature = normalTemperature
    }
}
