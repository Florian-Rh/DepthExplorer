import Foundation

/// Static definition for a single game level.
/// In Phase 1, a single default level is used with no hard depth limit.
/// Phase 2 will introduce multiple levels with progression-gated depth limits.
struct LevelDefinition {
    /// Hard depth limit in meters. `nil` means no limit (Phase 1 default).
    let depthLimit: Double?

    /// Pixels per meter. Controls how much ocean fits on screen.
    /// Higher values = more zoomed in, lower values = more compressed.
    let scalingFactor: Double

    /// When ascending and shallower than this depth (meters), auto-surface.
    /// Should be tuned relative to the level's depth range.
    let autoSurfaceDepth: Int

    /// Auto-surface scroll speed (pts per frame).
    let autoSurfaceSpeed: CGFloat

    // TODO: Phase 2 — available gear for purchase at this level

    static let `default` = LevelDefinition(
        depthLimit: nil,
        scalingFactor: 10.0,
        autoSurfaceDepth: 10,
        autoSurfaceSpeed: 4.0
    )
}

/// Game-wide tuning constants.
/// Collected here so they are easy to find and adjust for balancing (Phase 4).
enum GameConstants {
    // MARK: - Depth and Navigation

    /// Maximum representable depth in meters (Challenger Deep).
    static let maximumDepth: Double = 11500.0

    /// Scroll speed multiplier (pts per frame at full joystick deflection).
    static let scrollSpeed: CGFloat = 8.0

    // MARK: - Diver Movement

    /// Smoothing factor for position and tilt interpolation.
    /// 0 = instant snap, 1 = no movement. Applied as `(1 - smoothing)` per frame.
    static let diverSmoothing: CGFloat = 0.96

    /// Horizontal movement speed (pts per frame at full joystick deflection).
    static let diverHorizontalSpeed: CGFloat = 4.0

    /// Screen edge margin for horizontal clamping (pts).
    static let diverEdgeMargin: CGFloat = 30.0

    // MARK: - Joystick

    /// Joystick deadzone for release detection (both axes must be below this).
    static let joystickDeadzone: CGFloat = 0.05

    /// Joystick threshold for tracking left/right direction.
    static let joystickDirectionThreshold: CGFloat = 0.1

    // MARK: - Simulation Timing

    /// Time acceleration factor. 1 real second = this many simulated seconds.
    static let timeScale: Double = 60.0

    /// Simulation tick interval in real seconds.
    static let simulationInterval: Double = 0.2

    /// Depth below which the dive simulation activates (meters).
    static let diveActivationDepth: Int = 3

    /// Depth grouping threshold for history entries (meters).
    /// Consecutive entries within this range and same mixture are merged.
    static let depthGroupingThreshold: Int = 5

    // MARK: - Air Supply

    /// Default tank capacity in bar.
    /// A standard scuba cylinder. Will vary by gear in Phase 2.
    static let tankCapacity: Double = 200.0

    /// Surface air consumption rate in bar per simulated minute.
    /// At depth, actual consumption is `sacRate * ambientPressure`.
    static let sacRate: Double = 1.0

    /// Air pressure (bar) at which a caution warning is triggered.
    static let airWarningThreshold: Double = 50.0

    /// Air pressure (bar) at which a critical warning is triggered.
    static let airCriticalThreshold: Double = 10.0

    // MARK: - DCS / Ascent Speed

    /// Safe ascent speed in meters per real second.
    /// This is a game-tuned value, not a real-world constant.
    /// The diver's max vertical speed is roughly scrollSpeed / scalingFactor * 60 ≈ 48 m/s.
    static let safeAscentSpeed: Double = 20.0

    /// Fraction of safe ascent speed at which a caution warning is triggered.
    static let dcsWarningFraction: Double = 0.8

    /// Fraction of safe ascent speed at which a critical warning is triggered.
    static let dcsCriticalFraction: Double = 1.0

    /// Fraction of safe ascent speed at which a fatal warning is triggered.
    static let dcsFatalFraction: Double = 1.5

    /// How quickly the effective ascent speed builds up toward the instantaneous speed
    /// while ascending. Range 0–1; higher = faster buildup.
    static let ascentSpeedBuildupRate: Double = 0.08

    /// How quickly the effective ascent speed decays toward 0 when the diver stops
    /// or descends. Range 0–1; higher = faster decay.
    static let ascentSpeedDecayRate: Double = 0.25

    // MARK: - Thermal Model

    /// Normal human body temperature in °C.
    static let normalBodyTemperature: Double = 37.0

    /// Surface water temperature in °C (tropical surface).
    static let surfaceWaterTemperature: Double = 28.0

    /// Minimum deep-water temperature in °C (deep ocean floor).
    static let deepWaterTemperature: Double = 4.0

    /// Temperature drop per meter of depth in °C.
    /// Roughly models a thermocline: 25°C at surface → ~1°C at ~700m.
    static let temperatureDropPerMeter: Double =  0.035

    /// Cooling rate coefficient. Higher = faster heat loss.
    /// The actual cooling per minute is `(bodyTemp - waterTemp) * coolingRate`.
    static let coolingRate: Double = 0.006

    /// Body temperature (°C) at which a caution warning is triggered.
    static let hypothermiaWarningThreshold: Double = 36.0

    /// Body temperature (°C) at which a critical warning is triggered.
    static let hypothermiaCriticalThreshold: Double = 35.0

    /// Body temperature (°C) at which the diver is rescued (fatal).
    static let hypothermiaFatalThreshold: Double = 34.0

    // MARK: - Gas Mixtures

    /// Available gas mixtures. Will eventually be determined by player inventory.
    static let availableMixtures: [(name: String, mixture: GasMixture)] = [
        ("Air", .air),
        ("Pure Oxygen", .oxygen),
        ("Nitrox 32", .nitrox32),
        ("Nitrox 36", .nitrox36),
        ("Nitrox 40", .nitrox40),
        ("Trimix 21/35", .trimix2135),
    ]
}
