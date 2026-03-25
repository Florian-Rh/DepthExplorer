import SwiftUI

struct ScubaDiverView: View {
    var tilt: Double = 0.0
    var submersed: Bool = true
    var appearance: DiverAppearance = .naked

    var body: some View {
        ZStack {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate * 0.4
                Canvas { ctx, size in
                    DiverScene(size: size, t: t, appearance: appearance)
                        .draw(ctx, bodyTilt: tilt, submersed: submersed)
                }
            }
        }
    }
}

// MARK: - DiverScene
//
// COORDINATE SYSTEM (body-local):
//   origin  = torso centre
//   +x      = toward fins  (right on screen when tilt ≈ 0)
//   −x      = toward head
//   +y      = toward belly (down on screen)
//   −y      = toward back  (where the tank sits)
//   tilt    = +9° CW  →  head-down streamlined posture
//
// LIMB CONVENTION:
//   Every limb is drawn extending in the +y direction of its own frame.
//   Arms:  base rotation +25°  → arm hangs ~25° toward fins from vertical.
//   Legs:  base rotation +90° + kickAngle  → leg extends toward fins (+x).

private struct DiverScene {
    let size: CGSize
    let t: Double
    let appearance: DiverAppearance

    // Body-local anchor points
    private let headCtr      = CGPoint(x: -61, y:   0)
    private let nearShoulder = CGPoint(x: -35, y: +10)
    private let farShoulder  = CGPoint(x: -33, y:  +7)
    private let nearHip      = CGPoint(x: +36, y:  +5)
    private let farHip       = CGPoint(x: +34, y:  +5)
    private let tankCtr      = CGPoint(x:   0, y: -19)

    // Kinematics
    //
    // Flutter kick at ~1.7 Hz.
    // Fin flex lags 90° behind the leg (hydrodynamic drag):
    //   leg angle  ∝  sin(ω t)
    //   fin flex   ∝ −cos(ω t)   [= derivative direction]
    private var phase: Double { t * 1.72 * .pi * 2.0 }

    private var bobY: CGFloat { CGFloat(sin(t * 1.10) * 15) }
    private var bobX: CGFloat { CGFloat(cos(t * 0.57) * 15) }

    private var nearKick: Double { sin(phase) * 15.0 }
    private var nearFlex: Double { -cos(phase) }
    private var farKick: Double { -sin(phase) * 15.0 }
    private var farFlex: Double { cos(phase) }

    private var nearArmSwing: Double { sin(phase * 0.5 + .pi) * 4.0 }
    private var farArmSwing: Double { -sin(phase * 0.5) * 4.0 }

    private var diverCenter: CGPoint {
        CGPoint(x: size.width * 0.50 + bobX,
                y: size.height * 0.46 + bobY)
    }

    private func renderContext(bodyTilt: Double, submersed: Bool) -> DiverRenderContext {
        DiverRenderContext(
            headCtr: headCtr,
            nearShoulder: nearShoulder,
            farShoulder: farShoulder,
            nearHip: nearHip,
            farHip: farHip,
            tankCtr: tankCtr,
            nearKick: nearKick,
            nearFlex: nearFlex,
            farKick: farKick,
            farFlex: farFlex,
            nearArmSwing: nearArmSwing,
            farArmSwing: farArmSwing,
            bodyTilt: bodyTilt,
            hasDPV: appearance.dpv != nil,
            submersed: submersed
        )
    }

    // MARK: - Suit color for hose tinting

    private var suitColor: Color {
        switch appearance.suit {
        case nil:          return Color.yellow
        case .wetsuit3mm:  return Color(red: 0.20, green: 0.55, blue: 0.80)
        case .wetsuit5mm:  return Color(red: 0.15, green: 0.38, blue: 0.62)
        case .wetsuit7mm:  return Color(red: 0.10, green: 0.12, blue: 0.14)
        case .drysuit:     return Color(red: 0.22, green: 0.22, blue: 0.24)
        }
    }

    // MARK: - Drawing

    func draw(_ ctx: GraphicsContext, bodyTilt: Double, submersed: Bool) {
        drawDiver(ctx, bodyTilt: bodyTilt, submersed: submersed)
        if submersed && appearance.scubaGear != nil {
            drawBubbles(ctx, bodyTilt: bodyTilt)
        }
    }

