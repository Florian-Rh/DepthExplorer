import SwiftUI

/// Canvas-drawn static ambient decorations for a depth zone.
///
/// Each zone gets continuous rocky reef walls on both sides of the screen.
/// The wall profile is generated deterministically from a seed and remains
/// stable across frames. Decorative elements (corals, kelp, vents, etc.)
/// are attached to the wall surface.
///
/// The Canvas draws all elements regardless of scroll position — CoreGraphics
/// clips off-screen draws automatically. This keeps the Canvas inputs stable
/// so SwiftUI never invalidates or redraws it during scrolling.
struct AmbientElements: View {
    let config: AmbientConfig
    let zoneHeight: CGFloat
    /// Seed for deterministic placement.
    let seed: Int

    var body: some View {
        Canvas { context, size in
            var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))

            // Generate wall profiles for both sides (shared data for walls + decorations)
            let leftProfile = WallProfile.generate(
                config: config, zoneHeight: zoneHeight, screenWidth: size.width,
                isLeft: true, rng: &rng
            )
            let rightProfile = WallProfile.generate(
                config: config, zoneHeight: zoneHeight, screenWidth: size.width,
                isLeft: false, rng: &rng
            )

            // Draw reef walls
            drawWallProfile(leftProfile, context: &context)
            drawWallProfile(rightProfile, context: &context)

