//
//  ExternalPressureModel.swift
//  DepthExplorer
//
//  Created by Florian on 03.04.26.
//

import Foundation

class ExternalPressureModel: ObservableObject, DiveLimitationModel {
    @Published private(set) var currentPressure: Double = 1.0

    private let pressureRating: Double
    private let warningTolerance: Double

    init(pressureRating: Double, warningTolerance: Double = 1.0) {
        self.pressureRating = pressureRating
        self.warningTolerance = warningTolerance
    }

    /// Update internal state for this tick and evaluate warnings.
    /// - Returns: `.ok` if the dive can continue, or `.rescue(reason)` if the
    ///   model has reached a fatal condition.
    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        currentPressure = 1.0 + Double(context.depthMeters) / 10.0
        return evaluateWarning(depthMeters: Double(context.depthMeters), warningSystem: warningSystem)
    }

    /// Write this model's HUD-visible readings into the shared vitals snapshot.
    func updateVitals(_ vitals: inout DiveVitals) {
        vitals.externalPressure = currentPressure
    }

    /// Reset the model to its initial state for a new dive.
    func reset() {
        currentPressure = 1.0
    }

    // MARK: - Private

    private func evaluateWarning(depthMeters: Double, warningSystem: DiveWarningSystem) -> DiveLimitationResult {
        let warningThreshold = pressureRating * 0.8 * warningTolerance
        let criticalThreshold = pressureRating * 0.9 * warningTolerance
        let fatalThreshold = pressureRating * warningTolerance

        if currentPressure > fatalThreshold {
            warningSystem.set(DiveWarning(
                kind: .externalPressure,
                severity: .fatal,
                message: "Hull critically damaged! (\(String(format: "%.1f", currentPressure)) bar)"
            ))
            return .rescue("Hull imploded")
        } else if currentPressure > criticalThreshold {
            warningSystem.set(DiveWarning(
                kind: .externalPressure,
                severity: .critical,
                message: "Hull integrity compromised! (\(String(format: "%.1f", currentPressure)) bar)"
            ))
        } else if currentPressure > warningThreshold {
            warningSystem.set(DiveWarning(
                kind: .externalPressure,
                severity: .caution,
                message: "Approaching pressure limit (\(String(format: "%.1f", currentPressure)) bar)"
            ))
        } else {
            warningSystem.clear(.externalPressure)
        }
        return .ok
    }
}
