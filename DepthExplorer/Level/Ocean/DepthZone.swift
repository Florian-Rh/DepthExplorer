import SwiftUI

/// Configuration for particle effects within a depth zone.
struct ParticleConfig {
    /// Visual type of the particles.
    let type: ParticleType
    /// Number of particles per screen-height of zone visible area.
    let density: Int
    /// Base color of the particles.
    let color: Color
    /// Vertical drift speed in points per second (negative = upward).
    let speed: Double
    /// Size range for individual particles.
    let sizeRange: ClosedRange<CGFloat>
    /// Whether particles pulse in opacity (for bioluminescence).
    let pulses: Bool

    enum ParticleType {
        case bubble
        case plankton
        case bioluminescent
        case marineSnow
    }
}

/// The type of static ambient decorations drawn in a zone.
enum AmbientElementType {
    /// Coral formations and sea fans — colorful branching shapes on the seafloor areas.
    case coralReef
    /// Tall kelp strands and sparse rocky outcrops.
    case kelpAndRocks
    /// Bare rock formations, very sparse.
    case bareRock
    /// Rare hydrothermal vent silhouettes.
    case hydrothermalVents
    /// Angular trench-wall silhouettes on the sides.
    case trenchWalls
    /// No ambient elements.
    case none
}

/// Configuration for the ambient reef walls and decorative elements in a zone.
struct AmbientConfig {
    /// Type of decorations drawn on top of the walls.
    let type: AmbientElementType
    /// Number of decorative elements (corals, kelp, vents) in this zone.
    let decorationCount: Int
    /// Vertical spacing between wall profile control points (smaller = more detail).
    let wallSegmentHeightRange: ClosedRange<CGFloat>
    /// How far inward from the screen edge the wall extends (in points).
    let wallWidthRange: ClosedRange<CGFloat>
    /// Brightness range for the wall rock fill.
    let wallBrightness: ClosedRange<Double>
    /// Probability (0–1) of a wall segment being a gap (overhang/cave).
    let gapProbability: Double
}

/// Defines a single oceanic depth zone with its visual properties.
struct DepthZone: Identifiable {
    let id: String
    let name: String
    /// Depth range in meters (e.g., 0...200 for the sunlight zone).
    let depthRange: ClosedRange<Double>
    /// Gradient colors from top to bottom of this zone.
    /// Adjacent zones share boundary colors for soft transitions.
    let gradientColors: [Color]
    /// Particle effect configuration, if any.
    let particleConfig: ParticleConfig?
    /// Configuration for reef walls and decorative elements.
    let ambientConfig: AmbientConfig

    /// Height of this zone in pixels for a given scaling factor.
    func height(scalingFactor: Double) -> CGFloat {
        (depthRange.upperBound - depthRange.lowerBound) * scalingFactor
    }

    /// Vertical pixel offset of this zone's top edge from the ocean surface.
    func topOffset(scalingFactor: Double) -> CGFloat {
        depthRange.lowerBound * scalingFactor
    }

    // MARK: - Zone Colors

    // Shared boundary colors for soft transitions between zones.
    private static let surfaceCyan = Color(red: 0, green: 0.72, blue: 0.85)
    private static let brightTurquoise = Color(red: 0, green: 0.55, blue: 0.75)
    private static let deepBlue = Color(red: 0, green: 0.39, blue: 0.59)       // ≈ deepSeaBlue
    private static let indigo = Color(red: 0.06, green: 0.18, blue: 0.45)
    private static let darkNavy = Color(red: 0.03, green: 0.08, blue: 0.22)     // ≈ abyssBlue
    private static let nearBlack = Color(red: 0.01, green: 0.02, blue: 0.06)
    private static let pureBlack = Color.black

    // MARK: - All Zones

    static let sunlight = DepthZone(
        id: "sunlight",
        name: "Sunlight Zone",
        depthRange: 0...200,
        gradientColors: [surfaceCyan, brightTurquoise, deepBlue],
        particleConfig: ParticleConfig(
            type: .bubble,
            density: 25,
            color: .white.opacity(0.6),
            speed: -30,
            sizeRange: 2...6,
            pulses: false
        ),
        ambientConfig: AmbientConfig(
            type: .coralReef,
            decorationCount: 20,
            wallSegmentHeightRange: 80...300,
            wallWidthRange: 20...80,
            wallBrightness: 0.25...0.60,
            gapProbability: 0.4
        )
    )

    static let twilight = DepthZone(
        id: "twilight",
        name: "Twilight Zone",
        depthRange: 200...1000,
        gradientColors: [deepBlue, indigo, darkNavy],
        particleConfig: ParticleConfig(
            type: .plankton,
            density: 600,
            color: Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.5),
            speed: -5,
            sizeRange: 1...3,
            pulses: false
        ),
        ambientConfig: AmbientConfig(
            type: .kelpAndRocks,
            decorationCount: 30,
            wallSegmentHeightRange: 120...200,
            wallWidthRange: 25...55,
            wallBrightness: 0.12...0.22,
            gapProbability: 0.5
        )
    )

    static let midnight = DepthZone(
        id: "midnight",
        name: "Midnight Zone",
        depthRange: 1000...4000,
        gradientColors: [darkNavy, nearBlack],
        particleConfig: ParticleConfig(
            type: .bioluminescent,
            density: 1000,
            color: Color(red: 0.3, green: 0.8, blue: 0.9),
            speed: -2,
            sizeRange: 1...2,
            pulses: true
        ),
        ambientConfig: AmbientConfig(
            type: .bareRock,
            decorationCount: 0,
            wallSegmentHeightRange: 120...200,
            wallWidthRange: 15...45,
            wallBrightness: 0.06...0.14,
            gapProbability: 0.4
        )
    )

    static let abyssal = DepthZone(
        id: "abyssal",
        name: "Abyssal Zone",
        depthRange: 4000...6000,
        gradientColors: [nearBlack, pureBlack],
        particleConfig: ParticleConfig(
            type: .marineSnow,
            density: 1000,
            color: .white.opacity(0.3),
            speed: 10,
            sizeRange: 1...2,
            pulses: false
        ),
        ambientConfig: AmbientConfig(
            type: .hydrothermalVents,
            decorationCount: 6,
            wallSegmentHeightRange: 150...200,
            wallWidthRange: 10...35,
            wallBrightness: 0.04...0.10,
            gapProbability: 0.25
        )
    )

    static let hadal = DepthZone(
        id: "hadal",
        name: "Hadal Zone",
        depthRange: 6000...11500,
        gradientColors: [pureBlack, pureBlack],
        particleConfig: ParticleConfig(
            type: .marineSnow,
            density: 5000,
            color: .white.opacity(0.5),
            speed: 8,
            sizeRange: 1...1.5,
            pulses: false
        ),
        ambientConfig: AmbientConfig(
            type: .trenchWalls,
            decorationCount: 0,
            wallSegmentHeightRange: 100...200,
            wallWidthRange: 30...80,
            wallBrightness: 0.03...0.08,
            gapProbability: 0.05
        )
    )

    /// All zones in order from surface to deepest.
    static let allZones: [DepthZone] = [sunlight, twilight, midnight, abyssal, hadal]

    /// Find the zone containing a given depth in meters.
    static func zone(atDepth depth: Double) -> DepthZone? {
        allZones.first { $0.depthRange.contains(depth) }
    }
}
