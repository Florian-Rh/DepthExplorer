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
    @Published private(set) var diverOrientation = ScubaDiverView.Orientation.upwards
    @Published private var scrollPosition: CGFloat = 0

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
    private let timerInterval: Double = 0.1 // 100 ms

    var maximumDepthInPixels: Double {
        self.maximumDepth * self.scalingFactor
    }

    var currentDepth: Int {
        Int(abs(scrollPosition) / scalingFactor)
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

    func updateScrollPosition(_ value: CGPoint) {
        scrollPosition = value.y
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
//                depthHistory = [(currentDepth, Int(timeScale * timerInterval), selectedMixture)]
                diverOrientation = .downwards
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
