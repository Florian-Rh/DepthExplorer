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
    @Published private(set) var collectedTrashCount: Int = 0

    /// Items discovered this session with their depths, for XP calculation.
    private(set) var discoveredItemRecords: [DiscoveredItemInfo] = []

    /// IDs of trash items collected this dive (for persisting on safe surfacing).
    private(set) var collectedTrashIDs: [UUID] = []

    /// Maximum number of trash items the diver can carry per dive.
    let carryCapacity: Int

    /// Whether the diver's bag is full.
    var isBagFull: Bool {
        collectedTrashCount >= carryCapacity
    }

    init(carryCapacity: Int = GameConstants.defaultCarryCapacity) {
        self.carryCapacity = carryCapacity
    }

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

    /// Cancel an incomplete dive (minimum requirements not met).
    /// Returns to surface state without rewards or penalties.
    func cancelDive() {
        guard state == .diving else { return }
        reset()
    }

    /// Transition to rescued state on a failure condition.
    func rescue(reason: String) {
        guard state == .diving else { return }
        state = .rescued(reason: reason)
    }

    /// Record a Knowledgeable Item discovery during the dive.
    func discoverItem(named name: String, atDepth depth: Double) {
        guard state == .diving else { return }
        discoveredItemNames.insert(name)
        discoveredItemRecords.append(DiscoveredItemInfo(name: name, depthMeters: depth))
    }

    /// Record trash pickup during the dive. Returns `false` if the bag is full.
    @discardableResult
    func collectTrash(id: UUID, value: Int) -> Bool {
        guard state == .diving else { return false }
        guard !isBagFull else { return false }
        collectedSandDollars += value
        collectedTrashCount += 1
        collectedTrashIDs.append(id)
        return true
    }

    /// Commit session rewards to the persistent profile and reset for the next dive.
    /// Note: Discovered items are committed immediately on discovery (knowledge persists
    /// even after rescue). Only Sand Dollars require safe surfacing.
    func commitRewards(to store: ProfileStore) {
        guard state == .surfacedSafely else { return }
        if collectedSandDollars > 0 {
            store.addSandDollars(collectedSandDollars)
        }

        reset()
    }

    /// Discard session data and return to surface (after rescue or quit).
    func discard() {
        reset()
    }

    private func reset() {
        state = .surface
        discoveredItemNames = []
        discoveredItemRecords = []
        collectedSandDollars = 0
        collectedTrashCount = 0
        collectedTrashIDs = []
    }
}
