import Foundation

/// Tracks continuous game time that persists across app launches.
/// Game time advances at `GameConstants.timeScale` relative to wall-clock time.
///
/// Usage:
/// 1. On app foreground: call `resume()` to begin accumulating.
/// 2. On app background/termination: call `pause()` to snapshot elapsed time.
/// 3. Read `totalElapsed` for the current game-time total.
///
/// The clock does NOT tick on its own; it computes elapsed time lazily
/// from the wall-clock delta since `resume()` was last called.
struct GameClock {
    /// Total accumulated game-time seconds from all previous sessions.
    /// This is the value persisted in PlayerProfile.
    private var savedElapsed: TimeInterval

    /// Wall-clock timestamp when `resume()` was last called.
    /// `nil` means the clock is paused.
    private var resumedAt: Date?

    init(savedElapsed: TimeInterval) {
        self.savedElapsed = savedElapsed
        self.resumedAt = nil
    }

    /// Total game-time elapsed including the current running session.
    var totalElapsed: TimeInterval {
        guard let resumedAt else { return savedElapsed }
        let wallDelta = Date().timeIntervalSince(resumedAt)
        return savedElapsed + wallDelta * GameConstants.timeScale
    }

    /// Begin or continue accumulating game time.
    mutating func resume() {
        guard resumedAt == nil else { return }
        resumedAt = Date()
    }

    /// Stop accumulating and snapshot the elapsed time.
    /// Returns the new `totalElapsed` for persistence.
    @discardableResult
    mutating func pause() -> TimeInterval {
        let elapsed = totalElapsed
        savedElapsed = elapsed
        resumedAt = nil
        return elapsed
    }
}
