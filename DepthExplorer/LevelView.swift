import OpenSeasUI
import SwiftUI

struct LevelView: View {
    @StateObject var viewModel = LevelViewModel()
    @State private var scrollDriver = JoystickScrollDriver()

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: .coralSunsetGradient,
                startPoint: .bottom,
                endPoint: .top
            )

            GeometryReader { geo in
                ZStack {
                    OceanView(depthInPixels: viewModel.maximumDepthInPixels)

                    ForEach(
                        Array(KnowledgeableItem.allItems.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        KnowledgeableItemView(
                            item: item,
                            isLeftSide: index.isMultiple(of: 2),
                            scalingFactor: viewModel.scalingFactor,
                            contentOffset: viewModel.contentOffset
                        )
                        .offset(y: 50)
                    }
                    .offset(y: geo.size.height / 3)

                    DepthScale(
                        maximumDepth: GameConstants.maximumDepth,
                        factor: viewModel.scalingFactor
                    )
                    .offset(y: geo.size.height / 3 + 15)
                }
                .offset(y: -viewModel.contentOffset)
            }
            .clipped()

            ScubaDiverView(tilt: viewModel.diverController.tilt, submersed: viewModel.currentDepth > 0)
                .scaleEffect(0.6)
                .position(
                    x: UIScreen.main.bounds.width / 2 + viewModel.diverController.x,
                    y: UIScreen.main.bounds.height / 3 + 30 + viewModel.diverController.offset.height
                )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    JoystickView { offset, angle in
                        viewModel.diverController.offsetTarget = offset
                        if let angle {
                            viewModel.diverController.tiltTarget = angle
                        }
                        viewModel.diverController.joystickVertical = offset.height / 50.0
                        viewModel.diverController.joystickHorizontal = offset.width / 50.0
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 40)
            }

//            StatusPanel(viewModel: viewModel)
        }
        .clipped()
        .ignoresSafeArea()
        .onAppear {
            viewModel.startSimulation()
            scrollDriver.start(viewModel: viewModel)
        }
        .onDisappear {
            viewModel.stopSimulation()
            scrollDriver.stop()
        }
    }
}

/// Drives `contentOffset` on every display frame based on the joystick's vertical component.
private class JoystickScrollDriver {
    private var displayLink: CADisplayLink?
    private weak var viewModel: LevelViewModel?

    func start(viewModel: LevelViewModel) {
        self.viewModel = viewModel
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        guard let vm = viewModel else { return }

        let screenWidth = UIScreen.main.bounds.width
        vm.update(screenWidth: screenWidth)

        let vertical = vm.diverController.joystickVertical

        // Auto-surface when ascending near the surface
        if vm.currentDepth < vm.level.autoSurfaceDepth && vm.currentDepth > 0 && vertical <= 0 {
            vm.contentOffset = max(0, vm.contentOffset - vm.level.autoSurfaceSpeed)
            return
        }

        guard abs(vertical) > GameConstants.joystickDeadzone else { return }

        let delta = vertical * GameConstants.scrollSpeed
        let newOffset = max(0, min(vm.contentOffset + delta, vm.maximumDepthInPixels))
        vm.contentOffset = newOffset
    }
}

#Preview {
    LevelView()
}
