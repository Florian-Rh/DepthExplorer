import SwiftUI

/// Defines a category of ocean trash with distinct appearance, value, depth range, and respawn behavior.
/// Follows the same static-catalog pattern as `GearDefinition` and `SkillDefinition`.
struct TrashTypeDefinition: Identifiable {
    /// Stable identifier for this type (e.g. "trash.sodaCan").
    let id: String
    /// Accent color for the circle background and icon tint.
    let color: Color
    /// Sand Dollars awarded on collection.
    let sandDollarValue: Double
    /// Shallowest depth (meters) this type can spawn at.
    let minDepth: Double
    /// Deepest depth (meters) this type can spawn at.
    let maxDepth: Double
    /// Game-time seconds until the item respawns after collection.
    let respawnTime: TimeInterval
    /// Maximum number of this type that can exist in the world simultaneously.
    let maxCount: Int

    // MARK: - Catalog

    static let allTypes: [TrashTypeDefinition] = [
        TrashTypeDefinition(
            id: "trash.sodaCan",
            color: .red,
            sandDollarValue: 1.0,
            minDepth: 10,
            maxDepth: 100,
            respawnTime: 400,
            maxCount: 6
        ),
        TrashTypeDefinition(
            id: "trash.plasticBag",
            color: .white,
            sandDollarValue: 2.0,
            minDepth: 20,
            maxDepth: 150,
            respawnTime: 600,
            maxCount: 4
        ),
        TrashTypeDefinition(
            id: "trash.bottle",
            color: .green,
            sandDollarValue: 2.0,
            minDepth: 50,
            maxDepth: 300,
            respawnTime: 580,
            maxCount: 4
        ),
        TrashTypeDefinition(
            id: "trash.tire",
            color: .gray,
            sandDollarValue: 4.0,
            minDepth: 50,
            maxDepth: 200,
            respawnTime: 1200,
            maxCount: 4
        ),
        TrashTypeDefinition(
            id: "trash.battery",
            color: .yellow,
            sandDollarValue: 5.0,
            minDepth: 100,
            maxDepth: 300,
            respawnTime: 900,
            maxCount: 3
        ),
        TrashTypeDefinition(
            id: "trash.fishingNet",
            color: .orange,
            sandDollarValue: 6.0,
            minDepth: 100,
            maxDepth: 200,
            respawnTime: 1000,
            maxCount: 3
        ),
        TrashTypeDefinition(
            id: "trash.shoppingCart",
            color: .cyan,
            sandDollarValue: 10.0,
            minDepth: 300,
            maxDepth: 800,
            respawnTime: 2000,
            maxCount: 3
        ),
        TrashTypeDefinition(
            id: "trash.oilDrum",
            color: Color(red: 0.55, green: 0.35, blue: 0.15),
            sandDollarValue: 12.0,
            minDepth: 300,
            maxDepth: 1000,
            respawnTime: 2000,
            maxCount: 4
        ),
        TrashTypeDefinition(
            id: "trash.anchor",
            color: Color(red: 0.25, green: 0.35, blue: 0.55),
            sandDollarValue: 15.0,
            minDepth: 800,
            maxDepth: 1200,
            respawnTime: 2600,
            maxCount: 2
        ),
        TrashTypeDefinition(
            id: "trash.container",
            color: Color(red: 0.80, green: 0.30, blue: 0.10),
            sandDollarValue: 20.0,
            minDepth: 1300,
            maxDepth: 2800,
            respawnTime: 4000,
            maxCount: 3
        ),
    ]
}
