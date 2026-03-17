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
    /// Current ascent speed in meters per real second. Positive = ascending.
    @Published private(set) var ascentSpeed: Double = 0

    let airSupply = AirSupply()
    let thermalModel = ThermalModel()

    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    private var currentDepth: Int = 0
    private var previousDepth: Int = 0
    private weak var session: DiveSession?
    private weak var warningSystem: DiveWarningSystem?

    init() {
        airSupply.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        thermalModel.objectWillChange
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

    func resetSimulationData() {
        diveStart = Date()
        timeAtCurrentDepth = 0
        ascentSpeed = 0
        previousDepth = 0
        airSupply.refill()
        thermalModel.reset()
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

                // Air consumption
                airSupply.consume(simulatedSeconds: timeIncrement, depthMeters: currentDepth)
                if let warningSystem {
                    airSupply.evaluateWarnings(warningSystem: warningSystem)
                }
                if airSupply.remainingBar <= 0 {
                    session.rescue(reason: "Out of air")
                    warningSystem?.clearAll()
                    return
                }

                // Thermal exposure
                thermalModel.update(simulatedSeconds: timeIncrement, depthMeters: currentDepth)
                if let warningSystem {
                    thermalModel.evaluateWarnings(warningSystem: warningSystem)
                }
                if thermalModel.bodyTemperature <= GameConstants.hypothermiaFatalThreshold {
                    session.rescue(reason: "Hypothermia")
                    warningSystem?.clearAll()
                    return
                }

                // Ascent speed & DCS risk (smoothed)
                // Measured in m/s of real time — how fast the diver is physically moving
                // on screen. Compared against a game-tuned safe speed, not a real-world one.
                let depthChange = Double(previousDepth - currentDepth) // positive = ascending
                let instantaneousSpeed = depthChange / GameConstants.simulationInterval // m/s real time
                previousDepth = currentDepth

                if instantaneousSpeed > 0 {
                    // Ascending: blend toward instantaneous speed
                    ascentSpeed += (instantaneousSpeed - ascentSpeed) * GameConstants.ascentSpeedBuildupRate
                } else {
                    // Stopped or descending: decay toward 0
                    ascentSpeed *= (1.0 - GameConstants.ascentSpeedDecayRate)
                    if ascentSpeed < 0.5 { ascentSpeed = 0 }
                }

                if ascentSpeed > 0 {
                    evaluateDCSWarning()
                } else {
                    warningSystem?.clear(.decompression)
                }
            }
        } else if currentDepth == 0 {
            if session.state == .diving {
                session.completeDive()
                warningSystem?.clearAll()
                resetSimulationData()
            }
        }
    }

    private func evaluateDCSWarning() {
        let safeSpeed = GameConstants.safeAscentSpeed
        let ratio = ascentSpeed / safeSpeed

        if ratio >= GameConstants.dcsFatalFraction {
            warningSystem?.set(DiveWarning(
                kind: .decompression,
                severity: .fatal,
                message: "Ascending way too fast! (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
            session?.rescue(reason: "Decompression sickness")
            warningSystem?.clearAll()
        } else if ratio >= GameConstants.dcsCriticalFraction {
            warningSystem?.set(DiveWarning(
                kind: .decompression,
                severity: .critical,
                message: "Ascending too fast! (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
        } else if ratio >= GameConstants.dcsWarningFraction {
            warningSystem?.set(DiveWarning(
                kind: .decompression,
                severity: .caution,
                message: "Slow your ascent (\(String(format: "%.1f", ascentSpeed)) m/s)"
            ))
        } else {
            warningSystem?.clear(.decompression)
        }
    }
}
