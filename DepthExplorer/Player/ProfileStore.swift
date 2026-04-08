import Foundation

/// Loads and saves the player's persistent profile as a JSON file.
/// Usage: inject a single instance via `@StateObject` or environment at the app root.
final class ProfileStore: ObservableObject {
    @Published private(set) var profile: PlayerProfile

    /// Game clock that tracks continuous game time across app sessions.
    private(set) var gameClock: GameClock

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("player_profile.json")
        let loaded = Self.load(from: fileURL)
        self.profile = loaded
        self.gameClock = GameClock(savedElapsed: loaded.gameTimeElapsed)

        // Migrate old scubaGearAccessory slot → new stageBottle category
        if let oldAccessory = profile.equippedGearIDs["scubaGearAccessory"] {
            profile.equippedGearIDs.removeValue(forKey: "scubaGearAccessory")
            if let gear = GearDefinition.allGear.first(where: { $0.id == oldAccessory }) {
                profile.equippedGearIDs[gear.category.rawValue] = oldAccessory
            }
            save()
        }

        // Seed trash world on first launch or migration from old profile
        if profile.trashWorldState.isEmpty {
            profile.trashWorldState = TrashWorldItem.seedWorld()
            save()
        }
    }

    // MARK: - Mutations

    func addSandDollars(_ amount: Int) {
        profile.sandDollars += amount
        save()
    }

    func addExperience(_ amount: Int) {
        let levelBefore = LevelProgression.from(totalXP: profile.experiencePoints).level
        profile.experiencePoints += amount
        let levelAfter = LevelProgression.from(totalXP: profile.experiencePoints).level
        let levelsGained = levelAfter - levelBefore
        if levelsGained > 0 {
            profile.skillPoints += levelsGained
        }
        save()
    }

    struct DiveRecords {
        let newDepthRecord: Bool
        let newTimeRecord: Bool
    }

    /// Record a completed dive, update totals and personal records.
    /// Returns which records were broken (only counts if not the first dive).
    @discardableResult
    func recordCompletedDive(diveTimeSeconds: Int, maxDepth: Int) -> DiveRecords {
        let isFirstDive = profile.totalDives == 0

        let newDepthRecord = !isFirstDive && maxDepth > profile.recordMaxDepth
        let newTimeRecord = !isFirstDive && diveTimeSeconds > profile.recordDiveTimeSeconds

        profile.totalDives += 1
        profile.totalDiveTimeSeconds += diveTimeSeconds
        if maxDepth > profile.recordMaxDepth {
            profile.recordMaxDepth = maxDepth
        }
        if diveTimeSeconds > profile.recordDiveTimeSeconds {
            profile.recordDiveTimeSeconds = diveTimeSeconds
        }
        save()

        return DiveRecords(newDepthRecord: newDepthRecord, newTimeRecord: newTimeRecord)
    }

    // MARK: - Gear

    func purchaseGear(id: String, cost: Int) {
        guard profile.sandDollars >= cost,
              !profile.ownedGearIDs.contains(id) else { return }
        profile.sandDollars -= cost
        profile.ownedGearIDs.insert(id)
        // Auto-equip newly purchased gear
        if let gear = GearDefinition.allGear.first(where: { $0.id == id }) {
            enforceEquipmentExclusivity(for: gear.category)
            profile.equippedGearIDs[gear.category.rawValue] = id
        }
        save()
    }

    func equipGear(id: String, category: GearCategory) {
        enforceEquipmentExclusivity(for: category)
        profile.equippedGearIDs[category.rawValue] = id
        save()
    }

    func unequipGear(category: GearCategory) {
        profile.equippedGearIDs.removeValue(forKey: category.rawValue)
        save()
    }

    /// Unequip gear from conflicting equipment classes before equipping a new category.
    private func enforceEquipmentExclusivity(for category: GearCategory) {
        switch category.equipmentClass {
        case .submersible:
            // Unequip all scuba-class gear
            for cat in GearCategory.allCases where cat.equipmentClass == .scuba {
                profile.equippedGearIDs.removeValue(forKey: cat.rawValue)
            }
        case .scuba:
            // Unequip all submersible-class gear
            for cat in GearCategory.allCases where cat.equipmentClass == .submersible {
                profile.equippedGearIDs.removeValue(forKey: cat.rawValue)
            }
        }
    }

    // MARK: - Skills

    func acquireSkill(id: String) {
        guard profile.skillPoints > 0,
              !profile.acquiredSkillIDs.contains(id) else { return }
        profile.acquiredSkillIDs.insert(id)
        profile.skillPoints -= 1
        save()
    }

    // MARK: - Game Clock

    /// Resume the game clock. Called when the app enters the foreground.
    func resumeGameClock() {
        gameClock.resume()
    }

    /// Pause the game clock and persist the elapsed time. Called on background/termination.
    func pauseGameClock() {
        profile.gameTimeElapsed = gameClock.pause()
        save()
    }

    /// Current game time (convenience accessor).
    var currentGameTime: TimeInterval {
        gameClock.totalElapsed
    }

    // MARK: - Trash World

    /// Remove a collected trash item from the world and schedule a
    /// replacement spawn for that type.
    func collectTrashItem(id: UUID) {
        guard let index = profile.trashWorldState.firstIndex(where: { $0.id == id }) else { return }
        let typeID = profile.trashWorldState[index].typeID
        profile.trashWorldState.remove(at: index)

        // Always ensure a spawn is scheduled. Use the earliest of the
        // existing schedule or a fresh `now + respawnTime`.
        if let typeDef = TrashTypeDefinition.allTypes.first(where: { $0.id == typeID }) {
            let freshTime = currentGameTime + typeDef.respawnTime
            if let existing = profile.trashSpawnSchedule[typeID] {
                profile.trashSpawnSchedule[typeID] = min(existing, freshTime)
            } else {
                profile.trashSpawnSchedule[typeID] = freshTime
            }
        }
        save()
    }

    /// Spawn trash items whose scheduled spawn time has been reached.
    /// Spawns one item per elapsed respawn interval (items trickle in
    /// rather than all appearing at once). Call this before loading
    /// trash for a dive.
    func spawnDueTrash() {
        let now = currentGameTime
        var changed = false

        for typeDef in TrashTypeDefinition.allTypes {
            // Spawn one item each time the respawn interval elapses,
            // advancing the schedule forward until it's in the future
            // or the world is at max count for this type.
            while let spawnAt = profile.trashSpawnSchedule[typeDef.id], now >= spawnAt {
                let currentCount = profile.trashWorldState.filter { $0.typeID == typeDef.id }.count
                if currentCount < typeDef.maxCount {
                    profile.trashWorldState.append(.random(for: typeDef))
                    // Schedule the next spawn one interval later
                    profile.trashSpawnSchedule[typeDef.id] = spawnAt + typeDef.respawnTime
                    changed = true
                } else {
                    // At max count — clear the schedule
                    profile.trashSpawnSchedule.removeValue(forKey: typeDef.id)
                    changed = true
                    break
                }
            }

            // Ensure types below max count always have a pending schedule.
            // Covers new types added after the initial seed and edge cases
            // where a schedule entry was lost.
            if profile.trashSpawnSchedule[typeDef.id] == nil {
                let currentCount = profile.trashWorldState.filter { $0.typeID == typeDef.id }.count
                if currentCount < typeDef.maxCount {
                    profile.trashSpawnSchedule[typeDef.id] = now + typeDef.respawnTime
                    changed = true
                }
            }
        }

        if changed { save() }
    }

    /// Returns all trash items currently in the world (all are available).
    func availableTrashItems() -> [TrashWorldItem] {
        profile.trashWorldState
    }

    // MARK: - Discovery

    func discoverItem(named name: String) {
        guard !profile.discoveredItems.contains(name) else { return }
        profile.discoveredItems.insert(name)
        save()
    }

    /// Resets all progress. Intended for debugging only.
    func resetProfile() {
        profile = PlayerProfile()
        profile.trashWorldState = TrashWorldItem.seedWorld()
        gameClock = GameClock(savedElapsed: 0)
        gameClock.resume()
        save()
    }

    /// Sets the player's XP to an exact value. Debug only.
    func setExperience(_ amount: Int) {
        let levelBefore = LevelProgression.from(totalXP: profile.experiencePoints).level
        profile.experiencePoints = amount
        let levelAfter = LevelProgression.from(totalXP: profile.experiencePoints).level
        let levelsGained = levelAfter - levelBefore
        if levelsGained > 0 {
            profile.skillPoints += levelsGained
        }
        save()
    }

    /// Unlocks all gear items without spending sand dollars. Debug only.
    func unlockAllGear() {
        for gear in GearDefinition.allGear {
            profile.ownedGearIDs.insert(gear.id)
        }
        save()
    }

    /// Adds a skill point. Debug only.
    func addSkillPoint() {
        profile.skillPoints += 1
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[ProfileStore] Failed to save: \(error)")
        }
    }

    private static func load(from url: URL) -> PlayerProfile {
        guard let data = try? Data(contentsOf: url),
              let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data)
        else {
            return PlayerProfile()
        }
        return profile
    }
}
