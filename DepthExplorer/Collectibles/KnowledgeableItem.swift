import Foundation

/// Categories of real-world knowledge that can be discovered underwater.
enum KnowledgeableCategory: String, CaseIterable {
    case species
    case oceanography
    case humanHistory
    case humanImpact
}

/// A real-world fact placed at a fixed depth, discovered by the diver on proximity.
/// Discovery state is tracked in the persistent player profile (Phase 1).
struct KnowledgeableItem: Identifiable {
    static let allItems: [KnowledgeableItem] = [
        // Depth zone entries
        .init(
            depth: 5,
            name: "Sunlight Zone",
            image: "sun.max.fill",
            category: .oceanography,
            description: "The sunlight zone (epipelagic) extends from the surface to 200 meters. It receives enough light for photosynthesis and contains over 90% of all marine life, including coral reefs, seagrass meadows, and most fish species."
        ),
        .init(
            depth: 10,
            name: "Clownfish",
            image: "fish",
            category: .species,
            description: "Clownfish live in symbiosis with sea anemones, which protect them from predators with their stinging tentacles."
        ),
        .init(
            depth: 100,
            name: "Sea Turtle",
            image: "tortoise",
            category: .species,
            description: "Sea turtles can hold their breath for several hours and dive to depths of over 1,000 meters."
        ),
        .init(
            depth: 200,
            name: "Twilight Zone",
            image: "moon.stars.fill",
            category: .oceanography,
            description: "The twilight zone (mesopelagic, 200–1,000m) receives only faint traces of sunlight. Many creatures here have evolved bioluminescent abilities, and vast numbers of organisms migrate vertically through this zone each day — the largest migration on Earth."
        ),
        .init(
            depth: 332,
            name: "Deepest Scuba Dive",
            image: "figure.scuba.diving",
            category: .humanHistory,
            description: "In 2014, Ahmed Gabr set the world record for the deepest scuba dive at 332.35 meters in the Red Sea."
        ),
        .init(
            depth: 1000,
            name: "Midnight Zone",
            image: "moon.fill",
            category: .oceanography,
            description: "No sunlight reaches the midnight zone (bathypelagic, 1,000–4,000m). Life here relies on marine snow — organic debris falling from above — or chemosynthesis near hydrothermal vents. Creatures have adapted with enormous eyes, transparent bodies, and bioluminescent lures."
        ),
        .init(
            depth: 1000,
            name: "E-Scooter Pollution",
            image: "scooter",
            category: .humanImpact,
            description: "eScooter, die ins Meer geworfen werden, stellen ein ernsthaftes Umweltproblem dar. Ihre Batterien enthalten Schwermetalle und Chemikalien, die ins Wasser gelangen und Meerestiere sowie das Ökosystem schädigen können."
        ),
        .init(
            depth: 4000,
            name: "Abyssal Zone",
            image: "circle.fill",
            category: .oceanography,
            description: "The abyssal zone (abyssopelagic, 4,000–6,000m) covers over 80% of the ocean floor. Water temperature hovers just above freezing at 1–4°C, and the immense pressure reaches over 400 atmospheres. Despite these extremes, unique ecosystems thrive around hydrothermal vents."
        ),
        .init(
            depth: 4000,
            name: "Brine Pools",
            image: "water.waves",
            category: .oceanography,
            description: "Brine pools are lakes of super-salty water on the ocean floor. Their extreme salinity is toxic to most sea life, creating a 'shore' of dead organisms around their edges."
        ),
        .init(
            depth: 6000,
            name: "Hadal Zone",
            image: "arrow.down.to.line",
            category: .oceanography,
            description: "The hadal zone (hadalpelagic, 6,000–11,000m) exists only in deep ocean trenches. The Mariana Trench's Challenger Deep, at nearly 11,000 meters, is the deepest point on Earth. Even here, life persists — amphipods and xenophyophores have been found at the very bottom."
        ),
    ]

    let depth: Double
    let name: String
    let image: String
    let category: KnowledgeableCategory
    let description: String

    var id: String { name }
}
