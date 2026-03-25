import OpenSeasUI
import SwiftUI

struct LevelView: View {
    @ObservedObject var profileStore: ProfileStore
    @StateObject var viewModel: LevelViewModel
    @State private var frameDriver = FrameUpdateDriver()
    @State private var showDebugButton = false
    @State private var showDebugPanel = false
    @State private var showHub = false
    @State private var hubInitialTab: HubTab = .shop

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore
        _viewModel = StateObject(wrappedValue: LevelViewModel(profileStore: profileStore))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: .coralSunsetGradient,
                startPoint: .bottom,
                endPoint: .top
            )

            GeometryReader { geo in
                let screenSize = geo.size

                ZStack {
                    OceanView(depthInPixels: viewModel.maximumDepthInPixels, screenHeight: screenSize.height)

                    ForEach(
                        Array(KnowledgeableItem.allItems.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        if !viewModel.discoveredItemNames.contains(item.name) {
                            KnowledgeableItemView(
                                item: item,
                                isLeftSide: index.isMultiple(of: 2),
                                scalingFactor: viewModel.scalingFactor,
                                contentOffset: viewModel.contentOffset,
                                screenSize: screenSize,
                                isDiscovered: false
                            )
                            .offset(y: 50)
                        }
                    }
                    .offset(y: screenSize.height / 3)

                    ForEach(viewModel.trashItems) { item in
                        TrashItemView(
                            item: item,
                            scalingFactor: viewModel.scalingFactor,
                            contentOffset: viewModel.contentOffset,
                            screenSize: screenSize
                        )
                        .offset(y: 50)
                    }
                    .offset(y: screenSize.height / 3)

                    DepthScale(
                        maximumDepth: GameConstants.maximumDepth,
                        factor: viewModel.scalingFactor
                    )
                    .offset(y: screenSize.height / 3 + 15)
                }
                .offset(y: -viewModel.contentOffset)
                .onAppear { viewModel.screenSize = screenSize }
                .onChange(of: screenSize) { _, newSize in viewModel.screenSize = newSize }
            }
            .clipped()

            ScubaDiverView(tilt: viewModel.diverController.tilt, submersed: viewModel.currentDepth > 0, appearance: viewModel.diverAppearance)
                .scaleEffect(0.8)
                .position(
                    x: viewModel.screenSize.width / 2 + viewModel.diverController.x,
                    y: viewModel.screenSize.height / 3 + 30 + viewModel.diverController.offset.height
                )

            VStack {
                Spacer()
                DiveHUDView(
                    depth: viewModel.currentDepth,
                    diveTimeSeconds: viewModel.diveTimeSeconds,
                    remainingBar: viewModel.diveSimulation.vitals.remainingBar ?? viewModel.diveParameters.airCapacity,
                    airCapacity: viewModel.diveParameters.airCapacity,
                    ascentSpeed: viewModel.diveSimulation.vitals.ascentSpeed ?? 0,
                    bodyTemperature: viewModel.diveSimulation.vitals.bodyTemperature ?? GameConstants.normalBodyTemperature,
                    warnings: viewModel.warningSystem.activeWarnings,
                    isDiving: viewModel.diveSession.state == .diving,
                    hasScubaGear: viewModel.diveParameters.hasScubaGear,
                    trashCollected: viewModel.diveSession.collectedTrashCount,
                    carryCapacity: viewModel.diveSession.carryCapacity,
                    onJoystickChanged: { offset, angle in
                        viewModel.diverController.offsetTarget = offset
                        if let angle {
                            viewModel.diverController.tiltTarget = angle
                        }
                        viewModel.diverController.joystickVertical = offset.height / 50.0
                        viewModel.diverController.joystickHorizontal = offset.width / 50.0
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }

            VStack {
                HStack {
                    if showDebugButton {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDebugPanel.toggle()
                            }
                        } label: {
                            Image(systemName: "ladybug")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.leading, 12)
                        .padding(.top, 60)
                    }

                    Spacer()

                    // Hub button — opens shop, skills, inventory, glossary
                    // Hidden while diving to prevent session reset.
                    Button {
                        hubInitialTab = .shop
                        showHub = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Lv.\(LevelProgression.from(totalXP: profileStore.profile.experiencePoints).level)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)

                            Rectangle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 1, height: 16)

                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.yellow)
                                Text("\(profileStore.profile.sandDollars)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                            }

                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1))
                        .overlay(alignment: .topTrailing) {
                            if profileStore.profile.skillPoints > 0 {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -2, y: -2)
                            }
                        }
                    }
                    .padding(.top, 60)
                    .opacity(viewModel.diveSession.state == .diving ? 0 : 1)
                    .allowsHitTesting(viewModel.diveSession.state != .diving)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.diveSession.state == .diving)

                    Spacer()
                }
                .onTapGesture(count: 3) {
                    showDebugButton.toggle()
                }

                if showDebugPanel {
                    StatusPanel(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            // Dive complete overlay — always in the tree, manages its own visibility
            DiveCompleteOverlayView(
                stats: $viewModel.diveCompleteStats,
                onDismiss: {
                    viewModel.dismissDiveComplete()
                },
                onOpenSkillTree: {
                    hubInitialTab = .skills
                    showHub = true
                }
            )

            // Rescue overlay — always in the tree, manages its own visibility
            RescueOverlayView(
                rescueInfo: $viewModel.rescueInfo,
                onResetPosition: {
                    viewModel.resetToSurface()
                }
            )
        }
        .clipped()
        .ignoresSafeArea()
        .onAppear {
            viewModel.startSimulation()
            frameDriver.start(viewModel: viewModel)
        }
        .onDisappear {
            viewModel.stopSimulation()
            frameDriver.stop()
        }
        .sheet(isPresented: $showHub, onDismiss: {
            viewModel.recomputeParameters()
        }) {
            HubView(profileStore: profileStore, discoveredItems: viewModel.discoveredItemNames, initialTab: hubInitialTab)
        }
    }
}

#Preview {
    LevelView(profileStore: ProfileStore())
}
