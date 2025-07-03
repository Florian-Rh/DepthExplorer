//
//  ContentView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 11.06.25.
//

import SwiftUI
import OpenSeasUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}

struct ContentView: View {
    @State private var visibleItems: Set<String> = []
    @State private var scrollPosition: CGFloat = 0
    let maximumDepth = 11500.0
    let scalingFactor = 10.0

    private var depthInPixel: Double {
        self.maximumDepth * self.scalingFactor
    }

    private var currentDepth: Int {
        Int(abs(scrollPosition) / scalingFactor)
    }
    
    private var currentPressure: Double {
        // Pressure increases by 1 atm (101.325 kPa) per 10 meters
        let depthInMeters = Double(currentDepth)
        let pressureInAtm = 1.0 + (depthInMeters / 10.0)
        return pressureInAtm
    }

    init() {
        UIScrollView.appearance().bounces = false
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: .coralSunsetGradient,
                startPoint: .bottom,
                endPoint: .top
            )

            GeometryReader { geometry in
                ScrollView {
                    ZStack {
                        VStack(spacing: 0) {
                            ZStack {
                                WaveView(
                                    amplitude: 20,
                                    waveLength: 0.5,
                                    animationBehaviour: .backAndForth(duration: 3.0, distance: 1),
                                    startPhase: 1.0
                                )
                                .foregroundStyle(.oceanBlue)
                                WaveView(
                                    amplitude: 15,
                                    waveLength: 0.5,
                                    animationBehaviour: .backAndForth(duration: 5.0, distance: 1),
                                    rotation: .pi * 0
                                )
                                .foregroundStyle(.waveBlue)
                            }
                            .frame(height: geometry.size.height)
                            Rectangle()
                                .frame(height: depthInPixel)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: .deepOceanGradient,
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                        }

                        ForEach(Array(Item.allItems.enumerated()), id: \.element.id) { index, item in
                            ItemView(
                                item: item,
                                isLeftSide: index.isMultiple(of: 2),
                                scalingFactor: self.scalingFactor
                            )
                            .offset(y: 50)
                        }
                        .offset(y: geometry.size.height / 2)

                        DepthScale(maximumDepth: maximumDepth, factor: self.scalingFactor)
                            .offset(y: geometry.size.height / 2 + 15)
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("scroll")).origin
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollPosition = value.y
                }
            }

            // Scroll position label
            VStack {
                VStack(spacing: 4) {
                    Text("Depth: \(currentDepth)m")
                    Text("Pressure: \(String(format: "%.1f", currentPressure)) atm")
                }
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, 50)
                Spacer()
            }
            .padding(16)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
