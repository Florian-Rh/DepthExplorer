import QuartzCore

/// Drives per-frame updates via `CADisplayLink`: diver smoothing and scroll offset.
/// Owns the display link lifecycle and reads joystick state from the view model.
class FrameUpdateDriver {
    private var displayLink: CADisplayLink?
    private weak var viewModel: LevelViewModel?

    func start(viewModel: LevelViewModel) {
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

        vm.update()

        let vertical = vm.diverController.joystickVertical

        // Auto-surface when ascending near the surface
        if vm.currentDepth < vm.level.autoSurfaceDepth && vm.currentDepth > 0 && vertical <= 0 {
            vm.contentOffset = max(0, vm.contentOffset - vm.level.autoSurfaceSpeed)
            return
        }

        guard abs(vertical) > GameConstants.joystickDeadzone else { return }

        let delta = vertical * GameConstants.scrollSpeed
        let newOffset = max(0, min(vm.contentOffset + delta, vm.maximumDepthInPixels))
        vm.contentOffset = newOffset
    }
}
