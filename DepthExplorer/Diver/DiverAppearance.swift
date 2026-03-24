import SwiftUI

/// Describes which visual tier each gear slot should render at.
/// Computed from the player's equipped gear and passed into `ScubaDiverView`.
struct DiverAppearance: Equatable {
    /// The equipped suit tier, or `nil` for no suit (swim trunks / bikini top).
    var suit: SuitTier?
    /// The equipped fins tier, or `nil` for barefoot.
    var fins: FinsTier?
    /// The equipped scuba gear tier, or `nil` for apnoe (no tank/regulator/BCD).
    var scubaGear: ScubaGearTier?
    /// The equipped stage tank tier, or `nil` for no stage tanks.
    var stageTanks: StageTankTier?

    /// Default appearance: no gear at all (naked diver).
    static let naked = DiverAppearance(suit: nil, fins: nil, scubaGear: nil, stageTanks: nil)

    /// Build appearance from a player profile's equipped gear.
    static func from(profile: PlayerProfile) -> DiverAppearance {
        var appearance = DiverAppearance.naked

        for (_, gearID) in profile.equippedGearIDs {
            switch gearID {
            // Suits
            case "suit.3mm":  appearance.suit = .wetsuit3mm
            case "suit.5mm":  appearance.suit = .wetsuit5mm
            case "suit.7mm":  appearance.suit = .wetsuit7mm
            case "suit.dry":  appearance.suit = .drysuit
            // Fins
            case "fins.basic":    appearance.fins = .basic
            case "fins.advanced": appearance.fins = .advanced
            case "fins.pro":      appearance.fins = .pro
            // Scuba gear
            case "tank.standard": appearance.scubaGear = .standard
            case "tank.double":   appearance.scubaGear = .twinset
            // Stage tanks
            case "stage.single":  appearance.stageTanks = .single
            case "stage.double":  appearance.stageTanks = .double
            default: break
            }
        }

        return appearance
    }
}

// MARK: - Suit tiers

enum SuitTier: Equatable {
    case wetsuit3mm
    case wetsuit5mm
    case wetsuit7mm
    case drysuit
}

// MARK: - Fins tiers

enum FinsTier: Equatable {
    case basic
    case advanced
    case pro
}

// MARK: - Scuba gear tiers

enum ScubaGearTier: Equatable {
    case standard
    case twinset
}
// MARK: - Stage tank tiers

enum StageTankTier: Equatable {
    /// A single stage tank clipped to one hip.
    case single
    /// Two stage tanks, one on each hip.
    case double
}

