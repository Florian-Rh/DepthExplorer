import Combine
import Foundation

/// Manages the dive simulation: timer, depth history, tissue saturation, and physics tick.
/// Runs on a repeating Timer and receives the current depth from the view model each tick.
/// Lifecycle transitions (begin dive, surface, rescue) are delegated to `DiveSession`.
///
/// Limitation models (air supply, thermal, decompression, etc.) are evaluated generically
/// via the `DiveLimitationModel` protocol. Pass whichever models are appropriate for the
/// current equipment when constructing the simulation.
class DiveSimulation: ObservableObject {
    @Published var selectedMixture: GasMixture = .air
    @Published private(set) var diveStart: Date = Date()
    @Published private(set) var timeAtCurrentDepth: Double = 0
    @Published private(set) var saturation: TissueSaturationModel = HaldaneTissueSaturation(halfTime: 60, nitrogenPressure: 0.79)
    @Published private(set) var depthHistory: [(depth: Int, seconds: Int, mixture: GasMixture)] = []

    /// Aggregated HUD-visible readings from all active limitation models.
    /// Updated every tick after all models have been evaluated.
    @Published private(set) var vitals = DiveVitals()

    // MARK: - Limitation models

    /// The active limitation models, evaluated each tick in order.
    let limitationModels: [any DiveLimitationModel]

    /// Minimum depth (meters) the diver must reach for the dive to count.
    let minimumCompletionDepth: Int

    /// Minimum dive time (simulated seconds) for the dive to count.
    let minimumCompletionTime: Int

    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    private var currentDepth: Int = 0
    private var previousDepth: Int = 0
    private var maxDepthReached: Int = 0
    private weak var session: DiveSession?
    private weak var warningSystem: DiveWarningSystem?

    init(
        limitationModels: [any DiveLimitationModel],
        minimumCompletionDepth: Int = 0,
        minimumCompletionTime: Int = 0
    ) {
        self.limitationModels = limitationModels
        self.minimumCompletionDepth = minimumCompletionDepth
        self.minimumCompletionTime = minimumCompletionTime
        for model in limitationModels {
            forwardChanges(from: model)
        }
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

    func resetSimulationData() {
        diveStart = Date()
        timeAtCurrentDepth = 0
        previousDepth = 0
        maxDepthReached = 0
        for model in limitationModels {
            model.reset()
        }
        rebuildVitals()
    }

    /// Called by the view model to keep the simulation in sync with the current depth.
    func updateDepth(_ depth: Int) {
        currentDepth = depth
        if depth > maxDepthReached {
            maxDepthReached = depth
        }
    }

    // MARK: - Private

    private func forwardChanges(from model: some DiveLimitationModel) {
        model.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func rebuildVitals() {
        var snapshot = DiveVitals()
        for model in limitationModels {
            model.updateVitals(&snapshot)
        }
        vitals = snapshot
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
                previousDepth = currentDepth
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

                // Compute instantaneous ascent speed for this tick.
                // Measured in m/s of real time — how fast the diver is physically moving
                // on screen. Compared against a game-tuned safe speed, not a real-world one.
                let depthChange = Double(previousDepth - currentDepth) // positive = ascending
                let instantaneousSpeed = depthChange / GameConstants.simulationInterval
                previousDepth = currentDepth

                let context = DiveTickContext(
                    simulatedSeconds: timeIncrement,
                    depthMeters: currentDepth,
                    instantaneousAscentSpeed: instantaneousSpeed
                )

                // Evaluate all limitation models.
                if let warningSystem {
                    for model in limitationModels {
                        let result = model.tick(context: context, warningSystem: warningSystem)
                        if let reason = result.rescueReason {
                            session.rescue(reason: reason)
                            warningSystem.clearAll()
                            rebuildVitals()
                            return
                        }
                    }
                }

                rebuildVitals()
            }
        } else if currentDepth == 0 {
            if session.state == .diving {
                let diveTime = Int(Date().timeIntervalSince(diveStart) * GameConstants.timeScale)
                if maxDepthReached >= minimumCompletionDepth && diveTime >= minimumCompletionTime {
                    session.completeDive()
                } else {
                    session.cancelDive()
                }
                warningSystem?.clearAll()
            }
        }
    }
}
