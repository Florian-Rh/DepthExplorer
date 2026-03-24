import SwiftUI

/// Full-screen overlay shown after a successful dive.
///
/// Always present in the view hierarchy but invisible until triggered.
/// Stats appear one by one with numbers counting up from zero.
struct DiveCompleteOverlayView: View {
    @Binding var stats: LevelViewModel.DiveCompleteStats?
    var onDismiss: () -> Void
    var onOpenSkillTree: (() -> Void)?

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

    // Level progress bar animation state
    @State private var showLevelProgress = false
    @State private var levelBarFill: Double = 0

    // Rank promotion animation state
    @State private var showRankPromotion = false
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showRankInfo = false

    /// Set to `true` only when the full animation sequence has completed.
    @State private var animationFinished = false

    /// Animation speed multiplier. 1.0 = normal, 0.0 = instant.
    /// `skipToEnd()` sets this to 0, causing all pending steps to resolve immediately.
    @State private var animationSpeedMultiplier: Double = 1.0

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

    /// The rank the player was promoted to, if any.
    private var promotedRank: DiverRank? {
        guard let s = activeStats else { return nil }
        let before = LevelProgression.from(totalXP: s.totalXPBefore)
        let after = LevelProgression.from(totalXP: s.totalXPBefore + s.experienceBreakdown.totalXP)
        let rankBefore = DiverRank.rank(forLevel: before.level)
        let rankAfter = DiverRank.rank(forLevel: after.level)
        return rankAfter != rankBefore ? rankAfter : nil
    }

    /// The post-dive level progression (for rank info sheet).
    private var afterProgression: LevelProgression? {
        guard let s = activeStats else { return nil }
        return LevelProgression.from(totalXP: s.totalXPBefore + s.experienceBreakdown.totalXP)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.85)
                ScrollView {
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

                        // Level progress bar
                        levelProgressSection
                            .padding(.horizontal, 40)
                            .opacity(showLevelProgress ? 1 : 0)
                            .offset(y: showLevelProgress ? 0 : 10)

                        // Rank promotion banner
                        if let newRank = promotedRank {
                            rankPromotionBanner(rank: newRank)
                                .padding(.horizontal, 40)
                                .opacity(showRankPromotion ? 1 : 0)
                                .scaleEffect(showRankPromotion ? 1 : 0.7)
                        }

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
                    .safeAreaPadding(.top)
                }

                // Confetti particles overlay
                if !confettiParticles.isEmpty {
                    ConfettiOverlay(particles: confettiParticles)
                        .allowsHitTesting(false)
                }

                // Tap-to-skip layer: covers entire overlay while animation is playing.
                // Removed once the animation has fully completed, so the
                // Continue and Level Up buttons can receive taps.
                if !animationFinished {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            skipToEnd()
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .opacity(overlayOpacity)
        .allowsHitTesting(overlayOpacity > 0)
        .sheet(isPresented: $showRankInfo) {
            if let rank = promotedRank {
                RankInfoSheet(currentRank: rank, currentLevel: afterProgression?.level ?? 1)
            }
        }
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

    // MARK: - Level Progress Section

    @ViewBuilder
    private var levelProgressSection: some View {
        if let s = activeStats {
            let before = LevelProgression.from(totalXP: s.totalXPBefore)
            let after = LevelProgression.from(totalXP: s.totalXPBefore + s.experienceBreakdown.totalXP)

            VStack(spacing: 8) {
                HStack {
                    Text("Level \(after.level)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.cyan)

                    Spacer()

                    Text("\(after.xpToNextLevel) XP to next level")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.12))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.7), .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * levelBarFill)
                    }
                }
                .frame(height: 8)