    private func drawDiver(_ ctx: GraphicsContext, bodyTilt: Double, submersed: Bool) {
        var dc = ctx
        dc.translateBy(x: diverCenter.x, y: diverCenter.y)
        dc.rotate(by: .degrees(bodyTilt))
        if bodyTilt > 90.0 && bodyTilt < 270.0 {
            dc.scaleBy(x: 1.0, y: -1.0)
        }

        let rc = renderContext(bodyTilt: bodyTilt, submersed: submersed)

        // Build renderers based on appearance
        let bodyRenderer = BodyRenderer(
            suit: appearance.suit,
            hasFins: appearance.fins != nil,
            hasScubaGear: appearance.scubaGear != nil
        )

        // Paint order: far fins → tank → body (far limbs, torso, near limbs) → near fins → head
        // Far fins behind body
        if let finsTier = appearance.fins {
            // Draw only far fin first (behind body)
            let finsRenderer = FinsGearRenderer(tier: finsTier)
            drawFarFinOnly(dc, renderer: finsRenderer, render: rc)
        }

        // Tank behind body
        if let tankTier = appearance.scubaGear {
            let tankRenderer = TankGearRenderer(tier: tankTier, suitColor: suitColor)
            tankRenderer.draw(dc, render: rc)
        }

        // Far-side stage tank (behind body, only for double)
        if appearance.stageTanks == .double {
            let stageRenderer = StageTankGearRenderer(tier: .double)
            stageRenderer.drawStageTank(dc, render: rc, isFar: true)
        }

        // Body (torso + all limbs)
        bodyRenderer.draw(dc, render: rc)


//        // Near-side stage tank (in front of body)
        if let stageTier = appearance.stageTanks {
            let stageRenderer = StageTankGearRenderer(tier: stageTier)
            stageRenderer.drawStageTank(dc, render: rc, isFar: false)
        }

        // Mesh bag (in front of body, clipped to near hip)
        if let bagTier = appearance.meshBag {
            let bagRenderer = MeshBagGearRenderer(tier: bagTier)
            bagRenderer.draw(dc, render: rc)
        }

        // Lift bag (attached to near hip, always points up)
        if let liftTier = appearance.liftBag {
            let liftRenderer = LiftBagGearRenderer(tier: liftTier)
            liftRenderer.draw(dc, render: rc)
        }

        // DPV (held by near arm, in front of body)
        if let dpvTier = appearance.dpv {
            let dpvRenderer = DPVGearRenderer(tier: dpvTier)
            dpvRenderer.draw(dc, render: rc)
        }

        // Near fin in front of body
        if let finsTier = appearance.fins {
            let finsRenderer = FinsGearRenderer(tier: finsTier)
            drawNearFinOnly(dc, renderer: finsRenderer, render: rc)
        }

        // Head on top
        let headRenderer = HeadGearRenderer(
            suit: appearance.suit,
            hasScubaGear: appearance.scubaGear != nil
        )
        headRenderer.draw(dc, render: rc)
    }

    /// Draw only the far fin (called before the body for correct layering).
    private func drawFarFinOnly(_ ctx: GraphicsContext, renderer: FinsGearRenderer, render: DiverRenderContext) {
        // We need a temporary context approach — call the full renderer but we only need far.
        // Since FinsGearRenderer draws both, we use a dedicated single-fin draw.
        drawSingleFin(ctx, renderer: renderer, hip: render.farHip,
                      kickAngle: render.farKick, finFlex: render.farFlex,
                      scale: 0.91, alpha: 0.7)
    }

    /// Draw only the near fin (called after the body for correct layering).
    private func drawNearFinOnly(_ ctx: GraphicsContext, renderer: FinsGearRenderer, render: DiverRenderContext) {
        drawSingleFin(ctx, renderer: renderer, hip: render.nearHip,
                      kickAngle: render.nearKick, finFlex: render.nearFlex,
                      scale: 1.00, alpha: 1.00)
    }

