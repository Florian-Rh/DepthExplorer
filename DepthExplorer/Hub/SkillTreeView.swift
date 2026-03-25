import SwiftUI

/// Skill acquisition UI. Displays skill families as columns with level nodes.
struct SkillTreeView: View {
    @ObservedObject var profileStore: ProfileStore

    private var skillPoints: Int {
        profileStore.profile.skillPoints
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Skill points indicator
                skillPointsHeader

                // Skill family columns
                HStack(alignment: .top, spacing: 16) {
                    ForEach(SkillFamily.allCases, id: \.self) { family in
                        familyColumn(family)
                    }
                }
            }
            .padding(16)
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

    // MARK: - Family Column

    private func familyColumn(_ family: SkillFamily) -> some View {
        let skills = SkillDefinition.allSkills
            .filter { $0.family == family }
            .sorted { $0.level < $1.level }

        return VStack(spacing: 0) {
            // Family header
            VStack(spacing: 6) {
                Image(systemName: family.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.cyan)
                    .frame(height: 24)

                Text(family.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
//                Spacer()
            }
            .padding(.bottom, 16)

            // Skill nodes
            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                if index > 0 {
                    connectionLine(isActive: isAcquired(skill) || isAcquired(skills[index - 1]))
                }
                skillNode(skill)
            }
        }
        .frame(maxWidth: .infinity)
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
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Effect
                Text(skill.effectDescription)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(acquired ? .cyan.opacity(0.8) : .white.opacity(0.3))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .disabled(!available)
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
