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

    // Diver position controlled by joystick
    @Published var diverOffset: CGSize = .zero
    @Published var diverTilt: Double = 90.0

    /// Normalized joystick vertical component: -1..+1
    var joystickVertical: CGFloat = 0

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
    private let timerInterval: Double = 0.2 // 200 ms

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
