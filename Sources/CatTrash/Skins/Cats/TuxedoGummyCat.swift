import SwiftUI

// MARK: - 4. 奶牛猫 · 橡皮糖/软硅胶 (Tuxedo Gummy) 皮肤模块

enum TuxedoGummySkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        // 奶牛橡皮糖：高张力弹性收缩，腰身紧致
        p.pinch = 0.48
        p.pinchExponent = 1.3
        p.minHalfWidth = 8
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.22, green: 0.23, blue: 0.27), location: 0.0),
            .init(color: Color(red: 0.12, green: 0.13, blue: 0.16), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color.white.opacity(0.96)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        shape: ProfiledCatBodyShape,
        startPoint: CGPoint,
        endPoint: CGPoint,
        c1: CGPoint,
        c2: CGPoint,
        waistScale: CGFloat
    ) {
        // 奶牛橡皮糖：高张力软硅胶哑光柔滑反光带 + 黑白交界硅胶倒角细高光
        var specularRibbon = Path()
        specularRibbon.move(to: CGPoint(x: startPoint.x - 13 * waistScale, y: startPoint.y))
        specularRibbon.addCurve(
            to: CGPoint(x: endPoint.x - 12 * waistScale, y: endPoint.y + 6),
            control1: CGPoint(x: c1.x - 13 * waistScale, y: c1.y),
            control2: CGPoint(x: c2.x - 12 * waistScale, y: c2.y)
        )
        context.stroke(
            specularRibbon,
            with: .color(.white.opacity(0.35)),
            style: StrokeStyle(lineWidth: 5.0 * waistScale, lineCap: .round)
        )

        for side in [-1.0, 1.0] as [CGFloat] {
            var seam = Path()
            for i in 0...40 {
                let t = 0.04 + 0.94 * CGFloat(i) / 40.0
                let f = shape.frame(at: t)
                let off = min(11 * waistScale, shape.halfWidth(at: t) * 0.62) * side
                let p = CGPoint(x: f.center.x - 2.5 + f.normal.dx * off, y: f.center.y + 4 + f.normal.dy * off)
                if i == 0 { seam.move(to: p) } else { seam.addLine(to: p) }
            }
            context.stroke(seam, with: .color(.white.opacity(0.42)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
    }

    @ViewBuilder
    static func bodyEdgeStrokeView(shape: ProfiledCatBodyShape) -> some View {
        // 橡皮糖：外边缘软胶保护壳倒角细高光
        ZStack {
            shape.stroke(Color.black.opacity(0.35), lineWidth: 0.9)
            shape
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.75), .white.opacity(0.15), .white.opacity(0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.4
                )
                .clipShape(shape)
        }
    }
}
