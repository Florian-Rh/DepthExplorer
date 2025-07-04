import Foundation

/// Model representing a single tissue compartment for inert gas (e.g., nitrogen) saturation.
struct TissueCompartment {
    /// The half-time of the tissue compartment in minutes (how quickly it saturates/desaturates)
    let halfTime: Double
    /// The current nitrogen pressure in the tissue (atm)
    var nitrogenPressure: Double

    /// Returns the time constant tau for exponential uptake/elimination
    private var timeConstant: Double { halfTime / log(2.0) }

    /// Updates the nitrogen pressure in the tissue by replaying a depth history.
    /// - Parameters:
    ///   - history: Array of (depth, seconds, mixture) tuples
    mutating func updateNitrogenPressure(history: [(depth: Int, seconds: Int, mixture: GasMixture)]) {
        for entry in history {
            let pressure = 1.0 + (Double(entry.depth) / 10.0)
            let ambientN2 = entry.mixture.partialPressure(of: .nitrogen, at: pressure)
            let delta = ambientN2 - nitrogenPressure
            let exponent = -Double(entry.seconds) / 60.0 / timeConstant
            nitrogenPressure += delta * (1 - exp(exponent))
        }
    }
} 