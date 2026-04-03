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
            depth: 20,
            name: "Clownfish",
            image: "fish",
            category: .species,
            description: "Clownfish live in symbiosis with sea anemones, which protect them from predators with their stinging tentacles."
        ),
        .init(
            depth: 30,
            name: "Sunlight Zone",
            image: "sun.max.fill",
            category: .oceanography,
            description: "The sunlight zone (epipelagic) extends from the surface to 200 meters. It receives enough light for photosynthesis and contains over 90% of all marine life, including coral reefs, seagrass meadows, and most fish species."
        ),
        .init(
            depth: 40,
            name: "Branching Coral",
            image: "leaf.fill",
            category: .species,
            description: "Branching corals grow tree-like skeletons with many forking arms, creating dense thickets that shelter small fish and invertebrates. They are among the fastest-growing reef corals, but their delicate structure makes them especially vulnerable to storm damage and bleaching events."
        ),
        .init(
            depth: 60,
            name: "Sea Fan",
            image: "leaf.fill",
            category: .species,
            description: "Sea fans are soft corals that grow flat, fan-shaped colonies oriented perpendicular to the current to filter passing plankton. Their flexible, protein-based skeletons bend with the water flow rather than snapping. Some species can reach over a meter across and live for hundreds of years."
        ),
        .init(
            depth: 80,
            name: "Brain Coral",
            image: "leaf.fill",
            category: .species,
            description: "Brain corals get their name from the winding grooves on their surface that resemble a human brain. These massive, dome-shaped colonies grow very slowly — just a few millimeters per year — but can live for over 900 years, making them some of the longest-lived reef organisms."
        ),
        .init(
            depth: 110,
            name: "Staghorn Coral",
            image: "leaf.fill",
            category: .species,
            description: "Staghorn coral forms antler-like branches that can grow up to 20 centimeters per year, making it one of the fastest-growing reef-building corals. Its dense thickets provide critical habitat for juvenile fish. Once dominant across Caribbean reefs, its populations have declined by over 80% since the 1980s due to disease and warming seas."
        ),
        .init(
            depth: 130,
            name: "Tube Sponge",
            image: "leaf.fill",
            category: .species,
            description: "Tube sponges are among the oldest animal lineages on Earth, with a fossil record spanning over 600 million years. They pump thousands of liters of water through their hollow bodies each day, filtering out bacteria and organic particles. Their vivid colors — purple, orange, blue — come from symbiotic bacteria living in their tissues."
        ),
        .init(
            depth: 150,
            name: "Seagrass",
            image: "leaf.fill",
            category: .species,
            description: "Seagrass meadows are underwater flowering plants — not algae — that form dense carpets on sandy and muddy seafloors. They stabilize sediment, absorb carbon dioxide up to 35 times faster than tropical rainforests, and provide nursery grounds for commercially important fish and shellfish species."
        ),
        .init(
            depth: 170,
            name: "Coral Bleaching",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "When ocean temperatures rise even 1–2°C above normal, corals expel the symbiotic algae that give them color and provide up to 90% of their energy. The coral turns ghostly white — 'bleached' — and begins to starve. Prolonged bleaching is fatal. Since 1998, mass bleaching events driven by climate change have killed large swathes of reefs worldwide, including over half of the Great Barrier Reef's shallow-water corals."
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
            depth: 250,
            name: "Kelp Forests",
            image: "tree.fill",
            category: .oceanography,
            description: "Giant kelp can grow up to 60 centimeters per day, making it one of the fastest-growing organisms on Earth. Kelp forests provide shelter, food, and nursery habitat for hundreds of species. They anchor to rocky substrates with root-like holdfasts and can form underwater canopies stretching over 45 meters from the seafloor toward the light."
        ),
        .init(
            depth: 300,
            name: "Plankton",
            image: "sparkle",
            category: .species,
            description: "Plankton are the drifting foundation of ocean life. Phytoplankton — microscopic algae — produce roughly half of all the oxygen on Earth through photosynthesis. Zooplankton, the tiny animals that feed on them, form the base of the marine food web. Together they support everything from sardines to blue whales."
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
            depth: 1500,
            name: "Bioluminescence",
            image: "sparkles",
            category: .oceanography,
            description: "Below 1,000 meters, sunlight vanishes — yet the darkness is alive with light. Up to 90% of deep-sea creatures produce bioluminescence through chemical reactions in their bodies. They use it to lure prey, attract mates, confuse predators, or illuminate their surroundings. Lanternfish, jellyfish, and anglerfish are among the most prolific deep-sea light-makers."
        ),
        .init(
            depth: 4000,
            name: "Abyssal Zone",
            image: "circle.fill",
            category: .oceanography,
            description: "The abyssal zone (abyssopelagic, 4,000–6,000m) covers over 80% of the ocean floor. Water temperature hovers just above freezing at 1–4°C, and the immense pressure reaches over 400 atmospheres. Despite these extremes, unique ecosystems thrive around hydrothermal vents."
        ),
        .init(
            depth: 4500,
            name: "Hydrothermal Vents",
            image: "flame.fill",
            category: .oceanography,
            description: "Hydrothermal vents are fissures in the seafloor that spew superheated, mineral-rich water at temperatures exceeding 400°C. Black smokers get their name from dark plumes of metal sulfides. Despite the extreme heat, pressure, and total darkness, thriving ecosystems cluster around them — giant tube worms, blind shrimp, and chemosynthetic bacteria that convert hydrogen sulfide into energy, independent of sunlight."
        ),
        .init(
            depth: 4200,
            name: "Marine Snow",
            image: "snowflake",
            category: .oceanography,
            description: "Marine snow is a continuous shower of organic debris — dead plankton, fecal pellets, and mucus — that drifts down from the sunlit surface. It can take weeks to reach the deep ocean floor. This slow rain is the primary food source for most abyssal life and plays a critical role in the ocean's carbon cycle, transporting carbon from the atmosphere to the deep sea."
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
