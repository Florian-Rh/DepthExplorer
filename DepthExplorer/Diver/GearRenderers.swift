import SwiftUI

// MARK: - Gear Renderer Protocol

/// A gear renderer draws one piece of equipment into a Canvas `GraphicsContext`
/// that has already been translated/rotated to body-local coordinates.
///
/// Each renderer receives the full `DiverRenderContext` so it can access
/// kinematics (kick angles, arm swing) and anchor points.
protocol GearRenderer {
    func draw(_ ctx: GraphicsContext, render: DiverRenderContext)
}

/// Shared rendering state passed to all gear renderers.
struct DiverRenderContext {
    // Anchor points (body-local)
    let headCtr: CGPoint
    let nearShoulder: CGPoint
    let farShoulder: CGPoint
    let nearHip: CGPoint
    let farHip: CGPoint
    let tankCtr: CGPoint

    // Kinematics
    let nearKick: Double
    let nearFlex: Double
    let farKick: Double
    let farFlex: Double
    let nearArmSwing: Double
    let farArmSwing: Double

    /// Body tilt in degrees (used by lift bag to counter-rotate and always point up).
    let bodyTilt: Double

    /// Whether a DPV is equipped (affects arm posture).
    let hasDPV: Bool
    /// Whether the diver is currently submerged (DPV holding pose only when underwater).
    let submersed: Bool
    /// Whether an atmospheric diving suit is equipped (stiff posture, no kicking).
    let hasADS: Bool

    /// True when the diver should hold the DPV in extended-arm position.
    var holdingDPV: Bool { hasDPV && submersed }
}

// MARK: - Skin Palette

/// Colors for exposed skin (when no suit covers a body part).
enum SkinPalette {
    static let skin      = Color(red: 0.87, green: 0.72, blue: 0.58)
    static let skinShade = Color(red: 0.73, green: 0.58, blue: 0.44)
}

// MARK: - Body / Suit Renderer

/// Draws the torso and limbs. Appearance depends on equipped suit tier.
struct BodyRenderer: GearRenderer {
    let suit: SuitTier?
    let hasFins: Bool
    let hasScubaGear: Bool

    // MARK: Palette per tier

    private var torsoColor: Color {
        switch suit {
        case nil:          return SkinPalette.skin
        case .wetsuit3mm:  return Color(red: 0.20, green: 0.55, blue: 0.80)   // Light blue
        case .wetsuit5mm:  return Color(red: 0.15, green: 0.38, blue: 0.62)   // Medium blue
        case .wetsuit7mm:  return Color(red: 0.10, green: 0.12, blue: 0.14)   // Near-black
        case .drysuit:     return Color(red: 0.22, green: 0.22, blue: 0.24)   // Dark grey
        }
    }

    private var torsoAccent: Color {
        switch suit {
        case nil:          return SkinPalette.skinShade.opacity(0.4)
        case .wetsuit3mm:  return Color(red: 0.12, green: 0.34, blue: 0.56).opacity(0.5)
        case .wetsuit5mm:  return Color(red: 0.10, green: 0.26, blue: 0.46).opacity(0.55)
        case .wetsuit7mm:  return Color(red: 0.22, green: 0.24, blue: 0.28).opacity(0.5)
        case .drysuit:     return Color(red: 0.40, green: 0.40, blue: 0.42).opacity(0.45)
        }
    }

    private var limbColor: Color { torsoColor }

