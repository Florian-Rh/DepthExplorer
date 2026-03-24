import Foundation

/// Context passed to each limitation model on every simulation tick.
struct DiveTickContext {
    /// Number of simulated seconds elapsed this tick.
    let simulatedSeconds: Int
    /// Current depth in meters.
    let depthMeters: Int
    /// Instantaneous ascent speed in m/s of real time (positive = ascending).
    let instantaneousAscentSpeed: Double
}

/// Result returned by a limitation model after evaluating a tick.
struct DiveLimitationResult {
    /// If non-nil, the model has reached a fatal condition and the dive should
    /// be terminated with this reason string.
    let rescueReason: String?

    static let ok = DiveLimitationResult(rescueReason: nil)

    static func rescue(_ reason: String) -> DiveLimitationResult {
        DiveLimitationResult(rescueReason: reason)
    }
}

/// Aggregated snapshot of HUD-visible readings produced by limitation models.
///
/// Each field is optional so that `DiveVitals` only contains data for whichever
/// limitation models are active. The HUD checks for `nil` to decide which
/// instruments to display.
struct DiveVitals: Equatable {
    // Air supply
    var remainingBar: Double?
    var airFraction: Double?

    // Thermal
    var bodyTemperature: Double?

    // Decompression / ascent
    var ascentSpeed: Double?
}

/// A modular dive limitation that can trigger warnings and rescue conditions.
///
/// Conform to this protocol to add new survival factors to the dive simulation.
/// The simulation evaluates all registered models each tick, without knowledge
/// of their specific logic.
protocol DiveLimitationModel: AnyObject, ObservableObject {
    /// Update internal state for this tick and evaluate warnings.
    /// - Returns: `.ok` if the dive can continue, or `.rescue(reason)` if the
    ///   model has reached a fatal condition.
    func tick(context: DiveTickContext, warningSystem: DiveWarningSystem) -> DiveLimitationResult

    /// Write this model's HUD-visible readings into the shared vitals snapshot.
    func updateVitals(_ vitals: inout DiveVitals)

    /// Reset the model to its initial state for a new dive.
    func reset()
}
