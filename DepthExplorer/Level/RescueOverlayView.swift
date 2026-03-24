import SwiftUI

/// Full-screen overlay shown when the diver is rescued.
///
/// Always present in the view hierarchy but invisible until triggered.
/// When `rescueInfo` becomes non-nil, runs a phased animation:
///   1. Fade to solid black (1s)
///   2. Reset diver to surface (while screen is opaque)
///   3. Fade in text content (0.6s)
///   4. Player taps Continue → fade everything out (0.5s), then clear rescueInfo
struct RescueOverlayView: View {
    @Binding var rescueInfo: LevelViewModel.RescueInfo?
    var onResetPosition: () -> Void

    @State private var overlayOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var activeReason: String = ""
    @State private var activeLostSD: Int = 0

    private var headline: String {
        switch activeReason {
        case "Out of air":
            return "You ran out of air!"
        case "Hypothermia":
            return "Hypothermia took hold!"
        case "Decompression sickness":
            return "Decompression sickness!"
        default:
            return "You were rescued!"
        }
    }

    private var flavorText: String {
        switch activeReason {
        case "Out of air":
            return "Your tank ran dry and you lost consciousness. Luckily, a nearby dive boat spotted your emergency beacon."
        case "Hypothermia":
            return "The cold became unbearable and you could no longer move. A rescue team pulled you from the water just in time."
        case "Decompression sickness":
            return "Nitrogen bubbles formed in your blood from ascending too fast. You were airlifted to a decompression chamber."
        default:
            return "You were pulled from the water by a rescue team."
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lifepreserver")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text(headline)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(flavorText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if activeLostSD > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.yellow)
                        Text("\(activeLostSD) Sand Dollars lost")
                            .foregroundStyle(.yellow.opacity(0.9))
                    }
                    .font(.system(size: 14, weight: .medium))
                }

                Spacer()

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
                .padding(.bottom, 60)
            }
            .opacity(contentOpacity)
        }
        .opacity(overlayOpacity)
        .allowsHitTesting(overlayOpacity > 0)
        .onChange(of: rescueInfo?.reason) { _, newValue in
            if let info = rescueInfo, newValue != nil {
                show(info: info)
            }
        }
    }

    private func show(info: LevelViewModel.RescueInfo) {
        activeReason = info.reason
        activeLostSD = info.lostSandDollars
        contentOpacity = 0

        // Phase 1: fade to black
        withAnimation(.easeIn(duration: 1.0)) {
            overlayOpacity = 1
        } completion: {
            // Phase 2: screen is fully black — reset diver position
            onResetPosition()
            // Phase 3: reveal text content
            withAnimation(.easeIn(duration: 0.6)) {
                contentOpacity = 1
            }
        }
    }

    private func dismiss() {
        // Phase 4: fade everything out
        withAnimation(.easeOut(duration: 0.5)) {
            overlayOpacity = 0
            contentOpacity = 0
        } completion: {
            rescueInfo = nil
        }
    }
}

#Preview {
    @Previewable @State var info: LevelViewModel.RescueInfo? = .init(
        reason: "Out of air",
        lostSandDollars: 12
    )

    RescueOverlayView(
        rescueInfo: $info,
        onResetPosition: {}
    )
}
