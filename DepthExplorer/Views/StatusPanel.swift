import SwiftUI

struct StatusPanel: View {
    @ObservedObject var viewModel: LevelViewModel

    var body: some View {
        let sim = viewModel.diveSimulation
        let totalDiveTime = sim.diveActive ? Int(Date().timeIntervalSince(sim.diveStart) * GameConstants.timeScale) : 0
        let minutes = totalDiveTime / 60
        let seconds = totalDiveTime % 60
        let atDepthMinutes = Int(sim.timeAtCurrentDepth) / 60
        let atDepthSeconds = Int(sim.timeAtCurrentDepth) % 60
        let ppo2 = sim.selectedMixture.partialPressure(
            of: .oxygen,
            at: viewModel.currentPressure
        )
        VStack(alignment: .leading, spacing: 4) {
            Text("Dive time: \(String(format: "%02d:%02d", minutes, seconds))")
            Text("Time at depth (±5m): \(String(format: "%02d:%02d", atDepthMinutes, atDepthSeconds))")
            Text("Depth: \(viewModel.currentDepth)m")
            Text("Pressure: \(String(format: "%.1f", viewModel.currentPressure)) atm")
            HStack(spacing: 8) {
                Text("Gas Mixture:")
                Picker("Gas Mixture", selection: Binding(
                    get: { viewModel.diveSimulation.selectedMixture },
                    set: { viewModel.diveSimulation.selectedMixture = $0 }
                )) {
                    ForEach(GameConstants.availableMixtures, id: \.name) { option in
                        Text(option.name).tag(option.mixture as GasMixture)
                    }
                }
                .pickerStyle(.menu)
            }
            Text("pO₂: \(String(format: "%.2f", ppo2)) atm")
            Text("Tissue N₂: \(String(format: "%.2f", sim.saturation.nitrogenPressure)) atm")
        }
        .font(.system(.headline, design: .rounded))
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top, 64)
    }
} 

#Preview {
    @Previewable @StateObject var viewModel: LevelViewModel = .init()

    StatusPanel(viewModel: viewModel)
        .onAppear {
            viewModel.startSimulation()
        }
}
