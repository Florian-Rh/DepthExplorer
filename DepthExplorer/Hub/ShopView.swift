import SwiftUI

/// Gear purchase UI. Items are grouped by category with clear state indicators.
struct ShopView: View {
    @ObservedObject var profileStore: ProfileStore

    private var playerLevel: Int {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level
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

            ForEach(items) { gear in
                shopItemRow(gear)
            }
        }
    }

    // MARK: - Item Row

    private func shopItemRow(_ gear: GearDefinition) -> some View {
        let isOwned = profileStore.profile.ownedGearIDs.contains(gear.id)
        let canAfford = profileStore.profile.sandDollars >= gear.price
        let meetsLevel = playerLevel >= gear.requiredLevel

        return HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOwned ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 48, height: 48)
                Image(systemName: gear.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isOwned ? .green : .white.opacity(0.6))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(gear.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(gear.effectDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))

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
