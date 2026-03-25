import SwiftUI

/// Gear purchase UI. Items are grouped by category with clear state indicators.
struct ShopView: View {
    @ObservedObject var profileStore: ProfileStore

    /// Raw JSON string of collapsed category raw values, persisted across launches.
    @AppStorage("shop.collapsedSections") private var collapsedData: String = "[]"

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
    }

    private var collapsedSections: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: Data(collapsedData.utf8))) ?? []
    }

    private func setCollapsed(_ collapsed: Set<String>) {
        if let data = try? JSONEncoder().encode(collapsed),
           let str = String(data: data, encoding: .utf8) {
            collapsedData = str
        }
    }

    private func toggleSection(_ category: GearCategory) {
        var sections = collapsedSections
        if sections.contains(category.rawValue) {
            sections.remove(category.rawValue)
        } else {
            sections.insert(category.rawValue)
        }
        setCollapsed(sections)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(GearCategory.allCases, id: \.self) { category in
                    gearSection(category)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Sections

    private func gearSection(_ category: GearCategory) -> some View {
        let items = GearDefinition.allGear.filter { $0.category == category }
        let categoryLocked = category.minimumRank.minimumLevel > playerLevel
        let isCollapsed = collapsedSections.contains(category.rawValue)

        return VStack(alignment: .leading, spacing: 10) {
            // Tappable header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    toggleSection(category)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: categoryLocked ? "lock.fill" : category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(categoryLocked ? "Locked category" : category.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                ForEach(items) { gear in
                    shopItemRow(gear, categoryLocked: categoryLocked)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }

    // MARK: - Item Row

    private func shopItemRow(_ gear: GearDefinition, categoryLocked: Bool) -> some View {
        let isOwned = profileStore.profile.ownedGearIDs.contains(gear.id)
        let canAfford = profileStore.profile.sandDollars >= gear.price
        let meetsLevel = playerLevel >= gear.requiredLevel

        return HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOwned ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 48, height: 48)
                Image(systemName: categoryLocked ? "lock.fill" : gear.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isOwned ? .green : .white.opacity(0.6))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(categoryLocked ? "???" : gear.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(gear.effectDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .redacted(reason: categoryLocked ? .placeholder : [])

                if !meetsLevel {
                    Text("Requires Level \(gear.requiredLevel)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red.opacity(0.7))
                }
            }

            Spacer()

            // Action
            if isOwned {
                Text("Owned")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        profileStore.purchaseGear(id: gear.id, cost: gear.price)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text("\(gear.price)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .redacted(reason: categoryLocked ? .placeholder : [])
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        canAfford && meetsLevel
                            ? Color.yellow.opacity(0.2)
                            : Color.white.opacity(0.06),
                        in: Capsule()
                    )
                    .foregroundStyle(
                        canAfford && meetsLevel
                            ? .white
                            : .white.opacity(0.3)
                    )
                }
                .disabled(!canAfford || !meetsLevel)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isOwned ? 0.04 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isOwned ? Color.green.opacity(0.2) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    NavigationStack {
        ShopView(profileStore: ProfileStore())
            .background(Color(white: 0.06))
            .preferredColorScheme(.dark)
    }
}
