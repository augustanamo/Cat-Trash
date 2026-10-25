import SwiftUI

// MARK: - 5. 暹罗猫 · 软糯熟芝士/麻薯 (Siamese Cheese) 皮肤模块

enum SiameseCheeseSkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        // 芝士拉丝：两头粗中间极细 + 桶口倒三角黏液汇聚
        p.pinch = 0.88
        p.pinchExponent = 0.9
        p.minHalfWidth = 3.2
        p.endBulge = 3.0
        p.basePoolFlare = 17.0
        p.wobbleAmp = 0.4
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.98, green: 0.95, blue: 0.88), location: 0.0),
            .init(color: Color(red: 0.92, green: 0.85, blue: 0.74), location: 0.70),
            .init(color: Color(red: 0.62, green: 0.46, blue: 0.34), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color(red: 1.0, green: 0.98, blue: 0.93).opacity(0.92)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        startPoint: CGPoint,
        endPoint: CGPoint,
        c1: CGPoint,
        c2: CGPoint,
        waistScale: CGFloat
    ) {
        // 暹罗软糯麻薯/熟芝士：高黏度芝士/麻薯拉丝丝线
        for offset in [-8.0, 0.0, 8.0] as [CGFloat] {
            var cheeseStrand = Path()
            cheeseStrand.move(to: CGPoint(x: startPoint.x + offset, y: startPoint.y))
            cheeseStrand.addCurve(
                to: CGPoint(x: endPoint.x + offset * 0.7, y: endPoint.y),
                control1: CGPoint(x: c1.x + offset * waistScale, y: c1.y),
                control2: CGPoint(x: c2.x + offset * waistScale, y: c2.y)
            )
            context.stroke(
                cheeseStrand,
                with: .color(Color.white.opacity(0.55)),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
            )
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
