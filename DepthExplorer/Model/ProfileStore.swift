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
        profile.experiencePoints += amount
        save()
    }

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
