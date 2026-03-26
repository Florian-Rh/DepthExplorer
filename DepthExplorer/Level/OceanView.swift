import SwiftUI
import CoreMotion
import OpenSeasUI

struct OceanView: View {
    static let viewId = "oceanView"

    let scalingFactor: Double
    let screenHeight: CGFloat
    let contentOffset: CGFloat

    @State private var rotation: Double = 0.0

    private let motionManager = CMMotionManager()

    private static let surfaceCyan = Color(red: 0, green: 0.72, blue: 0.85)

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                WaveView(
                    amplitude: 20,
                    waveLength: 0.5,
                    waterLevel: 0.66,
                    animationBehaviour: .backAndForth(duration: 3.0, distance: 1),
                    rotation: rotation,
                    startPhase: 1.0
                )
                .foregroundStyle(.waveBlue)
                WaveView(
                    amplitude: 15,
                    waveLength: 0.5,
                    waterLevel: 0.66,
                    animationBehaviour: .backAndForth(duration: 5.0, distance: 1),
                    rotation: rotation
                )
                .foregroundStyle(Self.surfaceCyan)
            }
            .frame(height: screenHeight)

            ForEach(DepthZone.allZones) { zone in
                DepthZoneView(
                    zone: zone,
                    scalingFactor: scalingFactor,
                    contentOffset: contentOffset,
                    screenHeight: screenHeight
                )
            }
        }
        .id(Self.viewId)
//        .onAppear(perform: self.startDeviceMotionUpdates)
//        .onDisappear(perform: self.stopDeviceMotionUpdates)
    }

    private func startDeviceMotionUpdates() {
        self.motionManager.deviceMotionUpdateInterval = 0.01
        self.motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            if let gravity = motion?.gravity {
                var angle = atan2(gravity.x, gravity.y) + .pi
                // Normalize to [-π, π] so tilting clockwise gives a small
                // negative value instead of wrapping to ~2π.
                if angle > .pi { angle -= 2 * .pi }
                // Cap the tilt so rotations beyond 45° are ignored.
                let maxTilt: Double = .pi / 4
                angle = min(max(angle, -maxTilt), maxTilt)
                self.rotation = angle * 0.3
            }
        }
    }

    private func stopDeviceMotionUpdates() {
        self.motionManager.stopDeviceMotionUpdates()
    }
}
