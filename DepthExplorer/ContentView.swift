//
//  ContentView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 11.06.25.
//

import SwiftUI
import OpenSeasUI

struct ContentView: View {

    @State private var verticalOffset: CGFloat = 1

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

            ScrollView {
                WaveView(
                    amplitude: 10,
                    waveLength: 0.5,
                    waterLevel: 0.90
                )
                .frame(height: 5000)
                .foregroundStyle(
                    LinearGradient(
                        gradient: .deepOceanGradient,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .overlay {
                    ForEach(Item.allItems) { item in
                        Image(systemName: item.image)
                            .position(x: 120, y: item.depth * 4 + 500)
                            .foregroundStyle(.white)
                            .onTapGesture {
                                print("\(item.name) streicheln")
                            }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
