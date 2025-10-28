import SwiftUI

struct StatusPanel: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        let totalDiveTime = viewModel.diveActive ? Int(Date().timeIntervalSince(viewModel.diveStart) * viewModel.timeScale) : 0
        let minutes = totalDiveTime / 60
        let seconds = totalDiveTime % 60
        let atDepthMinutes = Int(viewModel.timeAtCurrentDepth) / 60
        let atDepthSeconds = Int(viewModel.timeAtCurrentDepth) % 60
        let ppo2 = viewModel.selectedMixture.partialPressure(
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
                Picker("Gas Mixture", selection: $viewModel.selectedMixture) {
                    ForEach(viewModel.availableMixtures, id: \.mixture) { option in
                        Text(option.name).tag(option.mixture)
                    }
                }
                .pickerStyle(.menu)
            }
            Text("pO₂: \(String(format: "%.2f", ppo2)) atm")
            Text("Tissue N₂: \(String(format: "%.2f", viewModel.saturation.nitrogenPressure)) atm")
        }
        .font(.system(.headline, design: .rounded))
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top, 64)
    }
} 