            // Draw zone-specific decorations attached to the walls
            let profiles = (left: leftProfile, right: rightProfile)
            switch config.type {
            case .coralReef:
                drawCoralDecorations(context: &context, size: size, profiles: profiles, rng: &rng)
            case .kelpAndRocks:
                drawKelpDecorations(context: &context, size: size, profiles: profiles, rng: &rng)
            case .bareRock:
                break // Walls alone are sufficient
            case .hydrothermalVents:
                drawVentDecorations(context: &context, size: size, profiles: profiles, rng: &rng)
            case .trenchWalls:
                break // Walls are already trench-like
            case .none:
                break
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Wall Profile

    /// Pre-computed wall shape for one side of the screen.
    /// Stores segment geometry so decorations can query actual wall width at any y.
    private struct WallProfile {
        struct Segment {
            let topY: CGFloat
            let bottomY: CGFloat
            /// Profile points from top to bottom, each storing the inward x coordinate.
            let profilePoints: [(x: CGFloat, y: CGFloat)]
            let isGap: Bool
            let brightness: Double
        }

        let segments: [Segment]
        let baseX: CGFloat
        let isLeft: Bool

        /// Returns surface information at the given y, or nil if y falls in a gap.
        func wallEdge(at y: CGFloat) -> CGPoint? {
            guard let seg = segments.first(where: { y >= $0.topY && y < $0.bottomY }) else {
                return nil
            }
            if seg.isGap { return nil }

            var allPoints: [(x: CGFloat, y: CGFloat)] = [(x: baseX, y: seg.topY)]
            allPoints.append(contentsOf: seg.profilePoints)
            allPoints.append((x: baseX, y: seg.bottomY))

            // Find the two points that bracket this y
            for i in 0..<(allPoints.count - 1) {
                let p0 = allPoints[i]
                let p1 = allPoints[i + 1]
                let minY = min(p0.y, p1.y)
                let maxY = max(p0.y, p1.y)
                if y >= minY && y <= maxY && maxY > minY {
                    let t = (y - p0.y) / (p1.y - p0.y)
                    let edgeX = p0.x + t * (p1.x - p0.x)

                    return CGPoint(x: edgeX, y: y)
                }
            }
            // Fallback
            if let nearest = seg.profilePoints.min(by: { abs($0.y - y) < abs($1.y - y) }) {
                return CGPoint(x: nearest.x, y: y)
            }
            return CGPoint(x: baseX, y: y)
        }

        static func generate(
            config: AmbientConfig,
            zoneHeight: CGFloat,
            screenWidth: CGFloat,
            isLeft: Bool,
            rng: inout SeededRNG
        ) -> WallProfile {
            guard config.type != .none else {
                return WallProfile(segments: [], baseX: isLeft ? 0 : screenWidth, isLeft: isLeft)
            }

            let segHeight = CGFloat.random(in: config.wallSegmentHeightRange, using: &rng)
            let segmentCount = max(1, Int(ceil(zoneHeight / segHeight)))
            let baseX: CGFloat = isLeft ? 0 : screenWidth
            let direction: CGFloat = isLeft ? 1 : -1

            var segments: [Segment] = []
            for i in 0..<segmentCount {
                let topY = CGFloat(i) * segHeight
                let bottomY = min(topY + segHeight, zoneHeight)
                let isGap = Double.random(in: 0...1, using: &rng) < config.gapProbability

                let pointCount = Int.random(in: 3...5, using: &rng)
                var points: [(x: CGFloat, y: CGFloat)] = []
                for j in 0..<pointCount {
                    let fraction = CGFloat(j + 1) / CGFloat(pointCount + 1)
                    let width = CGFloat.random(in: config.wallWidthRange, using: &rng)
                    let jitter = CGFloat.random(in: -5...5, using: &rng)
                    points.append((
                        x: baseX + direction * width,
                        y: topY + (bottomY - topY) * fraction + jitter
                    ))
                }

                let brightness = Double.random(in: config.wallBrightness, using: &rng)
                segments.append(Segment(
                    topY: topY, bottomY: bottomY,
                    profilePoints: points, isGap: isGap,
                    brightness: brightness
                ))
            }

            return WallProfile(segments: segments, baseX: baseX, isLeft: isLeft)
        }
    }

    // MARK: - Wall Drawing

    private func drawWallProfile(_ profile: WallProfile, context: inout GraphicsContext) {
        for seg in profile.segments {
            guard !seg.isGap else { continue }

            var wall = Path()
            wall.move(to: CGPoint(x: profile.baseX, y: seg.topY))
            for pt in seg.profilePoints {
                wall.addLine(to: CGPoint(x: pt.x, y: pt.y))
            }
            wall.addLine(to: CGPoint(x: profile.baseX, y: seg.bottomY))
            wall.closeSubpath()

            let color = Color(
                red: seg.brightness * 0.9,
                green: seg.brightness * 0.95,
                blue: seg.brightness * 1.1
            )
            context.fill(wall, with: .color(color.opacity(0.7)))

            // Subtle edge highlight
            var edge = Path()
            edge.move(to: CGPoint(x: profile.baseX, y: seg.topY))
            for pt in seg.profilePoints {
                edge.addLine(to: CGPoint(x: pt.x, y: pt.y))
            }
            edge.addLine(to: CGPoint(x: profile.baseX, y: seg.bottomY))
            context.stroke(edge, with: .color(color.opacity(0.3)), lineWidth: 1)
        }
    }

    // MARK: - Coral Decorations (Sunlight Zone)

    private func drawCoralDecorations(
        context: inout GraphicsContext,
        size: CGSize,
        profiles: (left: WallProfile, right: WallProfile),
        rng: inout SeededRNG
    ) {
        var elementCount = 0
        var failedAttempts = 0
        while elementCount < config.decorationCount && failedAttempts < 10 {
            let isLeft = Bool.random(using: &rng)
            // Consume RNG for position (keeps sequence stable regardless of wall shape)
            _ = CGFloat.random(in: config.wallWidthRange, using: &rng) // consumed for sequence stability
            let y = CGFloat.random(in: 0...zoneHeight, using: &rng)
            let kind = Int.random(in: 0...5, using: &rng)

            // Query the actual wall profile at this y
            let profile = isLeft ? profiles.left : profiles.right
            guard let wallEdge = profile.wallEdge(at: y) else {
                consumeRNG(forKind: kind, rng: &rng)
                failedAttempts += 1
                continue
            }
            failedAttempts = 0

            let inward: CGFloat = isLeft ? 1 : -1

            // Draw in a rotated coordinate space so the decoration grows
            // perpendicular to the rock surface. We translate to the attach
            // point, rotate by the surface angle, then draw at the origin.
            var offset = CGFloat.random(in: 10.0...15.0, using: &rng)
            if isLeft {
                offset *= -1
            }
            var ctx = context
            ctx.translateBy(x: wallEdge.x + offset, y: wallEdge.y)
            ctx.rotate(by: Angle(degrees: Double.random(in: -15...15, using: &rng)))

            let origin = CGPoint.zero

            switch kind {
            case 0:
                drawBranchingCoral(context: &ctx, at: origin, inward: inward, rng: &rng)
            case 1:
                drawSeaFan(context: &ctx, at: origin, inward: inward, rng: &rng)
            case 2:
                drawRoundCoral(context: &ctx, at: origin, rng: &rng)
            case 3:
                drawSeagrass(context: &ctx, at: origin, inward: inward, rng: &rng)
            case 4:
                drawStaghornCoral(context: &ctx, at: origin, inward: inward, rng: &rng)
            default:
                drawTubeSponge(context: &ctx, at: origin, inward: inward, rng: &rng)
            }
            elementCount += 1
        }
    }

    /// Consume the same number of RNG calls that a decoration draw would use,
    /// so that skipping invisible elements doesn't shift later positions.
    private func consumeRNG(forKind kind: Int, rng: inout SeededRNG) {
        switch kind {
        case 0: // branchingCoral
            for _ in 0..<27 { _ = rng.next() }
        case 1: // seaFan
            for _ in 0..<12 { _ = rng.next() }
        case 2: // roundCoral
            for _ in 0..<23 { _ = rng.next() }
        case 3: // seagrass
            for _ in 0..<16 { _ = rng.next() }
        case 4: // staghornCoral
            for _ in 0..<23 { _ = rng.next() }
        default: // tubeSponge
            for _ in 0..<18 { _ = rng.next() }
        }
    }

    // MARK: - Branching Coral

    private func drawBranchingCoral(context: inout GraphicsContext, at origin: CGPoint, inward: CGFloat, rng: inout SeededRNG) {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.4, blue: 0.3),
            Color(red: 0.9, green: 0.3, blue: 0.5),
            Color(red: 1.0, green: 0.6, blue: 0.2),
            Color(red: 0.8, green: 0.2, blue: 0.4),
            Color(red: 0.95, green: 0.5, blue: 0.6),
        ]
        let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        let height = CGFloat.random(in: 30...60, using: &rng)
        let branchCount = Int.random(in: 4...6, using: &rng)

