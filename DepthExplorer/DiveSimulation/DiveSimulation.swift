import Foundation

/// Manages the dive simulation: timer, depth history, tissue saturation, and dive lifecycle.
/// Runs on a repeating Timer and receives the current depth from the view model each tick.
class DiveSimulation: ObservableObject {
    @Published var selectedMixture: GasMixture = .air
    @Published private(set) var diveActive: Bool = false
    @Published private(set) var diveStart: Date = Date()
    @Published private(set) var timeAtCurrentDepth: Double = 0
    @Published private(set) var saturation: TissueSaturationModel = HaldaneTissueSaturation(halfTime: 60, nitrogenPressure: 0.79)
    @Published private(set) var depthHistory: [(depth: Int, seconds: Int, mixture: GasMixture)] = []

    private var timer: Timer?
    private var currentDepth: Int = 0

    func start() {
        reset()
        timer = Timer.scheduledTimer(withTimeInterval: GameConstants.simulationInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Called by the view model to keep the simulation in sync with the current depth.
    func updateDepth(_ depth: Int) {
        currentDepth = depth
    }

    private func tick() {
        let timeIncrement = Int(GameConstants.timeScale * GameConstants.simulationInterval)

        if let last = depthHistory.last,
           abs(currentDepth - last.depth) <= GameConstants.depthGroupingThreshold,
           selectedMixture == last.mixture {
            depthHistory[depthHistory.count - 1].seconds += timeIncrement
        } else {
            depthHistory.append((currentDepth, timeIncrement, selectedMixture))
        }
        saturation.updateNitrogenPressure(history: depthHistory)

        if currentDepth >= GameConstants.diveActivationDepth {
            if !diveActive {
                diveStart = Date()
                timeAtCurrentDepth = 0
                diveActive = true
            } else {
                if let last = depthHistory.last {
                    if abs(currentDepth - last.depth) <= GameConstants.depthGroupingThreshold
                        && selectedMixture == last.mixture {
                        timeAtCurrentDepth = Double(last.seconds)
                    } else {
                        timeAtCurrentDepth = Double(timeIncrement)
                    }
                }
            }
        } else if currentDepth == 0 {
            if diveActive {
                reset()
            }
        }
    }

    private func reset() {
        diveStart = Date()
        timeAtCurrentDepth = 0
        diveActive = false
    }
}
