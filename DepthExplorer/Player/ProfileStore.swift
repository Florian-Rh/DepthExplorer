import Foundation

/// Loads and saves the player's persistent profile as a JSON file.
/// Usage: inject a single instance via `@StateObject` or environment at the app root.
final class ProfileStore: ObservableObject {
    @Published private(set) var profile: PlayerProfile

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("player_profile.json")
        self.profile = Self.load(from: fileURL)
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
        save()
    }

    func equipGear(id: String, category: GearCategory) {
        profile.equippedGearIDs[category.rawValue] = id
        save()
    }

    func unequipGear(category: GearCategory) {
        profile.equippedGearIDs.removeValue(forKey: category.rawValue)
        save()
    }

    // MARK: - Skills

    func acquireSkill(id: String) {
        guard profile.skillPoints > 0,
              !profile.acquiredSkillIDs.contains(id) else { return }
        profile.acquiredSkillIDs.insert(id)
        profile.skillPoints -= 1
        save()
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
