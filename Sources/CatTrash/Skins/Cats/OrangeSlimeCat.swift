import SwiftUI

// MARK: - 1. 橘猫 · 史莱姆果冻 (Orange Slime / Jelly) 皮肤模块

enum OrangeSlimeSkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        p.pinch = 0.58
        p.pinchExponent = 1.6
        p.minHalfWidth = 8
        p.endBulge = 5.0
        p.basePoolFlare = 4.0
        p.wobbleAmp = 1.1
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.99, green: 0.78, blue: 0.46), location: 0.0),
            .init(color: Color(red: 0.98, green: 0.64, blue: 0.24), location: 0.45),
            .init(color: Color(red: 0.90, green: 0.42, blue: 0.12), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.85)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        shape: ProfiledCatBodyShape,
        startPoint: CGPoint,
        endPoint: CGPoint,
        c1: CGPoint,
        c2: CGPoint,
        waistScale: CGFloat,
        phase: CGFloat
    ) {
        var specularRibbon = Path()
        specularRibbon.move(to: CGPoint(x: startPoint.x - 13 * waistScale, y: startPoint.y))
        specularRibbon.addCurve(
            to: CGPoint(x: endPoint.x - 12 * waistScale, y: endPoint.y + 6),
            control1: CGPoint(x: c1.x - 13 * waistScale, y: c1.y),
            control2: CGPoint(x: c2.x - 12 * waistScale, y: c2.y)
        )
        context.stroke(
            specularRibbon,
            with: .color(.white.opacity(0.55)),
            style: StrokeStyle(lineWidth: 5.0 * waistScale, lineCap: .round)
        )

        for t in [0.28, 0.50, 0.72] as [CGFloat] {
            let pt = cubicBezierPoint(t: t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            var stripe = Path()
            stripe.move(to: CGPoint(x: pt.x + 6 * waistScale, y: pt.y - 3))
            stripe.addQuadCurve(
                to: CGPoint(x: pt.x + 24 * waistScale, y: pt.y + 4),
                control: CGPoint(x: pt.x + 16 * waistScale, y: pt.y - 5)
            )
            context.stroke(
                stripe,
                with: .color(Color(red: 0.76, green: 0.28, blue: 0.05).opacity(0.48)),
                style: StrokeStyle(lineWidth: 4.2, lineCap: .round)
            )
        }

        let bubbleSpecs: [(t: CGFloat, lateral: CGFloat, radius: CGFloat)] = [
            (0.28 + 0.03 * sin(phase), -4.0, 3.2),
            (0.54 + 0.04 * cos(phase * 1.2), 4.0, 2.4),
            (0.76 + 0.03 * sin(phase * 0.8 + 1.4), -2.5, 3.6)
        ]
        for spec in bubbleSpecs {
            let pt = cubicBezierPoint(t: spec.t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            let rect = CGRect(
                x: pt.x + spec.lateral * waistScale - spec.radius,
                y: pt.y - spec.radius,
                width: spec.radius * 2,
                height: spec.radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.32)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.65)), lineWidth: 0.8)
        }
    }

    @ViewBuilder
    static func bodyEdgeStrokeView(shape: ProfiledCatBodyShape) -> some View {
        shape.stroke(
            LinearGradient(
                colors: [
                    .white.opacity(0.85),
                    Color(red: 1.0, green: 0.82, blue: 0.50).opacity(0.38),
                    Color.black.opacity(0.25)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            lineWidth: 1.5
        )
    }
}
