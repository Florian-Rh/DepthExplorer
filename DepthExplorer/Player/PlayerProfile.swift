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

    // TODO: Phase 2 — purchased gear inventory
    // TODO: Phase 2 — equipped loadout
    // TODO: Phase 2 — acquired skills
}