    /// Draws a single fin blade at the given leg position.
    private func drawSingleFin(_ ctx: GraphicsContext, renderer: FinsGearRenderer,
                               hip: CGPoint, kickAngle: Double, finFlex: Double,
                               scale: CGFloat, alpha: Double) {
        var lc = ctx
        lc.translateBy(x: hip.x, y: hip.y)
        lc.scaleBy(x: scale, y: scale)
        lc.rotate(by: .degrees(-90.0 + kickAngle))
        // Navigate down the leg to the ankle
        lc.translateBy(x: 0, y: 32)  // thigh
        lc.rotate(by: .degrees(8))    // knee bend
        lc.translateBy(x: 0, y: 28)  // shin → ankle

        let bladeScale: CGFloat = {
            switch renderer.tier {
            case .basic:    return 0.85
            case .advanced: return 1.00
            case .pro:      return 1.15
            }
        }()

        let finColor: Color = {
            switch renderer.tier {
            case .basic:    return Color(red: 1.00, green: 0.44, blue: 0.10)
            case .advanced: return Color(red: 0.20, green: 0.70, blue: 0.40)
            case .pro:      return Color(red: 0.12, green: 0.12, blue: 0.14)
            }
        }()

        let finEdge: Color = {
            switch renderer.tier {
            case .basic:    return Color(red: 0.70, green: 0.27, blue: 0.04)
            case .advanced: return Color(red: 0.10, green: 0.45, blue: 0.22)
            case .pro:      return Color(red: 0.25, green: 0.25, blue: 0.28)
            }
        }()

        let blade = finBladePath(flex: finFlex, scale: bladeScale)
        lc.fill(blade, with: .color(finEdge.opacity(alpha * 0.50)))
        var lc2 = lc
        lc2.translateBy(x: -1, y: -1)
        lc2.fill(blade, with: .color(finColor.opacity(alpha)))
        lc2.stroke(blade, with: .color(Color.black.opacity(0.16 * alpha)), lineWidth: 0.9)

        // Pro fins: carbon fiber texture lines
        if renderer.tier == .pro {
            let tipX = CGFloat(finFlex) * 25.0 * bladeScale
            for i in stride(from: 10.0, to: 50.0 * bladeScale, by: 8.0) {
                let progress = CGFloat(i) / (50.0 * bladeScale)
                let xOff = tipX * progress
                var line = Path()
                line.move(to: CGPoint(x: -4 + xOff, y: i))
                line.addLine(to: CGPoint(x: 16 + xOff, y: i))
                lc2.stroke(line, with: .color(Color.white.opacity(0.08 * alpha)), lineWidth: 0.5)
            }
        }

        // Advanced fins: split-fin notch
        if renderer.tier == .advanced {
            let tipY = 54.0 * bladeScale
            let tipX = CGFloat(finFlex) * 25.0 * bladeScale
            var notch = Path()
            notch.move(to: CGPoint(x: 8 + tipX * 0.7, y: tipY * 0.6))
            notch.addLine(to: CGPoint(x: 10 + tipX, y: tipY))
            notch.addLine(to: CGPoint(x: 6 + tipX * 0.7, y: tipY * 0.6))
            lc2.stroke(notch, with: .color(Color.black.opacity(0.25 * alpha)), lineWidth: 1.2)
        }
    }

    private func finBladePath(flex: Double, scale: CGFloat) -> Path {
        let tip = CGFloat(flex) * 25.0 * scale
        let mid = CGFloat(flex) * 9.0 * scale
        let length: CGFloat = 54.0 * scale
        let tipWidth: CGFloat = 58.0 * scale
        var p = Path()
        p.move(to: CGPoint(x: -7, y: -3))
        p.addLine(to: CGPoint(x: 7, y: -3))
        p.addQuadCurve(to: CGPoint(x: 20 * scale + tip, y: length),
                       control: CGPoint(x: 11.0 * scale + mid, y: length * 0.46))
        p.addQuadCurve(to: CGPoint(x: -4.0 * scale + tip, y: tipWidth),
                       control: CGPoint(x: 2.5 * scale + tip, y: length * 1.11))
        p.addQuadCurve(to: CGPoint(x: -7, y: -3),
                       control: CGPoint(x: -10.5 * scale + mid, y: length * 0.46))
        p.closeSubpath()
        return p
    }

    // MARK: - Bubbles

