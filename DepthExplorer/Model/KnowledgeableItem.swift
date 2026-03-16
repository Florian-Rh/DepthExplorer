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
            depth: 332,
            name: "Deepest Scuba Dive",
            image: "figure.scuba.diving",
            category: .humanHistory,
            description: "In 2014, Ahmed Gabr set the world record for the deepest scuba dive at 332.35 meters in the Red Sea."
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
            name: "Brine Pools",
            image: "water.waves",
            category: .oceanography,
            description: "Brine pools are lakes of super-salty water on the ocean floor. Their extreme salinity is toxic to most sea life, creating a 'shore' of dead organisms around their edges."
        ),
    ]

    let depth: Double
    let name: String
    let image: String
    let category: KnowledgeableCategory
    let description: String

    var id: String { name }
}
