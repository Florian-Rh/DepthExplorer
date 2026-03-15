//
//  ContentView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 11.06.25.
//

import OpenSeasUI
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

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
                        Array(Item.allItems.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        ItemView(
                            item: item,
                            isLeftSide: index.isMultiple(of: 2),
                            scalingFactor: viewModel.scalingFactor,
                            contentOffset: viewModel.contentOffset
                        )
                        .offset(y: 50)
                    }
                    .offset(y: geo.size.height / 3)

                    DepthScale(
                        maximumDepth: viewModel.maximumDepth,
                        factor: viewModel.scalingFactor
                    )
                    .offset(y: geo.size.height / 3 + 15)
                }
                .offset(y: -viewModel.contentOffset)
            }
            .clipped()

            ScubaDiverView(tilt: viewModel.diverTilt, submersed: viewModel.currentDepth > 0)
                .scaleEffect(0.6)
                .position(
                    x: UIScreen.main.bounds.width / 2 + viewModel.diverOffset.width,
                    y: UIScreen.main.bounds.height / 3 + 30 + viewModel.diverOffset.height
                )

            // Joystick control
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    JoystickView { offset, angle in
                        viewModel.diverOffset = offset
                        if let angle {
                            viewModel.diverTilt = angle
                        }
                        viewModel.joystickVertical = offset.height / 50.0
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
            viewModel.startDiveSimulation()
            scrollDriver.start(viewModel: viewModel)
        }
        .onDisappear {
            viewModel.stopDiveSimulation()
            scrollDriver.stop()
        }
    }

    @State private var scrollDriver = JoystickScrollDriver()
}

/// Drives `contentOffset` on every display frame based on the joystick's vertical component.
private class JoystickScrollDriver {
    private var displayLink: CADisplayLink?
    private weak var viewModel: ContentViewModel?

    func start(viewModel: ContentViewModel) {
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

        let vertical = vm.joystickVertical

        // Snap to surface: when ascending and within threshold, auto-surface
        if vm.currentDepth < vm.autoSurfaceDepth && vm.currentDepth > 0 && vertical <= 0 {
            vm.contentOffset = max(0, vm.contentOffset - 4.0)
            return
        }

        guard abs(vertical) > 0.05 else { return }

        // Max speed: 8 pts per frame (~480 pts/sec at 60fps)
        let delta = vertical * 8.0
        let maxOffset = vm.maximumDepthInPixels
        let newOffset = max(0, min(vm.contentOffset + delta, maxOffset))
        vm.contentOffset = newOffset
    }
}

#Preview {
    ContentView()
}
