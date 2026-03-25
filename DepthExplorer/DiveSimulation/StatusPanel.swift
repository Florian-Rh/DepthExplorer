import SwiftUI

struct StatusPanel: View {
    @ObservedObject var viewModel: LevelViewModel
    @State private var warningsExpanded = false

    var body: some View {
        let sim = viewModel.diveSimulation
        let session = viewModel.diveSession
        let warnings = viewModel.warningSystem.activeWarnings
        let isDiving = session.state == .diving
        let totalDiveTime = isDiving ? Int(Date().timeIntervalSince(sim.diveStart) * GameConstants.timeScale) : 0
        let minutes = totalDiveTime / 60
        let seconds = totalDiveTime % 60
        let atDepthMinutes = Int(sim.timeAtCurrentDepth) / 60
        let atDepthSeconds = Int(sim.timeAtCurrentDepth) % 60
        let ppo2 = sim.selectedMixture.partialPressure(
            of: .oxygen,
            at: viewModel.currentPressure
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // MARK: - Session State
                HStack(spacing: 6) {
                    Circle()
                        .fill(sessionStateColor(session.state))
                        .frame(width: 8, height: 8)
                    Text("Session: \(sessionStateLabel(session.state))")
                }

                if isDiving {
                    Text("Collected: \(session.collectedSandDollars) SD, \(session.discoveredItemNames.count) items")
                }

                let profile = viewModel.profileStore.profile
                HStack {
                    Text("Profile: \(profile.sandDollars) SD, \(profile.discoveredItems.count) discovered")
                        .foregroundStyle(.cyan)
                    Spacer()
                    Button("Reset") {
                        viewModel.resetProfile()
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.red)
                }
                Text("Skill pts: \(profile.skillPoints) | Gear owned: \(profile.ownedGearIDs.count)/\(GearDefinition.allGear.count)")
                    .foregroundStyle(.cyan)
                let gameTime = Int(viewModel.profileStore.currentGameTime)
                let gtH = gameTime / 3600
                let gtM = (gameTime % 3600) / 60
                let gtS = gameTime % 60
                Text("Game time: \(String(format: "%02d:%02d:%02d", gtH, gtM, gtS))")
                    .foregroundStyle(.cyan)
                HStack(spacing: 12) {
                    Button("Unlock All Gear") {
                        viewModel.profileStore.unlockAllGear()
                    }
                    .foregroundStyle(.green)
                    Button("+1 Skill Point") {
                        viewModel.profileStore.addSkillPoint()
                    }
                    .foregroundStyle(.green)
                }
                .font(.system(.caption, design: .monospaced))

                Button {
                    viewModel.poseidonMode.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.poseidonMode ? "bolt.shield.fill" : "bolt.shield")
                        Text("Poseidon Mode: \(viewModel.poseidonMode ? "ON" : "OFF")")
                    }
                    .foregroundStyle(viewModel.poseidonMode ? .yellow : .white.opacity(0.5))
                }
                .font(.system(.caption, design: .monospaced))
                .buttonStyle(.plain)

                Divider().background(.white.opacity(0.3))

                // MARK: - Dive Data
                Text("Dive time: \(String(format: "%02d:%02d", minutes, seconds))")
                Text("Time at depth (\u{00B1}5m): \(String(format: "%02d:%02d", atDepthMinutes, atDepthSeconds))")
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
                Text("Air: \(String(format: "%.0f", sim.vitals.remainingBar ?? GameConstants.scubaGearCapacity)) / \(Int(GameConstants.scubaGearCapacity)) bar (\(String(format: "%.0f", (sim.vitals.airFraction ?? 1.0) * 100))%)")
                Text("Ascent: \(String(format: "%.1f", sim.vitals.ascentSpeed ?? 0)) m/s (safe: \(String(format: "%.1f", GameConstants.safeAscentSpeed)) m/s)")
                Text("Body temp: \(String(format: "%.1f", sim.vitals.bodyTemperature ?? GameConstants.normalBodyTemperature))°C (water: \(String(format: "%.1f", ThermalModel.waterTemperature(atDepth: viewModel.currentDepth)))°C)")
                Text("pO\u{2082}: \(String(format: "%.2f", ppo2)) atm")
                Text("Tissue N\u{2082}: \(String(format: "%.2f", sim.saturation.nitrogenPressure)) atm")

                // MARK: - Warnings
                Divider().background(.white.opacity(0.3))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        warningsExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Warnings (\(warnings.count))")
                        Image(systemName: warningsExpanded ? "chevron.up" : "chevron.down")
                    }
                }
                .buttonStyle(.plain)

                if warningsExpanded {
                    if warnings.isEmpty {
                        Text("None")
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        ForEach(warnings) { warning in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(warningSeverityColor(warning.severity))
                                    .frame(width: 8, height: 8)
                                Text("[\(warning.kind.rawValue)] \(warning.message)")
                            }
                        }
                    }
                }
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.white)
        }
        .frame(maxHeight: 320)
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top, 64)
        .padding(.horizontal, 8)
    }

    private func sessionStateLabel(_ state: DiveSessionState) -> String {
        switch state {
        case .surface: "Surface"
        case .diving: "Diving"
        case .surfacedSafely: "Surfaced Safely"
        case .rescued(let reason): "Rescued (\(reason))"
        }
    }

    private func sessionStateColor(_ state: DiveSessionState) -> Color {
        switch state {
        case .surface: .gray
        case .diving: .green
        case .surfacedSafely: .blue
        case .rescued: .red
        }
    }

    private func warningSeverityColor(_ severity: DiveWarningSeverity) -> Color {
        switch severity {
        case .caution: .yellow
        case .critical: .orange
        case .fatal: .red
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel: LevelViewModel = .init()

    StatusPanel(viewModel: viewModel)
        .onAppear {
            viewModel.startSimulation()
        }
}
