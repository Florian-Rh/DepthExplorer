import SwiftUI

/// Full-screen overlay shown after a successful dive.
///
/// Always present in the view hierarchy but invisible until triggered.
/// Stats appear one by one with numbers counting up from zero.
struct DiveCompleteOverlayView: View {
    @Binding var stats: LevelViewModel.DiveCompleteStats?
    var onDismiss: () -> Void

    @State private var overlayOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var revealedLines: Int = 0
    @State private var lineProgress: [Double] = Array(repeating: 0, count: 4)
    @State private var showButton = false
    @State private var showRecordBadges = false
    @State private var activeStats: LevelViewModel.DiveCompleteStats?

    // XP section animation state
    @State private var showXPSection = false
    @State private var xpLineProgress: [Double] = Array(repeating: 0, count: 3)
    @State private var xpTotalProgress: Double = 0

    // MARK: - Counted stat values

    private var countedDiveTime: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.diveTimeSeconds) * lineProgress[0])
    }
    private var countedMaxDepth: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.maxDepth) * lineProgress[1])
    }
    private var countedSandDollars: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.sandDollarsCollected) * lineProgress[2])
    }
    private var countedItems: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.itemsDiscovered) * lineProgress[3])
    }

    // MARK: - Counted XP values

    private var countedDiveProfileXP: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.experienceBreakdown.diveProfileXP) * xpLineProgress[0])
    }
    private var countedPersonalRecordXP: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.experienceBreakdown.personalRecordXP) * xpLineProgress[1])
    }
    private var countedDiscoveryXP: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.experienceBreakdown.discoveryXP) * xpLineProgress[2])
    }
    private var countedTotalXP: Int {
        guard let s = activeStats else { return 0 }
        return Int(Double(s.experienceBreakdown.totalXP) * xpTotalProgress)
    }

    private var diveTimeFormatted: String {
        let m = countedDiveTime / 60
        let s = countedDiveTime % 60
        return String(format: "%d:%02d", m, s)
    }

    private var totalDives: Int {
        guard let s = activeStats else { return 0 }
        return s.totalDivesBefore + 1
    }

    private var totalDiveTimeFormatted: String {
        guard let s = activeStats else { return "0:00" }
        let total = s.totalDiveTimeBefore + s.diveTimeSeconds
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Dive Complete!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Stats
                VStack(spacing: 20) {
                    statRow(
                        icon: "timer",
                        label: "Dive Time",
                        value: diveTimeFormatted,
                        lineIndex: 0,
                        isRecord: activeStats?.isTimeRecord == true
                    )

                    statRow(
                        icon: "arrow.down.to.line",
                        label: "Max Depth",
                        value: "\(countedMaxDepth) m",
                        lineIndex: 1,
                        isRecord: activeStats?.isDepthRecord == true
                    )

                    statRow(
                        icon: "dollarsign.circle.fill",
                        label: "Sand Dollars",
                        value: "+\(countedSandDollars)",
                        lineIndex: 2,
                        valueColor: .yellow
                    )

                    statRow(
                        icon: "book.fill",
                        label: "Items Discovered",
                        value: "\(countedItems)",
                        lineIndex: 3,
                        valueColor: .cyan
                    )
                }
                .padding(.horizontal, 40)

                // XP Breakdown
                xpBreakdownSection
                    .padding(.horizontal, 40)
                    .opacity(showXPSection ? 1 : 0)
                    .offset(y: showXPSection ? 0 : 10)

                // Totals (appear after counting finishes)
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 4)

                    totalRow(
                        label: "Total Dives",
                        value: "\(totalDives)"
                    )
                    totalRow(
                        label: "Total Dive Time",
                        value: totalDiveTimeFormatted
                    )
                }
                .padding(.horizontal, 40)
                .opacity(showButton ? 1 : 0)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(.white, in: Capsule())
                }
                .opacity(showButton ? 1 : 0)
                .padding(.bottom, 60)
            }
            .opacity(contentOpacity)
        }
        .opacity(overlayOpacity)
        .allowsHitTesting(overlayOpacity > 0)
        .onChange(of: stats != nil) { _, isPresent in
            if isPresent, let s = stats {
                show(stats: s)
            }
        }
    }

    // MARK: - XP Breakdown Section

    @ViewBuilder
    private var xpBreakdownSection: some View {
        let breakdown = activeStats?.experienceBreakdown

        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 2)

            Text("Experience Earned")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            xpRow(
                label: "Dive Profile",
                value: "+\(countedDiveProfileXP) XP",
                xpIndex: 0
            )

            if breakdown?.personalRecordXP ?? 0 > 0 {
                xpRow(
                    label: "Personal Record",
                    value: "+\(countedPersonalRecordXP) XP",
                    xpIndex: 1
                )
            }

            if breakdown?.discoveryXP ?? 0 > 0 {
                xpRow(
                    label: "\(breakdown?.itemDetails.count ?? 0) Discovered Item\(breakdown?.itemDetails.count == 1 ? "" : "s")",
                    value: "+\(countedDiscoveryXP) XP",
                    xpIndex: 2
                )
            }

            // Total XP
            HStack {
                Text("Total")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text("+\(countedTotalXP) XP")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func xpRow(label: String, value: String, xpIndex: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.green.opacity(0.85))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    @ViewBuilder
    private func statRow(
        icon: String,
        label: String,
        value: String,
        lineIndex: Int,
        valueColor: Color = .white,
        isRecord: Bool = false
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 28)

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            if isRecord && showRecordBadges {
                Text("New Record!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange, in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .opacity(revealedLines > lineIndex ? 1 : 0)
        .offset(y: revealedLines > lineIndex ? 0 : 15)
    }

    @ViewBuilder
    private func totalRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .monospacedDigit()
        }
    }

    // MARK: - Animation

    private func show(stats: LevelViewModel.DiveCompleteStats) {
        activeStats = stats
        revealedLines = 0
        lineProgress = Array(repeating: 0, count: 4)
        showButton = false
        showRecordBadges = false
        showXPSection = false
        xpLineProgress = Array(repeating: 0, count: 3)
        xpTotalProgress = 0
        contentOpacity = 0

        // Fade in overlay
        withAnimation(.easeIn(duration: 0.6)) {
            overlayOpacity = 1
            contentOpacity = 1
        } completion: {
            revealLines()
        }
    }

    private func revealLines() {
        let lineDelay = 0.5
        let countDuration = 0.8

        for i in 0..<4 {
            let delay = lineDelay * Double(i)

            // Reveal the line
            withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                revealedLines = i + 1
            }

            // Start counting for this line immediately after it appears
            withAnimation(.easeOut(duration: countDuration).delay(delay + 0.15)) {
                lineProgress[i] = 1.0
            }
        }

        // Show record badges after the last stat line finishes counting
        let statsEndDelay = lineDelay * 3 + 0.15 + countDuration + 0.1

        withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(statsEndDelay)) {
            showRecordBadges = true
        }

        // Reveal XP section after record badges
        let xpSectionDelay = statsEndDelay + 0.0

        withAnimation(.easeOut(duration: 0.4).delay(xpSectionDelay)) {
            showXPSection = true
        }

        // Count up XP lines
        let xpCountDelay = xpSectionDelay + 0.2
        let xpCountDuration = 0.35

        for i in 0..<3 {
            withAnimation(.easeOut(duration: xpCountDuration).delay(xpCountDelay + 0.15 * Double(i))) {
                xpLineProgress[i] = 1.0
            }
        }

        // Count up total XP after individual lines
        let xpTotalDelay = xpCountDelay + 0.15 * 2 + xpCountDuration + 0.05
        withAnimation(.easeOut(duration: xpCountDuration).delay(xpTotalDelay)) {
            xpTotalProgress = 1.0
        }

        // Show totals and button after XP finishes
        withAnimation(.easeIn(duration: 0.3).delay(xpTotalDelay + xpCountDuration + 0.15)) {
            showButton = true
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.4)) {
            overlayOpacity = 0
            contentOpacity = 0
        } completion: {
            activeStats = nil
            revealedLines = 0
            lineProgress = Array(repeating: 0, count: 4)
            showButton = false
            showRecordBadges = false
            showXPSection = false
            xpLineProgress = Array(repeating: 0, count: 3)
            xpTotalProgress = 0
            stats = nil
            onDismiss()
        }
    }
}

#Preview {
    @Previewable @State var stats: LevelViewModel.DiveCompleteStats? = .init(
        diveTimeSeconds: 754,
        maxDepth: 87,
        sandDollarsCollected: 24,
        itemsDiscovered: 3,
        totalDivesBefore: 11,
        totalDiveTimeBefore: 8420,
        isDepthRecord: true,
        isTimeRecord: false,
        experienceBreakdown: ExperienceBreakdown(
            diveProfileXP: 56,
            personalRecordXP: 50,
            discoveryXP: 170,
            itemDetails: [
                (name: "Clownfish", xp: 51),
                (name: "Sea Turtle", xp: 60),
                (name: "Deepest Scuba Dive", xp: 83)
            ],
            brokeDepthRecord: true,
            brokeTimeRecord: false
        )
    )

    DiveCompleteOverlayView(
        stats: $stats,
        onDismiss: {}
    )
}
