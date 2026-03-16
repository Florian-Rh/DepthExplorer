import SwiftUI

/// A compact dive computer showing current depth and an ascent-speed gauge.
///
/// The ascent gauge is a semicircular arc. The arc is divided into three
/// coloured zones (green / yellow / red) corresponding to safe, caution, and
/// critical thresholds. A needle sweeps from 0 (left) to maximum speed (right).
struct DiveComputerView: View {
    let depth: Int
    let ascentSpeed: Double     // m/s real time, positive = ascending

    // Thresholds
    private let maxDisplaySpeed = GameConstants.safeAscentSpeed * GameConstants.dcsFatalFraction
    private let warnSpeed  = GameConstants.safeAscentSpeed * GameConstants.dcsWarningFraction
    private let critSpeed  = GameConstants.safeAscentSpeed * GameConstants.dcsCriticalFraction
    private let fatalSpeed = GameConstants.safeAscentSpeed * GameConstants.dcsFatalFraction

    // Needle position: 0.0 = fully left, 1.0 = fully right
    private var needleFraction: Double {
        max(0, min(1, ascentSpeed / maxDisplaySpeed))
    }

    var body: some View {
        VStack(spacing: 6) {
            // ── Depth readout ──────────────────────────────────────────────
            VStack(spacing: 1) {
                Text("\(depth)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("m")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }

            // ── Ascent speed gauge ─────────────────────────────────────────
            AscentGauge(
                needleFraction: needleFraction,
                warnFraction:  warnSpeed  / maxDisplaySpeed,
                critFraction:  critSpeed  / maxDisplaySpeed
            )
            .frame(height: 50)

            Text("ascent")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Ascent gauge arc

private struct AscentGauge: View {
    let needleFraction: Double  // 0–1
    let warnFraction: Double    // fraction of arc where caution starts
    let critFraction: Double    // fraction of arc where critical starts

    // Arc sweeps from -180° to 0° (left half-circle opening downward)
    private let startAngle: Double = 180   // degrees, measured from 3-o'clock
    private let endAngle: Double   = 0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let cx = size.width / 2
            let cy = size.height          // centre at the bottom edge so the arc opens upward
            let radius = min(cx, cy) - 6

            ZStack {
                // ── Background track ──────────────────────────────────────
                ArcShape(startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: cx, y: cy)

                // ── Coloured zones ────────────────────────────────────────
                // Green zone: 0 → warn
                arcSegment(from: 0, to: warnFraction, radius: radius, cx: cx, cy: cy, color: Color(red: 0.2, green: 0.85, blue: 0.4))
                // Yellow zone: warn → crit
                arcSegment(from: warnFraction, to: critFraction, radius: radius, cx: cx, cy: cy, color: .yellow)
                // Red zone: crit → 1.0
                arcSegment(from: critFraction, to: 1.0, radius: radius, cx: cx, cy: cy, color: .red)

                // ── Needle ────────────────────────────────────────────────
                let needleAngleRad = angleRad(for: needleFraction)
                let needleTip = CGPoint(
                    x: cx + CGFloat(cos(needleAngleRad)) * (radius - 4),
                    y: cy + CGFloat(sin(needleAngleRad)) * (radius - 4)
                )
                Path { path in
                    path.move(to: CGPoint(x: cx, y: cy))
                    path.addLine(to: needleTip)
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .animation(.easeOut(duration: 0.15), value: needleFraction)

                // Centre dot
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 6, height: 6)
                    .position(x: cx, y: cy)
            }
        }
    }

    // Angle in radians for a given 0–1 fraction along the arc (left → right).
    // The arc goes from 180° to 0° (measured from the standard 3-o'clock zero).
    private func angleRad(for fraction: Double) -> Double {
        let deg = 180.0 - fraction * 180.0   // 180° (left) → 0° (right)
        return deg * .pi / 180.0
    }

    @ViewBuilder
    private func arcSegment(from: Double, to: Double, radius: CGFloat, cx: CGFloat, cy: CGFloat, color: Color) -> some View {
        let startDeg = 180.0 - from * 180.0
        let endDeg   = 180.0 - to   * 180.0
        ArcShape(startAngle: startDeg, endAngle: endDeg, clockwise: false)
            .stroke(color.opacity(0.75), style: StrokeStyle(lineWidth: 8, lineCap: .butt))
            .frame(width: radius * 2, height: radius * 2)
            .position(x: cx, y: cy)
    }
}

// MARK: - Helper: draws an arc path

private struct ArcShape: Shape {
    var startAngle: Double  // degrees, standard math convention (3-o'clock = 0)
    var endAngle: Double
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        var p = Path()
        p.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: r,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: clockwise
        )
        return p
    }
}

#Preview {
    ZStack {
        Color(white: 0.08)
        VStack(spacing: 20) {
            DiveComputerView(depth: 42, ascentSpeed: 0)
            DiveComputerView(depth: 42, ascentSpeed: 16)
            DiveComputerView(depth: 42, ascentSpeed: 25)
        }
        .frame(width: 150)
    }
}
