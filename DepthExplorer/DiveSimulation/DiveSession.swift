import Foundation

/// The possible states of a dive session.
enum DiveSessionState: Equatable {
    /// Player is at the surface, no active dive.
    case surface
    /// Player is underwater.
    case diving
    /// Player returned to the surface safely. Rewards are ready to be credited.
    case surfacedSafely
    /// Player was rescued (failure condition). Session items are lost.
    case rescued(reason: String)
}

/// Tracks the lifecycle and ephemeral inventory of a single dive session.
/// Items collected during a dive are held here until the session ends.
/// On safe surfacing, they are committed to the persistent `ProfileStore`.
/// On rescue or quit, they are discarded.
class DiveSession: ObservableObject {
    @Published private(set) var state: DiveSessionState = .surface
    @Published private(set) var discoveredItemNames: Set<String> = []
    @Published private(set) var collectedSandDollars: Int = 0

    /// Transition to diving state when the diver descends past the activation depth.
    func beginDive() {
        guard state == .surface else { return }
        state = .diving
    }

    /// Transition to surfaced safely when the diver returns to depth 0.
    func completeDive() {
        guard state == .diving else { return }
        state = .surfacedSafely
    }

    /// Transition to rescued state on a failure condition.
    func rescue(reason: String) {
        guard state == .diving else { return }
        state = .rescued(reason: reason)
    }

    /// Record a Knowledgeable Item discovery during the dive.
    func discoverItem(named name: String) {
        guard state == .diving else { return }
        discoveredItemNames.insert(name)
    }

    /// Record trash pickup during the dive.
    func collectTrash(value: Int) {
        guard state == .diving else { return }
        collectedSandDollars += value
    }

    /// Commit session rewards to the persistent profile and reset for the next dive.
    /// Note: Discovered items are committed immediately on discovery (knowledge persists
    /// even after rescue). Only Sand Dollars require safe surfacing.
    func commitRewards(to store: ProfileStore) {
        guard state == .surfacedSafely else { return }
        if collectedSandDollars > 0 {
            store.addSandDollars(collectedSandDollars)
        }
        // TODO: Phase 1 — add XP for discovered items
        reset()
    }

    /// Discard session data and return to surface (after rescue or quit).
    func discard() {
        reset()
    }

    private func reset() {
        state = .surface
        discoveredItemNames = []
        collectedSandDollars = 0
    }
}
