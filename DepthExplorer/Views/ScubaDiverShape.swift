import SwiftUI

struct ScubaDiverShape: Shape {
    /// Animation value for the fin stroke (0.0 = legs together, 1.0 = legs apart)
    var finStroke: CGFloat
    
    var animatableData: CGFloat {
        get { finStroke }
        set { finStroke = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let headRadius = rect.height * 0.08
        let bodyLength = rect.height * 0.28
        let bodyTop = rect.midY - bodyLength * 0.5
        let bodyBottom = rect.midY + bodyLength * 0.5
        let armLength = rect.height * 0.18
        let legLength = rect.height * 0.22
        let tankWidth = rect.width * 0.08
        let tankHeight = rect.height * 0.22
        let tankOffset = rect.width * 0.06
        let finLength = rect.height * 0.10
        let finSpread = finStroke * rect.width * 0.10
        // Head
        path.addEllipse(in: CGRect(x: centerX - headRadius, y: bodyTop - headRadius * 2, width: headRadius * 2, height: headRadius * 2))
        // Mask
        let maskWidth = headRadius * 1.6
        let maskHeight = headRadius * 0.7
        path.addRoundedRect(in: CGRect(x: centerX - maskWidth/2, y: bodyTop - headRadius * 1.7, width: maskWidth, height: maskHeight), cornerSize: CGSize(width: maskHeight/2, height: maskHeight/2))
        // Snorkel
        path.move(to: CGPoint(x: centerX + maskWidth/2, y: bodyTop - headRadius * 1.7 + maskHeight/2))
        path.addLine(to: CGPoint(x: centerX + maskWidth/2 + headRadius * 0.5, y: bodyTop - headRadius * 2.2))
        // Body (torso)
        path.move(to: CGPoint(x: centerX, y: bodyTop))
        path.addLine(to: CGPoint(x: centerX, y: bodyBottom))
        // BCD vest (shoulders)
        let vestWidth = headRadius * 2.2
//        path.addArc(center: CGPoint(x: centerX, y: bodyTop + headRadius * 0.7), radius: vestWidth/2, startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: false)
        // Weight belt
//        let beltY = bodyBottom - headRadius * 0.7
//        path.move(to: CGPoint(x: centerX - vestWidth/2, y: beltY))
//        path.addLine(to: CGPoint(x: centerX + vestWidth/2, y: beltY))
        // Tank (behind body)
        path.addRoundedRect(in: CGRect(x: centerX - tankWidth/2 - tankOffset, y: bodyTop + headRadius, width: tankWidth, height: tankHeight), cornerSize: CGSize(width: tankWidth/2, height: tankWidth/2))
        // Left Arm (with elbow)
        let leftShoulder = CGPoint(x: centerX - vestWidth/2, y: bodyTop + headRadius * 0.7)
        let leftElbow = CGPoint(x: leftShoulder.x - armLength * 0.4, y: leftShoulder.y + armLength * 0.6)
        let leftHand = CGPoint(x: leftElbow.x - armLength * 0.4, y: leftElbow.y + armLength * 0.5)
        path.move(to: leftShoulder)
        path.addLine(to: leftElbow)
        path.addLine(to: leftHand)
        // Right Arm (with elbow)
        let rightShoulder = CGPoint(x: centerX + vestWidth/2, y: bodyTop + headRadius * 0.7)
        let rightElbow = CGPoint(x: rightShoulder.x + armLength * 0.4, y: rightShoulder.y + armLength * 0.6)
        let rightHand = CGPoint(x: rightElbow.x + armLength * 0.4, y: rightElbow.y + armLength * 0.5)
        path.move(to: rightShoulder)
        path.addLine(to: rightElbow)
        path.addLine(to: rightHand)
        // Left Leg (animated, with knee)
        let leftHip = CGPoint(x: centerX - headRadius * 0.5, y: bodyBottom)
        let leftKneeAngle = CGFloat.pi / 4 + finStroke * CGFloat.pi / 8
        let leftKnee = CGPoint(
            x: leftHip.x - sin(leftKneeAngle) * legLength * 0.5,
            y: leftHip.y + cos(leftKneeAngle) * legLength * 0.5
        )
        let leftAnkle = CGPoint(
            x: leftKnee.x - sin(leftKneeAngle) * legLength * 0.5,
            y: leftKnee.y + cos(leftKneeAngle) * legLength * 0.5
        )
        path.move(to: leftHip)
        path.addLine(to: leftKnee)
        path.addLine(to: leftAnkle)
        // Left Fin
        path.move(to: leftAnkle)
        path.addLine(to: CGPoint(x: leftAnkle.x - finLength * 0.7, y: leftAnkle.y + finLength * 1.2 + finSpread))
        // Right Leg (animated, with knee)
        let rightHip = CGPoint(x: centerX + headRadius * 0.5, y: bodyBottom)
        let rightKneeAngle = -CGFloat.pi / 4 - finStroke * CGFloat.pi / 8
        let rightKnee = CGPoint(
            x: rightHip.x - sin(rightKneeAngle) * legLength * 0.5,
            y: rightHip.y + cos(rightKneeAngle) * legLength * 0.5
        )
        let rightAnkle = CGPoint(
            x: rightKnee.x - sin(rightKneeAngle) * legLength * 0.5,
            y: rightKnee.y + cos(rightKneeAngle) * legLength * 0.5
        )
        path.move(to: rightHip)
        path.addLine(to: rightKnee)
        path.addLine(to: rightAnkle)
        // Right Fin
        path.move(to: rightAnkle)
        path.addLine(to: CGPoint(x: rightAnkle.x - finLength * 0.7, y: rightAnkle.y + finLength * 1.2 + finSpread))
        // Regulator hose (simple arc)
        path.move(to: CGPoint(x: centerX, y: bodyTop - headRadius * 0.5))
        path.addCurve(to: CGPoint(x: centerX - tankOffset, y: bodyTop + headRadius * 1.2), control1: CGPoint(x: centerX - headRadius * 1.5, y: bodyTop), control2: CGPoint(x: centerX - tankOffset, y: bodyTop + headRadius * 0.7))
        return path
    }
}

private struct ScubaDiverShapeAnimatedPreview: View {
    @State private var finStroke: CGFloat = 0.0
    var body: some View {
        ScubaDiverShape(finStroke: finStroke)
            .stroke(lineWidth: 3)
            .frame(width: 200, height: 400)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    finStroke = 1.0
                }
            }
    }
}

#Preview("Animated") {
    ScubaDiverShapeAnimatedPreview()
}
