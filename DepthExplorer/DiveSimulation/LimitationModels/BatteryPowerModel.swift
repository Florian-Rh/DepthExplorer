//
//  BatteryPowerModel.swift
//  DepthExplorer
//
//  Created by Florian on 03.04.26.
//

import Foundation

class BatteryPowerModel: ObservableObject, DiveLimitationModel {
//    - Init with `batteryMinutes: Double` (simulated minutes of battery life)
//    - Battery drains each tick: base drain per simulated second
//    - When `abs(instantaneousAscentSpeed) > 0` (diver moving vertically), drain multiplier increases (e.g., 1.5x)
//    - Warning thresholds on battery fraction:
//      - Caution at 25%
//      - Critical at 10%
//      - Fatal at 0% → rescue
//    - Uses a new `DiveWarningKind.battery`
//    - Updates `vitals.batteryFraction` (new field)

    @Published private(set) var batteryMinutesRemaining: Double

    var batteryFraction: Double {
        max(0, batteryMinutesRemaining) / batteryMinutesMax
    }

    private let batteryMinutesMax: Double
    private let warningTolerance: Double


    init(batteryMinutes: Double, warningTolerance: Double) {
        self.batteryMinutesMax = batteryMinutes
        self.batteryMinutesRemaining = batteryMinutes
        self.warningTolerance = warningTolerance
    }


    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        drain(simulatedSeconds: context.simulatedSeconds, isMoving: abs(context.instantaneousAscentSpeed) > 0)
        return evaluateWarnings(warningSystem: warningSystem)
    }
    
    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.batteryFraction = batteryFraction
    }
    
    func reset() {
        batteryMinutesRemaining = batteryMinutesMax
    }

    // MARK: - Private

    private func drain(simulatedSeconds: Int, isMoving: Bool) {
        let baseDrain = Double(simulatedSeconds) / 60.0

        if isMoving {
            batteryMinutesRemaining -= baseDrain * 1.5
        } else {
            batteryMinutesRemaining -= baseDrain
        }
    }

    private func evaluateWarnings(warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        let warningFraction = 0.25 / warningTolerance
        let criticalFraction = 0.10 / warningTolerance

        // Emergency buffer accomodates the stress management skill, effectively allowing the battery to go below 0%
        let emergencyBuffer = warningFraction * (warningTolerance - 1.0)
        let fatalFraction = -emergencyBuffer

        // Use the raw fraction to check for the fatal threshold only, because it is allowed to go below 0
        let rawFraction = batteryMinutesRemaining / batteryMinutesMax

        if rawFraction <= fatalFraction {
            warningSystem.set(DiveWarning(
                kind: .batteryLevel,
                severity: .fatal,
                message: "Battery is dead!"
            ))
            return .rescue("Battery dead")
        } else if batteryFraction <= criticalFraction {
            warningSystem.set(DiveWarning(
                kind: .batteryLevel,
                severity: .critical,
                message: "Low battery! (\(Int(batteryFraction * 100))%)"
            ))
        } else if batteryFraction <= warningFraction {
            warningSystem.set(DiveWarning(
                kind: .batteryLevel,
                severity: .caution,
                message: "\(Int(batteryFraction * 100))% battery power remaining"
            ))
        } else {
             warningSystem.clear(.batteryLevel)
        }

        return .ok
    }

}
