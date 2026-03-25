import Foundation

/// A single trash item in the persistent world.
/// Stored in `PlayerProfile.trashWorldState`.
///
/// Every item in the array is available for pickup — collected items are
/// removed outright, and the spawn schedule creates fresh items at new
/// random positions over time.
struct TrashWorldItem: Codable, Identifiable {
    /// Stable identifier for this specific instance.
    let id: UUID
    /// References `TrashTypeDefinition.id` to look up appearance, value, etc.
    let typeID: String
    /// Depth in meters where this item is located.
    let depth: Double
    /// Normalized horizontal position: 0.0 = left edge, 1.0 = right edge.
    let xFraction: Double

    /// Create a random instance for a given type definition.
    static func random(for typeDef: TrashTypeDefinition) -> TrashWorldItem {
        TrashWorldItem(
            id: UUID(),
            typeID: typeDef.id,
            depth: Double.random(in: typeDef.minDepth...typeDef.maxDepth),
            xFraction: Double.random(in: 0.1...0.9)
        )
    }

    /// Generate the initial trash world from the type catalog.
    /// Called once when no trash world state exists in the profile.
    static func seedWorld() -> [TrashWorldItem] {
        var items: [TrashWorldItem] = []
        for typeDef in TrashTypeDefinition.allTypes {
            for _ in 0..<typeDef.maxCount {
                items.append(.random(for: typeDef))
            }
        }
        return items
    }
}