                // XP numbers under the bar
                HStack {
                    Text("\(after.currentLevelXP)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    Text("\(after.requiredLevelXP) XP")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Level-up badge if the player leveled up
                if after.level > before.level {
                    Button {
                        dismiss()
                        onOpenSkillTree?()
                    } label: {
                        VStack(spacing: 4) {
                            Text("Level Up!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 5)
                                .background(.cyan, in: Capsule())

                            HStack(spacing: 4) {
                                Text("+1 Skill Point")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)

                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.orange.opacity(0.7))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Rank Promotion Banner

    @ViewBuilder
    private func rankPromotionBanner(rank: DiverRank) -> some View {
        VStack(spacing: 10) {
            Text("New Rank!")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(2)

            Text(rank.rawValue)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Button {
                showRankInfo = true
            } label: {
                HStack(spacing: 4) {
                    Text("Show more")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.cyan.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cyan.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.cyan.opacity(0.25), lineWidth: 1)
                )
        )
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

    /// Scale a duration by the current animation speed. Returns at least 0.01
    /// so that completion handlers still fire.
    private func dur(_ base: Double) -> Double {
        max(base * animationSpeedMultiplier, 0.01)
    }

    /// Sleep for `base` seconds scaled by the animation speed.
    private func wait(_ base: Double) async {
        let ns = UInt64(dur(base) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
    }

    private func show(stats: LevelViewModel.DiveCompleteStats) {
        activeStats = stats
        revealedLines = 0
        lineProgress = Array(repeating: 0, count: 4)
        showButton = false
        showRecordBadges = false
        showXPSection = false
        xpLineProgress = Array(repeating: 0, count: 3)
        xpTotalProgress = 0
        showLevelProgress = false
        levelBarFill = 0
        showRankPromotion = false
        confettiParticles = []
        contentOpacity = 0
        animationFinished = false
        animationSpeedMultiplier = 1.0

        // Fade in overlay, then run the reveal sequence
        withAnimation(.easeIn(duration: 0.6)) {
            overlayOpacity = 1
            contentOpacity = 1
        }

        Task { @MainActor in
            await wait(0.6)
            await revealLines()
        }
    }

    @MainActor
    private func revealLines() async {
        // Stat lines — reveal and count each one sequentially
        for i in 0..<4 {
            withAnimation(.easeOut(duration: dur(0.3))) {
                revealedLines = i + 1
            }
            await wait(0.15)
            withAnimation(.easeOut(duration: dur(0.8))) {
                lineProgress[i] = 1.0
            }
            await wait(0.35)
        }

        // Record badges
        await wait(dur(0.1))
        withAnimation(.spring(duration: dur(0.4), bounce: 0.3)) {
            showRecordBadges = true
        }

        // XP section
        withAnimation(.easeOut(duration: dur(0.4))) {
            showXPSection = true
        }
        await wait(0.2)

        // XP line counts
        for i in 0..<3 {
            withAnimation(.easeOut(duration: dur(0.35))) {
                xpLineProgress[i] = 1.0
            }
            await wait(0.15)
        }

        // XP total
        await wait(0.05)
        withAnimation(.easeOut(duration: dur(0.35))) {
            xpTotalProgress = 1.0
        }
        await wait(dur(0.35) + 0.1)

        // Level progress bar
        withAnimation(.easeOut(duration: dur(0.4))) {
            showLevelProgress = true
        }
        await wait(0.25)

        if let s = activeStats {
            let before = LevelProgression.from(totalXP: s.totalXPBefore)
            let after = LevelProgression.from(totalXP: s.totalXPBefore + s.experienceBreakdown.totalXP)
            let startFill = before.level == after.level ? before.progress : 0
            levelBarFill = startFill

            withAnimation(.easeInOut(duration: dur(0.8))) {
                levelBarFill = after.progress
            }
            await wait(dur(0.8) + 0.15)

            // Rank promotion
            let rankBefore = DiverRank.rank(forLevel: before.level)
            let rankAfter = DiverRank.rank(forLevel: after.level)
            if rankAfter != rankBefore {
                confettiParticles = ConfettiParticle.spawn(count: 60)
                withAnimation(.spring(duration: dur(0.6), bounce: 0.4)) {
                    showRankPromotion = true
                }
                await wait(dur(0.6))
            }
        }

        // Show button and totals
        withAnimation(.easeIn(duration: dur(0.3))) {
            showButton = true
        }
        await wait(dur(0.3))
        animationFinished = true
    }

    /// Skip the reveal animation by setting speed to zero.
    /// All pending `wait()` calls resolve almost instantly, and all
    /// `dur()` durations collapse to near-zero.
    private func skipToEnd() {
        animationSpeedMultiplier = 0
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
            showLevelProgress = false
            levelBarFill = 0
            showRankPromotion = false
            confettiParticles = []
            animationFinished = false
            onDismiss()
            stats = nil
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
        ),
        totalXPBefore: 180
    )

    DiveCompleteOverlayView(
        stats: $stats,
        onDismiss: {}
    )
}

// MARK: - Confetti

/// A single confetti particle with randomized properties.
struct ConfettiParticle: Identifiable {
    let id = UUID()
    /// Normalized horizontal start position (0…1).
    let x: Double
    /// Vertical offset at creation (negative = above screen).
    let startY: Double
    let size: CGFloat
    let color: Color
    let rotation: Double
    let delay: Double

    static func spawn(count: Int) -> [ConfettiParticle] {
        let colors: [Color] = [.cyan, .blue, .green, .yellow, .orange, .pink, .purple, .white]
        return (0..<count).map { _ in
            ConfettiParticle(
                x: Double.random(in: 0...1),
                startY: Double.random(in: -60...(-10)),
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement() ?? .cyan,
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

/// Overlay that animates confetti particles falling down and fading out.
struct ConfettiOverlay: View {
    let particles: [ConfettiParticle]
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 0.6)
                        .rotationEffect(.degrees(animate ? p.rotation + 360 : p.rotation))
                        .position(
                            x: geo.size.width * p.x,
                            y: animate ? geo.size.height + 40 : p.startY
                        )
                        .opacity(animate ? 0 : 1)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 2.5)) {
                animate = true
            }
        }
    }
}
