import Foundation

/// Protocol for tissue saturation models
protocol TissueSaturationModel {
    /// The current nitrogen pressure in the tissue (atm)
    var nitrogenPressure: Double { get }
    /// The safe desaturation speed (maximum safe ascent speed in m/min)
    var safeDesaturationSpeed: Double { get }
    /// Updates the nitrogen pressure in the tissue by replaying a depth history.
    /// - Parameters:
    ///   - history: Array of (depth, seconds, mixture) tuples
    mutating func updateNitrogenPressure(history: [(depth: Int, seconds: Int, mixture: GasMixture)])
} 
