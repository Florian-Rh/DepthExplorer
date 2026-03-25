import SwiftUI

@main
struct DepthExplorerApp: App {
    @StateObject private var profileStore = ProfileStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LevelView(profileStore: profileStore)
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        profileStore.resumeGameClock()
                    case .inactive, .background:
                        profileStore.pauseGameClock()
                    @unknown default:
                        break
                    }
                }
                .onAppear {
                    profileStore.resumeGameClock()
                }
        }
    }
}
