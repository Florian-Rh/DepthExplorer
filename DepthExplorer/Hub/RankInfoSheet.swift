import SwiftUI

/// Sheet that explains all diver ranks, highlighting the player's current rank.
struct RankInfoSheet: View {
    let currentRank: DiverRank
    let currentLevel: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Your diving rank reflects your experience and expertise as an underwater explorer. As you level up, more equipment and skills become available to you.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        ForEach(DiverRank.allCases, id: \.self) { rank in
                            rankRow(rank)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(white: 0.06))
            .navigationTitle("Diver Ranks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func rankRow(_ rank: DiverRank) -> some View {
        let isCurrent = rank == currentRank
        let isLocked = currentLevel < rank.minimumLevel

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(isLocked ? "???" : rank.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isCurrent ? .cyan : isLocked ? .white.opacity(0.3) : .white)

                        if isCurrent {
                            Text("Current")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.cyan, in: Capsule())
                        }
                    }

                    let nextRank = DiverRank.allCases.first { $0.minimumLevel > rank.minimumLevel }
                    let maxLevel = nextRank.map { $0.minimumLevel - 1 }
                    if let max = maxLevel {
                        Text("Level \(rank.minimumLevel) – \(max)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text("Level \(rank.minimumLevel)+")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.2))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isCurrent ? .cyan : .green.opacity(0.6))
                }
            }

            Text(rank.description)
                .font(.system(size: 13))
                .foregroundStyle(isLocked ? .white.opacity(0.25) : .white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .redacted(reason: isLocked ? .placeholder : [])
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.cyan.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

#Preview {
    RankInfoSheet(currentRank: .scubaDiver, currentLevel: 6)
}
