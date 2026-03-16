import Combine
import Foundation

/// Manages the dive simulation: timer, depth history, tissue saturation, and physics tick.
/// Runs on a repeating Timer and receives the current depth from the view model each tick.
/// Lifecycle transitions (begin dive, surface, rescue) are delegated to `DiveSession`.
class DiveSimulation: ObservableObject {
    @Published var selectedMixture: GasMixture = .air
    @Published private(set) var diveStart: Date = Date()
    @Published private(set) var timeAtCurrentDepth: Double = 0
    @Published private(set) var saturation: TissueSaturationModel = HaldaneTissueSaturation(halfTime: 60, nitrogenPressure: 0.79)
    @Published private(set) var depthHistory: [(depth: Int, seconds: Int, mixture: GasMixture)] = []

    let airSupply = AirSupply()

    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    private var currentDepth: Int = 0
    private weak var session: DiveSession?
    private weak var warningSystem: DiveWarningSystem?

    init() {
        airSupply.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func start(session: DiveSession, warningSystem: DiveWarningSystem) {
        self.session = session
        self.warningSystem = warningSystem
        resetSimulationData()
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
        guard let session else { return }
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
            if session.state == .surface {
                diveStart = Date()
                timeAtCurrentDepth = 0
                session.beginDive()
            } else if session.state == .diving {
                if let last = depthHistory.last {
                    if abs(currentDepth - last.depth) <= GameConstants.depthGroupingThreshold
                        && selectedMixture == last.mixture {
                        timeAtCurrentDepth = Double(last.seconds)
                    } else {
                        timeAtCurrentDepth = Double(timeIncrement)
                    }
                }

                // Air consumption
                airSupply.consume(simulatedSeconds: timeIncrement, depthMeters: currentDepth)
                if let warningSystem {
                    airSupply.evaluateWarnings(warningSystem: warningSystem)
                }
                if airSupply.remainingBar <= 0 {
                    session.rescue(reason: "Out of air")
                    warningSystem?.clearAll()
                    resetSimulationData()
                    return
                }
            }
        } else if currentDepth == 0 {
            if session.state == .diving {
                session.completeDive()
                warningSystem?.clearAll()
                resetSimulationData()
            } else if session.state != .surface {
                // Auto-reset terminal states (surfacedSafely, rescued) so a new dive can begin.
                // TODO: Phase 1 — replace with explicit session end flow UI.
                session.discard()
            }
        }
    }

    private func resetSimulationData() {
        diveStart = Date()
        timeAtCurrentDepth = 0
        airSupply.refill()
    }
}
