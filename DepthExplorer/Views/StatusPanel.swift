import SwiftUI

struct StatusPanel: View {
    @Binding var currentDepth: Int
    @Binding var currentPressure: Double
    @Binding var selectedMixture: GasMixture
    let availableMixtures: [(name: String, mixture: GasMixture)]
    @Binding var timerActive: Bool
    @Binding var diveStart: Date
    @Binding var timeAtCurrentDepth: Double
    @Binding var tissue: TissueCompartment
    let timeScale: Double

    var body: some View {
        let totalDiveTime = timerActive ? Int(Date().timeIntervalSince(diveStart) * timeScale) : 0
        let minutes = totalDiveTime / 60
        let seconds = totalDiveTime % 60
        let atDepthMinutes = Int(timeAtCurrentDepth) / 60
        let atDepthSeconds = Int(timeAtCurrentDepth) % 60
        let ppo2 = selectedMixture.partialPressure(
            of: .oxygen,
            at: currentPressure
        )
        VStack(alignment: .leading, spacing: 4) {
            Text("Dive time: \(String(format: "%02d:%02d", minutes, seconds))")
            Text("Time at depth (±5m): \(String(format: "%02d:%02d", atDepthMinutes, atDepthSeconds))")
            Text("Depth: \(currentDepth)m")
            Text("Pressure: \(String(format: "%.1f", currentPressure)) atm")
            HStack(spacing: 8) {
                Text("Gas Mixture:")
                Picker("Gas Mixture", selection: $selectedMixture) {
                    ForEach(availableMixtures, id: \.mixture) { option in
                        Text(option.name).tag(option.mixture)
                    }
                }
                .pickerStyle(.menu)
            }
            Text("pO₂: \(String(format: "%.2f", ppo2)) atm")
            Text("Tissue N₂ (60min): \(String(format: "%.2f", tissue.nitrogenPressure)) atm")
        }
        .font(.system(.headline, design: .rounded))
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top, 64)
    }
} 