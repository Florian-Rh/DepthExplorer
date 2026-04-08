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
    /// Base time in simulated seconds to pick up this item (multiplied by pickupSpeedMultiplier).
    let pickupDuration: TimeInterval

    // MARK: - Catalog

    static let allTypes: [TrashTypeDefinition] = [
        TrashTypeDefinition(
            id: "trash.sodaCan",
            color: .red,
            sandDollarValue: 1.0,
            minDepth: 20,
            maxDepth: 100,
            respawnTime: 400,
            maxCount: 25,
            pickupDuration: 0.5
        ),
        TrashTypeDefinition(
            id: "trash.plasticBag",
            color: .white,
            sandDollarValue: 2.0,
            minDepth: 30,
            maxDepth: 150,
            respawnTime: 600,
            maxCount: 20,
            pickupDuration: 0.7
        ),
        TrashTypeDefinition(
            id: "trash.bottle",
            color: .green,
            sandDollarValue: 3.0,
            minDepth: 80,
            maxDepth: 300,
            respawnTime: 700,
            maxCount: 20,
            pickupDuration:0.7
        ),
        TrashTypeDefinition(
            id: "trash.tire",
            color: .gray,
            sandDollarValue: 5.0,
            minDepth: 100,
            maxDepth: 400,
            respawnTime: 1200,
            maxCount: 15,
            pickupDuration: 1.5
        ),
        TrashTypeDefinition(
            id: "trash.battery",
            color: .yellow,
            sandDollarValue: 5.0,
            minDepth: 250,
            maxDepth: 500,
            respawnTime: 1200,
            maxCount: 10,
            pickupDuration: 1.5
        ),
        TrashTypeDefinition(
            id: "trash.fishingNet",
            color: .orange,
            sandDollarValue: 7.0,
            minDepth: 500,
            maxDepth: 1000,
            respawnTime: 1200,
            maxCount: 15,
            pickupDuration: 1.5
        ),
        TrashTypeDefinition(
            id: "trash.shoppingCart",
            color: .cyan,
            sandDollarValue: 12.0,
            minDepth: 800,
            maxDepth: 1500,
            respawnTime: 2000,
            maxCount: 15,
            pickupDuration: 2.0
        ),
        TrashTypeDefinition(
            id: "trash.oilDrum",
            color: Color(red: 0.55, green: 0.35, blue: 0.15),
            sandDollarValue: 15.0,
            minDepth: 900,
            maxDepth: 2000,
            respawnTime: 2000,
            maxCount: 20,
            pickupDuration: 2.5
        ),
        TrashTypeDefinition(
            id: "trash.anchor",
            color: Color(red: 0.25, green: 0.35, blue: 0.55),
            sandDollarValue: 20.0,
            minDepth: 1000,
            maxDepth: 3000,
            respawnTime: 2600,
            maxCount: 20,
            pickupDuration: 3.0
        ),
        TrashTypeDefinition(
            id: "trash.container",
            color: Color(red: 0.80, green: 0.30, blue: 0.10),
            sandDollarValue: 30.0,
            minDepth: 2000,
            maxDepth: 4000,
            respawnTime: 4000,
            maxCount: 10,
            pickupDuration: 4.0
        ),
    ]
}
