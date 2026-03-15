import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    // UI State (exposed to the view)
    @Published var selectedMixture: GasMixture = .air
    @Published private(set) var diveActive: Bool = false
    @Published private(set) var diveStart: Date = Date()
    @Published private(set) var timeAtCurrentDepth: Double = 0 // seconds
    @Published private(set) var saturation: TissueSaturationModel = HaldaneTissueSaturation(halfTime: 60, nitrogenPressure: 0.79)
    @Published private(set) var depthHistory: [(depth: Int, seconds: Int, mixture: GasMixture)] = []
    /// Content offset driven by the joystick (positive = scrolled down = deeper)
    @Published var contentOffset: CGFloat = 0

    // Diver position controlled by joystick (raw targets)
    var diverOffsetTarget: CGSize = .zero
    var diverTiltTarget: Double = 90.0

    // Smoothed diver state (displayed values, lerped toward targets each frame)
    @Published var diverOffset: CGSize = .zero
    @Published var diverTilt: Double = 90.0

    /// Normalized joystick components: -1..+1
    var joystickVertical: CGFloat = 0
    var joystickHorizontal: CGFloat = 0

    /// Tracks whether the joystick was last in the right half (true) or left half (false)
    private var lastJoystickWasRight: Bool = true

    /// Horizontal position of the diver, accumulated from joystick input each frame
    @Published var diverX: CGFloat = 0

    /// Called every display frame to smoothly interpolate diver state toward targets.
    func updateDiverSmoothing() {
        let smoothing: CGFloat = 0.96 // 0 = instant, 1 = no movement

        let atSurface = currentDepth == 0
        let screenWidth = UIScreen.main.bounds.width
        let maxX = screenWidth / 2 - 30 // leave a small margin at edges

        // Horizontal: velocity-based, joystick controls speed
        let joystickReleased = abs(joystickHorizontal) <= 0.05 && abs(joystickVertical) <= 0.05

        // Track which side the joystick was last on
        if abs(joystickHorizontal) > 0.1 {
            lastJoystickWasRight = joystickHorizontal > 0
        }

        if atSurface || joystickReleased {
            // Smoothly return to center
            diverX += (0 - diverX) * (1 - smoothing)
        } else {
            let hSpeed: CGFloat = 4.0 // max pts per frame
            diverX += joystickHorizontal * hSpeed
            diverX = max(-maxX, min(diverX, maxX))
        }

        // Vertical offset: smoothly lerp toward target, clamped to not rise above surface
        let rawTargetY = diverOffsetTarget.height
        let clampedY = max(rawTargetY, -contentOffset)
        diverOffset.height += (clampedY - diverOffset.height) * (1 - smoothing)

        // Tilt: lerp using shortest angular path
        let targetTilt: Double
        if atSurface {
            targetTilt = 90.0 // face up
        } else if joystickReleased {
            targetTilt = lastJoystickWasRight ? 180.0 : 0.0 // face horizontal
        } else {
            targetTilt = diverTiltTarget
        }
        var delta = targetTilt - diverTilt
        // Normalize delta to -180...180 for shortest path
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        diverTilt += delta * (1 - smoothing)

        // Robust normalization to 0..<360
        diverTilt = diverTilt.truncatingRemainder(dividingBy: 360)
        if diverTilt < 0 { diverTilt += 360 }
    }

    let autoSurfaceDepth = 10 // meters — diver auto-surfaces when shallower than this
    let maximumDepth = 11500.0
    let scalingFactor = 10.0
    let timeScale: Double = 60.0
    let availableMixtures: [(name: String, mixture: GasMixture)] = [
        ("Air", .air),
        ("Pure Oxygen", .oxygen),
        ("Nitrox 32", .nitrox32),
        ("Nitrox 36", .nitrox36),
        ("Nitrox 40", .nitrox40),
        ("Trimix 21/35", .trimix2135),
    ]

    private var timer: Timer? = nil
    private let timerInterval: Double = 0.2 // 1000 ms

    var maximumDepthInPixels: Double {
        self.maximumDepth * self.scalingFactor
    }

    var currentDepth: Int {
        Int(contentOffset / scalingFactor)
    }

    var currentPressure: Double {
        // Pressure increases by 1 atm (101.325 kPa) per 10 meters
        let depthInMeters = Double(currentDepth)
        let pressureInAtm = 1.0 + (depthInMeters / 10.0)
        return pressureInAtm
    }

    func startDiveSimulation() {
        self.resetDiveSimulation()
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
             self?.timerTick()
        }
    }

    func stopDiveSimulation() {
        timer?.invalidate()
    }

    private func timerTick() {
        // Update depth history
        if let last = depthHistory.last, abs(currentDepth - last.depth) <= 5, selectedMixture == last.mixture {
            depthHistory[depthHistory.count - 1].seconds += Int(timeScale * timerInterval)
        } else {
            depthHistory.append((currentDepth, Int(timeScale * timerInterval), selectedMixture))
        }
        // Update the existing tissue instance in place
        saturation.updateNitrogenPressure(history: depthHistory)

        // Only run simulation if below 3m
        if currentDepth >= 3 {
            if !diveActive {
                // Start timing
                diveStart = Date()
                timeAtCurrentDepth = 0
                diveActive = true
            } else {
                // Update time at current depth
                if let last = depthHistory.last {
                    if abs(currentDepth - last.depth) <= 5 && selectedMixture == last.mixture {
                        timeAtCurrentDepth = Double(last.seconds)
                    } else {
                        timeAtCurrentDepth = timeScale * timerInterval
                    }
                }
            }
        } else if currentDepth == 0 {
            // If at surface (0m), reset everything
            if diveActive {
                resetDiveSimulation()
            }
        }
    }

    private func resetDiveSimulation() {
        diveStart = Date()
        timeAtCurrentDepth = 0
        diveActive = false
    }
}

#Preview {
    ContentView()
}
