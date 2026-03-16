import Foundation
import SwiftUI
import Combine

class LevelViewModel: ObservableObject {
    @Published var contentOffset: CGFloat = 0

    let diverController = DiverController()
    let diveSimulation = DiveSimulation()
    let autoSurfaceDepth = 10
    let maximumDepth = 11500.0
    let scalingFactor = 10.0

    private var cancellables: Set<AnyCancellable> = []

    var maximumDepthInPixels: Double {
        maximumDepth * scalingFactor
    }

    var currentDepth: Int {
        Int(contentOffset / scalingFactor)
    }

    var currentPressure: Double {
        1.0 + (Double(currentDepth) / 10.0)
    }

    init() {
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
