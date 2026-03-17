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
