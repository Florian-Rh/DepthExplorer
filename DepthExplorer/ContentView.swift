//
//  ContentView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 11.06.25.
//

import OpenSeasUI
import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    init() {
        UIScrollView.appearance().bounces = false
    }

    var body: some View {
        ScrollViewReader { scrollViewReader in
            ZStack {
                LinearGradient(
                    gradient: .coralSunsetGradient,
                    startPoint: .bottom,
                    endPoint: .top
                )

                ScrollView {
                    ZStack {
                        OceanView(depthInPixels: viewModel.maximumDepthInPixels)

                        ForEach(
                            Array(Item.allItems.enumerated()),
                            id: \.element.id
                        ) { index, item in
                            ItemView(
                                item: item,
                                isLeftSide: index.isMultiple(of: 2),
                                scalingFactor: viewModel.scalingFactor
                            )
                            .offset(y: 50)
                        }
                        .offset(y: UIScreen.main.bounds.height / 3)

                        DepthScale(
                            maximumDepth: viewModel.maximumDepth,
                            factor: viewModel.scalingFactor
                        )
                        .offset(y: UIScreen.main.bounds.height / 3 + 15)
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("scroll"))
                                        .origin
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    viewModel.updateScrollPosition(value)
                }

                // Scroll position label
                VStack {
                    Spacer()
                    StatusPanel(
                        currentDepth: .constant(viewModel.currentDepth),
                        currentPressure: .constant(viewModel.currentPressure),
                        selectedMixture: $viewModel.selectedMixture,
                        availableMixtures: viewModel.availableMixtures,
                        timerActive: $viewModel.timerActive,
                        diveStart: $viewModel.diveStart,
                        timeAtCurrentDepth: $viewModel.timeAtCurrentDepth,
                        tissue: $viewModel.tissue,
                        timeScale: viewModel.timeScale
                    )
                }
                .padding(16)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startDiveSimulation()
        }
        .onDisappear {
            viewModel.stopDiveSimulation()
        }
    }

    func scrollPositionForDepth(_ depth: Double) -> Double {
        let depthInPixels = depth * viewModel.scalingFactor
        return depthInPixels / viewModel.maximumDepthInPixels
    }
}

#Preview {
    ContentView()
}
