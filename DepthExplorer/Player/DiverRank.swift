import Foundation

/// Diver rank titles awarded at specific level thresholds.
///
/// Each rank represents a milestone in the player's progression and
/// reflects increasing diving expertise.
enum DiverRank: String, CaseIterable {
    case freeDiver = "Free Diver"
    case scubaDiver = "Scuba Diver"
    case techDiver = "Tech Diver"
    case marineSpecialist = "Marine Specialist"
    case oceanographer = "Oceanographer"

    /// The minimum player level required to hold this rank.
    var minimumLevel: Int {
        switch self {
        case .freeDiver: return 1
        case .scubaDiver: return 5
        case .techDiver: return 9
        case .marineSpecialist: return 15
        case .oceanographer: return 20
        }
    }

    /// A short description of what this rank represents.
    var description: String {
        switch self {
        case .freeDiver:
            return "You're just starting out, exploring the shallow waters with nothing but your lungs and determination. Free divers rely on breath-holding techniques and can only reach modest depths."
        case .scubaDiver:
            return "Holding your breath only get's you so far. With your first scuba certificate, you can bring compressed air with you. Be aware though: When when breathing pressurized air, you have to ascent more slowly, or you will risk decompression sickness!"
        case .techDiver:
            return "A seasoned diver with advanced training. Using different gas mixtures allows you to reduce the decompression risk and dive deeper and longer. There is a limit to everything though, and eventually the immense water pressure will take it's toll."
        case .marineSpecialist:
            return "Your deep-sea expertise has earned you recognition as a marine specialist. Research teams will grant you access to their deep sea exploration equipment, allowing you to go way past the limits of a human body – it won't be cheap though."
        case .oceanographer:
            return "The pinnacle of underwater exploration. As Oceanographer, you have mastered every aspect of diving and possess an encyclopedic knowledge of the deep. The entire ocean is your domain."
        }
    }

    /// Determine the rank for a given player level.
    static func rank(forLevel level: Int) -> DiverRank {
        // Iterate in reverse so the highest qualifying rank is found first.
        for rank in DiverRank.allCases.reversed() {
            if level >= rank.minimumLevel {
                return rank
            }
        }
        return .freeDiver
    }
}
