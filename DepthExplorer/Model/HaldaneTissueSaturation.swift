import Foundation

/// Model representing a single tissue compartment for inert gas (e.g., nitrogen) saturation using the Haldane model.
struct HaldaneTissueSaturation: TissueSaturationModel {
    let halfTime: Double
    var nitrogenPressure: Double

    var safeDesaturationSpeed: Double {
        halfTime <= 60 ? 10.0 : 5.0
    }

    private var timeConstant: Double {
        halfTime / log(2.0)
    }

    // MARK: - TissueSaturationModel

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
