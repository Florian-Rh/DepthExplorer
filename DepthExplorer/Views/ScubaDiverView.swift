//
//  ScubaDiverView.swift
//  DepthExplorer
//
//  Created by Florian Rhein on 04.07.25.
//

import SwiftUI

struct ScubaDiverView: View {
    enum Orientation {
        case upwards
        case downwards
        case swimmingLeft
        case swimmingRight

        var angle: Double {
            switch self {
                case .upwards:
                    0.0
                case .downwards:
                    .pi
                case .swimmingLeft:
                    .pi * 1.5
                case .swimmingRight:
                    .pi * 0.5
            }
        }
    }


    @State private var finStroke: CGFloat = 0.0
    let orientation: Orientation

    var body: some View {
        ScubaDiverShape(finStroke: finStroke)
            .stroke(lineWidth: 3)
            .rotation(.radians(self.orientation.angle))
            .animation(.linear, value: orientation)
            .onAppear(perform: startFinStrokeAnimation)
            .onChange(of: orientation, resetAndRestartFinStrokeAnimation)
    }

    private func startFinStrokeAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            finStroke = 1.0
        }
    }

    private func resetAndRestartFinStrokeAnimation() {
        finStroke = 0.0
        DispatchQueue.main.async {
            startFinStrokeAnimation()
        }
    }
}

#Preview {
    @Previewable @State var orientation = ScubaDiverView.Orientation.upwards

    VStack {
        ScubaDiverView(orientation: orientation)
        Button("Flip") {
            orientation = .downwards
        }
    }
}
