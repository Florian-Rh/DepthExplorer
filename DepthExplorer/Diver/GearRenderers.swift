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
            Path(roundedRect: CGRect(x: 15, y: -3, width: 27, height: 16), cornerRadius: 5),
            with: .color(trunkColor)
        )
        // Waistband
        ctx.fill(
            Path(roundedRect: CGRect(x: 15, y: -3, width: 27, height: 4), cornerRadius: 2),
            with: .color(trunkColor.opacity(0.7))
        )
        // Bikini top strap across upper chest
        let bikiniColor = Color(red: 0.85, green: 0.25, blue: 0.35)
        ctx.fill(
            Path(roundedRect: CGRect(x: -38, y: -2, width: 24, height: 8), cornerRadius: 3),
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
        renderArm(ctx, shoulder: render.nearShoulder,
                  baseAngle: 25.0 + render.nearArmSwing, elbowBend: -14,
                  scale: 1.00, alpha: 1.00)
    }

    private func drawFarArm(_ ctx: GraphicsContext, render: DiverRenderContext) {
        renderArm(ctx, shoulder: render.farShoulder,
                  baseAngle: 25.0 + render.farArmSwing, elbowBend: -11,
                  scale: 0.91, alpha: 0.75)
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
