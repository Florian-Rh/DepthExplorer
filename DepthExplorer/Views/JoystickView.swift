import SwiftUI

struct JoystickView: View {
    @State private var dragOffset: CGSize = .zero

    /// Called continuously with the joystick's offset (clamped to the radius)
    /// and the angle in degrees (0° = up, 90° = right, 180° = down, 270° = left).
    /// When the joystick is released, offset is .zero and angle is nil.
    var onChanged: (_ offset: CGSize, _ angleDegrees: Double?) -> Void

    private let radius: CGFloat = 50
    private let knobRadius: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )

            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.3))
                )
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let clamped = clampToRadius(value.translation)
                            dragOffset = clamped
                            let angle = angleDegrees(from: clamped)
                            onChanged(clamped, angle)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dragOffset = .zero
                            }
                            onChanged(.zero, nil)
                        }
                )
        }
        .frame(width: radius * 2 + 20, height: radius * 2 + 20)
    }

    private func clampToRadius(_ translation: CGSize) -> CGSize {
        let dx = translation.width
        let dy = translation.height
        let distance = sqrt(dx * dx + dy * dy)
        if distance <= radius {
            return translation
        }
        let scale = radius / distance
        return CGSize(width: dx * scale, height: dy * scale)
    }

    private func angleDegrees(from offset: CGSize) -> Double? {
        let dx = offset.width
        let dy = offset.height
        guard abs(dx) > 1 || abs(dy) > 1 else { return nil }
        let radians = atan2(dy, dx)
        var degrees = radians * 180.0 / .pi + 180.0
        degrees = degrees.truncatingRemainder(dividingBy: 360.0)
        if degrees < 0 { degrees += 360 }
        return degrees
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
        JoystickView { _, _ in }
    }
}
