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
        let experienceBreakdown: ExperienceBreakdown
        /// Player's total XP *before* this dive's XP is added.
        let totalXPBefore: Int
    }

    /// Set when the diver is rescued; cleared after the overlay is dismissed.
    @Published var rescueInfo: RescueInfo?
    /// Set when the diver surfaces safely; cleared after the overlay is dismissed.
    @Published var diveCompleteStats: DiveCompleteStats?
    /// Set when a knowledgeable item is discovered; pauses the simulation until dismissed.
    @Published var discoveredKnowledgeItem: KnowledgeableItem?
    @Published var screenSize: CGSize = .zero
    @Published var trashItems: [TrashItem] = []

    /// Debug: when enabled, all limitation models are disabled and the player cannot die.
    @Published var poseidonMode = false {
        didSet {
            guard poseidonMode != oldValue else { return }
            rebuildSimulation()
        }
    }

    /// Names of items discovered this session or previously (for UI display).
    @Published private(set) var discoveredItemNames: Set<String> = []
    @Published private(set) var contentOffset: CGFloat = 0

    /// Pickup progress per trash item (0…1). Resets when the diver moves away.
    @Published private(set) var trashPickupProgress: [UUID: Double] = [:]
    /// Pickup progress per knowledgeable item (0…1), keyed by item name. Resets when the diver moves away.
    @Published private(set) var knowledgePickupProgress: [String: Double] = [:]


    let diverController = DiverController()
    private(set) var diveSimulation: DiveSimulation
    private(set) var diveSession: DiveSession
    let warningSystem = DiveWarningSystem()
    let level: LevelDefinition
    let profileStore: ProfileStore
    private(set) var diveParameters: DiveParameters

    private var cancellables: Set<AnyCancellable> = []
    private var previousSessionState: DiveSessionState = .surface
    private var maxDepthReached: Int = 0
    /// Timestamp of the last `update()` call, used to compute delta time for hover progress.
    private var lastUpdateTime: Date?

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

    /// Visual appearance of the diver, derived from equipped gear.
    var diverAppearance: DiverAppearance {
        DiverAppearance.from(profile: profileStore.profile)
    }

    /// Total dive time in simulated seconds since the current dive began.
    /// Returns 0 when not actively diving.
    var diveTimeSeconds: Int {
        guard diveSession.state == .diving else { return 0 }
        return Int(Date().timeIntervalSince(diveSimulation.diveStart) * GameConstants.timeScale)
    }

    init(
        level: LevelDefinition = .default,
        profileStore: ProfileStore = ProfileStore()
    ) {
        let params = DiveParameters.from(profile: profileStore.profile)
        self.diveParameters = params
        self.diveSession = DiveSession(carryCapacity: params.carryCapacity, earningsFactor: params.earningsFactor)
        self.level = level
        self.profileStore = profileStore
        self.diveSimulation = DiveSimulation(
            limitationModels: Self.makeLimitationModels(from: params, poseidonMode: false),
            minimumCompletionDepth: level.minimumCompletionDepth,
            minimumCompletionTime: level.minimumCompletionTime
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

    /// Recompute dive parameters from the current profile (e.g. after loadout changes in the hub).
    /// Rebuilds the dive simulation with updated limitation models so that the next dive
    /// uses the new gear/skill values.
    func recomputeParameters() {
        diveParameters = DiveParameters.from(profile: profileStore.profile)

        // Recreate dive session with updated carry capacity.
        let newSession = DiveSession(carryCapacity: diveParameters.carryCapacity, earningsFactor: diveParameters.earningsFactor)
        diveSession = newSession
        newSession.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        diveSimulation.stop()
        let newSimulation = DiveSimulation(
            limitationModels: Self.makeLimitationModels(from: diveParameters, poseidonMode: poseidonMode),
            minimumCompletionDepth: level.minimumCompletionDepth,
            minimumCompletionTime: level.minimumCompletionTime
        )
        diveSimulation = newSimulation

        // Re-forward change notifications from the new simulation.
        newSimulation.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        newSimulation.start(session: diveSession, warningSystem: warningSystem)
    }

    /// Commit the discovery and resume the simulation after the discovery overlay is dismissed.
    func dismissDiscovery() {
        guard let item = discoveredKnowledgeItem else { return }
        diveSession.discoverItem(named: item.name, atDepth: item.depth)
        profileStore.discoverItem(named: item.name)
        discoveredItemNames.insert(item.name)
        discoveredKnowledgeItem = nil
        // Resume simulation
        diveSimulation.resume()
    }

    /// Commit rewards and reset session after the dive complete overlay is dismissed.
    func dismissDiveComplete() {
        if let breakdown = diveCompleteStats?.experienceBreakdown {
            profileStore.addExperience(breakdown.totalXP)
        }
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
        // Skip updates while a discovery overlay is showing (simulation is paused).
        guard discoveredKnowledgeItem == nil else { return }

        let now = Date()
        let dt = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        lastUpdateTime = now

        diverController.updateSmoothing(
            contentOffset: contentOffset,
            currentDepth: currentDepth,
            screenWidth: screenSize.width,
            horizontalSpeed: diveParameters.diverHorizontalSpeed
        )
        diveSimulation.updateDepth(currentDepth)
        if currentDepth > maxDepthReached {
            maxDepthReached = currentDepth
        }
        checkSessionTransitions()
        checkProximity(dt: dt)
        updateContentOffset()
    }

    // MARK: - Limitation Models

    /// Build the set of limitation models for a dive based on current parameters.
    /// DCS is only possible when breathing compressed gas (scuba gear equipped).
    /// Returns an empty array when `poseidonMode` is true.
    private static func makeLimitationModels(from params: DiveParameters, poseidonMode: Bool = false) -> [any DiveLimitationModel] {
        guard !poseidonMode else { return [] }
        let models: [any DiveLimitationModel]
        switch params.diveMode {
        case .apnoe:
            models = [
                AirSupplyModel(capacity: params.airCapacity, sacRate: params.sacRate, warningTolerance: params.warningThresholdTolerance, isPressureSensitive: false),
                ThermalModel(protectionFactor: params.thermalProtectionFactor, coolingRate: params.coolingRate, warningTolerance: params.warningThresholdTolerance)
            ]
        case .scuba:
            models = [
                AirSupplyModel(capacity: params.airCapacity, sacRate: params.sacRate, warningTolerance: params.warningThresholdTolerance, isPressureSensitive: true),
                ThermalModel(protectionFactor: params.thermalProtectionFactor, coolingRate: params.coolingRate, warningTolerance: params.warningThresholdTolerance),
                DecompressionModel(warningTolerance: params.warningThresholdTolerance, safeAscentSpeedMultiplier: params.safeAscentSpeedMultiplier)
            ]
        case .submersible:
            models = [
                AirSupplyModel(capacity: params.airCapacity, sacRate: params.sacRate, warningTolerance: params.warningThresholdTolerance, isPressureSensitive: false),
                ExternalPressureModel(pressureRating: params.pressureRating, warningTolerance: params.warningThresholdTolerance),
                BatteryPowerModel(batteryMinutes: params.batteryMinutes, warningTolerance: params.warningThresholdTolerance)
            ]
        }

        return models
    }

    /// Rebuild the dive simulation in-place, e.g. after toggling Poseidon Mode.
    private func rebuildSimulation() {
        let wasDiving = diveSession.state == .diving
        diveSimulation.stop()

        let newSimulation = DiveSimulation(
            limitationModels: Self.makeLimitationModels(from: diveParameters, poseidonMode: poseidonMode),
            minimumCompletionDepth: level.minimumCompletionDepth,
            minimumCompletionTime: level.minimumCompletionTime
        )
        diveSimulation = newSimulation

        newSimulation.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        if wasDiving {
            warningSystem.clearAll()
        }
        newSimulation.start(session: diveSession, warningSystem: warningSystem)
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

        let delta = vertical * diveParameters.scrollSpeed
        let newOffset = max(0, min(contentOffset + delta, maximumDepthInPixels))
        contentOffset = newOffset
    }

    // MARK: - Trash world

    /// Spawn any due trash, then load available items from the persistent world state.
    private func loadAvailableTrash() {
        profileStore.spawnDueTrash()
        let available = profileStore.availableTrashItems()
        trashItems = available.compactMap { worldItem -> TrashItem? in
            guard let typeDef = TrashTypeDefinition.allTypes.first(where: { $0.id == worldItem.typeID }) else {
                return nil
            }
            return TrashItem(
                id: worldItem.id,
                typeDef: typeDef,
                depth: worldItem.depth,
                xFraction: worldItem.xFraction
            )
        }
    }

    // MARK: - Session lifecycle

    private func checkSessionTransitions() {
        let currentState = diveSession.state

        // Detect dive start → load available trash from persistent world, reset max depth
        if previousSessionState == .surface && currentState == .diving {
            loadAvailableTrash()
            maxDepthReached = 0
        }

        // Detect safe surfacing → persist dive records, compute XP, capture stats, show overlay
        if previousSessionState == .diving && currentState == .surfacedSafely {
            let diveTime = Int(Date().timeIntervalSince(diveSimulation.diveStart) * GameConstants.timeScale)
            let totalDivesBefore = profileStore.profile.totalDives
            let totalTimeBefore = profileStore.profile.totalDiveTimeSeconds
            let isFirstDive = totalDivesBefore == 0

            // Build XP input before updating records
            let diveResult = DiveResult(
                maxDepthMeters: maxDepthReached,
                diveTimeSeconds: diveTime,
                discoveredItems: diveSession.discoveredItemRecords,
                sandDollarsCollected: Int(diveSession.collectedSandDollars),
                previousRecordDepth: isFirstDive ? nil : profileStore.profile.recordMaxDepth,
                previousRecordTime: isFirstDive ? nil : profileStore.profile.recordDiveTimeSeconds
            )
            let xpBreakdown = ExperienceCalculator().calculate(from: diveResult)

            let records = profileStore.recordCompletedDive(diveTimeSeconds: diveTime, maxDepth: maxDepthReached)

            diveCompleteStats = DiveCompleteStats(
                diveTimeSeconds: diveTime,
                maxDepth: maxDepthReached,
                sandDollarsCollected: Int(diveSession.collectedSandDollars),
                itemsDiscovered: diveSession.discoveredItemNames.count,
                totalDivesBefore: totalDivesBefore,
                totalDiveTimeBefore: totalTimeBefore,
                isDepthRecord: records.newDepthRecord,
                isTimeRecord: records.newTimeRecord,
                experienceBreakdown: xpBreakdown,
                totalXPBefore: profileStore.profile.experiencePoints
            )

            // Persist collected trash items in the world state
            for trashID in diveSession.collectedTrashIDs {
                profileStore.collectTrashItem(id: trashID)
            }
            trashItems = []
            trashPickupProgress = [:]
            knowledgePickupProgress = [:]
        }

        // Detect rescue → award discovery XP, show overlay, clear trash
        if case .rescued(let reason) = currentState, previousSessionState == .diving {
            // Discoveries persist even on rescue — award their XP immediately.
            if !diveSession.discoveredItemRecords.isEmpty {
                var discoveryXP = 0
                for item in diveSession.discoveredItemRecords {
                    discoveryXP += ExperienceCalculator.baseItemXP + Int(item.depthMeters * ExperienceCalculator.itemDepthBonusPerMeter)
                }
                profileStore.addExperience(discoveryXP)
            }

            rescueInfo = RescueInfo(
                reason: reason,
                lostSandDollars: Int(diveSession.collectedSandDollars)
            )
            trashItems = []
            trashPickupProgress = [:]
            knowledgePickupProgress = [:]
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

    private func checkProximity(dt: TimeInterval) {
        guard diveSession.state == .diving else { return }
        let diverPos = diverScreenPosition
        let radius = GameConstants.pickupRadius

        // Knowledgeable Items — hover-to-discover
        var knowledgeInRange: Set<String> = []
        for (index, item) in KnowledgeableItem.allItems.enumerated() {
            guard !discoveredItemNames.contains(item.name) else { continue }
            let itemPos = itemScreenPosition(
                depth: item.depth,
                isLeftSide: index.isMultiple(of: 2),
                hPadding: 60
            )
            guard distance(diverPos, itemPos) <= radius else { continue }

            knowledgeInRange.insert(item.name)

            let simulatedDt = dt
            let effectiveDuration = item.pickupDuration * diveParameters.pickupSpeedMultiplier
            let increment = effectiveDuration > 0 ? simulatedDt / effectiveDuration : 1.0
            let progress = (knowledgePickupProgress[item.name] ?? 0) + increment

            if progress >= 1.0 {
                knowledgePickupProgress.removeValue(forKey: item.name)
                // Pause simulation and show discovery overlay
                discoveredKnowledgeItem = item
                diveSimulation.pause()
                lastUpdateTime = nil
                return
            } else {
                knowledgePickupProgress[item.name] = progress
            }
        }

        // Reset progress for knowledge items no longer in range
        for name in knowledgePickupProgress.keys where !knowledgeInRange.contains(name) {
            knowledgePickupProgress.removeValue(forKey: name)
        }

        // Trash Items — hover-to-collect
        var inRangeIDs: Set<UUID> = []
        var pickedUp: [UUID] = []
        for item in trashItems {
            let screenY = item.depth * scalingFactor - contentOffset + screenSize.height / 3 + 50
            let screenX = item.xFraction * screenSize.width
            let itemPos = CGPoint(x: screenX, y: screenY)
            guard distance(diverPos, itemPos) <= radius else { continue }
            guard !diveSession.isBagFull else { break }

            inRangeIDs.insert(item.id)

            // Accumulate hover progress
            let effectiveDuration = item.typeDef.pickupDuration * diveParameters.pickupSpeedMultiplier
            let increment = effectiveDuration > 0 ? dt / effectiveDuration : 1.0
            let progress = (trashPickupProgress[item.id] ?? 0) + increment

            if progress >= 1.0 {
                if diveSession.collectTrash(id: item.id, value: item.sandDollarValue) {
                    pickedUp.append(item.id)
                }
                trashPickupProgress.removeValue(forKey: item.id)
            } else {
                trashPickupProgress[item.id] = progress
            }
        }

        // Reset progress for items no longer in range
        for id in trashPickupProgress.keys where !inRangeIDs.contains(id) {
            trashPickupProgress.removeValue(forKey: id)
        }

        if !pickedUp.isEmpty {
            trashItems.removeAll { pickedUp.contains($0.id) }
        }
    }
}
