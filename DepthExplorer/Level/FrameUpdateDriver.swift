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
        viewModel?.update()
    }
}
