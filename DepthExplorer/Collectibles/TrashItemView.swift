import SwiftUI

struct TrashItemView: View {
    let item: TrashItem
    let scalingFactor: Double
    let contentOffset: Double
    let screenSize: CGSize

    var yPosition: Double {
        item.depth * scalingFactor
    }

    var xPosition: Double {
        item.xFraction * screenSize.width
    }

    var isVisible: Bool {
        let itemScreenY = yPosition - contentOffset + screenSize.height / 3
        return itemScreenY > -200 && itemScreenY < screenSize.height + 200
    }

    /// Per-item phase offset derived from the UUID so each item sways independently.
    private var phaseOffset: Double {
        Double(item.id.hashValue & 0xFFFF) / Double(0xFFFF) * .pi * 2
    }

    /// Sway speed varies slightly per item for natural feel.
    private var swaySpeed: Double {
        0.4 + Double(item.id.hashValue & 0xFF) / Double(0xFF) * 0.3
    }

    @State private var rotationAnchor: UnitPoint = [
        UnitPoint.bottom,
        UnitPoint.leading,
        UnitPoint.trailing,
        UnitPoint.center,
        UnitPoint.top
    ].randomElement()!

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let sway = sin(t * swaySpeed * .pi * 2 + phaseOffset) * 8.0

            VStack(spacing: 4) {
                Canvas { ctx, size in
                    drawTrashShape(ctx, size: size, typeID: item.typeDef.id)
                }
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(sway), anchor: rotationAnchor)

