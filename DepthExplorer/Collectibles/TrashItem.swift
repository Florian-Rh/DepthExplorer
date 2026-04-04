import Foundation

/// A trash item prepared for rendering and proximity detection during a dive.
/// Combines persistent world state (`TrashWorldItem`) with catalog data (`TrashTypeDefinition`).
struct TrashItem: Identifiable {
    /// Matches `TrashWorldItem.id` for lookup when collecting.
    let id: UUID
    /// The type definition for appearance, value, etc.
    let typeDef: TrashTypeDefinition
    /// Depth in meters.
    let depth: Double
    /// Normalized horizontal position [0, 1].
    let xFraction: Double

    /// Convenience: sand dollar value from the type definition.
    var sandDollarValue: Double { typeDef.sandDollarValue }
}
