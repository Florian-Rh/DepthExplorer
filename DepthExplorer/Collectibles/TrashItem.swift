import Foundation

/// A piece of trash the diver can pick up during a dive session.
/// Trash is placed randomly within a depth range and awards Sand Dollars on collection.
/// Sand Dollars are only credited when the diver surfaces safely.
struct TrashItem: Identifiable {
    let id = UUID()
    let depth: Double
    let sandDollarValue: Int
}