    // Regulator bubbles
    //
    // Mouthpiece in body-local: (headCtr.x − 14, +10) = (−75, +10).
    // Transformed to world space using the CW rotation matrix:
    //   x_w =  x_b · cos θ + y_b · sin θ  +  center.x
    //   y_w = −x_b · sin θ + y_b · cos θ  +  center.y

    private let cBubble = Color(red: 0.80, green: 0.95, blue: 1.00)

    private func drawBubbles(_ ctx: GraphicsContext, bodyTilt: Double) {
        let θ = bodyTilt * .pi / 180.0
        let c = cos(θ), s = sin(θ)
        let bx = headCtr.x - 14.0
        let by: Double = 10.0
        let origin = CGPoint(
            x: diverCenter.x + CGFloat(c * bx + s * by),
            y: diverCenter.y + CGFloat(s * bx + c * by)
        )

        for i in 0..<14 {
            let fi = Double(i)
            let age = fmod(t + fi * 0.38, 3.8)
            let rise = CGFloat(age) * 27.0
            let wobble = CGFloat(sin(t * 2.1 + fi * 1.9)) * 10.0
                       + CGFloat(fi * 4.5 - 31.0)
            var r = CGFloat(2.4 + age * 1.30 + fi * 0.30)
            r = min(r, 14.0)
            let opacity = max(0.0, 1.0 - age / 3.4) * 0.80
            guard opacity > 0.01 else { continue }

            let px = origin.x + wobble
            let py = origin.y - rise
            let rect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)

            ctx.fill(Path(ellipseIn: rect),
                     with: .color(cBubble.opacity(opacity * 0.12)))
            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(cBubble.opacity(opacity * 0.70)),
                       lineWidth: 0.85)
            // Specular highlight
            let hlR = r * 0.27
            ctx.fill(Path(ellipseIn: CGRect(x: px - r * 0.42 - hlR,
                                            y: py - r * 0.42 - hlR,
                                            width: hlR * 2, height: hlR * 2)),
                     with: .color(Color.white.opacity(opacity * 0.62)))
        }
    }
}

#Preview("Naked") {
    ScubaDiverView(appearance: .naked)
        .preferredColorScheme(.dark)
}

#Preview("Full Gear") {
    ScubaDiverView(appearance: DiverAppearance(suit: .wetsuit5mm, fins: .advanced, scubaGear: .standard))
        .preferredColorScheme(.dark)
}

#Preview("Drysuit + Twinset + Pro Fins") {
    ScubaDiverView(appearance: DiverAppearance(suit: .drysuit, fins: .pro, scubaGear: .twinset))
        .preferredColorScheme(.dark)
}

#Preview("Twinset + Single Stage") {
    ScubaDiverView(appearance: DiverAppearance(suit: .wetsuit7mm, fins: .advanced, scubaGear: .twinset, stageTanks: .single))
        .preferredColorScheme(.dark)
}

#Preview("Twinset + Double Stage") {
    ScubaDiverView(appearance: DiverAppearance(suit: .drysuit, fins: .pro, scubaGear: .twinset, stageTanks: .double))
        .preferredColorScheme(.dark)
}
#Preview("With Mesh Bag") {
    ScubaDiverView(appearance: DiverAppearance(suit: .wetsuit5mm, fins: .advanced, scubaGear: .standard, meshBag: .large))
        .preferredColorScheme(.dark)
}

#Preview("Medium Lift Bag") {
    ScubaDiverView(appearance: DiverAppearance(suit: .wetsuit5mm, fins: .advanced, scubaGear: .standard, liftBag: .medium))
        .preferredColorScheme(.dark)
}
#Preview("Large Lift Bag") {
    ScubaDiverView(appearance: DiverAppearance(suit: .drysuit, fins: .pro, scubaGear: .twinset, liftBag: .large))
        .preferredColorScheme(.dark)
}

#Preview("Basic DPV") {
    ScubaDiverView(appearance: DiverAppearance(suit: .wetsuit5mm, fins: .advanced, scubaGear: .standard, dpv: .basic))
        .preferredColorScheme(.dark)
}

#Preview("Advanced DPV") {
    ScubaDiverView(appearance: DiverAppearance(suit: .drysuit, fins: .pro, scubaGear: .twinset, dpv: .advanced))
        .preferredColorScheme(.dark)
}



