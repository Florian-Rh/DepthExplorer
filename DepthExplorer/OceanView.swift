//
//  OceanView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 03.07.25.
//
import SwiftUI
import OpenSeasUI

struct OceanView: View {
    static let viewId = "oceanView"

    let depthInPixels: Double

    var body: some View {
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
            .frame(height: UIScreen.main.bounds.height)
            Rectangle()
                .frame(height: depthInPixels)
                .foregroundStyle(
                    LinearGradient(
                        gradient: .deepOceanGradient,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
        }
        .id(Self.viewId)
    }
}
