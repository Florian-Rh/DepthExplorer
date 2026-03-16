import Foundation

/// Identifies which survival factor produced the warning.
enum DiveWarningKind: String, CaseIterable {
    case airSupply
    case thermal
    case decompression
    case narcosis
    case barotrauma
}

/// Severity of a dive warning. Ordered from least to most severe.
enum DiveWarningSeverity: Int, Comparable {
    /// Player is approaching a soft limit. Informational.
    case caution = 0
    /// Player is near a failure threshold. Urgent.
    case critical = 1
    /// Player has exceeded the threshold. Rescue is imminent.
    case fatal = 2

    static func < (lhs: DiveWarningSeverity, rhs: DiveWarningSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single active warning produced by a survival factor.
struct DiveWarning: Identifiable, Equatable {
    let kind: DiveWarningKind
    let severity: DiveWarningSeverity
    let message: String

    var id: DiveWarningKind { kind }
}

/// Manages the set of active dive warnings.
/// Survival factors call `set(_:)` to post or update a warning,
/// and `clear(_:)` to remove it when conditions improve.
class DiveWarningSystem: ObservableObject {
    @Published private(set) var activeWarnings: [DiveWarning] = []

    /// The highest severity among all active warnings, or `nil` if none.
    var highestSeverity: DiveWarningSeverity? {
        activeWarnings.map(\.severity).max()
    }

    /// Post or update a warning for the given kind.
    /// Replaces any existing warning of the same kind.
    func set(_ warning: DiveWarning) {
        if let index = activeWarnings.firstIndex(where: { $0.kind == warning.kind }) {
            if activeWarnings[index] != warning {
                activeWarnings[index] = warning
            }
        } else {
            activeWarnings.append(warning)
        }
    }

    /// Remove the warning for the given kind, if present.
    func clear(_ kind: DiveWarningKind) {
        activeWarnings.removeAll { $0.kind == kind }
    }

    /// Remove all active warnings. Called when a dive session ends.
    func clearAll() {
        activeWarnings.removeAll()
    }
}
