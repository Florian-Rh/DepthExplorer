import SwiftUI

/// Loadout management: equip and unequip owned gear, one item per category slot.
///
/// When submersible equipment is unlocked, shows a picker to navigate between
/// "Scuba Equipment" and "Submersible Equipment" sub-views.
/// Before that unlock, shows the flat scuba list directly.
struct InventoryView: View {
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
            InventoryClassPicker(profileStore: profileStore)
        } else {
            InventoryGearList(
                profileStore: profileStore,
                categories: scubaCategories
            )
        }
    }

    private var scubaCategories: [GearCategory] {
        GearCategory.allCases.filter {
            $0.equipmentClass == .scuba
            && $0.minimumRank.minimumLevel <= playerLevel
        }
    }
}

// MARK: - Equipment class picker

/// Two large buttons that switch between Scuba and Submersible loadout lists.
private struct InventoryClassPicker: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var selectedClass: EquipmentClass = .scuba

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
    }

    private var scubaCategories: [GearCategory] {
        GearCategory.allCases.filter {
            $0.equipmentClass == .scuba
            && $0.minimumRank.minimumLevel <= playerLevel
        }
    }

    private var submersibleCategories: [GearCategory] {
        GearCategory.allCases.filter {
            $0.equipmentClass == .submersible
            && $0.minimumRank.minimumLevel <= playerLevel
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
                InventoryGearList(
                    profileStore: profileStore,
                    categories: scubaCategories
                )
            case .submersible:
                InventoryGearList(
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

/// Displays gear slot sections for the given categories.
/// Reused for both the scuba and submersible sub-views.
private struct InventoryGearList: View {
    @ObservedObject var profileStore: ProfileStore
    let categories: [GearCategory]

    private var hasAnyGear: Bool {
        !profileStore.profile.ownedGearIDs.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(categories, id: \.self) { category in
                    slotSection(category)
                }

                if !hasAnyGear {
                    emptyState
                }
            }
            .padding(16)
        }
    }

    // MARK: - Slot Section

    private func slotSection(_ category: GearCategory) -> some View {
        let equippedID = profileStore.profile.equippedGearIDs[category.rawValue]
        let ownedInCategory = GearDefinition.allGear.filter {
            $0.category == category && profileStore.profile.ownedGearIDs.contains($0.id)
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                Text(category.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Default option
            slotRow(
                name: "Default",
                description: category.defaultDescription,
                icon: category.icon,
                isEquipped: equippedID == nil,
                onTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        profileStore.unequipGear(category: category)
                    }
                }
            )

            // Owned items
            ForEach(ownedInCategory) { gear in
                slotRow(
                    name: gear.name,
                    description: gear.effectDescription,
                    icon: gear.icon,
                    isEquipped: equippedID == gear.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if equippedID == gear.id {
                                profileStore.unequipGear(category: category)
                            } else {
                                profileStore.equipGear(id: gear.id, category: category)
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Slot Row

    private func slotRow(
        name: String,
        description: String,
        icon: String,
        isEquipped: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isEquipped ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isEquipped ? .cyan : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.cyan)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isEquipped ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isEquipped ? Color.cyan.opacity(0.3) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.2))
            Text("No gear purchased yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text("Visit the Shop to buy gear upgrades")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.top, 40)
    }
}

#Preview {
    NavigationStack {
        InventoryView(profileStore: ProfileStore())
            .background(Color(white: 0.06))
            .preferredColorScheme(.dark)
    }
}
