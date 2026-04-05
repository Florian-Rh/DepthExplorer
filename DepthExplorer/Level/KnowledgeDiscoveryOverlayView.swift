import SwiftUI

/// Overlay shown when the diver discovers a knowledgeable item.
/// Pauses the simulation to present the item's description, XP earned,
/// and a note that the item is saved to the glossary.
struct KnowledgeDiscoveryOverlayView: View {
    let item: KnowledgeableItem
    var onDismiss: () -> Void

    @State private var overlayOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var iconScale: Double = 0.5
    @State private var showButton = false

    /// XP earned for this discovery: base + depth bonus.
    private var xpEarned: Int {
        ExperienceCalculator.baseItemXP + Int(item.depth * ExperienceCalculator.itemDepthBonusPerMeter)
    }

    private var categoryLabel: String {
        switch item.category {
        case .species: return "Species"
        case .oceanography: return "Oceanography Fact"
        case .humanHistory: return "Human History Fact"
        case .humanImpact: return "Human Impact Factor"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Category label
                Text("NEW \(categoryLabel.uppercased()) DISCOVERED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 90, height: 90)

                    Circle()
                        .strokeBorder(Color.cyan.opacity(0.4), lineWidth: 2)
                        .frame(width: 90, height: 90)

                    Image(systemName: item.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.cyan)
                }
                .scaleEffect(iconScale)

                // Name
                Text(item.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                // Depth
                Text("\(Int(item.depth)) m depth")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                // Description
                Text(item.description)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
                    .padding(.top, 4)

                // XP badge
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                    Text("+\(xpEarned) XP")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                .padding(.top, 8)

                // Glossary notice
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Text("Saved to your Glossary")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                .padding(.top, 2)

                Spacer()

                // Continue button
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
        }
        .opacity(overlayOpacity)
        .allowsHitTesting(overlayOpacity > 0)
        .onAppear {
            show()
        }
    }

    private func show() {
        contentOpacity = 0
        iconScale = 0.5
        showButton = false

        withAnimation(.easeIn(duration: 0.5)) {
            overlayOpacity = 1
        } completion: {
            withAnimation(.easeOut(duration: 0.4)) {
                contentOpacity = 1
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                iconScale = 1.0
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showButton = true
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.4)) {
            overlayOpacity = 0
            contentOpacity = 0
        } completion: {
            onDismiss()
        }
    }
}

#Preview {
    KnowledgeDiscoveryOverlayView(
        item: KnowledgeableItem.allItems[5],
        onDismiss: {}
    )
}
