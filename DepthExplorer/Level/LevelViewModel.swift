import Foundation
import SwiftUI
import Combine

class LevelViewModel: ObservableObject {
    @Published var contentOffset: CGFloat = 0
    @Published var screenSize: CGSize = .zero
    @Published var trashItems: [TrashItem] = []
    /// Names of items discovered this session or previously (for UI display).
    @Published private(set) var discoveredItemNames: Set<String> = []

    let diverController = DiverController()
    let diveSimulation = DiveSimulation()
    let diveSession = DiveSession()
    let warningSystem = DiveWarningSystem()
    let level: LevelDefinition
    let profileStore: ProfileStore

    private var cancellables: Set<AnyCancellable> = []
    private var previousSessionState: DiveSessionState = .surface

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

    init(level: LevelDefinition = .default, profileStore: ProfileStore = ProfileStore()) {
        self.level = level
        self.profileStore = profileStore
        discoveredItemNames = profileStore.profile.discoveredItems
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
        checkSessionTransitions()
        checkProximity()
    }

    // MARK: - Session lifecycle

    private func checkSessionTransitions() {
        let currentState = diveSession.state

        // Detect dive start → spawn trash
        if previousSessionState == .surface && currentState == .diving {
            trashItems = TrashItem.spawnForDive()
        }

        // Detect safe surfacing → commit rewards
        if previousSessionState == .diving && currentState == .surfacedSafely {
            diveSession.commitRewards(to: profileStore)
            discoveredItemNames = profileStore.profile.discoveredItems
            trashItems = []
        }

        // Detect rescue → clear trash
        if case .rescued = currentState, previousSessionState == .diving {
            trashItems = []
        }

        previousSessionState = currentState
    }

    // MARK: - Proximity detection

    /// The diver's current screen position in points.
    private var diverScreenPosition: CGPoint {
        CGPoint(
            x: screenSize.width / 2 + diverController.x,
            y: screenSize.height / 3 + 30 + diverController.offset.height
        )
    }

    /// Convert an item's world position to screen position.
    /// The +50 offset matches the `.offset(y: 50)` applied in LevelView.
    private func itemScreenPosition(depth: Double, isLeftSide: Bool, hPadding: Double) -> CGPoint {
        let screenY = depth * scalingFactor - contentOffset + screenSize.height / 3 + 50
        let screenX = isLeftSide ? hPadding : screenSize.width - hPadding
        return CGPoint(x: screenX, y: screenY)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    private func checkProximity() {
        guard diveSession.state == .diving else { return }
        let diverPos = diverScreenPosition
        let radius = GameConstants.pickupRadius

        // Knowledgeable Items
        for (index, item) in KnowledgeableItem.allItems.enumerated() {
            guard !discoveredItemNames.contains(item.name) else { continue }
            let itemPos = itemScreenPosition(
                depth: item.depth,
                isLeftSide: index.isMultiple(of: 2),
                hPadding: 60
            )
            guard distance(diverPos, itemPos) <= radius else { continue }
            diveSession.discoverItem(named: item.name)
            discoveredItemNames.insert(item.name)
        }

        // Trash Items
        var pickedUp: [UUID] = []
        for item in trashItems {
            let itemPos = itemScreenPosition(
                depth: item.depth,
                isLeftSide: item.isLeftSide,
                hPadding: 50
            )
            guard distance(diverPos, itemPos) <= radius else { continue }
            diveSession.collectTrash(value: item.sandDollarValue)
            pickedUp.append(item.id)
        }
        if !pickedUp.isEmpty {
            trashItems.removeAll { pickedUp.contains($0.id) }
        }
    }
}
