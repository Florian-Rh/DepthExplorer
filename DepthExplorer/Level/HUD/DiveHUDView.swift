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
    let safeAscentSpeedMultiplier: Double
    let warnings: [DiveWarning]
    let isDiving: Bool
    let hasScubaGear: Bool
    let hasADS: Bool
    let batteryFraction: Double
    let depthPressure: Double
    let pressureRating: Double
    let trashCollected: Int
    let carryCapacity: Int
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

    // ADS-specific derived values

    private var depthFraction: Double {
        guard pressureRating > 0 else { return 0 }
        return min(1, max(0, depthPressure / pressureRating))
    }

    private var depthLimitBarColor: Color {
        if depthFraction >= 0.95 { return .red }
        if depthFraction >= 0.80 { return .yellow }
        return Color(red: 0.2, green: 0.85, blue: 0.4)
    }

    private var batteryBarColor: Color {
        if batteryFraction <= 0.10 { return .red }
        if batteryFraction <= 0.25 { return .yellow }
        return Color(red: 0.2, green: 0.85, blue: 0.4)
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
            // ── Top row: dive time & (temperature or battery) ──────────────────
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

                if hasADS {
                    // ADS: battery indicator replaces body temperature
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("PRESSURE")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(String(format: "%.1f bar", depthPressure))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(depthLimitBarColor)
                            .monospacedDigit()
                    }
                } else {
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
            }
            .padding(.bottom, 8)

            // ── Center row: depth + (ascent rate or depth limit) ──────────────────
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

                if hasADS {
                    // ADS: depth limit bar replaces ascent rate
                    depthLimitBar
                        .frame(height: 44)
                } else if hasScubaGear {
                    AscentRateBarView(ascentSpeed: ascentSpeed, depthMeters: Double(depth), safeAscentSpeedMultiplier: safeAscentSpeedMultiplier)
                        .frame(height: 44)
                }
            }
            .padding(.bottom, 6)

            // ── Air supply bar ───────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                Text(hasScubaGear || hasADS ? "AIR" : "BREATH")
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

                        // Threshold markers (with a cylinder or ADS)
                        if hasScubaGear || hasADS {
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

                if hasScubaGear || hasADS {
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

            // ── Battery bar (ADS only) ────────────────────────
            if hasADS {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BATTERY")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.12))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(batteryBarColor.opacity(0.85))
                                .frame(width: geo.size.width * batteryFraction)
                                .animation(.linear(duration: 0.3), value: batteryFraction)

                            // Threshold markers
                            Rectangle()
                                .fill(Color.yellow.opacity(0.7))
                                .frame(width: 1.5)
                                .offset(x: geo.size.width * 0.25)

                            Rectangle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 1.5)
                                .offset(x: geo.size.width * 0.10)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.top, 4)
            }

            // ── Bag capacity indicator ────────────────────────
            if isDiving {
                HStack(spacing: 4) {
                    Image(systemName: trashCollected >= carryCapacity ? "bag.fill" : "bag")
                        .font(.system(size: 10))
                        .foregroundStyle(trashCollected >= carryCapacity ? .orange : .white.opacity(0.6))
                    Text("\(trashCollected)/\(carryCapacity)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(trashCollected >= carryCapacity ? .orange : .white)
                        .monospacedDigit()
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Depth limit bar (ADS)

    /// Vertical bar showing current depth as fraction of the ADS pressure rating.
    /// Fills from bottom to top with green→yellow→red color zones.
    private var depthLimitBar: some View {
        HStack(alignment: .bottom, spacing: 4) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("HULL")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Text(String(format: "%d%%", Int(depthFraction * 100)))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(depthLimitBarColor)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(depthLimitBarColor.opacity(0.85))
                        .frame(height: geo.size.height * depthFraction)
                        .animation(.linear(duration: 0.3), value: depthFraction)

                    // 80% warning marker
                    Rectangle()
                        .fill(Color.yellow.opacity(0.7))
                        .frame(height: 1.5)
                        .offset(y: -geo.size.height * 0.80)

                    // 95% critical marker
                    Rectangle()
                        .fill(Color.red.opacity(0.7))
                        .frame(height: 1.5)
                        .offset(y: -geo.size.height * 0.95)
                }
            }
            .frame(width: 8)
        }
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
            safeAscentSpeedMultiplier: 1.0,
            warnings: [],
            isDiving: true,
            hasScubaGear: true,
            hasADS: false,
            batteryFraction: 1.0,
            depthPressure: 0,
            pressureRating: 0,
            trashCollected: 1,
            carryCapacity: 5,
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
            safeAscentSpeedMultiplier: 1.0,
            warnings: [
                DiveWarning(kind: .airSupply, severity: .caution, message: "38 bar remaining"),
                DiveWarning(kind: .thermal, severity: .critical, message: "Hypothermia setting in (35.5°C)")
            ],
            isDiving: true,
            hasScubaGear: true,
            hasADS: false,
            batteryFraction: 1.0,
            depthPressure: 0,
            pressureRating: 0,
            trashCollected: 5,
            carryCapacity: 5,
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
            safeAscentSpeedMultiplier: 1.0,
            warnings: [],
            isDiving: true,
            hasScubaGear: false,
            hasADS: false,
            batteryFraction: 1.0,
            depthPressure: 0,
            pressureRating: 0,
            trashCollected: 2,
            carryCapacity: 3,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}

#Preview("ADS") {
    ZStack {
        Color(white: 0.08)
        DiveHUDView(
            depth: 380,
            diveTimeSeconds: 900,
            remainingBar: 280,
            airCapacity: 400,
            ascentSpeed: 0,
            bodyTemperature: 37,
            safeAscentSpeedMultiplier: 1.0,
            warnings: [],
            isDiving: true,
            hasScubaGear: false,
            hasADS: true,
            batteryFraction: 0.72,
            depthPressure: 39.0,
            pressureRating: 51.0,
            trashCollected: 3,
            carryCapacity: 5,
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
            safeAscentSpeedMultiplier: 1.0,
            warnings: [],
            isDiving: false,
            hasScubaGear: true,
            hasADS: false,
            batteryFraction: 1.0,
            depthPressure: 0,
            pressureRating: 0,
            trashCollected: 0,
            carryCapacity: 3,
            onJoystickChanged: { _, _ in }
        )
        .padding(.horizontal, 16)
    }
}
