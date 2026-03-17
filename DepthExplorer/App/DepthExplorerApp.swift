import SwiftUI

@main
struct DepthExplorerApp: App {
    @StateObject private var profileStore = ProfileStore()

    var body: some Scene {
        WindowGroup {
            LevelView(profileStore: profileStore)
        }
    }
}