    private var jointColor: Color {
        switch suit {
        case nil:          return SkinPalette.skinShade.opacity(0.55)
        case .wetsuit3mm:  return Color(red: 0.10, green: 0.34, blue: 0.56).opacity(0.65)
        case .wetsuit5mm:  return Color(red: 0.08, green: 0.22, blue: 0.40).opacity(0.65)
        case .wetsuit7mm:  return Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.65)
        case .drysuit:     return Color(red: 0.35, green: 0.35, blue: 0.38).opacity(0.65)
        }
    }

    private var gloveColor: Color {
        switch suit {
        case nil:          return SkinPalette.skin
        case .wetsuit3mm:  return Color(red: 0.14, green: 0.14, blue: 0.16).opacity(0.72)
        case .wetsuit5mm:  return Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.78)
        case .wetsuit7mm:  return Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.82)
        case .drysuit:     return Color(red: 0.06, green: 0.06, blue: 0.08).opacity(0.85)
        }
    }

    private var bootColor: Color {
        if !hasFins && suit == nil { return SkinPalette.skin }
        return Color.black.opacity(0.78)
    }

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        // Paint order: far limbs → torso → near limbs
        drawFarArm(ctx, render: render)
        drawFarLeg(ctx, render: render)
        drawTorso(ctx, render: render)
        drawNearArm(ctx, render: render)
        drawNearLeg(ctx, render: render)
    }

    // MARK: Torso

    private func drawTorso(_ ctx: GraphicsContext, render: DiverRenderContext) {
        // Main torso shape
        ctx.fill(
            Path(roundedRect: CGRect(x: -42, y: -13, width: 82, height: 26), cornerRadius: 10),
            with: .color(torsoColor)
        )

        if suit == nil {
            // Naked: swim trunks + bikini top
            drawSwimwear(ctx)
        } else {
            // Suit detail varies by tier
            drawSuitDetails(ctx, render: render)
        }
    }

    private func drawSwimwear(_ ctx: GraphicsContext) {
        let trunkColor = Color(red: 0.15, green: 0.45, blue: 0.70)
        // Swim trunks (lower torso / hip area)
        ctx.fill(
            Path(roundedRect: CGRect(x: 15, y: -13, width: 27, height: 26), cornerRadius: 5),
            with: .color(trunkColor)
        )
        // Waistband
        ctx.fill(
            Path(roundedRect: CGRect(x: 15, y: -13, width: 27, height: 26), cornerRadius: 2),
            with: .color(trunkColor.opacity(0.7))
        )
        // Bikini top strap across upper chest
        let bikiniColor = Color(red: 0.85, green: 0.25, blue: 0.35)
        ctx.fill(
            Path(roundedRect: CGRect(x: -38, y: -2, width: 24, height: 16), cornerRadius: 3),
            with: .color(bikiniColor)
        )
        // Second strap line
        var strap = Path()
        strap.move(to: CGPoint(x: -38, y: 2))
        strap.addLine(to: CGPoint(x: -38, y: -10))
        ctx.stroke(strap, with: .color(bikiniColor.opacity(0.7)),
                   style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
    }

    private func drawSuitDetails(_ ctx: GraphicsContext, render: DiverRenderContext) {
        switch suit {
        case .wetsuit3mm:
            // Minimal accent stripe
            ctx.fill(
                Path(roundedRect: CGRect(x: -40, y: -11, width: 80, height: 3), cornerRadius: 1),
                with: .color(Color.white.opacity(0.15))
            )
        case .wetsuit5mm:
            // Shoulder reinforcement panel
            ctx.fill(
                Path(roundedRect: CGRect(x: -40, y: -11, width: 46, height: 22), cornerRadius: 8),
                with: .color(torsoAccent)
            )
        case .wetsuit7mm:
            // Shoulder reinforcement + knee/elbow patches implied by accent
            ctx.fill(
                Path(roundedRect: CGRect(x: -40, y: -11, width: 46, height: 22), cornerRadius: 8),
                with: .color(torsoAccent)
            )
            // Reinforcement patch on chest
            ctx.fill(
                Path(roundedRect: CGRect(x: -30, y: -6, width: 18, height: 12), cornerRadius: 3),
                with: .color(Color(red: 0.25, green: 0.27, blue: 0.32).opacity(0.5))
            )
        case .drysuit:
            // Front zip line
            var zipLine = Path()
            zipLine.move(to: CGPoint(x: -20, y: -13))
            zipLine.addLine(to: CGPoint(x: -20, y: 13))
            ctx.stroke(zipLine, with: .color(Color(red: 0.70, green: 0.65, blue: 0.20).opacity(0.7)),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            // Wrist seal ring (visual at shoulder edges)
            ctx.fill(
                Path(roundedRect: CGRect(x: -42, y: -13, width: 6, height: 26), cornerRadius: 3),
                with: .color(Color(red: 0.60, green: 0.55, blue: 0.15).opacity(0.4))
            )
            // Reflective strip
            ctx.fill(
                Path(roundedRect: CGRect(x: -40, y: 8, width: 80, height: 2), cornerRadius: 1),
                with: .color(Color.white.opacity(0.25))
            )
        case nil:
            break
        }

        // BCD panels only if scuba gear is equipped
        if hasScubaGear {
            ctx.fill(
                Path(roundedRect: CGRect(x: -40, y: -11, width: 46, height: 22), cornerRadius: 8),
                with: .color(Color(red: 0.14, green: 0.26, blue: 0.46).opacity(0.38))
            )
            // Shoulder strap band
            ctx.fill(
                Path(roundedRect: CGRect(x: -38, y: -13, width: 9, height: 26), cornerRadius: 4),
                with: .color(Color(red: 0.14, green: 0.26, blue: 0.46).opacity(0.52))
            )
            // Tank strap
            var tankStrap = Path()
            tankStrap.move(to: CGPoint(x: -42, y: -7))
            tankStrap.addLine(to: CGPoint(x: 40, y: -7))
            ctx.stroke(tankStrap, with: .color(Color(red: 0.14, green: 0.26, blue: 0.46).opacity(0.38)), lineWidth: 2.5)
        }
    }

    // MARK: Arms

    private func renderArm(_ ctx: GraphicsContext, shoulder: CGPoint,
                           baseAngle: Double, elbowBend: Double,
                           scale: CGFloat, alpha: Double) {
        let col = limbColor.opacity(alpha)
        var ac = ctx
        ac.translateBy(x: shoulder.x, y: shoulder.y)
        ac.scaleBy(x: scale, y: scale)
        ac.rotate(by: .degrees(-90 + baseAngle))

        // Upper arm
        ac.fill(Path(roundedRect: CGRect(x: -4.5, y: 0, width: 9, height: 26), cornerRadius: 4),
                with: .color(col))
        // Elbow cap
        ac.fill(Path(ellipseIn: CGRect(x: -4.5, y: 22, width: 9, height: 9)),
                with: .color(jointColor.opacity(alpha)))

        // Forearm (pivots at elbow)
        var fc = ac
        fc.translateBy(x: 0, y: 27)
        fc.rotate(by: .degrees(elbowBend))
        fc.fill(Path(roundedRect: CGRect(x: -4, y: 0, width: 8, height: 22), cornerRadius: 3),
                with: .color(col))
        // Glove / bare hand
        fc.fill(Path(roundedRect: CGRect(x: -5, y: 20, width: 10, height: 9), cornerRadius: 4),
                with: .color(gloveColor.opacity(alpha)))
        if suit != nil {
            fc.fill(Path(ellipseIn: CGRect(x: -2, y: 20, width: 5, height: 4)),
                    with: .color(Color.white.opacity(0.12 * alpha)))
        }
    }

    private func drawNearArm(_ ctx: GraphicsContext, render: DiverRenderContext) {
        if render.holdingDPV {
            // Arms extended forward toward the DPV, slightly below the face.
            // baseAngle -45° rotates the arm toward the head (-x direction).
            // Straight elbow for a rigid grip on the DPV handle.
            renderArm(ctx, shoulder: render.nearShoulder,
                      baseAngle: 115, elbowBend: 40,
                      scale: 1.00, alpha: 1.00)
        } else {
            renderArm(ctx, shoulder: render.nearShoulder,
                      baseAngle: 25.0 + render.nearArmSwing, elbowBend: -14,
                      scale: 1.00, alpha: 1.00)
        }
    }

    private func drawFarArm(_ ctx: GraphicsContext, render: DiverRenderContext) {
        if render.holdingDPV {
            renderArm(ctx, shoulder: render.farShoulder,
                      baseAngle: 115, elbowBend: 40,
                      scale: 0.91, alpha: 0.75)
        } else {
            renderArm(ctx, shoulder: render.farShoulder,
                      baseAngle: 25.0 + render.farArmSwing, elbowBend: -11,
                      scale: 0.91, alpha: 0.75)
        }
    }

    // MARK: Legs (without fins — fins drawn by FinsRenderer)

    private func renderLeg(_ ctx: GraphicsContext, hip: CGPoint,
                           kickAngle: Double,
                           scale: CGFloat, alpha: Double) {
        var lc = ctx
        lc.translateBy(x: hip.x, y: hip.y)
        lc.scaleBy(x: scale, y: scale)
        lc.rotate(by: .degrees(-90.0 + kickAngle))

        // Thigh
        lc.fill(Path(roundedRect: CGRect(x: -5.5, y: 0, width: 11, height: 32), cornerRadius: 4),
                with: .color(limbColor.opacity(alpha)))

        if suit == nil {
            // Naked legs: show swim trunks on thigh
            let trunkColor = Color(red: 0.15, green: 0.45, blue: 0.70)
            lc.fill(Path(roundedRect: CGRect(x: -5.5, y: 0, width: 11, height: 14), cornerRadius: 4),
                    with: .color(trunkColor.opacity(alpha)))
        }

        // Kneecap
        lc.fill(Path(ellipseIn: CGRect(x: -5.5, y: 28, width: 11, height: 10)),
                with: .color(jointColor.opacity(alpha)))

        // 7mm / drysuit get knee patches
        if suit == .wetsuit7mm || suit == .drysuit {
            lc.fill(Path(roundedRect: CGRect(x: -6, y: 27, width: 12, height: 8), cornerRadius: 3),
                    with: .color(Color(red: 0.30, green: 0.30, blue: 0.34).opacity(0.5 * alpha)))
        }

        // Shin pivots at knee with 8° natural bend
        var kc = lc
        kc.translateBy(x: 0, y: 32)
        kc.rotate(by: .degrees(8))
        kc.fill(Path(roundedRect: CGRect(x: -5, y: 0, width: 10, height: 28), cornerRadius: 4),
                with: .color(limbColor.opacity(alpha)))
        // Boot / bare foot
        kc.fill(Path(roundedRect: CGRect(x: -6, y: 25, width: 12, height: 10), cornerRadius: 4),
                with: .color(bootColor.opacity(alpha)))
        if suit != nil || hasFins {
            kc.fill(Path(ellipseIn: CGRect(x: -3, y: 25, width: 6, height: 4)),
                    with: .color(Color.white.opacity(0.10 * alpha)))
        }
    }

    private func drawNearLeg(_ ctx: GraphicsContext, render: DiverRenderContext) {
        renderLeg(ctx, hip: render.nearHip, kickAngle: render.nearKick,
                  scale: 1.00, alpha: 1.00)
    }

    private func drawFarLeg(_ ctx: GraphicsContext, render: DiverRenderContext) {
        renderLeg(ctx, hip: render.farHip, kickAngle: render.farKick,
                  scale: 0.91, alpha: 0.7)
    }
}

// MARK: - Fins Renderer

/// Draws fins on both legs. Only instantiated when fins are equipped.
struct FinsGearRenderer: GearRenderer {
    let tier: FinsTier

    private var finColor: Color {
        switch tier {
        case .basic:    return Color(red: 1.00, green: 0.44, blue: 0.10)   // Orange
        case .advanced: return Color(red: 0.20, green: 0.70, blue: 0.40)   // Green
        case .pro:      return Color(red: 0.12, green: 0.12, blue: 0.14)   // Carbon black
        }
    }

    private var finEdge: Color {
        switch tier {
        case .basic:    return Color(red: 0.70, green: 0.27, blue: 0.04)
        case .advanced: return Color(red: 0.10, green: 0.45, blue: 0.22)
        case .pro:      return Color(red: 0.25, green: 0.25, blue: 0.28)
        }
    }

    /// Fin blade length scale (bigger = more powerful looking).
    private var bladeScale: CGFloat {
        switch tier {
        case .basic:    return 0.85
        case .advanced: return 1.00
        case .pro:      return 1.15
        }
    }

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        drawFin(ctx, hip: render.farHip, kickAngle: render.farKick, finFlex: render.farFlex,
                scale: 0.91, alpha: 0.7)
        drawFin(ctx, hip: render.nearHip, kickAngle: render.nearKick, finFlex: render.nearFlex,
                scale: 1.00, alpha: 1.00)
    }

    private func drawFin(_ ctx: GraphicsContext, hip: CGPoint,
                         kickAngle: Double, finFlex: Double,
                         scale: CGFloat, alpha: Double) {
        var lc = ctx
        lc.translateBy(x: hip.x, y: hip.y)
        lc.scaleBy(x: scale, y: scale)
        lc.rotate(by: .degrees(-90.0 + kickAngle))

        // Navigate down the leg to the ankle
        var kc = lc
        kc.translateBy(x: 0, y: 32) // thigh
        kc.rotate(by: .degrees(8))   // knee bend
        // Fin blade at ankle
        var fc = kc
        fc.translateBy(x: 0, y: 28)  // shin length

        let blade = finBladePath(flex: finFlex, scale: bladeScale)
        fc.fill(blade, with: .color(finEdge.opacity(alpha * 0.50)))
        var fc2 = fc
        fc2.translateBy(x: -1, y: -1)
        fc2.fill(blade, with: .color(finColor.opacity(alpha)))
        fc2.stroke(blade, with: .color(Color.black.opacity(0.16 * alpha)), lineWidth: 0.9)

        // Pro fins: carbon fiber texture lines
        if tier == .pro {
            let tipX = CGFloat(finFlex) * 25.0 * bladeScale
            for i in stride(from: 10.0, to: 50.0 * bladeScale, by: 8.0) {
                let progress = CGFloat(i) / (50.0 * bladeScale)
                let xOff = tipX * progress
                var line = Path()
                line.move(to: CGPoint(x: -4 + xOff, y: i))
                line.addLine(to: CGPoint(x: 16 + xOff, y: i))
                fc2.stroke(line, with: .color(Color.white.opacity(0.08 * alpha)), lineWidth: 0.5)
            }
        }

        // Advanced fins: split-fin notch
        if tier == .advanced {
            let tipY = 54.0 * bladeScale
            let tipX = CGFloat(finFlex) * 25.0 * bladeScale
            var notch = Path()
            notch.move(to: CGPoint(x: 8 + tipX * 0.7, y: tipY * 0.6))
            notch.addLine(to: CGPoint(x: 10 + tipX, y: tipY))
            notch.addLine(to: CGPoint(x: 6 + tipX * 0.7, y: tipY * 0.6))
            fc2.stroke(notch, with: .color(Color.black.opacity(0.25 * alpha)), lineWidth: 1.2)
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
}

// MARK: - Tank / Scuba Gear Renderer

/// Draws the scuba tank, valve, regulator hose, and BCD hardware.
/// Only instantiated when scuba gear is equipped.
struct TankGearRenderer: GearRenderer {
    let tier: ScubaGearTier
    let suitColor: Color  // Used for hose color to match suit

    private let cTank    = Color(red: 0.68, green: 0.74, blue: 0.83)
    private let cTankAcc = Color(red: 0.46, green: 0.52, blue: 0.61)

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        var tc = ctx
        tc.translateBy(x: render.tankCtr.x, y: render.tankCtr.y)

        switch tier {
        case .standard:
            drawSingleTank(tc)
        case .twinset:
            drawTwinTanks(tc)
        case .rebreather:
            return // Handled by RebreatherGearRenderer
        }

        // Regulator hose (from tank valve to head)
        drawRegulatorHose(tc)
    }

    private func drawSingleTank(_ tc: GraphicsContext) {
        // Main cylinder
        tc.fill(
            Path(roundedRect: CGRect(x: -22, y: -5, width: 44, height: 10), cornerRadius: 4),
            with: .color(cTank)
        )
        // Sheen
        tc.fill(
            Path(roundedRect: CGRect(x: -21, y: -5, width: 42, height: 3), cornerRadius: 1.5),
            with: .color(Color.white.opacity(0.22))
        )
        // Left end-cap (valve side)
        tc.fill(Path(ellipseIn: CGRect(x: -25, y: -5, width: 6, height: 10)), with: .color(cTankAcc))
        // Right end-cap
        tc.fill(Path(ellipseIn: CGRect(x: 19, y: -5, width: 6, height: 10)), with: .color(cTankAcc))
        // Valve knob
        tc.fill(Path(roundedRect: CGRect(x: -30, y: -3, width: 6, height: 6), cornerRadius: 1),
                with: .color(cTank))
    }

    private func drawTwinTanks(_ tc: GraphicsContext) {
        // Back tank (slightly offset up)
        tc.fill(
            Path(roundedRect: CGRect(x: -22, y: -9, width: 44, height: 9), cornerRadius: 4),
            with: .color(cTank.opacity(0.7))
        )
        tc.fill(
            Path(roundedRect: CGRect(x: -21, y: -9, width: 42, height: 2.5), cornerRadius: 1),
            with: .color(Color.white.opacity(0.15))
        )
        tc.fill(Path(ellipseIn: CGRect(x: -25, y: -9, width: 6, height: 9)), with: .color(cTankAcc.opacity(0.7)))
        tc.fill(Path(ellipseIn: CGRect(x: 19, y: -9, width: 6, height: 9)), with: .color(cTankAcc.opacity(0.7)))

        // Front tank
        tc.fill(
            Path(roundedRect: CGRect(x: -22, y: -1, width: 44, height: 10), cornerRadius: 4),
            with: .color(cTank)
        )
        tc.fill(
            Path(roundedRect: CGRect(x: -21, y: -1, width: 42, height: 3), cornerRadius: 1.5),
            with: .color(Color.white.opacity(0.22))
        )
        tc.fill(Path(ellipseIn: CGRect(x: -25, y: -1, width: 6, height: 10)), with: .color(cTankAcc))
        tc.fill(Path(ellipseIn: CGRect(x: 19, y: -1, width: 6, height: 10)), with: .color(cTankAcc))

        // Manifold crossbar between tanks
        tc.fill(
            Path(roundedRect: CGRect(x: -10, y: -10, width: 20, height: 3), cornerRadius: 1),
            with: .color(cTankAcc)
        )

        // Valve knob
        tc.fill(Path(roundedRect: CGRect(x: -30, y: -2, width: 6, height: 6), cornerRadius: 1),
                with: .color(cTank))
    }

    private func drawRegulatorHose(_ tc: GraphicsContext) {
        var hose = Path()
        hose.move(to: CGPoint(x: -25, y: 0))
        hose.addCurve(
            to:       CGPoint(x: -75, y: 29),
            control1: CGPoint(x: -30, y: -22),
            control2: CGPoint(x: -68, y: 6)
        )
        tc.stroke(hose, with: .color(suitColor.opacity(0.88)),
                  style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
    }
}

// MARK: - Rebreather Renderer

/// Draws a closed-circuit rebreather on the diver's back.
/// The unit is a yellow box housing the CO₂ scrubber with two small black
/// tanks mounted on top. Two thick corrugated hoses loop from the unit
/// around the shoulders to the diver's mouthpiece.
struct RebreatherGearRenderer: GearRenderer {

    // Colors
    private let cBox        = Color(red: 0.88, green: 0.78, blue: 0.15)  // Yellow housing
    private let cBoxDark    = Color(red: 0.68, green: 0.58, blue: 0.08)  // Shadow / edge
    private let cBoxLight   = Color(red: 1.00, green: 0.94, blue: 0.50)  // Highlight
    private let cTank       = Color(red: 0.10, green: 0.10, blue: 0.12)  // Small black tanks
    private let cTankCap    = Color(red: 0.22, green: 0.22, blue: 0.26)  // Tank end-caps
    private let cHose       = Color(red: 0.14, green: 0.14, blue: 0.16)  // Breathing hoses
    private let cHoseRib    = Color(red: 0.24, green: 0.24, blue: 0.28)  // Corrugation ribs

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        var tc = ctx
        tc.translateBy(x: render.tankCtr.x, y: render.tankCtr.y)

        // --- Main yellow housing box ---
        let boxW: CGFloat = 38
        let boxH: CGFloat = 18
        tc.fill(
            Path(roundedRect: CGRect(x: -boxW / 2, y: -boxH / 2, width: boxW, height: boxH),
                 cornerRadius: 4),
            with: .color(cBox)
        )
        // Top highlight strip
        tc.fill(
            Path(roundedRect: CGRect(x: -boxW / 2 + 2, y: -boxH / 2, width: boxW - 4, height: 4),
                 cornerRadius: 2),
            with: .color(cBoxLight.opacity(0.45))
        )
        // Bottom shadow strip
        tc.fill(
            Path(roundedRect: CGRect(x: -boxW / 2 + 2, y: boxH / 2 - 4, width: boxW - 4, height: 4),
                 cornerRadius: 2),
            with: .color(cBoxDark.opacity(0.40))
        )
        // Scrubber canister detail (dark rectangle inside box)
        tc.fill(
            Path(roundedRect: CGRect(x: -8, y: -boxH / 2 + 3, width: 16, height: boxH - 6),
                 cornerRadius: 2),
            with: .color(cBoxDark.opacity(0.25))
        )

        // --- Two small black tanks sitting on top of the box (behind diver's back = -y) ---
        let tankLen: CGFloat = 30
        let tankR: CGFloat = 4
        let tankSpacing: CGFloat = 5
        for offset in [-tankSpacing, tankSpacing] {
            // Tank cylinder
            tc.fill(
                Path(roundedRect: CGRect(x: -tankLen / 2, y: -boxH / 2 - tankR * 2 + offset,
                                         width: tankLen, height: tankR * 2),
                     cornerRadius: tankR),
                with: .color(cTank)
            )
            // Sheen
            tc.fill(
                Path(roundedRect: CGRect(x: -tankLen / 2 + 1, y: -boxH / 2 - tankR * 2 + offset,
                                         width: tankLen - 2, height: tankR * 0.8),
                     cornerRadius: 1),
                with: .color(Color.white.opacity(0.12))
            )
            // Left end-cap (valve side)
            tc.fill(
                Path(ellipseIn: CGRect(x: -tankLen / 2 - 2, y: -boxH / 2 - tankR * 2 + offset,
                                       width: 4, height: tankR * 2)),
                with: .color(cTankCap)
            )
            // Right end-cap
            tc.fill(
                Path(ellipseIn: CGRect(x: tankLen / 2 - 2, y: -boxH / 2 - tankR * 2 + offset,
                                       width: 4, height: tankR * 2)),
                with: .color(cTankCap)
            )
        }

        // --- Manifold crossbar between the two small tanks ---
        tc.fill(
            Path(roundedRect: CGRect(x: -6, y: -boxH / 2 - tankR * 2 - tankSpacing,
                                     width: 12, height: tankSpacing * 2 + tankR * 2),
                 cornerRadius: 1.5),
            with: .color(cTankCap.opacity(0.6))
        )

        // --- Breathing hoses (from box top, looping forward to the mouthpiece) ---
        drawBreathingHoses(tc, render: render)
    }

    private func drawBreathingHoses(_ tc: GraphicsContext, render: DiverRenderContext) {
        // The hoses originate from the left side (head-side) of the box
        // and curve around to the diver's mouth.
        // Head center is at render.headCtr relative to body origin;
        // we are translated to tankCtr, so offset = headCtr - tankCtr.
        let mouthX = render.headCtr.x - render.tankCtr.x - 14
        let mouthY = render.headCtr.y - render.tankCtr.y + 14

        let hoseWidth: CGFloat = 4.0

        // Inhale hose (upper path)
        var inhale = Path()
        inhale.move(to: CGPoint(x: -15, y: -4))
        inhale.addCurve(
            to:       CGPoint(x: mouthX, y: mouthY),
            control1: CGPoint(x: -30, y: -22),
            control2: CGPoint(x: mouthX + 10, y: mouthY - 20)
        )
        tc.stroke(inhale, with: .color(cHose),
                  style: StrokeStyle(lineWidth: hoseWidth, lineCap: .round))

        // Exhale hose (lower path)
        var exhale = Path()
        exhale.move(to: CGPoint(x: -15, y: 4))
        exhale.addCurve(
            to:       CGPoint(x: mouthX, y: mouthY + 4),
            control1: CGPoint(x: -32, y: 20),
            control2: CGPoint(x: mouthX + 8, y: mouthY + 18)
        )
        tc.stroke(exhale, with: .color(cHose),
                  style: StrokeStyle(lineWidth: hoseWidth, lineCap: .round))

        // Corrugation ribs on both hoses
        drawCorrugation(tc, along: inhale, hoseWidth: hoseWidth, segments: 8)
        drawCorrugation(tc, along: exhale, hoseWidth: hoseWidth, segments: 8)
    }

    /// Draws evenly-spaced corrugation ribs along a hose path for that
    /// characteristic accordion-tube look.
    private func drawCorrugation(_ tc: GraphicsContext, along path: Path,
                                 hoseWidth: CGFloat, segments: Int) {
        let bounds = path.boundingRect
        guard !bounds.isEmpty else { return }

        // Sample points along the path by trimming
        for i in 1..<segments {
            let frac = CGFloat(i) / CGFloat(segments)
            let trimmed = path.trimmedPath(from: 0, to: frac)
            let end = trimmed.boundingRect
            let pt = CGPoint(x: end.maxX, y: end.midY)

            var rib = Path()
            rib.move(to: CGPoint(x: pt.x - 1, y: pt.y - hoseWidth * 0.6))
            rib.addLine(to: CGPoint(x: pt.x - 1, y: pt.y + hoseWidth * 0.6))
            tc.stroke(rib, with: .color(cHoseRib.opacity(0.5)), lineWidth: 1.0)
        }
    }
}

// MARK: - Head Renderer

/// Draws the head: either bare (with hair) + mask, or hooded + mask + regulator.
struct HeadGearRenderer: GearRenderer {
    let suit: SuitTier?
    let hasScubaGear: Bool

    private let cMask    = Color(red: 0.04, green: 0.04, blue: 0.06)
    private let cLens    = Color(red: 0.28, green: 0.78, blue: 0.92).opacity(0.55)
    private let cSpec    = Color.white.opacity(0.32)
    private let cReg     = Color(red: 0.18, green: 0.20, blue: 0.24)

    /// Hood color matches suit; nil = bare head with hair.
    private var headColor: Color {
        switch suit {
        case nil:          return SkinPalette.skin
        case .wetsuit3mm:  return Color(red: 0.20, green: 0.55, blue: 0.80)
        case .wetsuit5mm:  return Color(red: 0.15, green: 0.38, blue: 0.62)
        case .wetsuit7mm:  return Color(red: 0.10, green: 0.12, blue: 0.14)
        case .drysuit:     return Color(red: 0.22, green: 0.22, blue: 0.24)
        }
    }

    private var headOutline: Color {
        switch suit {
        case nil:          return SkinPalette.skinShade.opacity(0.3)
        case .wetsuit3mm:  return Color(red: 0.12, green: 0.34, blue: 0.56).opacity(0.28)
        case .wetsuit5mm:  return Color(red: 0.10, green: 0.26, blue: 0.46).opacity(0.28)
        case .wetsuit7mm:  return Color(red: 0.22, green: 0.24, blue: 0.28).opacity(0.28)
        case .drysuit:     return Color(red: 0.40, green: 0.40, blue: 0.42).opacity(0.28)
        }
    }

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        var hc = ctx
        hc.translateBy(x: render.headCtr.x, y: render.headCtr.y)

        // Head shape (hood or bare)
        hc.fill(Path(ellipseIn: CGRect(x: -20, y: -20, width: 40, height: 40)),
                with: .color(headColor))
        hc.stroke(Path(ellipseIn: CGRect(x: -20, y: -20, width: 40, height: 40)),
                  with: .color(headOutline), lineWidth: 1.5)

        if suit == nil {
            // Bare head: draw some hair on top
            drawHair(hc)
        }

        // Mask (always present)
        drawMask(hc)

        // Regulator only with scuba gear
        if hasScubaGear {
            drawRegulator(hc)
        }
    }

    private func drawHair(_ hc: GraphicsContext) {
        let hairColor = Color(red: 0.30, green: 0.20, blue: 0.10)
        // Hair on top/back of head
        var hairPath = Path()
        hairPath.addArc(center: CGPoint(x: 0, y: 0), radius: 20,
                        startAngle: .degrees(-160), endAngle: .degrees(10), clockwise: false)
        hairPath.addArc(center: CGPoint(x: 0, y: 0), radius: 15,
                        startAngle: .degrees(10), endAngle: .degrees(-160), clockwise: true)
        hairPath.closeSubpath()
        hc.fill(hairPath, with: .color(hairColor))
    }

    private func drawMask(_ hc: GraphicsContext) {
        // Mask frame
        hc.fill(Path(roundedRect: CGRect(x: -21, y: -10, width: 20, height: 18), cornerRadius: 4),
                with: .color(cMask))
        // Lens
        hc.fill(Path(roundedRect: CGRect(x: -19, y: -8, width: 16, height: 14), cornerRadius: 3),
                with: .color(cLens))
        // Lens specular
        hc.fill(Path(roundedRect: CGRect(x: -17, y: -6, width: 7, height: 4), cornerRadius: 2),
                with: .color(cSpec))
        // Mask strap
        var strap = Path()
        strap.move(to: CGPoint(x: -1, y: -7))
        strap.addLine(to: CGPoint(x: 19, y: -5))
        strap.move(to: CGPoint(x: -1, y: 6))
        strap.addLine(to: CGPoint(x: 19, y: 4))
        hc.stroke(strap, with: .color(Color.black.opacity(0.50)),
                  style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    }

    private func drawRegulator(_ hc: GraphicsContext) {
        // Regulator second stage
        hc.fill(Path(ellipseIn: CGRect(x: -18, y: 8, width: 13, height: 11)),
                with: .color(cReg))
        // Purge button
        hc.fill(Path(ellipseIn: CGRect(x: -16, y: 10, width: 9, height: 7)),
                with: .color(Color(red: 0.38, green: 0.42, blue: 0.50)))
        // Mouthpiece stem
        hc.fill(Path(roundedRect: CGRect(x: -14, y: 18, width: 8, height: 6), cornerRadius: 2),
                with: .color(Color.black.opacity(0.78)))
        // Exhaust port vents
        hc.fill(Path(roundedRect: CGRect(x: -22, y: 11, width: 5, height: 4), cornerRadius: 1),
                with: .color(cReg.opacity(0.75)))
    }
}

// MARK: - Mesh Bag Renderer

/// Draws a mesh collection bag clipped to the diver's near hip.
/// The bag is a rounded pouch with a net-like crosshatch pattern.
/// Size scales with tier (small → medium → large).
struct MeshBagGearRenderer: GearRenderer {
    let tier: MeshBagTier

    // Bag body size scaling per tier
    private var bagWidth: CGFloat {
        switch tier {
        case .small:  return 16
        case .medium: return 20
        case .large:  return 26
        }
    }

    private var bagHeight: CGFloat {
        switch tier {
        case .small:  return 22
        case .medium: return 28
        case .large:  return 36
        }
    }

    private let cBag      = Color(red: 0.55, green: 0.58, blue: 0.52) // olive mesh
    private let cBagDark  = Color(red: 0.38, green: 0.40, blue: 0.35)
    private let cRing     = Color(red: 0.50, green: 0.50, blue: 0.54) // metal ring
    private let cClip     = Color(red: 0.30, green: 0.30, blue: 0.34)

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        let hip = render.nearHip

        var bc = ctx
        bc.translateBy(x: hip.x + 4, y: hip.y + 6)
        // Tilt the bag so it dangles slightly behind and below
        bc.rotate(by: .degrees(-25))

        // Clip / carabiner attaching bag to harness
        bc.fill(
            Path(roundedRect: CGRect(x: -3, y: -6, width: 6, height: 7), cornerRadius: 1.5),
            with: .color(cClip)
        )
        // Metal ring at top of bag
        bc.stroke(
            Path(ellipseIn: CGRect(x: -4, y: -3, width: 8, height: 6)),
            with: .color(cRing), lineWidth: 1.5
        )

        // Bag body — rounded trapezoid shape (wider at bottom)
        let topW = bagWidth * 0.7
        let botW = bagWidth
        var bagPath = Path()
        bagPath.move(to: CGPoint(x: -topW / 2, y: 2))
        bagPath.addLine(to: CGPoint(x: topW / 2, y: 2))
        bagPath.addQuadCurve(
            to: CGPoint(x: botW / 2, y: bagHeight - 4),
            control: CGPoint(x: topW / 2 + 3, y: bagHeight * 0.4)
        )
        bagPath.addQuadCurve(
            to: CGPoint(x: -botW / 2, y: bagHeight - 4),
            control: CGPoint(x: 0, y: bagHeight + 2)
        )
        bagPath.addQuadCurve(
            to: CGPoint(x: -topW / 2, y: 2),
            control: CGPoint(x: -topW / 2 - 3, y: bagHeight * 0.4)
        )
        bagPath.closeSubpath()

        // Fill bag body
        bc.fill(bagPath, with: .color(cBag.opacity(0.65)))
        bc.stroke(bagPath, with: .color(cBagDark.opacity(0.8)), lineWidth: 1.0)

        // Net/mesh crosshatch pattern inside the bag
        let meshSpacing: CGFloat = bagHeight > 30 ? 6 : 5
        // Horizontal mesh lines
        for yOff in stride(from: meshSpacing + 2, to: bagHeight - 5, by: meshSpacing) {
            // Width at this height (interpolate between top and bottom)
            let t = (yOff - 2) / (bagHeight - 6)
            let w = topW + (botW - topW) * t
            var line = Path()
            line.move(to: CGPoint(x: -w / 2 + 1, y: yOff))
            line.addLine(to: CGPoint(x: w / 2 - 1, y: yOff))
            bc.stroke(line, with: .color(cBagDark.opacity(0.35)), lineWidth: 0.6)
        }
        // Diagonal mesh lines (\ direction)
        for xOff in stride(from: -botW / 2, through: botW / 2, by: meshSpacing) {
            var line = Path()
            line.move(to: CGPoint(x: xOff, y: 4))
            line.addLine(to: CGPoint(x: xOff + bagHeight * 0.25, y: bagHeight - 5))
            // Clip to bag shape by using the context clip
            bc.stroke(line, with: .color(cBagDark.opacity(0.25)), lineWidth: 0.5)
        }
        // Diagonal mesh lines (/ direction)
        for xOff in stride(from: -botW / 2, through: botW / 2, by: meshSpacing) {
            var line = Path()
            line.move(to: CGPoint(x: xOff, y: 4))
            line.addLine(to: CGPoint(x: xOff - bagHeight * 0.25, y: bagHeight - 5))
            bc.stroke(line, with: .color(cBagDark.opacity(0.25)), lineWidth: 0.5)
        }

        // Drawstring / cinch cord at the opening
        var drawstring = Path()
        drawstring.move(to: CGPoint(x: -topW / 2 - 1, y: 3))
        drawstring.addQuadCurve(
            to: CGPoint(x: topW / 2 + 1, y: 3),
            control: CGPoint(x: 0, y: 5)
        )
        bc.stroke(drawstring, with: .color(cBagDark.opacity(0.7)),
                  style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
    }
}

// MARK: - Lift Bag Renderer

/// Draws a lift bag attached by ropes to the diver's near hip.
/// The bag resembles an inflated balloon with the lower third open,
/// and always points upward regardless of body tilt.
struct LiftBagGearRenderer: GearRenderer {
    let tier: LiftBagTier

    private var bagColor: Color {
        switch tier {
        case .medium: return Color(red: 0.95, green: 0.80, blue: 0.10)   // Yellow
        case .large:  return Color(red: 0.85, green: 0.15, blue: 0.12)   // Red
        }
    }

    private var bagHighlight: Color {
        switch tier {
        case .medium: return Color(red: 1.00, green: 0.92, blue: 0.50)
        case .large:  return Color(red: 1.00, green: 0.45, blue: 0.40)
        }
    }

    private var bagShadow: Color {
        switch tier {
        case .medium: return Color(red: 0.70, green: 0.58, blue: 0.05)
        case .large:  return Color(red: 0.58, green: 0.08, blue: 0.06)
        }
    }

    /// Bag envelope width.
    private var bagWidth: CGFloat {
        switch tier {
        case .medium: return 28
        case .large:  return 36
        }
    }

    /// Bag envelope height (the inflated portion above the opening).
    private var bagHeight: CGFloat {
        switch tier {
        case .medium: return 34
        case .large:  return 44
        }
    }

    /// Rope length from hip to the bottom opening of the bag.
    private var ropeLength: CGFloat {
        switch tier {
        case .medium: return 28
        case .large:  return 32
        }
    }

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        guard render.submersed else { return }

        let hip = render.nearHip

        var lc = ctx
        lc.translateBy(x: hip.x + 4, y: hip.y)

        // Counter-rotate so the bag always points upward.
        // The parent context has been rotated by bodyTilt degrees,
        // and when facing right (bodyTilt 90–270) the Y-axis is flipped.
        // We must undo both transformations to get world-vertical.
        let isFlipped = render.bodyTilt > 90.0 && render.bodyTilt < 270.0
        if isFlipped {
            // Undo the Y-flip first, then counter-rotate
            lc.scaleBy(x: 1.0, y: -1.0)
            lc.rotate(by: .degrees(-render.bodyTilt))
        } else {
            lc.rotate(by: .degrees(-render.bodyTilt))
        }

        // The bag floats above the hip: ropes go up, bag sits on top.
        // In counter-rotated (world) space, "up" is −y.
        let openingY: CGFloat = -ropeLength       // bottom of the balloon opening
        let topY: CGFloat = openingY - bagHeight   // top of the balloon

        // — Ropes from hip to bag opening —
        let ropeColor = Color(red: 0.35, green: 0.35, blue: 0.30)
        // Left rope
        var leftRope = Path()
        leftRope.move(to: CGPoint(x: -3, y: 0))
        leftRope.addQuadCurve(
            to: CGPoint(x: -bagWidth * 0.35, y: openingY),
            control: CGPoint(x: -bagWidth * 0.25, y: -ropeLength * 0.4)
        )
        lc.stroke(leftRope, with: .color(ropeColor.opacity(0.8)),
                  style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        // Right rope
        var rightRope = Path()
        rightRope.move(to: CGPoint(x: 3, y: 0))
        rightRope.addQuadCurve(
            to: CGPoint(x: bagWidth * 0.35, y: openingY),
            control: CGPoint(x: bagWidth * 0.25, y: -ropeLength * 0.4)
        )
        lc.stroke(rightRope, with: .color(ropeColor.opacity(0.8)),
                  style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

        // — Bag envelope (upper 2/3 of a sphere, open at bottom) —
        // Drawn as a path: arc from left opening to right opening across the top.
        let hw = bagWidth / 2  // half-width at the opening

        var envelope = Path()
        // Start at the left edge of the opening
        envelope.move(to: CGPoint(x: -hw, y: openingY))
        // Left side bulge curving up
        envelope.addCurve(
            to: CGPoint(x: 0, y: topY),
            control1: CGPoint(x: -hw - 4, y: openingY - bagHeight * 0.45),
            control2: CGPoint(x: -hw * 0.5, y: topY - 2)
        )
        // Top right side curving down to the right opening edge
        envelope.addCurve(
            to: CGPoint(x: hw, y: openingY),
            control1: CGPoint(x: hw * 0.5, y: topY - 2),
            control2: CGPoint(x: hw + 4, y: openingY - bagHeight * 0.45)
        )
        // Don't close — the bottom is open

        // Fill the bag with gradient-like layering
        var filled = envelope
        filled.closeSubpath()
        lc.fill(filled, with: .color(bagColor))

        // Highlight on the left (light source)
        var hlPath = Path()
        hlPath.move(to: CGPoint(x: -hw + 3, y: openingY + 2))
        hlPath.addCurve(
            to: CGPoint(x: -2, y: topY + 4),
            control1: CGPoint(x: -hw, y: openingY - bagHeight * 0.35),
            control2: CGPoint(x: -hw * 0.4, y: topY + 2)
        )
        hlPath.addLine(to: CGPoint(x: -hw * 0.3, y: openingY - bagHeight * 0.3))
        hlPath.closeSubpath()
        lc.fill(hlPath, with: .color(bagHighlight.opacity(0.35)))

        // Shadow on the right
        var shPath = Path()
        shPath.move(to: CGPoint(x: hw - 3, y: openingY + 2))
        shPath.addCurve(
            to: CGPoint(x: 4, y: topY + 6),
            control1: CGPoint(x: hw, y: openingY - bagHeight * 0.3),
            control2: CGPoint(x: hw * 0.5, y: topY + 3)
        )
        shPath.addLine(to: CGPoint(x: hw * 0.3, y: openingY - bagHeight * 0.25))
        shPath.closeSubpath()
        lc.fill(shPath, with: .color(bagShadow.opacity(0.30)))

        // Outline
        lc.stroke(envelope, with: .color(bagShadow.opacity(0.7)),
                  style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // Opening rim (thicker line at the bottom to show the cut-off)
        var rim = Path()
        rim.move(to: CGPoint(x: -hw, y: openingY))
        rim.addLine(to: CGPoint(x: hw, y: openingY))
        lc.stroke(rim, with: .color(bagShadow.opacity(0.6)),
                  style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

        // Vertical seam lines on the bag for realism
        let seamCount = tier == .large ? 4 : 3
        for i in 1..<seamCount {
            let frac = CGFloat(i) / CGFloat(seamCount)
            let sx = -hw + bagWidth * frac
            let seamTopY = topY + 3 + abs(sx) * 0.1  // slightly lower away from center
            var seam = Path()
            seam.move(to: CGPoint(x: sx * 0.8, y: seamTopY))
            seam.addQuadCurve(
                to: CGPoint(x: sx, y: openingY),
                control: CGPoint(x: sx * 0.95, y: openingY - bagHeight * 0.35)
            )
            lc.stroke(seam, with: .color(bagShadow.opacity(0.20)),
                      style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        }
    }
}

// MARK: - DPV Renderer

/// Draws a diver propulsion vehicle held in front of the diver's body.
/// When submerged, the DPV is held at arm's length in front of and slightly
/// below the face, with both arms extended toward it. When on the surface,
/// the DPV is not drawn (stowed).
///
/// Basic tier: compact single-thruster unit.
/// Advanced tier: larger dual-thruster unit with a shroud.
struct DPVGearRenderer: GearRenderer {
    let tier: DPVTier

    // Size scaling per tier
    private var bodyLength: CGFloat {
        switch tier {
        case .basic:    return 58
        case .advanced: return 74
        }
    }

    private var bodyHeight: CGFloat {
        switch tier {
        case .basic:    return 14
        case .advanced: return 18
        }
    }

    private var thrusterRadius: CGFloat {
        switch tier {
        case .basic:    return 6
        case .advanced: return 7
        }
    }

    private var hullColor: Color {
        switch tier {
        case .basic:    return Color(red: 0.30, green: 0.32, blue: 0.36)
        case .advanced: return Color(red: 0.12, green: 0.14, blue: 0.18)
        }
    }

    private var hullAccent: Color {
        switch tier {
        case .basic:    return Color(red: 0.90, green: 0.55, blue: 0.10) // orange accent
        case .advanced: return Color(red: 0.20, green: 0.65, blue: 0.90) // blue accent
        }
    }

    private var thrusterColor: Color {
        Color(red: 0.22, green: 0.22, blue: 0.26)
    }

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        // Only draw when submerged — on the surface the DPV is stowed.
        guard render.submersed else { return }

        // Position the DPV in front of the head, where the extended arms reach.
        // In body-local coords: head center is at ~(-61, 0).
        // The DPV sits ahead of the head and slightly below (toward belly = +y).
        let headX = render.headCtr.x
        var dc = ctx
        dc.translateBy(x: headX - 50, y: 50)
        // Rotate so the torpedo's long axis aligns with the body's -x direction
        // (pointing forward). +y in the DPV's frame extends toward the diver's head direction.
        dc.rotate(by: .degrees(-90))

        let hw = bodyHeight / 2

        // --- Main hull (torpedo body) ---
        let hullRect = CGRect(x: -hw, y: 0, width: bodyHeight, height: bodyLength)
        dc.fill(
            Path(roundedRect: hullRect, cornerRadius: hw),
            with: .color(hullColor)
        )

        // Hull sheen (top highlight)
        dc.fill(
            Path(roundedRect: CGRect(x: -hw + 1, y: 2, width: bodyHeight * 0.35, height: bodyLength - 4), cornerRadius: hw * 0.4),
            with: .color(Color.white.opacity(0.12))
        )

        // --- Accent stripe ---
        dc.fill(
            Path(roundedRect: CGRect(x: -hw + 2, y: bodyLength * 0.3, width: bodyHeight - 4, height: 3), cornerRadius: 1),
            with: .color(hullAccent.opacity(0.8))
        )

        // --- Nose cone (rounded tip) ---
        dc.fill(
            Path(ellipseIn: CGRect(x: -hw + 1, y: -3, width: bodyHeight - 2, height: 8)),
            with: .color(hullColor.opacity(0.9))
        )
        // Nose highlight
        dc.fill(
            Path(ellipseIn: CGRect(x: -hw + 3, y: -1, width: 4, height: 4)),
            with: .color(Color.white.opacity(0.18))
        )

        // --- Thruster(s) at the back ---
        let thrusterY = bodyLength - 2

        if tier == .advanced {
            // Dual thrusters
            let offset: CGFloat = hw * 0.48
            for xOff in [-offset, offset] {
                drawThruster(dc, x: xOff, y: thrusterY)
            }
            // Shroud connecting the two thrusters
            dc.fill(
                Path(roundedRect: CGRect(x: -hw - 1, y: thrusterY - 2, width: bodyHeight + 2, height: thrusterRadius * 2 + 4), cornerRadius: 3),
                with: .color(thrusterColor.opacity(0.6))
            )
            // Redraw thrusters on top of shroud
            for xOff in [-offset, offset] {
                drawThruster(dc, x: xOff, y: thrusterY)
            }
        } else {
            // Single thruster centered
            drawThruster(dc, x: 0, y: thrusterY)
        }

        // --- Handle grip bar ---
        let gripY = bodyLength * 0.18
        dc.fill(
            Path(roundedRect: CGRect(x: -hw - 3, y: gripY, width: bodyHeight + 6, height: 4), cornerRadius: 2),
            with: .color(Color(red: 0.25, green: 0.25, blue: 0.28))
        )
        // Grip texture
        for i in stride(from: CGFloat(-hw - 1), through: hw + 1, by: 3) {
            var tick = Path()
            tick.move(to: CGPoint(x: i, y: gripY))
            tick.addLine(to: CGPoint(x: i, y: gripY + 4))
            dc.stroke(tick, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5)
        }
    }

    private func drawThruster(_ ctx: GraphicsContext, x: CGFloat, y: CGFloat) {
        let r = thrusterRadius
        // Outer ring
        ctx.fill(
            Path(ellipseIn: CGRect(x: x - r, y: y, width: r * 2, height: r * 2)),
            with: .color(thrusterColor)
        )
        // Inner dark (propeller void)
        ctx.fill(
            Path(ellipseIn: CGRect(x: x - r + 2, y: y + 2, width: r * 2 - 4, height: r * 2 - 4)),
            with: .color(Color.black.opacity(0.5))
        )
        // Rim highlight
        ctx.stroke(
            Path(ellipseIn: CGRect(x: x - r, y: y, width: r * 2, height: r * 2)),
            with: .color(Color.white.opacity(0.12)), lineWidth: 0.8
        )
    }
}

// MARK: - Stage Tank Renderer

/// Draws stage tanks clipped to the diver's hip area.
///
/// Stage tanks are full-size cylinders carried alongside the body,
/// attached at the hip and tilted slightly to trail behind the diver.
/// Uses the same cylinder geometry as `TankGearRenderer.drawSingleTank`.
/// Near/far layering follows the same convention as limbs: the far tank
/// is drawn at reduced scale and opacity behind the body, the near tank
/// in front.
struct StageTankGearRenderer: GearRenderer {
    let tier: StageTankTier

    /// Tilt angle (degrees) that tips the stage tank valve-end toward the
    /// diver's back (−y direction), so the tank trails behind.
    static let danglingTilt: Double = -15

    private let cTank    = Color(red: 0.82, green: 0.72, blue: 0.20) // Yellow aluminum
    private let cTankAcc = Color(red: 0.60, green: 0.52, blue: 0.15)
    private let cClip    = Color(red: 0.30, green: 0.30, blue: 0.34)

    func draw(_ ctx: GraphicsContext, render: DiverRenderContext) {
        switch tier {
        case .single:
            drawStageTank(ctx, render: render, isFar: true)
        case .double:
            drawStageTank(ctx, render: render, isFar: true)
            drawStageTank(ctx, render: render, isFar: false)
        }
    }

    /// Draw a single stage tank. `isFar` controls the depth-plane treatment
    /// (reduced scale + opacity, like far-side limbs).
    func drawStageTank(_ ctx: GraphicsContext, render: DiverRenderContext, isFar: Bool) {
        let hip = isFar ? render.farHip : render.nearHip

//        let hipX = (render.nearHip.x + render.farHip.x) / 2
//        let hipY = (render.nearHip.y + render.farHip.y) / 2
        let scale: CGFloat = isFar ? 1.2 : 1.2
        let alpha: Double  = isFar ? 0.7  : 1.0
        let angle = isFar ? Self.danglingTilt - 25.0 : Self.danglingTilt

        var tc = ctx
        tc.translateBy(x: hip.x + 10.0, y: hip.y - 10.0)
        tc.scaleBy(x: scale, y: scale)
        // Tilt the tank so the valve end points slightly toward the diver's back
        tc.rotate(by: .degrees(angle))

        // Clip bolts (attach tank to harness waistband)
        tc.fill(
            Path(roundedRect: CGRect(x: -12, y: -8, width: 5, height: 3), cornerRadius: 1),
            with: .color(cClip.opacity(alpha))
        )
        tc.fill(
            Path(roundedRect: CGRect(x: 7, y: -8, width: 5, height: 3), cornerRadius: 1),
            with: .color(cClip.opacity(alpha))
        )

        // Main cylinder — same dimensions as the standard back-mounted tank
        tc.fill(
            Path(roundedRect: CGRect(x: -22, y: -5, width: 44, height: 10), cornerRadius: 4),
            with: .color(cTank.opacity(alpha))
        )
        // Sheen
        tc.fill(
            Path(roundedRect: CGRect(x: -21, y: -5, width: 42, height: 3), cornerRadius: 1.5),
            with: .color(Color.white.opacity(0.22 * alpha))
        )
        // Left end-cap (valve side)
        tc.fill(Path(ellipseIn: CGRect(x: -25, y: -5, width: 6, height: 10)),
                with: .color(cTankAcc.opacity(alpha)))
        // Right end-cap
        tc.fill(Path(ellipseIn: CGRect(x: 19, y: -5, width: 6, height: 10)),
                with: .color(cTankAcc.opacity(alpha)))
        // Valve knob
        tc.fill(Path(roundedRect: CGRect(x: -30, y: -3, width: 6, height: 6), cornerRadius: 1),
                with: .color(cTank.opacity(alpha)))

        // Bungee cord loop (elastic retainer typical of stage mounting)
        var bungee = Path()
        bungee.move(to: CGPoint(x: -10, y: -7))
        bungee.addQuadCurve(
            to: CGPoint(x: 10, y: -7),
            control: CGPoint(x: 0, y: -12)
        )
        tc.stroke(bungee, with: .color(Color.black.opacity(0.4 * alpha)),
                  style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }
}

// MARK: - Atmospheric Diving Suit Renderer

/// Draws a rigid atmospheric diving suit (ADS) enclosing the diver.
/// The suit is a hard shell with a viewport dome, arm/leg cylinders,
/// and thruster nozzles on the back. Tier affects color and size.
///
/// Split into three draw passes so `ScubaDiverView` can layer the body
/// between the hull (behind) and the viewport + thrusters (in front).
struct ADSGearRenderer {
    let tier: ADSTier

    // MARK: - Palette

    private var hullColor: Color {
        switch tier {
        case .jims:     return Color(red: 0.85, green: 0.85, blue: 0.82) // White/silver
        case .newtsuit: return Color(red: 0.78, green: 0.68, blue: 0.20) // Classic yellow
        case .exosuit:  return Color(red: 0.90, green: 0.90, blue: 0.90) // Near black
        }
    }

    private var hullShade: Color {
        switch tier {
        case .jims:     return Color(red: 0.58, green: 0.50, blue: 0.12)
        case .newtsuit: return Color(red: 0.60, green: 0.60, blue: 0.58)
        case .exosuit:  return Color(red: 0.65, green: 0.28, blue: 0.06)
        }
    }

    private var hullHighlight: Color {
        switch tier {
        case .jims:     return Color(red: 0.92, green: 0.84, blue: 0.40)
        case .newtsuit: return Color(red: 0.96, green: 0.96, blue: 0.94)
        case .exosuit:  return Color(red: 1.00, green: 0.60, blue: 0.30)
        }
    }

    private var jointColor: Color {
        Color(red: 0.35, green: 0.35, blue: 0.38)
    }

    private var viewportFrame: Color {
        Color(red: 0.22, green: 0.22, blue: 0.26)
    }

    private var viewportGlass: Color {
        Color(red: 0.25, green: 0.70, blue: 0.88).opacity(0.55)
    }

    private var thrusterMetal: Color {
        Color(red: 0.28, green: 0.28, blue: 0.32)
    }

    /// Hull width scales with tier (more advanced suits are bulkier).
    private var hullScale: CGFloat {
        switch tier {
        case .jims:     return 1.0
        case .newtsuit: return 1.08
        case .exosuit:  return 1.15
        }
    }

    // MARK: - Hull (drawn behind body)

    /// Draws the main suit hull — a rounded rectangular shell enclosing
    /// the torso and extending over the limbs as rigid cylindrical segments.
    func drawHull(_ ctx: GraphicsContext, render: DiverRenderContext) {
        let sc = hullScale

        // --- Main torso hull ---
        // Slightly wider and taller than the body's torso rect (-42..+40, -13..+13)
        let torsoRect = CGRect(x: -48 * sc, y: -18 * sc, width: 96 * sc, height: 36 * sc)
        ctx.fill(
            Path(roundedRect: torsoRect, cornerRadius: 14 * sc),
            with: .color(hullColor)
        )
        // Top highlight
        ctx.fill(
            Path(roundedRect: CGRect(x: torsoRect.minX + 3, y: torsoRect.minY + 2,
                                     width: torsoRect.width - 6, height: 6 * sc),
                 cornerRadius: 3),
            with: .color(hullHighlight.opacity(0.25))
        )
        // Outline
        ctx.stroke(
            Path(roundedRect: torsoRect, cornerRadius: 14 * sc),
            with: .color(hullShade.opacity(0.6)), lineWidth: 1.5
        )

        // --- Reinforcement seams ---
        // Horizontal seam across the chest
        var seam = Path()
        seam.move(to: CGPoint(x: torsoRect.minX + 8, y: 0))
        seam.addLine(to: CGPoint(x: torsoRect.maxX - 8, y: 0))
        ctx.stroke(seam, with: .color(hullShade.opacity(0.3)),
                   style: StrokeStyle(lineWidth: 1.0, lineCap: .round))

        // Vertical seam down the center
        var vSeam = Path()
        vSeam.move(to: CGPoint(x: 0, y: torsoRect.minY + 6))
        vSeam.addLine(to: CGPoint(x: 0, y: torsoRect.maxY - 6))
        ctx.stroke(vSeam, with: .color(hullShade.opacity(0.2)),
                   style: StrokeStyle(lineWidth: 0.8, lineCap: .round))

        // --- Arm cylinders ---
        drawArmCylinder(ctx, shoulder: render.nearShoulder,
                        armSwing: render.nearArmSwing, scale: 1.0, alpha: 1.0)
        drawArmCylinder(ctx, shoulder: render.farShoulder,
                        armSwing: render.farArmSwing, scale: 0.91, alpha: 0.7)

        // --- Leg cylinders ---
        drawLegCylinder(ctx, hip: render.nearHip,
                        kickAngle: render.nearKick, scale: 1.0, alpha: 1.0)
        drawLegCylinder(ctx, hip: render.farHip,
                        kickAngle: render.farKick, scale: 0.91, alpha: 0.7)

        // --- Life support pack on back ---
        let packRect = CGRect(x: -20 * sc, y: -28 * sc, width: 40 * sc, height: 14 * sc)
        ctx.fill(
            Path(roundedRect: packRect, cornerRadius: 5 * sc),
            with: .color(hullShade.opacity(0.85))
        )
        ctx.stroke(
            Path(roundedRect: packRect, cornerRadius: 5 * sc),
            with: .color(Color.black.opacity(0.3)), lineWidth: 1.0
        )
        // Vent grille on the pack
        for xOff in stride(from: packRect.minX + 5, to: packRect.maxX - 4, by: 4 * sc) {
            var vent = Path()
            vent.move(to: CGPoint(x: xOff, y: packRect.minY + 3))
            vent.addLine(to: CGPoint(x: xOff, y: packRect.maxY - 3))
            ctx.stroke(vent, with: .color(Color.black.opacity(0.2)), lineWidth: 0.6)
        }
    }

    private func drawArmCylinder(_ ctx: GraphicsContext, shoulder: CGPoint,
                                  armSwing: Double, scale: CGFloat, alpha: Double) {
        let sc = hullScale
        var ac = ctx
        ac.translateBy(x: shoulder.x, y: shoulder.y)
        ac.scaleBy(x: scale, y: scale)
        ac.rotate(by: .degrees(-90 + 25 + armSwing))

        // Rotary joint at shoulder
        ac.fill(Path(ellipseIn: CGRect(x: -8 * sc, y: -4, width: 16 * sc, height: 8)),
                with: .color(jointColor.opacity(alpha)))

        // Upper arm cylinder
        let uaRect = CGRect(x: -7 * sc, y: 2, width: 14 * sc, height: 28)
        ac.fill(Path(roundedRect: uaRect, cornerRadius: 5 * sc),
                with: .color(hullColor.opacity(alpha)))
        ac.stroke(Path(roundedRect: uaRect, cornerRadius: 5 * sc),
                  with: .color(hullShade.opacity(0.4 * alpha)), lineWidth: 1.0)

        // Elbow joint
        ac.fill(Path(ellipseIn: CGRect(x: -7 * sc, y: 28, width: 14 * sc, height: 10)),
                with: .color(jointColor.opacity(alpha)))

        // Forearm cylinder
        var fc = ac
        fc.translateBy(x: 0, y: 32)
        let faRect = CGRect(x: -6 * sc, y: 0, width: 12 * sc, height: 24)
        fc.fill(Path(roundedRect: faRect, cornerRadius: 4 * sc),
                with: .color(hullColor.opacity(alpha)))
        fc.stroke(Path(roundedRect: faRect, cornerRadius: 4 * sc),
                  with: .color(hullShade.opacity(0.4 * alpha)), lineWidth: 1.0)

        // Manipulator claw at the end
        let clawColor = Color(red: 0.30, green: 0.30, blue: 0.34)
        fc.fill(Path(roundedRect: CGRect(x: -7 * sc, y: 22, width: 14 * sc, height: 10), cornerRadius: 3),
                with: .color(clawColor.opacity(alpha)))
        // Claw fingers
        var finger1 = Path()
        finger1.move(to: CGPoint(x: -4 * sc, y: 30))
        finger1.addLine(to: CGPoint(x: -6 * sc, y: 36))
        var finger2 = Path()
        finger2.move(to: CGPoint(x: 4 * sc, y: 30))
        finger2.addLine(to: CGPoint(x: 6 * sc, y: 36))
        fc.stroke(finger1, with: .color(clawColor.opacity(alpha)),
                  style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        fc.stroke(finger2, with: .color(clawColor.opacity(alpha)),
                  style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    private func drawLegCylinder(_ ctx: GraphicsContext, hip: CGPoint,
                                  kickAngle: Double, scale: CGFloat, alpha: Double) {
        let sc = hullScale
        var lc = ctx
        lc.translateBy(x: hip.x, y: hip.y)
        lc.scaleBy(x: scale, y: scale)
        lc.rotate(by: .degrees(-90 + kickAngle))

        // Rotary joint at hip
        lc.fill(Path(ellipseIn: CGRect(x: -9 * sc, y: -4, width: 18 * sc, height: 8)),
                with: .color(jointColor.opacity(alpha)))

        // Thigh cylinder
        let thighRect = CGRect(x: -8 * sc, y: 2, width: 16 * sc, height: 34)
        lc.fill(Path(roundedRect: thighRect, cornerRadius: 6 * sc),
                with: .color(hullColor.opacity(alpha)))
        lc.stroke(Path(roundedRect: thighRect, cornerRadius: 6 * sc),
                  with: .color(hullShade.opacity(0.4 * alpha)), lineWidth: 1.0)

        // Knee joint
        lc.fill(Path(ellipseIn: CGRect(x: -8 * sc, y: 32, width: 16 * sc, height: 10)),
                with: .color(jointColor.opacity(alpha)))

        // Shin cylinder
        var kc = lc
        kc.translateBy(x: 0, y: 38)
        let shinRect = CGRect(x: -7 * sc, y: 0, width: 14 * sc, height: 30)
        kc.fill(Path(roundedRect: shinRect, cornerRadius: 5 * sc),
                with: .color(hullColor.opacity(alpha)))
        kc.stroke(Path(roundedRect: shinRect, cornerRadius: 5 * sc),
                  with: .color(hullShade.opacity(0.4 * alpha)), lineWidth: 1.0)

        // Foot plate (flat bottom)
        kc.fill(Path(roundedRect: CGRect(x: -9 * sc, y: 28, width: 18 * sc, height: 8), cornerRadius: 3),
                with: .color(hullShade.opacity(alpha)))
    }

    // MARK: - Viewport (drawn in front of body, replaces head rendering)

    /// Draws the dome viewport where the diver's face would be visible.
    func drawViewport(_ ctx: GraphicsContext, render: DiverRenderContext) {
        let sc = hullScale
        var hc = ctx
        hc.translateBy(x: render.headCtr.x, y: render.headCtr.y)

        // Helmet dome (larger than the normal head)
        let domeR: CGFloat = 26 * sc
        let domeRect = CGRect(x: -domeR, y: -domeR, width: domeR * 2, height: domeR * 2)
        hc.fill(Path(ellipseIn: domeRect), with: .color(hullColor))
        hc.stroke(Path(ellipseIn: domeRect), with: .color(hullShade.opacity(0.6)), lineWidth: 1.5)

        // Viewport glass (front-facing window)
        let vpRect = CGRect(x: -domeR - 2, y: -12 * sc, width: 18 * sc, height: 24 * sc)
        hc.fill(Path(roundedRect: vpRect, cornerRadius: 6 * sc),
                with: .color(viewportFrame))
        let glassRect = CGRect(x: vpRect.minX + 2, y: vpRect.minY + 2,
                               width: vpRect.width - 4, height: vpRect.height - 4)
        hc.fill(Path(roundedRect: glassRect, cornerRadius: 4 * sc),
                with: .color(viewportGlass))
        // Glass specular highlight
        hc.fill(Path(roundedRect: CGRect(x: glassRect.minX + 2, y: glassRect.minY + 2,
                                         width: 6, height: 8), cornerRadius: 2),
                with: .color(Color.white.opacity(0.35)))

        // Helmet bolts around the dome
        let boltR: CGFloat = 2.0
        let boltPositions: [CGPoint] = [
            CGPoint(x: -domeR + 6, y: -domeR + 6),
            CGPoint(x: -domeR + 6, y: domeR - 6),
            CGPoint(x: domeR - 6, y: -domeR + 6),
            CGPoint(x: domeR - 6, y: domeR - 6),
            CGPoint(x: 0, y: -domeR + 4),
            CGPoint(x: 0, y: domeR - 4),
        ]
        for bp in boltPositions {
            hc.fill(Path(ellipseIn: CGRect(x: bp.x - boltR, y: bp.y - boltR,
                                           width: boltR * 2, height: boltR * 2)),
                    with: .color(jointColor.opacity(0.7)))
        }
    }

    // MARK: - Thrusters (drawn on top of everything)

    /// Draws thruster nozzles on the foot-side (+x) edge of the life support pack.
    /// The nozzles open toward +x (feet direction) so exhaust shoots backward.
    func drawThrusters(_ ctx: GraphicsContext, render: DiverRenderContext) {
        let sc = hullScale
        let nozzleR: CGFloat = 5 * sc

        // Nozzles sit at the +x edge of the life support pack, offset along y
        // Pack spans x: -20*sc..+20*sc, y: -28*sc..-14*sc
        let packRightEdge = 20 * sc
        let packMidY = (-28 * sc + -14 * sc) / 2  // vertical center of pack
        let nozzlePositions: [CGPoint] = [
            CGPoint(x: packRightEdge, y: packMidY - 5 * sc),
            CGPoint(x: packRightEdge, y: packMidY + 5 * sc)
        ]

        for pos in nozzlePositions {
            var nc = ctx
            nc.translateBy(x: pos.x, y: pos.y)

            // Nozzle bell opening toward +x (feet direction)
            var bell = Path()
            bell.move(to: CGPoint(x: 0, y: -nozzleR * 0.6))
            bell.addLine(to: CGPoint(x: 8 * sc, y: -nozzleR))
            bell.addQuadCurve(
                to: CGPoint(x: 8 * sc, y: nozzleR),
                control: CGPoint(x: 10 * sc, y: 0)
            )
            bell.addLine(to: CGPoint(x: 0, y: nozzleR * 0.6))
            bell.closeSubpath()

            nc.fill(bell, with: .color(thrusterMetal))
            nc.stroke(bell, with: .color(Color.black.opacity(0.3)), lineWidth: 1.0)

            // Inner void at the opening
            nc.fill(
                Path(ellipseIn: CGRect(x: 7 * sc, y: -nozzleR * 0.5,
                                       width: nozzleR * 0.6, height: nozzleR)),
                with: .color(Color.black.opacity(0.4))
            )
        }
    }
}
