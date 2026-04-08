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
        // MARK: Sunlight Zone (0–200m)
        .init(
            depth: 25,
            name: "Seagrass",
            image: "leaf.fill",
            category: .species,
            description: "Seagrass meadows are underwater flowering plants — not algae — that form dense carpets on sandy and muddy seafloors. They stabilize sediment, absorb carbon dioxide up to 35 times faster than tropical rainforests, and provide nursery grounds for commercially important fish and shellfish species."
        ),
        .init(
            depth: 45,
            name: "Clownfish",
            image: "fish",
            category: .species,
            description: "Clownfish live in symbiosis with sea anemones, which protect them from predators with their stinging tentacles."
        ),
        .init(
            depth: 50,
            name: "Sunlight Zone",
            image: "sun.max.fill",
            category: .oceanography,
            description: "The sunlight zone (epipelagic) extends from the surface to 200 meters. It receives enough light for photosynthesis and contains over 90% of all marine life, including coral reefs, seagrass meadows, and most fish species."
        ),
        .init(
            depth: 60,
            name: "Kelp Forests",
            image: "tree.fill",
            category: .oceanography,
            description: "Giant kelp can grow up to 60 centimeters per day, making it one of the fastest-growing organisms on Earth. Kelp forests provide shelter, food, and nursery habitat for hundreds of species. They anchor to rocky substrates with root-like holdfasts and can form underwater canopies stretching over 45 meters from the seafloor toward the light."
        ),
        .init(
            depth: 70,
            name: "Sea Fan",
            image: "leaf.fill",
            category: .species,
            description: "Sea fans are soft corals that grow flat, fan-shaped colonies oriented perpendicular to the current to filter passing plankton. Their flexible, protein-based skeletons bend with the water flow rather than snapping. Some species can reach over a meter across and live for hundreds of years."
        ),
        .init(
            depth: 130,
            name: "Tube Sponge",
            image: "leaf.fill",
            category: .species,
            description: "Tube sponges are among the oldest animal lineages on Earth, with a fossil record spanning over 600 million years. They pump thousands of liters of water through their hollow bodies each day, filtering out bacteria and organic particles. Their vivid colors — purple, orange, blue — come from symbiotic bacteria living in their tissues."
        ),
        .init(
            depth: 170,
            name: "Coral Bleaching",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "When ocean temperatures rise even 1–2°C above normal, corals expel the symbiotic algae that give them color and provide up to 90% of their energy. The coral turns ghostly white — 'bleached' — and begins to starve. Prolonged bleaching is fatal. Since 1998, mass bleaching events driven by climate change have killed large swathes of reefs worldwide, including over half of the Great Barrier Reef's shallow-water corals."
        ),

        // MARK: Twilight Zone (200–1000m)
        .init(
            depth: 200,
            name: "Twilight Zone",
            image: "moon.stars.fill",
            category: .oceanography,
            description: "The twilight zone (mesopelagic, 200–1,000m) receives only faint traces of sunlight. Many creatures here have evolved bioluminescent abilities, and vast numbers of organisms migrate vertically through this zone each day — the largest migration on Earth."
        ),
        .init(
            depth: 250,
            name: "Plankton",
            image: "sparkle",
            category: .species,
            description: "Plankton are the drifting foundation of ocean life. Phytoplankton — microscopic algae — produce roughly half of all the oxygen on Earth through photosynthesis. Zooplankton, the tiny animals that feed on them, form the base of the marine food web. Together they support everything from sardines to blue whales."
        ),
        .init(
            depth: 300,
            name: "Deep-Sea Trawling",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "Bottom trawlers drag heavy nets across the seafloor at depths reaching 2,000 meters, destroying coral gardens, sponge fields, and other slow-growing habitats that took centuries to form. A single pass can flatten structures that will not recover for decades. Deep-sea trawling is estimated to disturb an area of seabed equivalent to the lower 48 U.S. states every year."
        ),
        .init(
            depth: 332,
            name: "Deepest Scuba Dive",
            image: "figure.dance",
            category: .humanHistory,
            description: "In 2014, Ahmed Gabr set the world record for the deepest scuba dive at 332.35 meters in the Red Sea."
        ),
        .init(
            depth: 400,
            name: "Sea Turtle",
            image: "tortoise",
            category: .species,
            description: "Sea turtles can hold their breath for several hours and dive to depths of over 1,000 meters."
        ),
        .init(
            depth: 500,
            name: "Sperm Whale",
            image: "fish.fill",
            category: .species,
            description: "Sperm whales routinely dive to 500–1,000 meters to hunt giant squid, holding their breath for up to 90 minutes. They are the deepest-diving mammals, with a confirmed record of 2,250 meters."
        ),
        .init(
            depth: 600,
            name: "Giant Squid",
            image: "fish",
            category: .species,
            description: "Giant squid inhabit depths of 300–1,000 meters. First filmed alive in 2004 by Japanese scientists at around 900 meters, they possess eyes up to 27 centimeters across — the largest in the animal kingdom."
        ),
        .init(
            depth: 700,
            name: "Oxygen Minimum Zone",
            image: "aqi.low",
            category: .oceanography,
            description: "Between 200–1,000 meters, bacteria consume so much oxygen decomposing sinking organic matter that dissolved oxygen drops to near zero. Many organisms avoid this layer entirely; those that tolerate it face almost no competition."
        ),
        .init(
            depth: 800,
            name: "Microplastics",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "Microplastic particles smaller than 5 millimeters have been found throughout the water column, from the surface down to the deepest ocean trenches. An estimated 14 million tonnes of microplastic sit on the ocean floor."
        ),

        .init(
            depth: 923,
            name: "Bathysphere",
            image: "globe.desk.fill",
            category: .humanHistory,
            description: "In 1934, William Beebe and Otis Barton descended to 923 meters off Bermuda inside the Bathysphere — a cramped steel sphere just 1.4 meters across. It was the first time humans observed the deep ocean firsthand, and Beebe's vivid radio broadcasts of bioluminescent creatures captivated the world."
        ),

        // MARK: Midnight Zone (1000–4000m)
        .init(
            depth: 1000,
            name: "Midnight Zone",
            image: "moon.fill",
            category: .oceanography,
            description: "No sunlight reaches the midnight zone (bathypelagic, 1,000–4,000m). Life here relies on marine snow — organic debris falling from above — or chemosynthesis near hydrothermal vents. Creatures have adapted with enormous eyes, transparent bodies, and bioluminescent lures."
        ),
        .init(
            depth: 1200,
            name: "Deepwater Horizon",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "The 2010 Deepwater Horizon disaster released an estimated 4.9 million barrels of oil from a wellhead at 1,500 meters in the Gulf of Mexico. A deep-sea oil plume was detected between 1,000 and 1,300 meters, persisting for months and devastating deep-water coral communities up to 20 kilometers from the well site."
        ),
        .init(
            depth: 1500,
            name: "Bioluminescence",
            image: "sparkles",
            category: .oceanography,
            description: "Below 1,000 meters, sunlight vanishes — yet the darkness is alive with light. Up to 90% of deep-sea creatures produce bioluminescence through chemical reactions in their bodies. They use it to lure prey, attract mates, confuse predators, or illuminate their surroundings. Lanternfish, jellyfish, and anglerfish are among the most prolific deep-sea light-makers."
        ),
        .init(
            depth: 2000,
            name: "Giant Tube Worm",
            image: "leaf.fill",
            category: .species,
            description: "Riftia pachyptila grow up to 2.4 meters near hydrothermal vents at 1,500–2,500 meters depth. They have no mouth or digestive system; symbiotic bacteria inside them convert hydrogen sulfide into energy."
        ),
        .init(
            depth: 2400,
            name: "Discovery of Vent Life",
            image: "flame.fill",
            category: .humanHistory,
            description: "In 1977, scientists aboard the submersible Alvin discovered thriving ecosystems around hydrothermal vents at 2,500 meters on the Galápagos Rift. Giant tube worms, clams, and shrimp were living entirely without sunlight — sustained by chemosynthetic bacteria. It was the first known ecosystem on Earth powered by chemical energy rather than photosynthesis."
        ),
        .init(
            depth: 2500,
            name: "Anglerfish",
            image: "fish",
            category: .species,
            description: "Deep-sea anglerfish use a bioluminescent lure dangling from their forehead to attract prey in total darkness. Males of some species permanently fuse to females, sharing a circulatory system — one of the most extreme examples of sexual dimorphism in the animal kingdom."
        ),
        .init(
            depth: 2500,
            name: "Mid-Ocean Ridge",
            image: "mountain.2.fill",
            category: .oceanography,
            description: "The global mid-ocean ridge system stretches over 65,000 kilometers — the longest mountain range on Earth. New oceanic crust forms here as tectonic plates diverge and magma rises to fill the gap."
        ),
        .init(
            depth: 3000,
            name: "Whale Fall",
            image: "fish.fill",
            category: .oceanography,
            description: "When a whale carcass sinks to the deep seafloor, it creates a 'whale fall' ecosystem that can sustain specialized communities of organisms — bone-eating worms, sleeper sharks, and chemosynthetic bacteria — for decades."
        ),
        .init(
            depth: 3800,
            name: "Titanic Wreck",
            image: "ferry.fill",
            category: .humanHistory,
            description: "The RMS Titanic rests at 3,784 meters in the North Atlantic. Discovered in 1985 by Robert Ballard, the wreck is being consumed by iron-eating bacteria and may fully disintegrate by the 2030s."
        ),

        // MARK: Abyssal Zone (4000–6000m)
        .init(
            depth: 4000,
            name: "Abyssal Zone",
            image: "circle.fill",
            category: .oceanography,
            description: "The abyssal zone (abyssopelagic, 4,000–6,000m) covers over 80% of the ocean floor. Water temperature hovers just above freezing at 1–4°C, and the immense pressure reaches over 400 atmospheres. Despite these extremes, unique ecosystems thrive around hydrothermal vents."
        ),
        .init(
            depth: 4200,
            name: "Marine Snow",
            image: "snowflake",
            category: .oceanography,
            description: "Marine snow is a continuous shower of organic debris — dead plankton, fecal pellets, and mucus — that drifts down from the sunlit surface. It can take weeks to reach the deep ocean floor. This slow rain is the primary food source for most abyssal life and plays a critical role in the ocean's carbon cycle, transporting carbon from the atmosphere to the deep sea."
        ),
        .init(
            depth: 4500,
            name: "Hydrothermal Vents",
            image: "flame.fill",
            category: .oceanography,
            description: "Hydrothermal vents are fissures in the seafloor that spew superheated, mineral-rich water at temperatures exceeding 400°C. Black smokers get their name from dark plumes of metal sulfides. Despite the extreme heat, pressure, and total darkness, thriving ecosystems cluster around them — giant tube worms, blind shrimp, and chemosynthetic bacteria that convert hydrogen sulfide into energy, independent of sunlight."
        ),
        .init(
            depth: 4700,
            name: "Bismarck Wreck",
            image: "ferry.fill",
            category: .humanHistory,
            description: "The German battleship Bismarck, sunk in 1941 after a dramatic North Atlantic chase, rests at 4,790 meters. Discovered by Robert Ballard in 1989, the wreck sits upright on an underwater volcano slope, remarkably intact despite the extreme depth."
        ),
        .init(
            depth: 5000,
            name: "Brine Pools",
            image: "water.waves",
            category: .oceanography,
            description: "Brine pools are lakes of super-salty water on the ocean floor. Their extreme salinity is toxic to most sea life, creating a 'shore' of dead organisms around their edges."
        ),
        .init(
            depth: 5500,
            name: "Deep-Sea Mining",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "Vast fields of polymetallic nodules — potato-sized lumps rich in manganese, nickel, cobalt, and copper — cover the abyssal plains at 4,000–6,000 meters. Mining these nodules would destroy habitats that took millions of years to form, stir up sediment plumes that could smother filter-feeding organisms across thousands of square kilometers, and disrupt one of the least understood ecosystems on Earth."
        ),

        // MARK: Hadal Zone (6000–11000m)
        .init(
            depth: 6000,
            name: "Hadal Zone",
            image: "arrow.down.to.line",
            category: .oceanography,
            description: "The hadal zone (hadalpelagic, 6,000–11,000m) exists only in deep ocean trenches. The Mariana Trench's Challenger Deep, at nearly 11,000 meters, is the deepest point on Earth. Even here, life persists — amphipods and xenophyophores have been found at the very bottom."
        ),
        .init(
            depth: 6500,
            name: "Shinkai 6500",
            image: "arrow.down.circle.fill",
            category: .humanHistory,
            description: "Japan's Shinkai 6500, operational since 1989, is the deepest-diving crewed research submersible in active service, rated to 6,527 meters. It has completed over 1,500 dives, studying hydrothermal vents, subduction zones, and deep-sea biodiversity across the world's oceans."
        ),
        .init(
            depth: 7500,
            name: "Xenophyophores",
            image: "circle.dashed",
            category: .species,
            description: "Xenophyophores are giant single-celled organisms found on the deep ocean floor, some exceeding 10 centimeters across. Despite being individual cells, they build elaborate shells from sediment and debris. They have been found at depths exceeding 10,600 meters."
        ),
        .init(
            depth: 8000,
            name: "Mariana Snailfish",
            image: "fish",
            category: .species,
            description: "The Mariana snailfish (Pseudoliparis swirei) is the deepest-living fish ever recorded, found at 8,178 meters in the Mariana Trench. Its translucent, gelatinous body is adapted to withstand over 800 atmospheres of pressure."
        ),
        .init(
            depth: 10000,
            name: "Trench Pollution",
            image: "exclamationmark.triangle.fill",
            category: .humanImpact,
            description: "Amphipods collected from the bottom of the Mariana Trench contain PCBs and other persistent organic pollutants at concentrations comparable to those found in heavily industrialized rivers. Plastic bags have been filmed at nearly 11,000 meters. No part of the ocean, however remote or deep, has escaped human contamination."
        ),
        .init(
            depth: 10920,
            name: "Challenger Deep",
            image: "arrow.down.to.line.circle.fill",
            category: .humanHistory,
            description: "In 1960, Jacques Piccard and Don Walsh descended to 10,916 meters in the bathyscaphe Trieste — the first humans to reach the bottom of the ocean. In 2019, Victor Vescovo reached 10,928 meters in DSV Limiting Factor."
        ),
    ]

    let depth: Double
    let name: String
    let image: String
    let category: KnowledgeableCategory
    let description: String
    /// Base time in simulated seconds to discover this item (multiplied by pickupSpeedMultiplier).
    var pickupDuration: TimeInterval = 1.5

    var id: String { name }
}
