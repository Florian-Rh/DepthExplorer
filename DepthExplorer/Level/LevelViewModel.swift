import Foundation
import SwiftUI
import Combine

class LevelViewModel: ObservableObject {
    struct RescueInfo {
        let reason: String
        let lostSandDollars: Int
    }

    struct DiveCompleteStats {
        let diveTimeSeconds: Int
        let maxDepth: Int
        let sandDollarsCollected: Int
        let itemsDiscovered: Int
        let totalDivesBefore: Int
        let totalDiveTimeBefore: Int
        let isDepthRecord: Bool
        let isTimeRecord: Bool
    }

    /// Set when the diver is rescued; cleared after the overlay is dismissed.
    @Published var rescueInfo: RescueInfo?
    /// Set when the diver surfaces safely; cleared after the overlay is dismissed.
    @Published var diveCompleteStats: DiveCompleteStats?
    @Published var screenSize: CGSize = .zero
    @Published var trashItems: [TrashItem] = []

    /// Names of items discovered this session or previously (for UI display).
    @Published private(set) var discoveredItemNames: Set<String> = []
    @Published private(set) var contentOffset: CGFloat = 0


    let diverController = DiverController()
    let diveSimulation: DiveSimulation
    let diveSession = DiveSession()
    let warningSystem = DiveWarningSystem()
    let level: LevelDefinition
    let profileStore: ProfileStore

    private var cancellables: Set<AnyCancellable> = []
    private var previousSessionState: DiveSessionState = .surface
    private var maxDepthReached: Int = 0

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

    init(
        level: LevelDefinition = .default,
        profileStore: ProfileStore = ProfileStore(),
        limitationModels: [any DiveLimitationModel]? = nil
    ) {
        self.level = level
        self.profileStore = profileStore
        self.diveSimulation = DiveSimulation(
            limitationModels: limitationModels ?? [
                AirSupplyModel(),
                ThermalModel(),
                DecompressionModel(),
            ]
        )
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

    func resetProfile() {
        profileStore.resetProfile()
        discoveredItemNames = []
    }

    /// Commit rewards and reset session after the dive complete overlay is dismissed.
    func dismissDiveComplete() {
        diveSession.commitRewards(to: profileStore)
        discoveredItemNames = profileStore.profile.discoveredItems
        diveSimulation.resetSimulationData()
        diveCompleteStats = nil
    }

    /// Reset diver and session state back to surface. Called while the rescue overlay is still opaque.
    func resetToSurface() {
        diveSession.discard()
        warningSystem.clearAll()
        diveSimulation.resetSimulationData()
        contentOffset = 0
        diverController.reset()
    }

    /// Called every display frame by the scroll driver.
    func update() {
        diverController.updateSmoothing(
            contentOffset: contentOffset,
            currentDepth: currentDepth,
            screenWidth: screenSize.width
        )
        diveSimulation.updateDepth(currentDepth)
        if currentDepth > maxDepthReached {
            maxDepthReached = currentDepth
        }
        checkSessionTransitions()
        checkProximity()
        updateContentOffset()
    }

    // MARK: - Screen control

    private func updateContentOffset() {
        guard diveSession.state == .diving || diveSession.state == .surface else { return }

        let vertical = diverController.joystickVertical

        // Auto-surface when ascending near the surface
        if currentDepth < level.autoSurfaceDepth && currentDepth > 0 && vertical <= 0 {
            contentOffset = max(0, contentOffset - level.autoSurfaceSpeed)
            return
        }

        guard abs(vertical) > GameConstants.joystickDeadzone else { return }

        let delta = vertical * GameConstants.scrollSpeed
        let newOffset = max(0, min(contentOffset + delta, maximumDepthInPixels))
        contentOffset = newOffset
    }

    // MARK: - Session lifecycle

    private func checkSessionTransitions() {
        let currentState = diveSession.state

        // Detect dive start → spawn trash, reset max depth
        if previousSessionState == .surface && currentState == .diving {
            trashItems = TrashItem.spawnForDive()
            maxDepthReached = 0
        }

        // Detect safe surfacing → persist dive records, capture stats, show overlay
        if previousSessionState == .diving && currentState == .surfacedSafely {
            let diveTime = Int(Date().timeIntervalSince(diveSimulation.diveStart) * GameConstants.timeScale)
            let totalDivesBefore = profileStore.profile.totalDives
            let totalTimeBefore = profileStore.profile.totalDiveTimeSeconds
            let records = profileStore.recordCompletedDive(diveTimeSeconds: diveTime, maxDepth: maxDepthReached)

            diveCompleteStats = DiveCompleteStats(
                diveTimeSeconds: diveTime,
                maxDepth: maxDepthReached,
                sandDollarsCollected: diveSession.collectedSandDollars,
                itemsDiscovered: diveSession.discoveredItemNames.count,
                totalDivesBefore: totalDivesBefore,
                totalDiveTimeBefore: totalTimeBefore,
                isDepthRecord: records.newDepthRecord,
                isTimeRecord: records.newTimeRecord
            )
            trashItems = []
        }

        // Detect rescue → show overlay, clear trash
        if case .rescued(let reason) = currentState, previousSessionState == .diving {
            rescueInfo = RescueInfo(
                reason: reason,
                lostSandDollars: diveSession.collectedSandDollars
            )
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
            profileStore.discoverItem(named: item.name)
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
