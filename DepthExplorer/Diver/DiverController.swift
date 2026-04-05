import Foundation
import SwiftUI

/// Manages diver position, tilt, and smoothing based on joystick input.
/// Updated every display frame by the scroll driver.
class DiverController: ObservableObject {
    @Published private(set) var offset: CGSize = .zero
    @Published private(set) var tilt: Double = 90.0
    @Published private(set) var x: CGFloat = 0

    var offsetTarget: CGSize = .zero
    var tiltTarget: Double = 90.0
    var joystickVertical: CGFloat = 0
    var joystickHorizontal: CGFloat = 0

    /// Reset all state to initial values (surface position).
    func reset() {
        offset = .zero
        tilt = 90.0
        x = 0
        offsetTarget = .zero
        tiltTarget = 90.0
        joystickVertical = 0
        joystickHorizontal = 0
        lastJoystickWasRight = true
    }

    private var lastJoystickWasRight: Bool = true

    /// Called every display frame to smoothly interpolate diver state toward targets.
    func updateSmoothing(contentOffset: CGFloat, currentDepth: Int, screenWidth: CGFloat, horizontalSpeed: CGFloat = GameConstants.diverHorizontalSpeed) {
        let smoothing = GameConstants.diverSmoothing
        let atSurface = currentDepth == 0
        let maxX = screenWidth / 2 - GameConstants.diverEdgeMargin

        let joystickReleased = abs(joystickHorizontal) <= GameConstants.joystickDeadzone
                            && abs(joystickVertical) <= GameConstants.joystickDeadzone

        if abs(joystickHorizontal) > GameConstants.joystickDirectionThreshold {
            lastJoystickWasRight = joystickHorizontal > 0
        }

        if atSurface {
            x += (0 - x) * (1 - smoothing)
        } else if !joystickReleased {
            x += joystickHorizontal * horizontalSpeed
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
