import SwiftUI

/// A vertical bar-segment ascent rate indicator, modeled after real dive computers.
///
/// Displays a column of horizontal segments that fill from bottom to top as
/// ascent speed increases. The segments are color-coded:
/// - Green: safe zone (below warning threshold)
/// - Yellow: caution zone (warning → critical)
/// - Red: danger zone (critical and above)
struct AscentRateBarView: View {
    /// Current ascent speed in m/s (positive = ascending).
    let ascentSpeed: Double

    private let segmentCount = 8
    private let maxDisplaySpeed = GameConstants.safeAscentSpeed * GameConstants.dcsFatalFraction
    private let warnFraction = GameConstants.dcsWarningFraction / GameConstants.dcsFatalFraction
    private let critFraction = GameConstants.dcsCriticalFraction / GameConstants.dcsFatalFraction

    /// How many segments are "filled" (0...segmentCount).
    private var filledCount: Int {
        let fraction = max(0, min(1, ascentSpeed / maxDisplaySpeed))
        return Int((fraction * Double(segmentCount)).rounded(.up))
    }

    /// Returns the zone color for a segment at the given index (0 = bottom).
    private func segmentColor(index: Int) -> Color {
        let segmentFraction = Double(index + 1) / Double(segmentCount)
        if segmentFraction > critFraction {
            return .red
        } else if segmentFraction > warnFraction {
            return .yellow
        } else {
            return Color(red: 0.2, green: 0.85, blue: 0.4)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            // Label at top
            Text("ASC")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            // Segments from top (highest speed) to bottom (lowest speed)
            VStack(spacing: 2) {
                ForEach((0..<segmentCount).reversed(), id: \.self) { index in
                    let isFilled = index < filledCount
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(isFilled ? segmentColor(index: index) : Color.white.opacity(0.12))
                        .frame(height: 4)
                }
            }
        }
        .frame(width: 18)
        .animation(.easeOut(duration: 0.15), value: filledCount)
    }
}

#Preview {
    ZStack {
        Color(white: 0.08)
        HStack(spacing: 20) {
            AscentRateBarView(ascentSpeed: 0)
            AscentRateBarView(ascentSpeed: 10)
            AscentRateBarView(ascentSpeed: 20)
            AscentRateBarView(ascentSpeed: 28)
        }
        .padding()
    }
}
