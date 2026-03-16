import Foundation
import SwiftUI
import Combine

class LevelViewModel: ObservableObject {
    @Published var contentOffset: CGFloat = 0

    let diverController = DiverController()
    let diveSimulation = DiveSimulation()
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

    init(level: LevelDefinition = .default) {
        self.level = level
        diverController.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        diveSimulation.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func startSimulation() {
        diveSimulation.start()
    }

    func stopSimulation() {
        diveSimulation.stop()
    }

    /// Called every display frame by the scroll driver.
    func update(screenWidth: CGFloat) {
        diverController.updateSmoothing(
            contentOffset: contentOffset,
            currentDepth: currentDepth,
            screenWidth: screenWidth
        )
        diveSimulation.updateDepth(currentDepth)
    }
}
