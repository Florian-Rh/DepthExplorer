import SwiftUI

/// High-performance particle system for ocean zone effects.
/// Uses `TimelineView` + `Canvas` to animate many particles without
/// creating individual SwiftUI views. Particles are spawned relative to
/// the visible viewport and recycled as they drift out of view.
///
/// Particle state lives in a reference-type `ParticleState` so that the
/// `Canvas` draw closure can read and advance the simulation without
/// mutating `@State` during a view update.
struct OceanParticleView: View {
    let config: ParticleConfig
    let zoneHeight: CGFloat
    /// The visible vertical range within this zone (in zone-local coordinates).
    /// When nil the zone is off-screen and the particle system pauses.
    let visibleRange: ClosedRange<CGFloat>?
    /// Seed for deterministic initial placement.
    let seed: Int

    @State private var state = ParticleState()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                state.advance(to: timeline.date, config: config, zoneHeight: zoneHeight, canvasSize: size)
                if let visibleRange {
                    state.draw(into: &context, config: config, visibleRange: visibleRange, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            state.initialize(config: config, zoneHeight: zoneHeight, seed: seed)
        }
    }
}

// MARK: - Particle State (Reference Type)

/// Holds mutable particle data in a class so `Canvas` can update it
/// without triggering a SwiftUI state write during rendering.
private final class ParticleState {
    var particles: [Particle] = []
    var lastUpdate: Date?
    var isInitialized = false

    func initialize(config: ParticleConfig, zoneHeight: CGFloat, seed: Int) {
        guard !isInitialized else { return }
        isInitialized = true

        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        let count = config.density
        guard zoneHeight > 0 else { return }

        for i in 0..<count {
            particles.append(Particle(
                id: i,
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...zoneHeight, using: &rng),
                size: CGFloat.random(in: config.sizeRange, using: &rng),
                opacity: Double.random(in: 0.4...1.0, using: &rng),
                phaseOffset: Double.random(in: 0...(.pi * 2), using: &rng),
                horizontalDrift: CGFloat.random(in: -5...5, using: &rng)
            ))
        }
    }

    func advance(to now: Date, config: ParticleConfig, zoneHeight: CGFloat, canvasSize size: CGSize) {
        guard let last = lastUpdate else {
            lastUpdate = now
            return
        }
        let dt = now.timeIntervalSince(last)
        guard dt > 0 && dt < 1 else {
            lastUpdate = now
            return
        }
        lastUpdate = now

        let verticalDelta = CGFloat(config.speed * dt)

        for i in particles.indices {
            particles[i].y += verticalDelta
            particles[i].x += particles[i].horizontalDrift * CGFloat(dt) / max(size.width, 1)

            // Wrap x to stay in [0, 1]
            if particles[i].x < 0 { particles[i].x += 1 }
            if particles[i].x > 1 { particles[i].x -= 1 }

            // Wrap y within the zone (particles leaving one end re-enter from the other)
            if particles[i].y < 0 {
                particles[i].y += zoneHeight
            } else if particles[i].y > zoneHeight {
                particles[i].y -= zoneHeight
            }
        }
    }

    func draw(into context: inout GraphicsContext, config: ParticleConfig, visibleRange: ClosedRange<CGFloat>, time: Double) {
        let canvasWidth = context.clipBoundingRect.width

        for particle in particles {
            guard particle.y >= visibleRange.lowerBound - 20 &&
                  particle.y <= visibleRange.upperBound + 20 else { continue }

            var opacity = particle.opacity
            if config.pulses {
                let pulse = sin(time * 2.0 + particle.phaseOffset)
                opacity *= 0.3 + 0.7 * ((pulse + 1) / 2)
            }

            let rect = CGRect(
                x: particle.x * canvasWidth - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )

            switch config.type {
            case .bubble:
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(config.color.opacity(opacity * 0.8)),
                    lineWidth: 0.8
                )
                let highlightSize = particle.size * 0.3
                let highlightRect = CGRect(
                    x: rect.midX - highlightSize / 2 - particle.size * 0.15,
                    y: rect.midY - highlightSize / 2 - particle.size * 0.15,
                    width: highlightSize,
                    height: highlightSize
                )
                context.fill(
                    Path(ellipseIn: highlightRect),
                    with: .color(.white.opacity(opacity * 0.6))
                )

            case .bioluminescent:
                let haloRect = rect.insetBy(dx: -particle.size, dy: -particle.size)
                context.fill(
                    Path(ellipseIn: haloRect),
                    with: .color(config.color.opacity(opacity * 0.15))
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(config.color.opacity(opacity))
                )

            case .plankton, .marineSnow:
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(config.color.opacity(opacity))
                )
            }
        }
    }
}

// MARK: - Particle Model

private struct Particle {
    let id: Int
    var x: CGFloat          // Normalized 0...1 across zone width
    var y: CGFloat          // Zone-local y coordinate in points
    var size: CGFloat
    var opacity: Double
    let phaseOffset: Double // For pulsing effects
    var horizontalDrift: CGFloat // Points per second
}
