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

    // TODO: Phase 2 — purchased gear inventory
    // TODO: Phase 2 — equipped loadout
    // TODO: Phase 2 — acquired skills
}
