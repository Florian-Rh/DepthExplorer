import Foundation
import SwiftUI

/// Manages diver position, tilt, and smoothing based on joystick input.
/// Updated every display frame by the scroll driver.
class DiverController: ObservableObject {
    // Smoothed diver state (displayed values, lerped toward targets each frame)
    @Published private(set) var offset: CGSize = .zero
    @Published private(set) var tilt: Double = 90.0
    @Published private(set) var x: CGFloat = 0

    // Raw joystick targets (set by JoystickView callback)
    var offsetTarget: CGSize = .zero
    var tiltTarget: Double = 90.0

    /// Normalized joystick components: -1..+1
    var joystickVertical: CGFloat = 0
    var joystickHorizontal: CGFloat = 0

    private var lastJoystickWasRight: Bool = true

    /// Called every display frame to smoothly interpolate diver state toward targets.
    /// - Parameters:
    ///   - contentOffset: The current scroll offset in pixels (needed to clamp vertical position)
    ///   - currentDepth: The current depth in meters (needed for surface behavior)
    ///   - screenWidth: The available screen width (needed for horizontal clamping)
    func updateSmoothing(contentOffset: CGFloat, currentDepth: Int, screenWidth: CGFloat) {
        let smoothing: CGFloat = 0.96 // 0 = instant, 1 = no movement

        let atSurface = currentDepth == 0
        let maxX = screenWidth / 2 - 30

        let joystickReleased = abs(joystickHorizontal) <= 0.05 && abs(joystickVertical) <= 0.05

        if abs(joystickHorizontal) > 0.1 {
            lastJoystickWasRight = joystickHorizontal > 0
        }

        if atSurface || joystickReleased {
            x += (0 - x) * (1 - smoothing)
        } else {
            let hSpeed: CGFloat = 4.0
            x += joystickHorizontal * hSpeed
            x = max(-maxX, min(x, maxX))
        }

        // Vertical offset: smoothly lerp toward target, clamped to not rise above surface
        let clampedY = max(offsetTarget.height, -contentOffset)
        offset.height += (clampedY - offset.height) * (1 - smoothing)

        // Tilt: lerp using shortest angular path
        let targetTilt: Double
        if atSurface {
            targetTilt = 90.0
        } else if joystickReleased {
            targetTilt = lastJoystickWasRight ? 180.0 : 0.0
        } else {
            targetTilt = tiltTarget
        }
        var delta = targetTilt - tilt
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        tilt += delta * (1 - smoothing)

        tilt = tilt.truncatingRemainder(dividingBy: 360)
        if tilt < 0 { tilt += 360 }
    }
}
