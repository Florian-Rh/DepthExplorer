import SwiftUI

/// A unified bottom-bar HUD combining dive instruments and joystick input.
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────────────────┐
/// │ DIVE TIME   42   TEMP  │                         │
/// │  12:34    ▮▮ m  36°C   │      (joystick)         │
/// │ 145 bar ████████░░ AIR │                         │
/// ├──────────────────────────────────────────────────┤
/// │ ⚠ Hypothermia setting in (35.5°C)                │
/// └──────────────────────────────────────────────────┘
/// ```
struct DiveHUDView: View {
    let depth: Int
    let diveTimeSeconds: Int
    let remainingBar: Double
    let airCapacity: Double
    let ascentSpeed: Double
    let bodyTemperature: Double
    let warnings: [DiveWarning]
    let isDiving: Bool
    let hasScubaGear: Bool
    var onJoystickChanged: (_ offset: CGSize, _ angleDegrees: Double?) -> Void

    // MARK: - Derived values

    private var diveTimeFormatted: String {
        let minutes = diveTimeSeconds / 60
        let seconds = diveTimeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var airFraction: Double {
        max(0, min(1, remainingBar / airCapacity))
    }

    private var airBarColor: Color {
        if airFraction <= GameConstants.airCriticalFraction { return .red }
        if airFraction <= GameConstants.airWarningFraction { return .yellow }
        return Color(red: 0.2, green: 0.85, blue: 0.4)
    }

    private var temperatureFormatted: String {
        String(format: "%.1f°C", bodyTemperature)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ── Main row: instruments + joystick ──────────────────────
            HStack(spacing: 0) {
                // Left: instrument panel
                instrumentPanel
                    .frame(maxWidth: .infinity)

                // Divider — fixed height to match instrument panel
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 100)
                    .padding(.vertical, 4)

                // Right: joystick
                JoystickView(onChanged: onJoystickChanged)
                    .frame(width: 120)
            }

            // ── Full-width warning banner (space always reserved) ─────
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 4)

            WarningBannerView(warnings: warnings)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: warnings.count)
    }

    // MARK: - Instrument panel (left side)

    private var instrumentPanel: some View {
        VStack(spacing: 0) {
            // ── Top row: dive time & temperature ──────────────────
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("DIVE TIME")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(isDiving ? diveTimeFormatted : "--:--")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("BODY TEMP")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(temperatureFormatted)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
            .padding(.bottom, 8)

            // ── Center row: depth + ascent rate ──────────────────
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .bottom, spacing: 0) {
                    Text(String(format: "%05d", depth))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text(" m")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 2)
                }

                Spacer()

                if hasScubaGear {
                    AscentRateBarView(ascentSpeed: ascentSpeed)
                        .frame(height: 44)
                }
            }
            .padding(.bottom, 6)

            // ── Air supply bar ───────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                Text(hasScubaGear ? "AIR" : "BREATH")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(airBarColor.opacity(0.85))
                            .frame(width: geo.size.width * airFraction)
                            .animation(.linear(duration: 0.3), value: airFraction)

                        // Threshold markers (only with a cylinder)
                        if hasScubaGear {
                            Rectangle()
                                .fill(Color.yellow.opacity(0.7))
                                .frame(width: 1.5)
                                .offset(x: geo.size.width * GameConstants.airWarningFraction)

                            Rectangle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 1.5)
                                .offset(x: geo.size.width * GameConstants.airCriticalFraction)
                        }
                    }
                }
                .frame(height: 5)

                if hasScubaGear {
                    HStack(spacing: 0) {
                        Text(String(format: "%03d", Int(remainingBar)))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        Text(" bar")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))

                        Spacer()
                    }
                } else {
                    HStack(spacing: 0) {
                        Text(String(format: "%d%%", Int(airFraction * 100)))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview("Diving") {
    ZStack {
        Color(white: 0.08)
        DiveHUDView(
            depth: 42,
            diveTimeSeconds: 754,
            remainingBar: 145,
            airCapacity: 200,
            ascentSpeed: 5,
            bodyTemperature: 36.2,
            warnings: [],
            isDiving: true,
            hasScubaGear: true,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Warnings") {
    ZStack {
        Color(white: 0.08)
        DiveHUDView(
            depth: 85,
            diveTimeSeconds: 1200,
            remainingBar: 38,
            airCapacity: 200,
            ascentSpeed: 18,
            bodyTemperature: 35.5,
            warnings: [
                DiveWarning(kind: .airSupply, severity: .caution, message: "38 bar remaining"),
                DiveWarning(kind: .thermal, severity: .critical, message: "Hypothermia setting in (35.5°C)")
            ],
            isDiving: true,
            hasScubaGear: true,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Apnoe") {
    ZStack {
        Color(white: 0.08)
        DiveHUDView(
            depth: 15,
            diveTimeSeconds: 90,
            remainingBar: 32,
            airCapacity: 50,
            ascentSpeed: 0,
            bodyTemperature: 36.8,
            warnings: [],
            isDiving: true,
            hasScubaGear: false,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Surface") {
    ZStack {
        Color(white: 0.08)
        DiveHUDView(
            depth: 0,
            diveTimeSeconds: 0,
            remainingBar: 200,
            airCapacity: 200,
            ascentSpeed: 0,
            bodyTemperature: 37,
            warnings: [],
            isDiving: false,
            hasScubaGear: true,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}