        // Main trunk — slightly curved
        var trunk = Path()
        trunk.move(to: origin)
        let tipX = origin.x + inward * 6
        let tipY = origin.y - height
        let controlX = origin.x + inward * 3
        trunk.addQuadCurve(
            to: CGPoint(x: tipX, y: tipY),
            control: CGPoint(x: controlX, y: origin.y - height * 0.5)
        )
        context.stroke(trunk, with: .color(color), lineWidth: 3)

        for i in 0..<branchCount {
            let fraction = CGFloat(i + 1) / CGFloat(branchCount + 1)
            let branchOriginY = origin.y - height * fraction
            let branchOriginX = origin.x + inward * (6 * fraction)
            let branchLength = CGFloat.random(in: 10...25, using: &rng)
            let branchHeight = CGFloat.random(in: 5...15, using: &rng)

            let side: CGFloat = (i % 2 == 0) ? 1 : -0.6
            let endX = branchOriginX + inward * branchLength * side
            let endY = branchOriginY - branchHeight

            var branch = Path()
            branch.move(to: CGPoint(x: branchOriginX, y: branchOriginY))
            branch.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: CGPoint(x: (branchOriginX + endX) / 2, y: branchOriginY - branchHeight * 0.3)
            )
            context.stroke(branch, with: .color(color.opacity(0.85)), lineWidth: 2)

