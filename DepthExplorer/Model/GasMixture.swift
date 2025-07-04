import Foundation

/// Enum representing different gases that can be part of a mixture.
enum Gas: String, CaseIterable, Codable, Hashable {
    case nitrogen = "N2"
    case oxygen = "O2"
    case argon = "Ar"
    case carbonDioxide = "CO2"
    case neon = "Ne"
    case helium = "He"
    case methane = "CH4"
    case krypton = "Kr"
    case hydrogen = "H2"
    case xenon = "Xe"
    // Add more gases as needed
}

/// Model representing a gas mixture with concentrations for each gas.
struct GasMixture: Codable, Hashable {
    /// Dictionary mapping each gas to its concentration (as a fraction, e.g., 0.78 for 78%)
    var concentrations: [Gas: Double]

    /// Initializes a GasMixture, ensuring the concentrations add up to 1.0 (with a small tolerance for floating point errors).
    init(concentrations: [Gas: Double]) {
        let total = concentrations.values.reduce(0, +)
        let tolerance = 0.0001 // Allow a small margin for floating point imprecision
        guard abs(total - 1.0) <= tolerance else {
            fatalError("Gas concentrations must add up to 1.0. Current total: \(total)")
        }
        self.concentrations = concentrations
    }

    static let oxygen = GasMixture(concentrations: [
        .oxygen: 1.0
    ])

    /// Standard air composition at sea level (fractions by volume)
    static let air = GasMixture(concentrations: [
        .nitrogen: 0.79,
        .oxygen: 0.21
    ])

    /// Common Nitrox 32 (EAN32): 0.32 O2, 0.68 N2
    static let nitrox32 = GasMixture(concentrations: [
        .nitrogen: 0.68,
        .oxygen: 0.32
    ])

    /// Common Nitrox 36 (EAN36): 0.36 O2, 0.64 N2
    static let nitrox36 = GasMixture(concentrations: [
        .nitrogen: 0.64,
        .oxygen: 0.36
    ])

    /// Common Nitrox 40 (EAN40): 0.40 O2, 0.60 N2
    static let nitrox40 = GasMixture(concentrations: [
        .nitrogen: 0.60,
        .oxygen: 0.40
    ])

    /// Common Trimix 21/35: 0.21 O2, 0.35 He, 0.44 N2
    static let trimix2135 = GasMixture(concentrations: [
        .nitrogen: 0.44,
        .oxygen: 0.21,
        .helium: 0.35
    ])

    /// Calculates the partial pressure of a given gas at a specified pressure in atmospheres (ATM).
    /// - Parameters:
    ///   - gas: The gas for which to calculate the partial pressure.
    ///   - pressureATM: The total pressure of the mixture in atmospheres (ATM).
    /// - Returns: The partial pressure of the specified gas in atmospheres (ATM).
    func partialPressure(of gas: Gas, at pressureATM: Double) -> Double {
        guard let fraction = concentrations[gas] else { return 0.0 }
        return fraction * pressureATM
    }
} 
