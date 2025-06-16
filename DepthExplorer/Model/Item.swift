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
        .init(depth: 10, name: "Fischi", image: "fish", description: nil),
        .init(depth: 100, name: "Panzi", image: "tortoise", description: nil),
        .init(depth: 400, name: "Typi", image: "figure.dance", description: nil),
        .init(depth: 1000, name: "Mülli", image: "scooter", description: nil),
    ]
}