            let tipSpread = CGFloat.random(in: 3...8, using: &rng)
            let tipLen = CGFloat.random(in: 3...7, using: &rng)
            for offset in [-tipSpread * 0.5, tipSpread * 0.5] {
                var tip = Path()
                tip.move(to: CGPoint(x: endX, y: endY))
                tip.addLine(to: CGPoint(x: endX + offset, y: endY - tipLen))
                context.stroke(tip, with: .color(color.opacity(0.6)), lineWidth: 1.2)
            }
        }
    }

    // MARK: - Sea Fan

    private func drawSeaFan(context: inout GraphicsContext, at origin: CGPoint, inward: CGFloat, rng: inout SeededRNG) {
        let colors: [Color] = [
            Color(red: 0.6, green: 0.2, blue: 0.6),
            Color(red: 0.9, green: 0.5, blue: 0.3),
            Color(red: 0.8, green: 0.3, blue: 0.3),
            Color(red: 0.7, green: 0.25, blue: 0.5),
        ]
        let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        let width = CGFloat.random(in: 22...45, using: &rng)
        let height = CGFloat.random(in: 30...50, using: &rng)

        var stem = Path()
        stem.move(to: origin)
        let stemEnd = CGPoint(x: origin.x + inward * 12, y: origin.y - height * 0.3)
        stem.addLine(to: stemEnd)
        context.stroke(stem, with: .color(color.opacity(0.8)), lineWidth: 2.5)

        let fanCenterX = origin.x + inward * (12 + width * 0.3)
        let fanCenterY = origin.y - height * 0.65
        let fanRect = CGRect(
            x: fanCenterX - width / 2,
            y: fanCenterY - height * 0.35,
            width: width,
            height: height * 0.7
        )
        var fan = Path()
        fan.addEllipse(in: fanRect)
        context.fill(fan, with: .color(color.opacity(0.25)))
        context.stroke(fan, with: .color(color.opacity(0.5)), lineWidth: 1.2)

        let ribCount = Int.random(in: 4...7, using: &rng)
        for i in 0..<ribCount {
            let angle = -CGFloat.pi * 0.15 + CGFloat.pi * 0.6 * CGFloat(i) / CGFloat(max(1, ribCount - 1))
            let ribLen = min(width, height * 0.7) * 0.4
            var rib = Path()
            rib.move(to: CGPoint(x: fanCenterX, y: fanCenterY + height * 0.15))
            rib.addLine(to: CGPoint(
                x: fanCenterX + cos(angle) * ribLen * inward,
                y: fanCenterY + height * 0.15 - sin(angle) * ribLen
            ))
            context.stroke(rib, with: .color(color.opacity(0.2)), lineWidth: 0.7)
        }
    }

    // MARK: - Round / Brain Coral

    private func drawRoundCoral(context: inout GraphicsContext, at origin: CGPoint, rng: inout SeededRNG) {
        let colors: [Color] = [
            Color(red: 0.3, green: 0.7, blue: 0.4),
            Color(red: 0.4, green: 0.6, blue: 0.8),
            Color(red: 0.9, green: 0.8, blue: 0.3),
            Color(red: 0.7, green: 0.5, blue: 0.7),
        ]
        let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        let radius = CGFloat.random(in: 12...26, using: &rng)
        let blobCount = Int.random(in: 3...5, using: &rng)

        for _ in 0..<blobCount {
            let offsetX = CGFloat.random(in: -radius * 0.5...radius * 0.5, using: &rng)
            let offsetY = CGFloat.random(in: -radius * 0.5...0, using: &rng)
            let blobRadius = CGFloat.random(in: radius * 0.4...radius * 0.65, using: &rng)
            let blobRect = CGRect(
                x: origin.x + offsetX - blobRadius,
                y: origin.y + offsetY - blobRadius,
                width: blobRadius * 2,
                height: blobRadius * 2
            )
            var blob = Path()
            blob.addEllipse(in: blobRect)
            context.fill(blob, with: .color(color.opacity(0.35)))
            context.stroke(blob, with: .color(color.opacity(0.5)), lineWidth: 0.8)

            if blobRadius > radius * 0.45 {
                let textureCount = Int.random(in: 2...3, using: &rng)
                for t in 0..<textureCount {
                    let ty = blobRect.midY + CGFloat(t - 1) * blobRadius * 0.35
                    let waveAmp = CGFloat.random(in: 1...3, using: &rng)
                    var textureLine = Path()
                    textureLine.move(to: CGPoint(x: blobRect.minX + blobRadius * 0.3, y: ty))
                    textureLine.addQuadCurve(
                        to: CGPoint(x: blobRect.maxX - blobRadius * 0.3, y: ty),
                        control: CGPoint(x: blobRect.midX, y: ty - waveAmp)
                    )
                    context.stroke(textureLine, with: .color(color.opacity(0.2)), lineWidth: 0.5)
                }
            } else {
                _ = Int.random(in: 2...3, using: &rng)
                for _ in 0..<3 {
                    _ = CGFloat.random(in: 1...3, using: &rng)
                }
            }
        }
    }

    // MARK: - Seagrass

    private func drawSeagrass(context: inout GraphicsContext, at origin: CGPoint, inward: CGFloat, rng: inout SeededRNG) {
        let bladeCount = Int.random(in: 3...7, using: &rng)
        let color = Color(red: 0.2, green: CGFloat.random(in: 0.45...0.65, using: &rng), blue: 0.25)

        for i in 0..<bladeCount {
            let spread = CGFloat(i - bladeCount / 2) * 3
            let height = CGFloat.random(in: 25...60, using: &rng)
            let sway = CGFloat.random(in: 3...15, using: &rng) * inward

            var blade = Path()
            blade.move(to: CGPoint(x: origin.x + spread, y: origin.y))
            blade.addQuadCurve(
                to: CGPoint(x: origin.x + spread + sway, y: origin.y - height),
                control: CGPoint(x: origin.x + spread + sway * 0.6, y: origin.y - height * 0.5)
            )
            context.stroke(blade, with: .color(color.opacity(0.5)), lineWidth: 1.5)
        }
    }

    // MARK: - Staghorn Coral

    private func drawStaghornCoral(context: inout GraphicsContext, at origin: CGPoint, inward: CGFloat, rng: inout SeededRNG) {
        let colors: [Color] = [
            Color(red: 0.85, green: 0.75, blue: 0.55),
            Color(red: 0.6, green: 0.85, blue: 0.7),
            Color(red: 0.95, green: 0.85, blue: 0.6),
            Color(red: 0.75, green: 0.6, blue: 0.45),
        ]
        let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        let baseHeight = CGFloat.random(in: 20...40, using: &rng)
        let armCount = Int.random(in: 3...5, using: &rng)

        for i in 0..<armCount {
            let angle = CGFloat.random(in: -0.6...0.6, using: &rng)
            let armLength = CGFloat.random(in: baseHeight * 0.6...baseHeight * 1.2, using: &rng)
            let armEndX = origin.x + inward * (CGFloat(i + 1) * 6) + sin(angle) * armLength * 0.3
            let armEndY = origin.y - armLength

            var arm = Path()
            arm.move(to: CGPoint(x: origin.x + inward * CGFloat(i) * 3, y: origin.y))
            arm.addQuadCurve(
                to: CGPoint(x: armEndX, y: armEndY),
                control: CGPoint(x: (origin.x + armEndX) / 2, y: origin.y - armLength * 0.4)
            )
            context.stroke(arm, with: .color(color), lineWidth: 2.5)

            let forkLen = CGFloat.random(in: 5...12, using: &rng)
            let forkAngle = CGFloat.random(in: 0.3...0.8, using: &rng)
            for side in [-1.0, 1.0] as [CGFloat] {
                var fork = Path()
                fork.move(to: CGPoint(x: armEndX, y: armEndY))
                fork.addLine(to: CGPoint(
                    x: armEndX + side * sin(forkAngle) * forkLen,
                    y: armEndY - cos(forkAngle) * forkLen
                ))
                context.stroke(fork, with: .color(color.opacity(0.7)), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Tube Sponge

    private func drawTubeSponge(context: inout GraphicsContext, at origin: CGPoint, inward: CGFloat, rng: inout SeededRNG) {
        let colors: [Color] = [
            Color(red: 0.6, green: 0.3, blue: 0.7),
            Color(red: 0.85, green: 0.55, blue: 0.2),
            Color(red: 0.3, green: 0.55, blue: 0.7),
            Color(red: 0.7, green: 0.2, blue: 0.35),
        ]
        let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
        let tubeCount = Int.random(in: 2...4, using: &rng)

        let horizontalOffset = CGFloat(tubeCount * 5) * inward
        var origin = origin
        origin.x -= horizontalOffset

        for i in 0..<tubeCount {
            let tubeHeight = CGFloat.random(in: 18...40, using: &rng)
            let tubeWidth = CGFloat.random(in: 5...10, using: &rng)
            let lean = CGFloat.random(in: -4...4, using: &rng)
            let offsetX = CGFloat(i) * tubeWidth * 1.2 * inward

            let baseL = CGPoint(x: origin.x + offsetX - tubeWidth / 2, y: origin.y)
            let baseR = CGPoint(x: origin.x + offsetX + tubeWidth / 2, y: origin.y)
            let topL = CGPoint(x: baseL.x + lean, y: origin.y - tubeHeight)
            let topR = CGPoint(x: baseR.x + lean, y: origin.y - tubeHeight)

            var tube = Path()
            tube.move(to: baseL)
            tube.addLine(to: topL)
            tube.addLine(to: topR)
            tube.addLine(to: baseR)
            tube.closeSubpath()
            context.fill(tube, with: .color(color.opacity(0.35)))
            context.stroke(tube, with: .color(color.opacity(0.55)), lineWidth: 1)

            let rimExtra = CGFloat.random(in: 1...3, using: &rng)
            var rim = Path()
            rim.addEllipse(in: CGRect(
                x: topL.x - rimExtra,
                y: topL.y - tubeWidth * 0.3,
                width: tubeWidth + rimExtra * 2 + lean.magnitude,
                height: tubeWidth * 0.6
            ))
            context.fill(rim, with: .color(color.opacity(0.15)))
            context.stroke(rim, with: .color(color.opacity(0.4)), lineWidth: 0.8)
        }
    }

    // MARK: - Kelp Decorations (Twilight Zone)

    private func drawKelpDecorations(
        context: inout GraphicsContext,
        size: CGSize,
        profiles: (left: WallProfile, right: WallProfile),
        rng: inout SeededRNG
    ) {
        let kelpCount = config.decorationCount
        for _ in 0..<kelpCount {
            let isLeft = Bool.random(using: &rng)
            _ = CGFloat.random(in: config.wallWidthRange, using: &rng) // consumed for sequence stability
            let y = CGFloat.random(in: 0...zoneHeight, using: &rng)

            // RNG for the whole plant (consumed regardless of placement)
            let plantHeight = CGFloat.random(in: 120...250, using: &rng)
            let green = CGFloat.random(in: 0.25...0.45, using: &rng)
            let branchCount = Int.random(in: 2...4, using: &rng)

            // Per-branch data (always consumed for RNG stability)
            struct BranchData {
                let heightFraction: CGFloat  // fraction of plantHeight
                let xSpread: CGFloat         // horizontal offset from base
                let segmentCount: Int
                var swayValues: [CGFloat]
                var leafPositions: [(dx: CGFloat, side: CGFloat)] // leaf offsets
            }

            var branches: [BranchData] = []
            for b in 0..<branchCount {
                let heightFraction = CGFloat.random(in: 0.6...1.0, using: &rng)
                let xSpread = CGFloat.random(in: -8...8, using: &rng) + CGFloat(b - branchCount / 2) * 5
                let segCount = Int.random(in: 8...14, using: &rng)

                var sway: [CGFloat] = []
                for _ in 0..<segCount {
                    sway.append(CGFloat.random(in: -8...8, using: &rng))
                }

                var leaves: [(dx: CGFloat, side: CGFloat)] = []
                // Leaves every 2–3 segments, starting from segment 2
                for s in stride(from: 2, to: segCount, by: Int.random(in: 2...3, using: &rng)) {
                    let dx = CGFloat.random(in: 2...8, using: &rng)
                    let side: CGFloat = (s % 2 == 0) ? 1 : -1
                    leaves.append((dx: dx * side, side: side))
                    _ = s // use s to keep the compiler happy
                }

                branches.append(BranchData(
                    heightFraction: heightFraction,
                    xSpread: xSpread,
                    segmentCount: segCount,
                    swayValues: sway,
                    leafPositions: leaves
                ))
            }

            // Query wall profile for attachment point
            let profile = isLeft ? profiles.left : profiles.right
            guard let wallEdge = profile.wallEdge(at: y) else { continue }

            let baseX = wallEdge.x
            let baseY = wallEdge.y
            let baseColor = Color(red: 0.1, green: green, blue: 0.1)

            // Draw each branch — always grows vertically (no surface rotation)
            for branch in branches {
                let branchHeight = plantHeight * branch.heightFraction
                let segHeight = branchHeight / CGFloat(branch.segmentCount)
                let startX = baseX + branch.xSpread

                // Stipe (stem)
                var stipe = Path()
                stipe.move(to: CGPoint(x: startX, y: baseY))
                var prevX = startX
                for s in 0..<branch.segmentCount {
                    let sway = branch.swayValues[s]
                    prevX = startX + sway
                    stipe.addLine(to: CGPoint(
                        x: prevX,
                        y: baseY - segHeight * CGFloat(s + 1)
                    ))
                }
                // Thicker at base, thinner at top
                context.stroke(stipe, with: .color(baseColor.opacity(0.4)), lineWidth: 3)

                // Leaves — elongated blades attached at intervals
                var leafIdx = 0
                for s in stride(from: 2, to: branch.segmentCount, by: 2) {
                    guard leafIdx < branch.leafPositions.count else { break }
                    let leaf = branch.leafPositions[leafIdx]
                    leafIdx += 1

                    let attachY = baseY - segHeight * CGFloat(s)
                    let attachX = startX + branch.swayValues[min(s, branch.swayValues.count - 1)]

                    // Leaf blade — a curved quad from attachment point outward and slightly down
                    let leafLen = CGFloat.random(in: 15...30, using: &rng)
                    let leafDroop = CGFloat.random(in: 5...15, using: &rng)

                    var blade = Path()
                    blade.move(to: CGPoint(x: attachX, y: attachY))
                    blade.addQuadCurve(
                        to: CGPoint(x: attachX + leaf.dx * leafLen / 5, y: attachY + leafDroop),
                        control: CGPoint(x: attachX + leaf.dx * leafLen / 8, y: attachY - leafDroop * 0.2)
                    )
                    let leafColor = Color(red: 0.08, green: green + 0.05, blue: 0.08)
                    context.stroke(blade, with: .color(leafColor.opacity(0.35)), lineWidth: 2)

                    // Leaf fill — thin ellipse along the blade
                    var leafShape = Path()
                    leafShape.addEllipse(in: CGRect(
                        x: attachX + leaf.dx * leafLen / 12 - 2,
                        y: attachY - 2,
                        width: abs(leaf.dx) * leafLen / 4,
                        height: leafDroop + 4
                    ))
                    context.fill(leafShape, with: .color(leafColor.opacity(0.15)))
                }

                // Gas bladders (small circles near the top)
                let topSegStart = max(0, branch.segmentCount - 3)
                for s in topSegStart..<branch.segmentCount {
                    let bladderY = baseY - segHeight * CGFloat(s) - segHeight * 0.5
                    let bladderX = startX + branch.swayValues[min(s, branch.swayValues.count - 1)]
                    let bladderSize: CGFloat = 3
                    var bladder = Path()
                    bladder.addEllipse(in: CGRect(
                        x: bladderX - bladderSize / 2,
                        y: bladderY - bladderSize / 2,
                        width: bladderSize,
                        height: bladderSize
                    ))
                    context.fill(bladder, with: .color(baseColor.opacity(0.3)))
                }
            }
        }
    }

    // MARK: - Vent Decorations (Abyssal Zone)

    private func drawVentDecorations(
        context: inout GraphicsContext,
        size: CGSize,
        profiles: (left: WallProfile, right: WallProfile),
        rng: inout SeededRNG
    ) {
        let ventCount = config.decorationCount
        for _ in 0..<ventCount {
            let isLeft = Bool.random(using: &rng)
            _ = CGFloat.random(in: config.wallWidthRange, using: &rng) // consumed for sequence stability
            let y = CGFloat.random(in: 0...zoneHeight, using: &rng)

            let ventWidth = CGFloat.random(in: 15...30, using: &rng)
            let ventHeight = CGFloat.random(in: 20...40, using: &rng)
            var plumeOffsets: [CGFloat] = []
            for _ in 0..<4 {
                plumeOffsets.append(CGFloat.random(in: -3...3, using: &rng))
            }

            // Query wall profile for attachment point
            let profile = isLeft ? profiles.left : profiles.right
            guard let wallEdge = profile.wallEdge(at: y) else { continue }

            var offset = CGFloat.random(in: 10.0...15.0, using: &rng)
            if isLeft {
                offset *= -1
            }
            var ctx = context
            ctx.translateBy(x: wallEdge.x + offset, y: wallEdge.y)
            ctx.rotate(by: Angle(degrees: Double.random(in: -15...15, using: &rng)))

            // Chimney
            var chimney = Path()
            chimney.move(to: CGPoint(x: -ventWidth * 0.25, y: 0))
            chimney.addLine(to: CGPoint(x: -ventWidth * 0.12, y: -ventHeight))
            chimney.addLine(to: CGPoint(x: ventWidth * 0.12, y: -ventHeight))
            chimney.addLine(to: CGPoint(x: ventWidth * 0.25, y: 0))
            chimney.closeSubpath()

            let chimneyColor = Color(red: 0.10, green: 0.07, blue: 0.05)
            ctx.fill(chimney, with: .color(chimneyColor.opacity(0.5)))

            // Glow
            let glowRadius = ventWidth * 0.35
            let glowCenter = CGPoint(x: 0, y: -ventHeight)
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: glowCenter.x - glowRadius,
                    y: glowCenter.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.8, green: 0.3, blue: 0.1).opacity(0.25),
                        Color.clear,
                    ]),
                    center: glowCenter,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )

            // Smoke plume
            for i in 0..<4 {
                let plumeY = glowCenter.y - CGFloat(i) * 7
                let plumeRadius = CGFloat(i + 1) * 3.5
                let plumeOpacity = 0.12 - Double(i) * 0.025
                var plume = Path()
                plume.addEllipse(in: CGRect(
                    x: glowCenter.x - plumeRadius + plumeOffsets[i],
                    y: plumeY - plumeRadius / 2,
                    width: plumeRadius * 2,
                    height: plumeRadius
                ))
                ctx.fill(plume, with: .color(Color.gray.opacity(max(0.02, plumeOpacity))))
            }
        }
    }

}

// MARK: - Seeded RNG

/// Lightweight xorshift64 RNG for deterministic element placement.
/// Not part of OpenSeasUI — local to the ambient element system.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Ensure state is never zero (xorshift requires non-zero seed).
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state &<< 13
        state ^= state &>> 7
        state ^= state &<< 17
        return state
    }
}
