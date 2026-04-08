import SwiftUI

/// Gear purchase UI. Items are grouped by category with clear state indicators.
///
/// When submersible equipment is unlocked, shows a picker to navigate between
/// "Scuba" and "Submersible" shop sections.
/// Before that unlock, shows the flat scuba shop directly.
struct ShopView: View {
    @ObservedObject var profileStore: ProfileStore

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
    }

    /// Whether the player has unlocked any submersible-class category.
    private var hasSubmersibleUnlocked: Bool {
        GearCategory.allCases.contains { cat in
            cat.equipmentClass == .submersible
            && cat.minimumRank.minimumLevel <= playerLevel
        }
    }

    var body: some View {
        if hasSubmersibleUnlocked {
            ShopClassPicker(profileStore: profileStore)
        } else {
            ShopGearList(
                profileStore: profileStore,
                categories: GearCategory.allCases.filter {
                    $0.equipmentClass == .scuba
                }
            )
        }
    }
}

// MARK: - Equipment class picker

/// Segmented control switching between Scuba and Submersible shop sections.
private struct ShopClassPicker: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var selectedClass: EquipmentClass = .submersible

    private var scubaCategories: [GearCategory] {
        GearCategory.allCases.filter {
            $0.equipmentClass == .scuba
        }
    }

    private var submersibleCategories: [GearCategory] {
        GearCategory.allCases.filter {
            $0.equipmentClass == .submersible
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Class selector ───────────────────────────────
            HStack(spacing: 0) {
                classTab(
                    title: "Scuba",
                    icon: "figure.pool.swim",
                    equipmentClass: .scuba
                )
                classTab(
                    title: "Submersible",
                    icon: "shield.checkered",
                    equipmentClass: .submersible
                )
            }
            .padding(3)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // ── Content ──────────────────────────────────────
            switch selectedClass {
            case .scuba:
                ShopGearList(
                    profileStore: profileStore,
                    categories: scubaCategories
                )
            case .submersible:
                ShopGearList(
                    profileStore: profileStore,
                    categories: submersibleCategories
                )
            }
        }
    }

    private func classTab(title: String, icon: String, equipmentClass: EquipmentClass) -> some View {
        let isSelected = selectedClass == equipmentClass
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedClass = equipmentClass
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.white.opacity(0.12)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gear list for a set of categories

/// Displays shop sections for the given categories.
/// Reused for both the scuba and submersible tabs.
private struct ShopGearList: View {
    @ObservedObject var profileStore: ProfileStore
    let categories: [GearCategory]

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
                ForEach(categories, id: \.self) { category in
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
