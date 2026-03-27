#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
import QuartzCore

/// Drives per-frame updates via `CADisplayLink`: diver smoothing and scroll offset.
/// Owns the display link lifecycle and reads joystick state from the view model.
class FrameUpdateDriver {
    private var displayLink: CADisplayLink?
    private weak var viewModel: LevelViewModel?

    func start(viewModel: LevelViewModel) {
        self.viewModel = viewModel
        #if os(macOS)
        guard let link = NSScreen.main?.displayLink(target: self, selector: #selector(tick)) else { return }
        #else
        let link = CADisplayLink(target: self, selector: #selector(tick))
        #endif
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
