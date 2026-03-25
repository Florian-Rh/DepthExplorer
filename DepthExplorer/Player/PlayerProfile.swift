import Foundation

/// Persistent player state that survives across dive sessions.
/// Saved as a JSON file in the app's documents directory.
struct PlayerProfile: Codable {
    /// Sand Dollars earned from collecting trash.
    var sandDollars: Int = 0

    /// Total experience points earned from discovering Knowledgeable Items.
    var experiencePoints: Int = 0

    /// Names of Knowledgeable Items the player has discovered.
    /// Uses `KnowledgeableItem.name` as the stable identifier.
    var discoveredItems: Set<String> = []

    /// Total number of dives completed successfully.
    var totalDives: Int = 0

    /// Accumulated dive time across all successful dives, in simulated seconds.
    var totalDiveTimeSeconds: Int = 0

    /// Personal record: deepest depth reached in a successful dive, in meters.
    var recordMaxDepth: Int = 0

    /// Personal record: longest single dive, in simulated seconds.
    var recordDiveTimeSeconds: Int = 0

    /// IDs of gear items the player has purchased.
    var ownedGearIDs: Set<String> = []

    /// Currently equipped gear, keyed by `GearCategory.rawValue`.
    /// Value is the `GearDefinition.id`, absent if using the default for that slot.
    var equippedGearIDs: [String: String] = [:]

    /// IDs of skills the player has acquired (e.g. `"breathingTechniques.2"`).
    var acquiredSkillIDs: Set<String> = []

    /// Unspent skill points. Incremented on level-up, decremented on skill acquisition.
    var skillPoints: Int = 0

    /// Accumulated game-time in seconds. Drives trash respawn and (future) day/night cycle.
    var gameTimeElapsed: TimeInterval = 0

    /// Persistent state of all trash items in the world.
    /// Every item in this array is available for pickup. Collected items are removed.
    var trashWorldState: [TrashWorldItem] = []

    /// Per-type spawn schedule: maps `TrashTypeDefinition.id` → game-time at which the
    /// next item of that type should be spawned. Empty on first launch (seed fills the world).
    var trashSpawnSchedule: [String: TimeInterval] = [:]
}
