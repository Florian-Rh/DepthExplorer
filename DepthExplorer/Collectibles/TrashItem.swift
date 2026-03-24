import Foundation

/// A piece of trash the diver can pick up during a dive session.
/// Trash is placed randomly within a depth range and awards Sand Dollars on collection.
/// Sand Dollars are only credited when the diver surfaces safely.
struct TrashItem: Identifiable {
    let id = UUID()
    let depth: Double
    let sandDollarValue: Int
    /// Whether this item is placed on the left side of the screen.
    let isLeftSide: Bool

    /// Generate a random set of trash items for a new dive.
    static func spawnForDive() -> [TrashItem] {
        (0..<GameConstants.trashCountPerDive).map { index in
            TrashItem(
                depth: Double.random(in: GameConstants.trashMinDepth...GameConstants.trashMaxDepth),
                sandDollarValue: Int.random(in: GameConstants.trashMinValue...GameConstants.trashMaxValue),
                isLeftSide: index.isMultiple(of: 2)
            )
        }
    }
}
