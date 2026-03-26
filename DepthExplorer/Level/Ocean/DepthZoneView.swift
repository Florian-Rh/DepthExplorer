import SwiftUI

/// Renders a single oceanic depth zone: gradient background + ambient elements + particles.
/// Ambient and particle layers are only rendered when the zone is near the viewport.
struct DepthZoneView: View {
    let zone: DepthZone
    let scalingFactor: Double
    /// Current scroll offset in pixels (from the ocean surface).
    let contentOffset: CGFloat
    /// Screen height in points (for viewport culling).
    let screenHeight: CGFloat

    private var zoneHeight: CGFloat {
        zone.height(scalingFactor: scalingFactor)
    }

    private var zoneTopInPixels: CGFloat {
        zone.topOffset(scalingFactor: scalingFactor)
    }

    /// The portion of this zone that is visible on screen, in zone-local coordinates.
    /// Returns nil if the zone is entirely off-screen.
    private var visibleRange: ClosedRange<CGFloat>? {
        let buffer = screenHeight
        let viewportTop = contentOffset - buffer
        let viewportBottom = contentOffset + screenHeight + buffer

        let zoneBottom = zoneTopInPixels + zoneHeight

        // No overlap — zone is entirely off-screen
        guard viewportBottom > zoneTopInPixels && viewportTop < zoneBottom else {
            return nil
        }

        let localTop = max(0, viewportTop - zoneTopInPixels)
        let localBottom = min(zoneHeight, viewportBottom - zoneTopInPixels)
        return localTop...localBottom
    }

    var body: some View {
        ZStack {
            // Layer 1: Gradient background (always rendered — cheap)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: zone.gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Layer 2: Ambient elements — always present with stable inputs so
            // SwiftUI never invalidates the Canvas during scrolling. CoreGraphics
            // clips off-screen draws automatically.
            AmbientElements(
                config: zone.ambientConfig,
                zoneHeight: zoneHeight,
                seed: zone.id.hashValue
            )

            // Layer 3: Particles (same approach — always present, draws nothing when nil)
            if let particleConfig = zone.particleConfig {
                OceanParticleView(
                    config: particleConfig,
                    zoneHeight: zoneHeight,
                    visibleRange: visibleRange,
                    seed: zone.id.hashValue &+ 1000
                )
            }
        }
        .frame(height: zoneHeight)
    }
}
