import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    // UI State
    @Published var visibleItems: Set<String> = []
    @Published var scrollPosition: CGFloat = 0
    @Published var selectedMixture: GasMixture = .air
    @Published var timerActive: Bool = false
    @Published var diveStart: Date = Date()
    @Published var timeAtCurrentDepth: Double = 0 // seconds
    @Published var tissue = TissueCompartment(halfTime: 60, nitrogenPressure: 0.79)
    @Published var depthHistory: [(depth: Int, seconds: Int, mixture: GasMixture)] = []
    @Published var lastUpdate: Date = Date()
    @Published var lastDepth: Int = 0
    @Published var lastTimerDepth: Int = 0
    @Published var timer: Timer? = nil

    let maximumDepth = 11500.0
    let scalingFactor = 10.0
    let timeScale: Double = 60.0
    let timerInterval: Double = 0.1 // 100 ms
    let availableMixtures: [(name: String, mixture: GasMixture)] = [
        ("Air", .air),
        ("Pure Oxygen", .oxygen),
        ("Nitrox 32", .nitrox32),
        ("Nitrox 36", .nitrox36),
        ("Nitrox 40", .nitrox40),
        ("Trimix 21/35", .trimix2135),
    ]

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
        diveStart = Date()
        lastTimerDepth = currentDepth
        timeAtCurrentDepth = 0
        timer?.invalidate()
        depthHistory = []
        tissue = TissueCompartment(halfTime: 60, nitrogenPressure: 0.79)
        timerActive = false
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }

    func stopDiveSimulation() {
        timer?.invalidate()
    }

    func updateScrollPosition(_ value: CGPoint) {
        let now = Date()
        let deltaT = now.timeIntervalSince(lastUpdate) / 60.0 // minutes
        let ambientN2 = selectedMixture.partialPressure(of: .nitrogen, at: currentPressure)
        lastUpdate = now
        lastDepth = currentDepth
        scrollPosition = value.y
    }

    private func timerTick() {
        // Only run simulation if below 3m
        if currentDepth >= 3 {
            if !timerActive {
                // Start timing
                diveStart = Date()
                lastTimerDepth = currentDepth
                timeAtCurrentDepth = 0
                depthHistory = [(currentDepth, Int(timeScale * timerInterval), selectedMixture)]
                tissue = TissueCompartment(halfTime: 60, nitrogenPressure: 0.79)
                timerActive = true
            } else {
                // Update depth history
                if let last = depthHistory.last, abs(currentDepth - last.depth) <= 5, selectedMixture == last.mixture {
                    depthHistory[depthHistory.count - 1].seconds += Int(timeScale * timerInterval)
                } else {
                    depthHistory.append((currentDepth, Int(timeScale * timerInterval), selectedMixture))
                }
                // Update the existing tissue instance in place
                tissue.updateNitrogenPressure(history: depthHistory)
                // Update time at current depth
                if let last = depthHistory.last {
                    if abs(currentDepth - last.depth) <= 5 && selectedMixture == last.mixture {
                        timeAtCurrentDepth = Double(last.seconds)
                    } else {
                        timeAtCurrentDepth = timeScale * timerInterval
                    }
                }
            }
        } else {
            // If at surface (0m), reset everything
            if currentDepth == 0 {
                timerActive = false
                diveStart = Date()
                timeAtCurrentDepth = 0
                depthHistory = []
                tissue = TissueCompartment(halfTime: 60, nitrogenPressure: 0.79)
            }
        }
    }
} 
