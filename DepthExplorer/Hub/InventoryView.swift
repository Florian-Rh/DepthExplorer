import SwiftUI

/// Loadout management: equip and unequip owned gear, one item per category slot.
struct InventoryView: View {
    @ObservedObject var profileStore: ProfileStore

    @State private var equipmentClass: EquipmentClass = .scuba

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
    }

    var body: some View {
        let availableCategories = GearCategory.allCases.filter {
            $0.minimumRank.minimumLevel <= playerLevel
            && ($0.equipmentClass == equipmentClass || $0.equipmentClass == .universal)
        }

        return ScrollView {
            VStack(spacing: 24) {
                Picker("Equipment Class", selection: $equipmentClass) {
                    Text("Apnoe / Scuba")
                        .tag(EquipmentClass.scuba)
                    Text("Specialist")
                        .tag(EquipmentClass.specialist)
                }
                ForEach(availableCategories, id: \.self) { category in
                    slotSection(category)
                }

                if !hasAnyGear {
                    emptyState
                }
            }
            .padding(16)
        }
    }

    private var hasAnyGear: Bool {
        !profileStore.profile.ownedGearIDs.isEmpty
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
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isEquipped ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isEquipped ? .cyan : .white.opacity(0.5))
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Equipped indicator
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
