import Foundation
import SwiftUI
import Combine

class LevelViewModel: ObservableObject {
    @Published var contentOffset: CGFloat = 0
    @Published var screenSize: CGSize = .zero

    let diverController = DiverController()
    let diveSimulation = DiveSimulation()
    let diveSession = DiveSession()
    let warningSystem = DiveWarningSystem()
    let level: LevelDefinition

    private var cancellables: Set<AnyCancellable> = []

    var scalingFactor: Double {
        level.scalingFactor
    }

    var maximumDepthInPixels: Double {
        GameConstants.maximumDepth * level.scalingFactor
    }

    var currentDepth: Int {
        Int(contentOffset / level.scalingFactor)
    }

    var currentPressure: Double {
        1.0 + (Double(currentDepth) / 10.0)
    }

    /// Total dive time in simulated seconds since the current dive began.
    /// Returns 0 when not actively diving.
    var diveTimeSeconds: Int {
        guard diveSession.state == .diving else { return 0 }
        return Int(Date().timeIntervalSince(diveSimulation.diveStart) * GameConstants.timeScale)
    }

    init(level: LevelDefinition = .default) {
        self.level = level
        diverController.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        diveSimulation.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        diveSession.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        warningSystem.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func startSimulation() {
        diveSimulation.start(session: diveSession, warningSystem: warningSystem)
    }

    func stopSimulation() {
        diveSimulation.stop()
    }

    /// Called every display frame by the scroll driver.
    func update() {
        diverController.updateSmoothing(
            contentOffset: contentOffset,
            currentDepth: currentDepth,
            screenWidth: screenSize.width
        )
        diveSimulation.updateDepth(currentDepth)
    }
}
