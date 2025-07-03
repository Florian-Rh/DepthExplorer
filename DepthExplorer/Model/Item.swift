//
//  Item.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 11.06.25.
//

import Foundation

// TODO: rename more appropriately
struct Item: Identifiable {
    let depth: Double
    let name: String
    let image: String
    let description: String?

    var id: String { self.name }

    static let allItems: [Self] = [
        .init(depth: 10, name: "Fischi", image: "fish", description: "Das ist 1 Fischi"),
        .init(depth: 100, name: "Panzi", image: "tortoise", description: "Das ist 1 Kröti"),
        .init(depth: 400, name: "Typi", image: "figure.dance", description: nil),
        .init(depth: 1000, name: "Mülli", image: "scooter", description: "eScooter, die ins Meer geworfen werden, stellen ein ernsthaftes Umweltproblem dar. Ihre Batterien enthalten Schwermetalle und Chemikalien, die ins Wasser gelangen und Meerestiere sowie das Ökosystem schädigen können. Zudem verschmutzen sie den Lebensraum und verursachen Kosten für Bergung und Entsorgung."),
        .init(depth: 4000, name: "Tiefi", image: "square.and.arrow.down", description: "5000 Meter ist schon ganz schön tief!"),
    ]
}
