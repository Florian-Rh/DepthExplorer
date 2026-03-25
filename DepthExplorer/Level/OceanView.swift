import SwiftUI
import CoreMotion
import OpenSeasUI

struct OceanView: View {
    static let viewId = "oceanView"

    let depthInPixels: Double
    let screenHeight: CGFloat

    @State private var rotation: Double = 0.0

    private let motionManager = CMMotionManager()

    static var adjustedMidnightAbyssGradient: Gradient {
        Gradient(colors: [.oceanBlue, .deepSeaBlue, .abyssBlue, .black, .black, .black])
    }

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
                .foregroundStyle(.oceanBlue)
            }
            .frame(height: screenHeight)
            Rectangle()
                .frame(height: depthInPixels)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Self.adjustedMidnightAbyssGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .id(Self.viewId)
        .onAppear(perform: self.startDeviceMotionUpdates)
        .onDisappear(perform: self.stopDeviceMotionUpdates)
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
