import OpenSeasUI
import SwiftUI

struct LevelView: View {
    @ObservedObject var profileStore: ProfileStore
    @StateObject var viewModel: LevelViewModel
    @State private var frameDriver = FrameUpdateDriver()
    @State private var showDebugPanel = false

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
                        KnowledgeableItemView(
                            item: item,
                            isLeftSide: index.isMultiple(of: 2),
                            scalingFactor: viewModel.scalingFactor,
                            contentOffset: viewModel.contentOffset,
                            screenSize: screenSize,
                            isDiscovered: viewModel.discoveredItemNames.contains(item.name)
                        )
                        .offset(y: 50)
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

            ScubaDiverView(tilt: viewModel.diverController.tilt, submersed: viewModel.currentDepth > 0)
                .scaleEffect(0.6)
                .position(
                    x: viewModel.screenSize.width / 2 + viewModel.diverController.x,
                    y: viewModel.screenSize.height / 3 + 30 + viewModel.diverController.offset.height
                )

            VStack {
                Spacer()
                DiveHUDView(
                    depth: viewModel.currentDepth,
                    diveTimeSeconds: viewModel.diveTimeSeconds,
                    remainingBar: viewModel.diveSimulation.airSupply.remainingBar,
                    tankCapacity: GameConstants.tankCapacity,
                    ascentSpeed: viewModel.diveSimulation.ascentSpeed,
                    bodyTemperature: viewModel.diveSimulation.thermalModel.bodyTemperature,
                    warnings: viewModel.warningSystem.activeWarnings,
                    isDiving: viewModel.diveSession.state == .diving,
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
                    Spacer()
                }

                if showDebugPanel {
                    StatusPanel(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
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
    }
}

#Preview {
    LevelView(profileStore: ProfileStore())
}