                Text("$\(Int(item.sandDollarValue))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .position(x: xPosition, y: yPosition)
            .opacity(isVisible ? 1 : 0)
        }
    }

    // MARK: - Shape drawing

    private func drawTrashShape(_ ctx: GraphicsContext, size: CGSize, typeID: String) {
        let w = size.width
        let h = size.height

        switch typeID {
        case "trash.sodaCan":
            drawSodaCan(ctx, w: w, h: h)
        case "trash.plasticBag":
            drawPlasticBag(ctx, w: w, h: h)
        case "trash.bottle":
            drawBottle(ctx, w: w, h: h)
        case "trash.tire":
            drawTire(ctx, w: w, h: h)
        case "trash.battery":
            drawBattery(ctx, w: w, h: h)
        case "trash.fishingNet":
            drawFishingNet(ctx, w: w, h: h)
        case "trash.oilDrum":
            drawOilDrum(ctx, w: w, h: h)
        case "trash.shoppingCart":
            drawShoppingCart(ctx, w: w, h: h)
        case "trash.anchor":
            drawAnchor(ctx, w: w, h: h)
        case "trash.container":
            drawContainer(ctx, w: w, h: h)
        default:
            break
        }
    }

    // MARK: Soda Can

    private func drawSodaCan(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bodyColor = Color(red: 0.85, green: 0.15, blue: 0.15)
        let rimColor = Color(red: 0.70, green: 0.70, blue: 0.75)

        // Can body
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.2, y: h * 0.15, width: w * 0.6, height: h * 0.7),
                 cornerRadius: 4),
            with: .color(bodyColor)
        )
        // Highlight stripe
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.18, width: w * 0.15, height: h * 0.64),
                 cornerRadius: 2),
            with: .color(Color.white.opacity(0.2))
        )
        // Top rim
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.12, width: w * 0.56, height: h * 0.08),
                 cornerRadius: 2),
            with: .color(rimColor)
        )
        // Bottom rim
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.8, width: w * 0.56, height: h * 0.07),
                 cornerRadius: 2),
            with: .color(rimColor.opacity(0.7))
        )
        // Pull tab
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.08, width: w * 0.18, height: h * 0.1)),
            with: .color(rimColor)
        )
    }

    // MARK: Plastic Bag

    private func drawPlasticBag(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bagColor = Color(white: 0.92)

        // Main crumpled bag shape
        var bagPath = Path()
        bagPath.move(to: CGPoint(x: w * 0.3, y: h * 0.1))
        bagPath.addQuadCurve(to: CGPoint(x: w * 0.75, y: h * 0.15),
                             control: CGPoint(x: w * 0.55, y: h * 0.0))
        bagPath.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.55),
                             control: CGPoint(x: w * 0.9, y: h * 0.3))
        bagPath.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.9),
                             control: CGPoint(x: w * 0.8, y: h * 0.8))
        bagPath.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.65),
                             control: CGPoint(x: w * 0.25, y: h * 0.95))
        bagPath.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.1),
                             control: CGPoint(x: w * 0.05, y: h * 0.3))
        bagPath.closeSubpath()

        ctx.fill(bagPath, with: .color(bagColor.opacity(0.5)))
        ctx.stroke(bagPath, with: .color(Color.white.opacity(0.6)), lineWidth: 0.8)

        // Wrinkle lines
        var wrinkle1 = Path()
        wrinkle1.move(to: CGPoint(x: w * 0.35, y: h * 0.3))
        wrinkle1.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.6),
                              control: CGPoint(x: w * 0.55, y: h * 0.35))
        ctx.stroke(wrinkle1, with: .color(Color.white.opacity(0.35)), lineWidth: 0.5)

        var wrinkle2 = Path()
        wrinkle2.move(to: CGPoint(x: w * 0.25, y: h * 0.5))
        wrinkle2.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.75),
                              control: CGPoint(x: w * 0.4, y: h * 0.5))
        ctx.stroke(wrinkle2, with: .color(Color.white.opacity(0.3)), lineWidth: 0.5)

        // Handle loops at top
        var handle = Path()
        handle.move(to: CGPoint(x: w * 0.35, y: h * 0.15))
        handle.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.15),
                            control: CGPoint(x: w * 0.42, y: h * 0.02))
        ctx.stroke(handle, with: .color(Color.white.opacity(0.5)),
                   style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    // MARK: Bottle

    private func drawBottle(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bottleColor = Color(red: 0.25, green: 0.70, blue: 0.35)
        let capColor = Color(red: 0.20, green: 0.50, blue: 0.28)

        // Bottle body
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.25, y: h * 0.3, width: w * 0.5, height: h * 0.6),
                 cornerRadius: 5),
            with: .color(bottleColor.opacity(0.7))
        )
        // Highlight
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.27, y: h * 0.33, width: w * 0.12, height: h * 0.52),
                 cornerRadius: 2),
            with: .color(Color.white.opacity(0.2))
        )
        // Neck
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.37, y: h * 0.12, width: w * 0.26, height: h * 0.22),
                 cornerRadius: 3),
            with: .color(bottleColor.opacity(0.65))
        )
        // Cap
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.06, width: w * 0.24, height: h * 0.1),
                 cornerRadius: 2),
            with: .color(capColor)
        )
        // Label area
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.52, width: w * 0.44, height: h * 0.2),
                 cornerRadius: 2),
            with: .color(Color.white.opacity(0.2))
        )
    }

    // MARK: Tire

    private func drawTire(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let tireColor = Color(red: 0.18, green: 0.18, blue: 0.20)
        let rimColor = Color(red: 0.45, green: 0.45, blue: 0.50)

        let cx = w * 0.5
        let cy = h * 0.5
        let outerR = min(w, h) * 0.44
        let innerR = outerR * 0.55

        // Outer tire
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - outerR, y: cy - outerR,
                                   width: outerR * 2, height: outerR * 2)),
            with: .color(tireColor)
        )
        // Tread highlight
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - outerR + 2, y: cy - outerR + 2,
                                   width: (outerR - 2) * 2, height: (outerR - 2) * 2)),
            with: .color(Color.white.opacity(0.08)), lineWidth: 2
        )
        // Inner hole
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - innerR, y: cy - innerR,
                                   width: innerR * 2, height: innerR * 2)),
            with: .color(Color(red: 0.08, green: 0.20, blue: 0.30).opacity(0.6))
        )
        // Rim ring
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - innerR, y: cy - innerR,
                                   width: innerR * 2, height: innerR * 2)),
            with: .color(rimColor.opacity(0.5)), lineWidth: 1.5
        )
        // Tread marks
        for angle in stride(from: 0.0, to: 360.0, by: 30.0) {
            let rad = CGFloat(angle) * .pi / 180
            var mark = Path()
            mark.move(to: CGPoint(x: cx + CoreGraphics.cos(rad) * (innerR + 2),
                                  y: cy + CoreGraphics.sin(rad) * (innerR + 2)))
            mark.addLine(to: CGPoint(x: cx + CoreGraphics.cos(rad) * (outerR - 2),
                                     y: cy + CoreGraphics.sin(rad) * (outerR - 2)))
            ctx.stroke(mark, with: .color(Color.white.opacity(0.06)), lineWidth: 1.5)
        }
    }

    // MARK: Battery

    private func drawBattery(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bodyColor = Color(red: 0.80, green: 0.72, blue: 0.10)
        let termColor = Color(red: 0.55, green: 0.55, blue: 0.58)

        // Battery body
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.2, y: h * 0.2, width: w * 0.6, height: h * 0.65),
                 cornerRadius: 3),
            with: .color(bodyColor)
        )
        // Dark stripe (label)
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.4, width: w * 0.56, height: h * 0.25),
                 cornerRadius: 1),
            with: .color(Color.black.opacity(0.35))
        )
        // + terminal
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.35, y: h * 0.1, width: w * 0.12, height: h * 0.14),
                 cornerRadius: 1),
            with: .color(termColor)
        )
        // − terminal
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.53, y: h * 0.12, width: w * 0.12, height: h * 0.11),
                 cornerRadius: 1),
            with: .color(termColor)
        )
        // + sign
        var plus = Path()
        plus.move(to: CGPoint(x: w * 0.32, y: h * 0.5))
        plus.addLine(to: CGPoint(x: w * 0.42, y: h * 0.5))
        plus.move(to: CGPoint(x: w * 0.37, y: h * 0.45))
        plus.addLine(to: CGPoint(x: w * 0.37, y: h * 0.55))
        ctx.stroke(plus, with: .color(Color.white.opacity(0.7)), lineWidth: 1.2)
        // − sign
        var minus = Path()
        minus.move(to: CGPoint(x: w * 0.58, y: h * 0.5))
        minus.addLine(to: CGPoint(x: w * 0.68, y: h * 0.5))
        ctx.stroke(minus, with: .color(Color.white.opacity(0.7)), lineWidth: 1.2)
    }

    // MARK: Fishing Net

    private func drawFishingNet(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let netColor = Color(red: 0.75, green: 0.55, blue: 0.25)
        let ropeColor = Color(red: 0.60, green: 0.42, blue: 0.18)

        // Tangled net body — irregular blob
        var netPath = Path()
        netPath.move(to: CGPoint(x: w * 0.15, y: h * 0.2))
        netPath.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.1),
                             control: CGPoint(x: w * 0.4, y: h * 0.0))
        netPath.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.5),
                             control: CGPoint(x: w * 0.95, y: h * 0.25))
        netPath.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.9),
                             control: CGPoint(x: w * 0.85, y: h * 0.75))
        netPath.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.75),
                             control: CGPoint(x: w * 0.35, y: h * 0.95))
        netPath.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.2),
                             control: CGPoint(x: w * 0.0, y: h * 0.45))
        netPath.closeSubpath()

        ctx.fill(netPath, with: .color(netColor.opacity(0.35)))
        ctx.stroke(netPath, with: .color(ropeColor.opacity(0.6)), lineWidth: 0.8)

        // Net mesh lines (diamond pattern)
        let spacing: CGFloat = 7
        for x in stride(from: w * 0.15, to: w * 0.9, by: spacing) {
            var line = Path()
            line.move(to: CGPoint(x: x, y: h * 0.1))
            line.addLine(to: CGPoint(x: x + spacing * 0.8, y: h * 0.9))
            ctx.stroke(line, with: .color(ropeColor.opacity(0.4)), lineWidth: 0.5)
        }
        for x in stride(from: w * 0.15, to: w * 0.9, by: spacing) {
            var line = Path()
            line.move(to: CGPoint(x: x + spacing, y: h * 0.1))
            line.addLine(to: CGPoint(x: x, y: h * 0.9))
            ctx.stroke(line, with: .color(ropeColor.opacity(0.35)), lineWidth: 0.5)
        }

        // Rope knot at top
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.35, y: h * 0.05, width: w * 0.18, height: h * 0.14)),
            with: .color(ropeColor.opacity(0.7))
        )
    }

    // MARK: Oil Drum

    private func drawOilDrum(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bodyColor = Color(red: 0.50, green: 0.32, blue: 0.12)
        let rustColor = Color(red: 0.65, green: 0.40, blue: 0.15)
        let rimColor = Color(red: 0.38, green: 0.25, blue: 0.10)

        // Main barrel body
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.15, y: h * 0.1, width: w * 0.7, height: h * 0.8),
                 cornerRadius: 5),
            with: .color(bodyColor)
        )
        // Highlight
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.17, y: h * 0.12, width: w * 0.18, height: h * 0.74),
                 cornerRadius: 3),
            with: .color(Color.white.opacity(0.1))
        )
        // Top rim
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.13, y: h * 0.08, width: w * 0.74, height: h * 0.06),
                 cornerRadius: 2),
            with: .color(rimColor)
        )
        // Bottom rim
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.13, y: h * 0.86, width: w * 0.74, height: h * 0.06),
                 cornerRadius: 2),
            with: .color(rimColor)
        )
        // Middle band
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.46, width: w * 0.72, height: h * 0.06),
                 cornerRadius: 1),
            with: .color(rimColor.opacity(0.7))
        )
        // Rust patches
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.5, y: h * 0.55, width: w * 0.25, height: h * 0.2)),
            with: .color(rustColor.opacity(0.5))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.25, width: w * 0.18, height: h * 0.15)),
            with: .color(rustColor.opacity(0.4))
        )
        // Cap on top
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.4, y: h * 0.04, width: w * 0.14, height: h * 0.09)),
            with: .color(rimColor)
        )
    }

    // MARK: Shopping Cart

    private func drawShoppingCart(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let metalColor = Color(red: 0.55, green: 0.65, blue: 0.70)
        let darkMetal = Color(red: 0.35, green: 0.42, blue: 0.48)

        // Cart basket (wireframe trapezoid)
        var basket = Path()
        basket.move(to: CGPoint(x: w * 0.15, y: h * 0.15))
        basket.addLine(to: CGPoint(x: w * 0.85, y: h * 0.15))
        basket.addLine(to: CGPoint(x: w * 0.78, y: h * 0.65))
        basket.addLine(to: CGPoint(x: w * 0.22, y: h * 0.65))
        basket.closeSubpath()
        ctx.stroke(basket, with: .color(metalColor), lineWidth: 1.5)

        // Grid lines horizontal
        for yFrac in stride(from: 0.3, through: 0.55, by: 0.12) {
            let t = (yFrac - 0.15) / 0.5
            let leftX = w * (0.15 + t * 0.07)
            let rightX = w * (0.85 - t * 0.07)
            var line = Path()
            line.move(to: CGPoint(x: leftX, y: h * yFrac))
            line.addLine(to: CGPoint(x: rightX, y: h * yFrac))
            ctx.stroke(line, with: .color(metalColor.opacity(0.6)), lineWidth: 0.7)
        }
        // Grid lines vertical
        for xFrac in stride(from: 0.3, through: 0.75, by: 0.15) {
            var line = Path()
            line.move(to: CGPoint(x: w * xFrac, y: h * 0.15))
            line.addLine(to: CGPoint(x: w * (xFrac - 0.01), y: h * 0.65))
            ctx.stroke(line, with: .color(metalColor.opacity(0.5)), lineWidth: 0.6)
        }

        // Handle bar
        var handle = Path()
        handle.move(to: CGPoint(x: w * 0.12, y: h * 0.15))
        handle.addLine(to: CGPoint(x: w * 0.05, y: h * 0.05))
        handle.addLine(to: CGPoint(x: w * 0.35, y: h * 0.05))
        ctx.stroke(handle, with: .color(darkMetal),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Wheels
        let wheelR: CGFloat = w * 0.07
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.25 - wheelR, y: h * 0.75 - wheelR,
                                   width: wheelR * 2, height: wheelR * 2)),
            with: .color(darkMetal)
        )
        ctx.stroke(
            Path(ellipseIn: CGRect(x: w * 0.25 - wheelR, y: h * 0.75 - wheelR,
                                   width: wheelR * 2, height: wheelR * 2)),
            with: .color(metalColor.opacity(0.6)), lineWidth: 0.8
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.7 - wheelR, y: h * 0.75 - wheelR,
                                   width: wheelR * 2, height: wheelR * 2)),
            with: .color(darkMetal)
        )
        ctx.stroke(
            Path(ellipseIn: CGRect(x: w * 0.7 - wheelR, y: h * 0.75 - wheelR,
                                   width: wheelR * 2, height: wheelR * 2)),
            with: .color(metalColor.opacity(0.6)), lineWidth: 0.8
        )

        // Axle lines
        var axle = Path()
        axle.move(to: CGPoint(x: w * 0.22, y: h * 0.65))
        axle.addLine(to: CGPoint(x: w * 0.25, y: h * 0.75))
        axle.move(to: CGPoint(x: w * 0.78, y: h * 0.65))
        axle.addLine(to: CGPoint(x: w * 0.7, y: h * 0.75))
        ctx.stroke(axle, with: .color(darkMetal), lineWidth: 1.2)
    }

    // MARK: Anchor

    private func drawAnchor(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let anchorColor = Color(red: 0.25, green: 0.35, blue: 0.55)
        let highlight = Color(red: 0.40, green: 0.52, blue: 0.72)

        // Shank (vertical bar)
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.45, y: h * 0.15, width: w * 0.1, height: h * 0.65),
                 cornerRadius: 2),
            with: .color(anchorColor)
        )
        // Highlight on shank
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.46, y: h * 0.17, width: w * 0.03, height: h * 0.6),
                 cornerRadius: 1),
            with: .color(highlight.opacity(0.3))
        )

        // Ring at top
        ctx.stroke(
            Path(ellipseIn: CGRect(x: w * 0.37, y: h * 0.02, width: w * 0.26, height: h * 0.2)),
            with: .color(anchorColor), lineWidth: 3
        )

        // Cross bar (stock)
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.2, y: h * 0.32, width: w * 0.6, height: h * 0.07),
                 cornerRadius: 2),
            with: .color(anchorColor)
        )

        // Left fluke (curved arm)
        var leftFluke = Path()
        leftFluke.move(to: CGPoint(x: w * 0.45, y: h * 0.78))
        leftFluke.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.6),
                               control: CGPoint(x: w * 0.15, y: h * 0.85))
        leftFluke.addLine(to: CGPoint(x: w * 0.08, y: h * 0.52))
        ctx.stroke(leftFluke, with: .color(anchorColor),
                   style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

        // Right fluke
        var rightFluke = Path()
        rightFluke.move(to: CGPoint(x: w * 0.55, y: h * 0.78))
        rightFluke.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.6),
                                control: CGPoint(x: w * 0.85, y: h * 0.85))
        rightFluke.addLine(to: CGPoint(x: w * 0.92, y: h * 0.52))
        ctx.stroke(rightFluke, with: .color(anchorColor),
                   style: StrokeStyle(lineWidth: 3.5, lineCap: .round))

        // Fluke tips (pointed)
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.04, y: h * 0.48, width: w * 0.1, height: h * 0.1)),
            with: .color(anchorColor)
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.86, y: h * 0.48, width: w * 0.1, height: h * 0.1)),
            with: .color(anchorColor)
        )
    }

    // MARK: Shipping Container

    private func drawContainer(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let bodyColor = Color(red: 0.80, green: 0.30, blue: 0.10)
        let frameColor = Color(red: 0.55, green: 0.20, blue: 0.06)
        let rustColor = Color(red: 0.60, green: 0.35, blue: 0.15)

        // Main body
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.05, y: h * 0.15, width: w * 0.9, height: h * 0.7),
                 cornerRadius: 2),
            with: .color(bodyColor)
        )

        // Corrugation lines (vertical ridges)
        for xFrac in stride(from: 0.12, to: 0.92, by: 0.08) {
            var line = Path()
            line.move(to: CGPoint(x: w * xFrac, y: h * 0.17))
            line.addLine(to: CGPoint(x: w * xFrac, y: h * 0.83))
            ctx.stroke(line, with: .color(frameColor.opacity(0.5)), lineWidth: 0.7)
        }

        // Top frame
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.03, y: h * 0.13, width: w * 0.94, height: h * 0.06),
                 cornerRadius: 1),
            with: .color(frameColor)
        )
        // Bottom frame
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.03, y: h * 0.83, width: w * 0.94, height: h * 0.06),
                 cornerRadius: 1),
            with: .color(frameColor)
        )
        // Left frame
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.03, y: h * 0.13, width: w * 0.06, height: h * 0.76),
                 cornerRadius: 1),
            with: .color(frameColor)
        )
        // Right frame
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.91, y: h * 0.13, width: w * 0.06, height: h * 0.76),
                 cornerRadius: 1),
            with: .color(frameColor)
        )

        // Door latch handles
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.88, y: h * 0.35, width: w * 0.04, height: h * 0.12),
                 cornerRadius: 1),
            with: .color(Color.white.opacity(0.25))
        )
        ctx.fill(
            Path(roundedRect: CGRect(x: w * 0.88, y: h * 0.55, width: w * 0.04, height: h * 0.12),
                 cornerRadius: 1),
            with: .color(Color.white.opacity(0.25))
        )

        // Rust patches
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.55, width: w * 0.25, height: h * 0.2)),
            with: .color(rustColor.opacity(0.45))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.25, width: w * 0.2, height: h * 0.15)),
            with: .color(rustColor.opacity(0.35))
        )
    }
}

// MARK: - Previews

#Preview("All Trash Types") {
    GeometryReader { geo in
        ZStack {
            Color(red: 0.02, green: 0.10, blue: 0.22)
            ForEach(Array(TrashTypeDefinition.allTypes.enumerated()), id: \.element.id) { index, typeDef in
                TrashItemView(
                    item: TrashItem(
                        id: UUID(),
                        typeDef: typeDef,
                        depth: 15 + Double(index) * 8,
                        xFraction: 0.15 + Double(index) * 0.17
                    ),
                    scalingFactor: 10,
                    contentOffset: 0,
                    screenSize: geo.size
                )
            }
        }
    }
    .preferredColorScheme(.dark)
}
