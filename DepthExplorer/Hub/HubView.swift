import SwiftUI

/// Tab identifier for the hub's segmented picker.
enum HubTab: String, CaseIterable, Hashable {
    case shop = "Shop"
    case skills = "Skills"
    case inventory = "Loadout"
    case glossary = "Glossary"
}

/// Central hub for the player's out-of-dive activities: shop, skills, inventory, and glossary.
struct HubView: View {
    @ObservedObject var profileStore: ProfileStore
    let discoveredItems: Set<String>
    var initialTab: HubTab = .shop
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            HubContentView(profileStore: profileStore, discoveredItems: discoveredItems, initialTab: initialTab)
                .background(Color(white: 0.06))
                .navigationTitle("Hub")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Reset", role: .destructive) {
                            showResetConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .alert("Reset Game?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        profileStore.resetProfile()
                    }
                } message: {
                    Text("This will erase all progress. Your level, equipment, skills, discoveries, and sand dollars will be permanently lost.")
                }
                .preferredColorScheme(.dark)
        }
    }
}

/// Inner view that owns the tab selection state.
/// Separated from HubView so that NavigationStack chrome does not
/// participate in the re-render triggered by tab changes.
private struct HubContentView: View {
    @ObservedObject var profileStore: ProfileStore
    let discoveredItems: Set<String>

    @State private var selectedTab: HubTab
    @State private var showRankInfo = false

    init(profileStore: ProfileStore, discoveredItems: Set<String>, initialTab: HubTab = .shop) {
        self.profileStore = profileStore
        self.discoveredItems = discoveredItems
        _selectedTab = State(initialValue: initialTab)
    }

    private var progression: LevelProgression {
        LevelProgression.from(totalXP: profileStore.profile.experiencePoints)
    }

    private var currentRank: DiverRank {
        DiverRank.rank(forLevel: progression.level)
    }

    var body: some View {
        VStack(spacing: 0) {
            hubHeader
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                ForEach(HubTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab
                                    ? Color.white.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(alignment: .topTrailing) {
                                if tab == .skills && profileStore.profile.skillPoints > 0 && selectedTab != .skills {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 6, height: 6)
                                        .offset(x: -6, y: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()
                .overlay(Color.white.opacity(0.1))

            Group {
                switch selectedTab {
                case .shop:
                    ShopView(profileStore: profileStore)
                case .skills:
                    SkillTreeView(profileStore: profileStore)
                case .inventory:
                    InventoryView(profileStore: profileStore)
                case .glossary:
                    GlossaryContentView(discoveredItems: discoveredItems)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .sheet(isPresented: $showRankInfo) {
            RankInfoSheet(currentRank: currentRank, currentLevel: progression.level)
        }
    }

    // MARK: - Header

    private var hubHeader: some View {
        HStack(spacing: 16) {
            // Level badge
            VStack(spacing: 2) {
                Text("Level")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(progression.level)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
            }
            .frame(width: 56)

            // Rank + XP progress
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(currentRank.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)

                    Button {
                        showRankInfo = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.cyan)
                            .frame(width: geo.size.width * progression.progress)
                    }
                }
                .frame(height: 6)

                Text("\(progression.xpToNextLevel) XP to next level")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Skill points
            if profileStore.profile.skillPoints > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("\(profileStore.profile.skillPoints)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.15), in: Capsule())
            }

            // Sand Dollars
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                Text("\(profileStore.profile.sandDollars)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

#Preview {
    HubView(
        profileStore: ProfileStore(),
        discoveredItems: ["Clownfish"]
    )
}
