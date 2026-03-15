import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// MARK: – Entry Point
// ══════════════════════════════════════════════════════════════════════════

struct ScubaDiverView: View {
    var tilt: Double = 0.0
    var submersed: Bool = true

    var body: some View {
        ZStack {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate * 0.4
                Canvas { ctx, size in
                    OceanScene(size: size, t: t).draw(ctx, bodyTilt: tilt, submersed: submersed)
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// MARK: – Scene
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
//          This is the KEY fix vs. the previous version (which used 0° base).
// ══════════════════════════════════════════════════════════════════════════

private struct OceanScene {
    let size: CGSize
    let t:    Double

    // ── Kinematics ────────────────────────────────────────────────────────
    //
    //  Flutter kick at ~1.7 Hz.
    //  Fin flex lags 90° behind the leg (hydrodynamic drag):
    //    leg angle  ∝  sin(ω t)
    //    fin flex   ∝ −cos(ω t)   [= derivative direction]
    //
    private var phase:    Double { t * 1.72 * .pi * 2.0 }

    var bobY:      CGFloat { CGFloat(sin(t * 1.10) * 15) }
    var bobX:      CGFloat { CGFloat(cos(t * 0.57) * 15) }
    // removed bodyTilt property as per instructions

    var nearKick:  Double { sin(phase) * 15.0 }       // near leg swing ±22°
    var nearFlex:  Double { -cos(phase) }              // near fin flex −1…+1
    var farKick:   Double { -sin(phase) * 15.0 }      // far leg (opposite phase)
    var farFlex:   Double { cos(phase) }

    var nearArmSwing: Double { sin(phase * 0.5 + .pi) * 4.0 }
    var farArmSwing:  Double { -sin(phase * 0.5) * 4.0  }

    // ── Body-local anchor points ─────────────────────────────────────────
    private let headCtr      = CGPoint(x: -61,  y:  0)
    private let nearShoulder = CGPoint(x: -35,  y: +10)   // belly side
    private let farShoulder  = CGPoint(x: -33,  y:  +7)
    private let nearHip      = CGPoint(x: +36,  y: +5)   // belly side
    private let farHip       = CGPoint(x: +34,  y:  +5)
    private let tankCtr      = CGPoint(x:   0,  y: -19)   // on back (−y)

    // ── World-space diver centre ─────────────────────────────────────────
    var diverCenter: CGPoint {
        CGPoint(x: size.width * 0.50 + bobX,
                y: size.height * 0.46 + bobY)
    }

    // ── Palette ──────────────────────────────────────────────────────────
    let cSuit    = Color.yellow //Color(red:0.07,green:0.14,blue:0.26)
    let cSuitHi  = Color(red:0.14,green:0.26,blue:0.46)
    let cFin     = Color(red:1.00,green:0.44,blue:0.10)
    let cFinEdge = Color(red:0.70,green:0.27,blue:0.04)
    let cTank    = Color(red:0.68,green:0.74,blue:0.83)
    let cTankAcc = Color(red:0.46,green:0.52,blue:0.61)
    let cMask    = Color(red:0.04,green:0.04,blue:0.06)
    let cLens    = Color(red:0.28,green:0.78,blue:0.92).opacity(0.55)
    let cSpec    = Color.white.opacity(0.32)
    let cReg     = Color(red:0.18,green:0.20,blue:0.24)
    let cBubble  = Color(red:0.80,green:0.95,blue:1.00)

    // ════════════════════════════════════════════════════════════════════
    // MARK: – Top-Level Draw
    // ════════════════════════════════════════════════════════════════════

    func draw(_ ctx: GraphicsContext, bodyTilt: Double, submersed: Bool) {
        drawDiver(ctx, bodyTilt: bodyTilt)
        if submersed {
            drawBubbles(ctx, bodyTilt: bodyTilt)
        }
    }

    // ════════════════════════════════════════════════════════════════════
    // MARK: – Diver  (body-local transform entry)
    // ════════════════════════════════════════════════════════════════════

    private func drawDiver(_ ctx: GraphicsContext, bodyTilt: Double) {
        var dc = ctx
        dc.translateBy(x: diverCenter.x, y: diverCenter.y)
        dc.rotate(by: .degrees(bodyTilt))
        if bodyTilt > 100.0 && bodyTilt < 260.0 {
            dc.scaleBy(x: 1.0, y: -1.0)
        }
        // dc is now in body-local space.

        // Paint order: far parts first (behind), near parts last (in front)
        drawFarArm(dc)
        drawFarLegAndFin(dc)
        drawTank(dc)
        drawTorso(dc)
        drawNearArm(dc)
        drawNearLegAndFin(dc)
        drawHead(dc)
    }

    // ── Tank (horizontal cylinder on back = −y side) ─────────────────────

    private func drawTank(_ ctx: GraphicsContext) {
        var tc = ctx
        tc.translateBy(x: tankCtr.x, y: tankCtr.y)
        // Tank-local: horizontal cylinder, long axis = x, on the diver's back.
        // Whole cylinder: x −22…+22, y −5…+5.

        // Main cylinder
        tc.fill(
            Path(roundedRect: CGRect(x:-22,y:-5,width:44,height:10), cornerRadius:4),
            with: .color(cTank)
        )
        // Sheen along top
        tc.fill(
            Path(roundedRect: CGRect(x:-21,y:-5,width:42,height:3), cornerRadius:1.5),
            with: .color(Color.white.opacity(0.22))
        )
        // Left end-cap (toward head — valve side)
        tc.fill(Path(ellipseIn: CGRect(x:-25,y:-5,width:6,height:10)), with:.color(cTankAcc))
        // Right end-cap (toward fins)
        tc.fill(Path(ellipseIn: CGRect(x: 19,y:-5,width:6,height:10)), with:.color(cTankAcc))
        // Valve knob on left
        tc.fill(Path(roundedRect: CGRect(x:-30,y:-3,width:6,height:6), cornerRadius:1),
                with:.color(cTank))

        // ── Regulator hose ────────────────────────────────────────────────
        // First stage at valve: tank-local (−25, 0) = body-local (−25, −19).
        // Mouthpiece at: head-local (−14, +10) = body-local (−75, +10).
        // In tank-local: (−75 − 0, +10 − (−19)) = (−75, +29).
        var hose = Path()
        hose.move(to: CGPoint(x:-25, y:0))
        hose.addCurve(
            to:       CGPoint(x:-75, y:29),
            control1: CGPoint(x:-30, y:-22),  // arc up over the shoulder area
            control2: CGPoint(x:-68, y: 6)    // sweeps forward to chin
        )
        tc.stroke(hose, with: .color(cSuit.opacity(0.88)),
                  style: StrokeStyle(lineWidth:3.0, lineCap:.round))
    }

    // ── Torso / BCD ───────────────────────────────────────────────────────

    private func drawTorso(_ ctx: GraphicsContext) {
        // Torso: x −42…+40 (82 px along body), y −13…+13 (26 px across)
        ctx.fill(
            Path(roundedRect: CGRect(x:-42,y:-13,width:82,height:26), cornerRadius:10),
            with: .color(cSuit)
        )
        // BCD front panel (belly side, slightly inset)
        ctx.fill(
            Path(roundedRect: CGRect(x:-40,y:-11,width:46,height:22), cornerRadius:8),
            with: .color(cSuitHi.opacity(0.38))
        )
        // Shoulder strap band
        ctx.fill(
            Path(roundedRect: CGRect(x:-38,y:-13,width:9,height:26), cornerRadius:4),
            with: .color(cSuitHi.opacity(0.52))
        )
        // Tank strap (holds cylinder to back)
        var strap = Path()
        strap.move(to: CGPoint(x:-42,y:-7)); strap.addLine(to: CGPoint(x:40,y:-7))
        ctx.stroke(strap, with: .color(cSuitHi.opacity(0.38)), lineWidth: 2.5)
    }

    // ── Arm (shared renderer) ─────────────────────────────────────────────
    //
    //  Arm is drawn extending in +y (downward) in arm-local space, then
    //  rotated so it hangs at `baseAngle` degrees from +y = ~25° toward fins.

    private func renderArm(_ ctx: GraphicsContext, shoulder: CGPoint,
                            baseAngle: Double, elbowBend: Double,
                            scale: CGFloat, alpha: Double) {
        let col = cSuit.opacity(alpha)
        var ac = ctx
        ac.translateBy(x: shoulder.x, y: shoulder.y)
        ac.scaleBy(x: scale, y: scale)
        ac.rotate(by: .degrees(-90 + baseAngle))

        // Upper arm
        ac.fill(Path(roundedRect: CGRect(x:-4.5,y:0,width:9,height:26), cornerRadius:4),
                with:.color(col))
        // Elbow cap
        ac.fill(Path(ellipseIn: CGRect(x:-4.5,y:22,width:9,height:9)),
                with:.color(cSuitHi.opacity(alpha * 0.70)))

        // Forearm (pivots at elbow)
        var fc = ac
        fc.translateBy(x:0, y:27)
        fc.rotate(by: .degrees(elbowBend))
        fc.fill(Path(roundedRect: CGRect(x:-4,y:0,width:8,height:22), cornerRadius:3),
                with:.color(col))
        // Glove
        fc.fill(Path(roundedRect: CGRect(x:-5,y:20,width:10,height:9), cornerRadius:4),
                with:.color(Color.black.opacity(0.72 * alpha)))
        fc.fill(Path(ellipseIn: CGRect(x:-2,y:20,width:5,height:4)),
                with:.color(Color.white.opacity(0.12 * alpha)))
    }

    private func drawNearArm(_ ctx: GraphicsContext) {
        renderArm(ctx, shoulder: nearShoulder,
                  baseAngle: 25.0 + nearArmSwing, elbowBend: -14,
                  scale: 1.00, alpha: 1.00)
    }
    private func drawFarArm(_ ctx: GraphicsContext) {
        renderArm(ctx, shoulder: farShoulder,
                  baseAngle: 25.0 + farArmSwing, elbowBend: -11,
                  scale: 0.91, alpha: 0.75)
    }

    // ── Leg + Fin (shared renderer) ───────────────────────────────────────
    //
    //  KEY FIX:  base rotation = +90°  →  +y in leg frame = +x in body frame.
    //  This makes the leg extend toward the fins (+x direction) rather than
    //  hanging downward as in the previous version.
    //  kickAngle swings the leg ±22° above/below this horizontal baseline.

    private func renderLegAndFin(_ ctx: GraphicsContext, hip: CGPoint,
                                  kickAngle: Double, finFlex: Double,
                                  scale: CGFloat, alpha: Double) {
        var lc = ctx
        lc.translateBy(x: hip.x, y: hip.y)
        lc.scaleBy(x: scale, y: scale)
        lc.rotate(by: .degrees(-90.0 + kickAngle))
        // +y now points toward fins (+x body-local). Kick swings ±kickAngle.

        // Thigh
        lc.fill(Path(roundedRect: CGRect(x:-5.5,y:0,width:11,height:32), cornerRadius:4),
                with:.color(cSuit.opacity(alpha)))
        // Kneecap
        lc.fill(Path(ellipseIn: CGRect(x:-5.5,y:28,width:11,height:10)),
                with:.color(cSuitHi.opacity(alpha * 0.65)))

        // Shin pivots at knee with 8° natural bend toward belly (+y)
        var kc = lc
        kc.translateBy(x:0, y:32)
        kc.rotate(by: .degrees(8))
        kc.fill(Path(roundedRect: CGRect(x:-5,y:0,width:10,height:28), cornerRadius:4),
                with:.color(cSuit.opacity(alpha)))
        // Boot
        kc.fill(Path(roundedRect: CGRect(x:-6,y:25,width:12,height:10), cornerRadius:4),
                with:.color(Color.black.opacity(0.78 * alpha)))
        kc.fill(Path(ellipseIn: CGRect(x:-3,y:25,width:6,height:4)),
                with:.color(Color.white.opacity(0.10 * alpha)))

        // Fin blade pivots at ankle
        var fc = kc
        fc.translateBy(x:0, y:28)
        let blade = finBladePath(flex: finFlex)
//        let glow  = finGlowPath(flex: finFlex)
        // Shadow (depth / thickness illusion)
        fc.fill(blade, with:.color(cFinEdge.opacity(alpha * 0.50)))
        // Blade fill (offset by 1pt for 3-D pop)
        var fc2 = fc; fc2.translateBy(x:-1, y:-1)
        fc2.fill(blade, with:.color(cFin.opacity(alpha)))
//        fc2.fill(glow,  with:.color(Color.white.opacity(0.14 * alpha)))
        fc2.stroke(blade, with:.color(Color.black.opacity(0.16 * alpha)), lineWidth:0.9)
    }

    private func drawNearLegAndFin(_ ctx: GraphicsContext) {
        renderLegAndFin(ctx, hip: nearHip, kickAngle: nearKick, finFlex: nearFlex,
                        scale: 1.00, alpha: 1.00)
    }
    private func drawFarLegAndFin(_ ctx: GraphicsContext) {
        renderLegAndFin(ctx, hip: farHip, kickAngle: farKick, finFlex: farFlex,
                        scale: 0.91, alpha: 0.7)
    }

    // ── Fin Blade (flexible Bézier) ───────────────────────────────────────
    //
    //  Blade runs from ankle (0,0) in +y direction (= fin's "forward" direction).
    //  `flex` ∈ [−1,+1] deflects tip ±25 px in blade-local x:
    //    flex > 0 → tip sweeps toward +x  (toward belly in world)
    //    flex < 0 → tip sweeps toward −x  (toward back)

    private func finBladePath(flex: Double) -> Path {
        let tip = CGFloat(flex) * 25.0
        let mid = CGFloat(flex) *  9.0
        var p = Path()
        p.move(to: CGPoint(x: -7, y: -3))
        p.addLine(to: CGPoint(x:  7, y: -3))
        p.addQuadCurve(to: CGPoint(x:  20+tip, y:54),
                       control: CGPoint(x: 11.0+mid, y:25))
        p.addQuadCurve(to: CGPoint(x: -4.0+tip, y:58),
                       control: CGPoint(x:  2.5+tip, y:60))
        p.addQuadCurve(to: CGPoint(x: -7, y:-3),
                       control: CGPoint(x:-10.5+mid, y:25))
        p.closeSubpath()
        return p
    }

//    private func finGlowPath(flex: Double) -> Path {
//        let tip = CGFloat(flex) * 14.0
//        let mid = CGFloat(flex) *  5.0
//        var p = Path()
//        p.move(to: CGPoint(x:-1.5, y:2))
//        p.addQuadCurve(to: CGPoint(x: 1.0+tip*0.55, y:42),
//                       control: CGPoint(x: 3.0+mid*0.55, y:20))
//        p.addLine(to: CGPoint(x:-2.0+tip*0.45, y:42))
//        p.closeSubpath()
//        return p
//    }

    // ── Head (hood + mask + regulator second stage) ───────────────────────
    //
    //  Head-local axes: (0,0) = head centre.
    //  Diver faces LEFT  →  face side = −x,  back of hood = +x (toward torso).
    //  Mask is placed on the −x (face) side.

    private func drawHead(_ ctx: GraphicsContext) {
        var hc = ctx
        hc.translateBy(x: headCtr.x, y: headCtr.y)

        // Wetsuit hood
        hc.fill(Path(ellipseIn: CGRect(x:-20,y:-20,width:40,height:40)),
                with:.color(cSuit))
        hc.stroke(Path(ellipseIn: CGRect(x:-20,y:-20,width:40,height:40)),
                  with:.color(cSuitHi.opacity(0.28)), lineWidth:1.5)

        // ── Mask (on face = −x side) ──────────────────────────────────────
        // Frame
        hc.fill(Path(roundedRect: CGRect(x:-21,y:-10,width:20,height:18), cornerRadius:4),
                with:.color(cMask))
        // Lens (single pane visible from side)
        hc.fill(Path(roundedRect: CGRect(x:-19,y:-8,width:16,height:14), cornerRadius:3),
                with:.color(cLens))
        // Lens specular
        hc.fill(Path(roundedRect: CGRect(x:-17,y:-6,width:7,height:4), cornerRadius:2),
                with:.color(cSpec))
        // Mask strap (from mask edge at +x side of frame → around back of hood)
        var strap = Path()
        strap.move(to: CGPoint(x: -1, y: -7)); strap.addLine(to: CGPoint(x: 19, y: -5))
        strap.move(to: CGPoint(x: -1, y:  6)); strap.addLine(to: CGPoint(x: 19, y:  4))
        hc.stroke(strap, with:.color(Color.black.opacity(0.50)),
                  style:StrokeStyle(lineWidth:2.2, lineCap:.round))

        // ── Regulator second stage (chin / mouth area) ────────────────────
        // Demand-valve housing
        hc.fill(Path(ellipseIn: CGRect(x:-18,y: 8,width:13,height:11)),
                with:.color(cReg))
        // Purge button
        hc.fill(Path(ellipseIn: CGRect(x:-16,y:10,width: 9,height: 7)),
                with:.color(Color(red:0.38,green:0.42,blue:0.50)))
        // Mouthpiece stem
        hc.fill(Path(roundedRect: CGRect(x:-14,y:18,width:8,height:6), cornerRadius:2),
                with:.color(Color.black.opacity(0.78)))
        // Exhaust port vents
        hc.fill(Path(roundedRect: CGRect(x:-22,y:11,width:5,height:4), cornerRadius:1),
                with:.color(cReg.opacity(0.75)))
    }

    // ════════════════════════════════════════════════════════════════════
    // MARK: – Regulator Bubbles
    //
    //  Mouthpiece in body-local: (headCtr.x − 14, +10) = (−75, +10).
    //  Transformed to world space using the CW rotation matrix:
    //    x_w =  x_b · cos θ + y_b · sin θ  +  center.x
    //    y_w = −x_b · sin θ + y_b · cos θ  +  center.y
    // ════════════════════════════════════════════════════════════════════

    private func drawBubbles(_ ctx: GraphicsContext, bodyTilt: Double) {
        let θ  = bodyTilt * .pi / 180.0
        let c  = cos(θ), s = sin(θ)
        let bx = headCtr.x - 14.0        // mouthpiece, body-local x
        let by: Double = 10.0            // mouthpiece, body-local y
        let origin = CGPoint(
            x: diverCenter.x + CGFloat( c * bx + s * by),
            y: diverCenter.y + CGFloat(s * bx + c * by)
        )

        for i in 0..<14 {
            let fi      = Double(i)
            let age     = fmod(t + fi * 0.38, 3.8)
            let rise    = CGFloat(age) * 27.0
            let wobble  = CGFloat(sin(t * 2.1 + fi * 1.9)) * 10.0
                        + CGFloat(fi * 4.5 - 31.0)
            var r       = CGFloat(2.4 + age * 1.30 + fi * 0.30)
            r = min(r, 14.0)
            let opacity = max(0.0, 1.0 - age / 3.4) * 0.80
            guard opacity > 0.01 else { continue }

            let px   = origin.x + wobble
            let py   = origin.y - rise
            let rect = CGRect(x: px-r, y: py-r, width: r*2, height: r*2)

            ctx.fill(Path(ellipseIn: rect),
                     with:.color(cBubble.opacity(opacity * 0.12)))
            ctx.stroke(Path(ellipseIn: rect),
                       with:.color(cBubble.opacity(opacity * 0.70)),
                       lineWidth:0.85)
            // Specular highlight
            let hlR = r * 0.27
            ctx.fill(Path(ellipseIn: CGRect(x: px - r*0.42 - hlR,
                                            y: py - r*0.42 - hlR,
                                            width: hlR*2, height: hlR*2)),
                     with:.color(Color.white.opacity(opacity * 0.62)))
        }
    }
}

// ══════════════════════════════════════════════════════════════════════════
// MARK: – Preview
// ══════════════════════════════════════════════════════════════════════════

#Preview {
    ScubaDiverView()
        .preferredColorScheme(.dark)
}
