import SwiftUI

/// Skill acquisition UI. Displays skill families as columns with level nodes.
struct SkillTreeView: View {
    @ObservedObject var profileStore: ProfileStore

    private var skillPoints: Int {
        profileStore.profile.skillPoints
    }

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
    }

    /// Maximum skill level across all families (drives the number of grid rows).
    private var maxLevel: Int {
        SkillDefinition.allSkills.map(\.level).max() ?? 3
    }

    /// Skills for a family, sorted by level.
    private func skills(for family: SkillFamily) -> [SkillDefinition] {
        SkillDefinition.allSkills
            .filter { $0.family == family }
            .sorted { $0.level < $1.level }
    }

    /// Fixed column width — wide enough for skill names and effect text.
    private let columnWidth: CGFloat = 120

    /// Tracks whether the horizontal scroll has more content to the right.
    @State private var showsScrollHint = true
    @State private var visibleWidth: CGFloat = 0

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                // Skill points indicator
                skillPointsHeader
                    .padding(.horizontal, 16)

                // Horizontally scrollable grid of skill families
                // with a trailing fade + chevron hint
                ZStack(alignment: .trailing) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        skillGrid
                            .padding(.horizontal, 16)
                            .background(alignment: .trailing) {
                                // Invisible marker at the trailing edge of the content.
                                // When its frame enters the visible area, hide the hint.
                                GeometryReader { contentGeo in
                                    Color.clear
                                        .onAppear {
                                            updateScrollHint(contentGeo)
                                        }
                                        .onChange(of: contentGeo.frame(in: .global).maxX) {
                                            updateScrollHint(contentGeo)
                                        }
                                }
                                .frame(width: 1)
                            }
                    }

                    // Fade gradient + chevron on the trailing edge
                    if showsScrollHint {
                        scrollHintOverlay
                            .transition(.opacity)
                    }
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { visibleWidth = proxy.size.width }
                            .onChange(of: proxy.size.width) { _, new in visibleWidth = new }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: showsScrollHint)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Scroll Hint

    /// A small trailing chevron pill hinting at more content.
    private var scrollHintOverlay: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, Color(white: 0.06)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 28)

            Color(white: 0.06)
                .frame(width: 28)
                .overlay {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 24, height: 36)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .trailing)
    }

    private func updateScrollHint(_ geo: GeometryProxy) {
        let trailingEdge = geo.frame(in: .global).maxX
        showsScrollHint = trailingEdge > visibleWidth + 30
    }

    // MARK: - Skill Grid

    private var skillGrid: some View {
        let families = SkillFamily.allCases

        return Grid(alignment: .center, horizontalSpacing: 12, verticalSpacing: 0) {
            // Header row: icon + family name
            GridRow {
                ForEach(families, id: \.self) { family in
                    familyHeader(family)
                        .frame(width: columnWidth)
                }
            }

            // Skill level rows (alternating: connection line row, then skill node row)
            ForEach(1...maxLevel, id: \.self) { level in
                // Connection line row
                GridRow {
                    ForEach(families, id: \.self) { family in
                        let familySkills = skills(for: family)
                        let isRedacted = family.minimumLevel.map { playerLevel < $0 } ?? false
                        if level > 1, familySkills.count >= level {
                            let prev = familySkills[level - 2]
                            let curr = familySkills[level - 1]
                            connectionLine(isActive: !isRedacted && (isAcquired(curr) || isAcquired(prev)))
                        } else {
                            Color.clear.frame(height: 20)
                        }
                    }
                }

                // Skill node row
                GridRow {
                    ForEach(families, id: \.self) { family in
                        let familySkills = skills(for: family)
                        let isRedacted = family.minimumLevel.map { playerLevel < $0 } ?? false
                        if level <= familySkills.count {
                            let skill = familySkills[level - 1]
                            if isRedacted {
                                redactedSkillNode(level: skill.level)
                                    .frame(width: columnWidth)
                            } else {
                                skillNode(skill)
                                    .frame(width: columnWidth)
                            }
                        } else {
                            Color.clear.frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var skillPointsHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)

            if skillPoints > 0 {
                Text("\(skillPoints) skill point\(skillPoints == 1 ? "" : "s") available")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.orange)
            } else {
                Text("No skill points — level up to earn more")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(skillPoints > 0 ? Color.orange.opacity(0.1) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    skillPoints > 0 ? Color.orange.opacity(0.25) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Family Header

    private func familyHeader(_ family: SkillFamily) -> some View {
        let isRedacted = family.minimumLevel.map { playerLevel < $0 } ?? false

        return VStack(spacing: 6) {
            Image(systemName: isRedacted ? "lock.fill" : family.icon)
                .font(.system(size: 24))
                .foregroundStyle(isRedacted ? .white.opacity(0.2) : .cyan)
                .frame(height: 24)

            Text(isRedacted ? "???" : family.displayName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isRedacted ? .white.opacity(0.2) : .white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if isRedacted, let minLevel = family.minimumLevel {
                Text("Unlocks at Lv. \(minLevel)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Skill Node

    private func skillNode(_ skill: SkillDefinition) -> some View {
        let acquired = isAcquired(skill)
        let available = canAcquire(skill)

        return Button {
            guard available else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                profileStore.acquireSkill(id: skill.id)
            }
        } label: {
            VStack(spacing: 6) {
                // Level indicator
                ZStack {
                    Circle()
                        .fill(nodeBackgroundColor(acquired: acquired, available: available))
                        .frame(width: 52, height: 52)

                    Circle()
                        .strokeBorder(
                            nodeBorderColor(acquired: acquired, available: available),
                            lineWidth: 2
                        )
                        .frame(width: 52, height: 52)

                    Text("L\(skill.level)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(nodeTextColor(acquired: acquired, available: available))
                }

                // Skill name
                Text(skill.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(acquired ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)

                // Effect
                Text(skill.effectDescription)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(acquired ? .cyan.opacity(0.8) : .white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .disabled(!available)
    }

    // MARK: - Redacted Skill Node

    private func redactedSkillNode(level: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 52, height: 52)

                Circle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 2)
                    .frame(width: 52, height: 52)

                Text("L\(level)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.15))
            }

            Text("???")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)

            Text("???")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.15))
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Connection Line

    private func connectionLine(isActive: Bool) -> some View {
        Rectangle()
            .fill(isActive ? Color.cyan.opacity(0.4) : Color.white.opacity(0.12))
            .frame(width: 2, height: 20)
    }

    // MARK: - Node Colors

    private func nodeBackgroundColor(acquired: Bool, available: Bool) -> Color {
        if acquired { return .cyan.opacity(0.2) }
        if available { return .orange.opacity(0.15) }
        return .white.opacity(0.05)
    }

    private func nodeBorderColor(acquired: Bool, available: Bool) -> Color {
        if acquired { return .cyan }
        if available { return .orange.opacity(0.6) }
        return .white.opacity(0.15)
    }

    private func nodeTextColor(acquired: Bool, available: Bool) -> Color {
        if acquired { return .cyan }
        if available { return .orange }
        return .white.opacity(0.3)
    }

    // MARK: - Logic

    private func isAcquired(_ skill: SkillDefinition) -> Bool {
        profileStore.profile.acquiredSkillIDs.contains(skill.id)
    }

    private func canAcquire(_ skill: SkillDefinition) -> Bool {
        guard skillPoints > 0 else { return false }
        guard !isAcquired(skill) else { return false }
        // Skill family locked behind a minimum player level
        if let minLevel = skill.family.minimumLevel, playerLevel < minLevel {
            return false
        }
        if let prereq = skill.prerequisiteID {
            return profileStore.profile.acquiredSkillIDs.contains(prereq)
        }
        return true
    }
}

#Preview {
    NavigationStack {
        SkillTreeView(profileStore: ProfileStore())
            .background(Color(white: 0.06))
            .preferredColorScheme(.dark)
    }
}
