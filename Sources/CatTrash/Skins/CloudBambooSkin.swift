import SwiftUI

// MARK: - 竹篓：圆筒透视、交错编织与缠绕桶沿

struct BambooBasketBackWallView: View {
    var body: some View {
        Canvas { context, _ in
            var shadow = context
            shadow.addFilter(.blur(radius: 3.5))
            shadow.fill(Path(ellipseIn: CGRect(x: 12, y: 78, width: 79, height: 9)),
                        with: .color(.black.opacity(0.24)))
            let opening = CGRect(x: 4, y: 5, width: 92, height: 27)
            context.fill(Path(ellipseIn: opening), with: .radialGradient(
                Gradient(colors: [bambooColor(0.18, 0.13, 0.085), bambooColor(0.42, 0.31, 0.19)]),
                center: CGPoint(x: 53, y: 23), startRadius: 4, endRadius: 47
            ))
            BambooBasketDrawing.drawRim(context: &context, front: false)
        }
        .frame(width: 100, height: 88)
    }
}

struct BambooBasketFrontWallView: View {
    var body: some View {
        Canvas { context, _ in
            BambooBasketDrawing.drawWall(context: &context)
            BambooBasketDrawing.drawRim(context: &context, front: true)
        }
        .frame(width: 100, height: 88)
    }
}

private func bambooColor(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(red: r, green: g, blue: b)
}

private enum BambooBasketDrawing {
    // 以椭圆角度采样而非等距网格：侧面竹条自然压缩，形成圆筒体积。
    static func surface(angle: CGFloat, depth: CGFloat) -> CGPoint {
        CGPoint(x: 50 + (46 - 7 * depth) * cos(angle),
                y: 18 + 58 * depth + (13 - 5 * depth) * sin(angle))
    }

    static func wall() -> Path {
        var p = Path()
        p.move(to: surface(angle: 0, depth: 0))
        for i in 1...48 {
            p.addLine(to: surface(angle: CGFloat(i) / 48 * .pi, depth: 0))
        }
        p.addCurve(to: surface(angle: .pi, depth: 1),
                   control1: CGPoint(x: 5, y: 37), control2: CGPoint(x: 9, y: 67))
        for i in stride(from: 47, through: 0, by: -1) {
            p.addLine(to: surface(angle: CGFloat(i) / 48 * .pi, depth: 1))
        }
        p.addCurve(to: surface(angle: 0, depth: 0),
                   control1: CGPoint(x: 94, y: 67), control2: CGPoint(x: 96, y: 36))
        p.closeSubpath()
        return p
    }

    static func band(from a: CGFloat, to b: CGFloat, depth: CGFloat) -> Path {
        var path = Path()
        for i in 0...6 {
            let angle = a + (b - a) * CGFloat(i) / 6
            let point = surface(angle: angle, depth: depth)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    static func drawWall(context: inout GraphicsContext) {
        let shape = wall()
        var weave = context
        weave.clip(to: shape)
        weave.fill(shape, with: .linearGradient(
            Gradient(stops: [
                .init(color: bambooColor(0.38, 0.34, 0.23), location: 0),
                .init(color: bambooColor(0.68, 0.63, 0.43), location: 0.18),
                .init(color: bambooColor(0.84, 0.79, 0.58), location: 0.40),
                .init(color: bambooColor(0.65, 0.59, 0.39), location: 0.76),
                .init(color: bambooColor(0.35, 0.31, 0.21), location: 1)
            ]), startPoint: CGPoint(x: 4, y: 0), endPoint: CGPoint(x: 96, y: 0)
        ))
        let columns = 18
        for column in 1..<columns {
            let angle = CGFloat(column) / CGFloat(columns) * .pi
            var stake = Path()
            stake.move(to: surface(angle: angle, depth: 0))
            stake.addLine(to: surface(angle: angle, depth: 1))
            weave.stroke(stake, with: .color(bambooColor(0.34, 0.29, 0.18).opacity(0.65)),
                         style: StrokeStyle(lineWidth: 3.2, lineCap: .butt))
            weave.stroke(stake, with: .color(bambooColor(0.80, 0.74, 0.51)),
                         style: StrokeStyle(lineWidth: 2.1, lineCap: .butt))
        }
        for row in 0..<12 {
            let depth = CGFloat(row + 1) / 13
            for column in 0..<columns {
                let a = CGFloat(column) / CGFloat(columns) * .pi
                let b = CGFloat(column + 1) / CGFloat(columns) * .pi
                let path = band(from: a, to: b, depth: depth)
                let facing = sin((a + b) / 2)
                let irregularity = Double(sin(CGFloat(row * 31 + column * 13))) * 0.02
                let light = Double(facing) * 0.18 + irregularity
                let isOver = (row + column).isMultiple(of: 2)
                weave.stroke(path, with: .color(bambooColor(0.33, 0.28, 0.18).opacity(0.58)),
                             style: StrokeStyle(lineWidth: 4.0, lineCap: .butt))
                weave.stroke(path, with: .color(bambooColor(0.61 + light, 0.56 + light, 0.36 + light * 0.8)),
                             style: StrokeStyle(lineWidth: isOver ? 3.45 : 3.10, lineCap: .butt))
                var glint = weave
                glint.translateBy(x: -0.15, y: -0.9)
                glint.stroke(path, with: .color(bambooColor(0.97, 0.93, 0.75).opacity(isOver ? 0.48 : 0.20)),
                             style: StrokeStyle(lineWidth: 0.75, lineCap: .butt))
                if !isOver {
                    let angle = b
                    let p = surface(angle: angle, depth: depth)
                    var crossing = Path()
                    crossing.move(to: CGPoint(x: p.x, y: p.y - 2.0))
                    crossing.addLine(to: CGPoint(x: p.x, y: p.y + 2.0))
                    weave.stroke(crossing, with: .color(bambooColor(0.78 + irregularity, 0.71 + irregularity, 0.48)),
                                 style: StrokeStyle(lineWidth: 2.15 * max(facing, 0.25), lineCap: .butt))
                    var edge = weave
                    edge.translateBy(x: -0.45, y: 0)
                    edge.stroke(crossing, with: .color(.white.opacity(0.25)),
                                style: StrokeStyle(lineWidth: 0.35))
                }
            }
        }
        weave.fill(shape, with: .linearGradient(
            Gradient(colors: [.clear, .black.opacity(0.02), .black.opacity(0.22)]),
            startPoint: CGPoint(x: 50, y: 35), endPoint: CGPoint(x: 50, y: 86)
        ))
        context.stroke(band(from: 0, to: .pi, depth: 0.98),
                       with: .color(bambooColor(0.48, 0.42, 0.27)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    static func drawRim(context: inout GraphicsContext, front: Bool) {
        let start: CGFloat = front ? 0 : .pi
        let end: CGFloat = front ? .pi : .pi * 2
        let path = band(from: start, to: end, depth: 0)
        var shadow = context
        shadow.translateBy(x: 0, y: 1.6)
        shadow.stroke(path, with: .color(.black.opacity(front ? 0.38 : 0.20)),
                      style: StrokeStyle(lineWidth: 5.8, lineCap: .round))
        context.stroke(path, with: .linearGradient(
            Gradient(colors: [bambooColor(0.62, 0.56, 0.37), bambooColor(0.92, 0.86, 0.65), bambooColor(0.57, 0.51, 0.33)]),
            startPoint: CGPoint(x: 4, y: 0), endPoint: CGPoint(x: 96, y: 0)
        ), style: StrokeStyle(lineWidth: 5.0, lineCap: .round))
        // 整齐的扁竹篾包边，不绘制草绳式毛刺或散开的纤维。
        for i in 0..<32 {
            let angle = start + (end - start) * (CGFloat(i) + 0.5) / 32
            guard abs(sin(angle)) > 0.18 else { continue }
            let p = surface(angle: angle, depth: 0)
            let tangent = CGVector(dx: -46 * sin(angle), dy: 13 * cos(angle))
            let length = max(hypot(tangent.dx, tangent.dy), 0.001)
            let tx = tangent.dx / length
            let ty = tangent.dy / length
            var wrap = Path()
            wrap.move(to: CGPoint(x: p.x + ty * 2.1 - tx * 0.6, y: p.y - tx * 2.1 - ty * 0.6))
            wrap.addQuadCurve(to: CGPoint(x: p.x - ty * 2.1 + tx * 0.6, y: p.y + tx * 2.1 + ty * 0.6),
                              control: CGPoint(x: p.x + tx, y: p.y + ty))
            context.stroke(wrap, with: .color(bambooColor(0.42, 0.36, 0.23).opacity(0.60)),
                           style: StrokeStyle(lineWidth: 1.05, lineCap: .butt))
            var highlight = context
            highlight.translateBy(x: -0.5, y: -0.4)
            highlight.stroke(wrap, with: .color(bambooColor(0.99, 0.95, 0.79).opacity(0.60)),
                             style: StrokeStyle(lineWidth: 0.55, lineCap: .butt))
        }
    }
}

// MARK: - 云朵棉絮材质：只装饰共用轮廓，不定义独立猫头或五官

enum CloudCottonSkin {
    static let colors = [
        Color(red: 0.84, green: 0.88, blue: 0.93),
        Color(red: 0.98, green: 0.98, blue: 0.96),
        Color.white
    ]
    static let innerEarColor = Color(red: 0.91, green: 0.73, blue: 0.75).opacity(0.55)
    static var headGradientStops: [Gradient.Stop] {
        [
            .init(color: colors[1], location: 0),
            .init(color: .white, location: 0.52),
            .init(color: colors[0], location: 1)
        ]
    }
    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: colors[0], location: 0),
            .init(color: .white, location: 0.40),
            .init(color: colors[1], location: 0.65),
            .init(color: colors[0], location: 1)
        ]
    }

    static func puff(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.85,
                                           width: radius * 2, height: radius * 1.7)),
                     with: .radialGradient(
                        Gradient(colors: [.white.opacity(opacity), colors[1].opacity(opacity),
                                          colors[0].opacity(opacity * 0.50), .clear]),
                        center: CGPoint(x: center.x - radius * 0.20, y: center.y - radius * 0.25),
                        startRadius: radius * 0.2, endRadius: radius * 1.2))
    }

    static func drawBodyTextures(context: inout GraphicsContext, shape: ProfiledCatBodyShape, phase: CGFloat) {
        // 连续的宽幅云雾沿脊线交叠，没有独立圆球的暗边和重复排列。
        var mist = context
        mist.addFilter(.blur(radius: 3.8))
        for lane in 0..<5 {
            var ribbon = Path()
            for i in 0...ProfiledCatBodyShape.samples {
                let t = CGFloat(i) / CGFloat(ProfiledCatBodyShape.samples)
                let f = shape.frame(at: t)
                let drift = sin(t * 5.5 + CGFloat(lane) * 1.8 + sin(phase * 0.2) * 0.12)
                let offset = (CGFloat(lane - 2) * 0.24 + drift * 0.12) * shape.halfWidth(at: t)
                let p = CGPoint(x: f.center.x + f.normal.dx * offset,
                                y: f.center.y + f.normal.dy * offset)
                if i == 0 { ribbon.move(to: p) } else { ribbon.addLine(to: p) }
            }
            mist.stroke(ribbon, with: .color(lane.isMultiple(of: 2) ? .white.opacity(0.27) : colors[0].opacity(0.07)),
                        style: StrokeStyle(lineWidth: shape.baseHalfWidth * 0.65, lineCap: .round))
        }

        let length = hypot(shape.endPoint.x - shape.startPoint.x, shape.endPoint.y - shape.startPoint.y)
        let count = min(420, max(100, Int(length * 1.1)))
        for i in 0..<count {
            let t = 0.02 + noise(i, seed: 11) * 0.96
            let f = shape.frame(at: t)
            let offset = (noise(i, seed: 23) * 2 - 1) * shape.halfWidth(at: t) * 0.93
            let point = CGPoint(x: f.center.x + f.normal.dx * offset,
                                y: f.center.y + f.normal.dy * offset)
            let fibreLength = 1.0 + noise(i, seed: 37) * 2.0
            var fibre = Path()
            fibre.move(to: point)
            fibre.addQuadCurve(
                to: CGPoint(x: point.x + f.tangent.dx * fibreLength, y: point.y + f.tangent.dy * fibreLength),
                control: CGPoint(x: point.x + f.tangent.dx * 0.5 + f.normal.dx * 0.4,
                                 y: point.y + f.tangent.dy * 0.5 + f.normal.dy * 0.4))
            context.stroke(fibre, with: .color(colors[0].opacity(0.14)),
                           style: StrokeStyle(lineWidth: 0.35, lineCap: .round))
        }
    }

    private static func noise(_ index: Int, seed: Int) -> CGFloat {
        let value = sin(CGFloat(index * 37 + seed * 101) * 12.9898) * 43758.5453
        return value - floor(value)
    }

    static func drawBodyEdge(context: inout GraphicsContext, shape: ProfiledCatBodyShape) {
        let edges = shape.edges()
        var soft = context
        soft.addFilter(.blur(radius: 1.0))
        for points in [edges.left, edges.right] {
            var edge = Path()
            for (i, p) in points.enumerated() {
                if i == 0 { edge.move(to: p) } else { edge.addLine(to: p) }
            }
            soft.stroke(edge, with: .color(.white.opacity(0.8)),
                        style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
            for i in 1..<(points.count - 1) {
                let p = points[i]
                let f = shape.frame(at: CGFloat(i) / CGFloat(ProfiledCatBodyShape.samples))
                let distance = max(hypot(p.x - f.center.x, p.y - f.center.y), 0.001)
                let nx = (p.x - f.center.x) / distance
                let ny = (p.y - f.center.y) / distance
                let length = 0.7 + noise(i, seed: 41) * 1.0
                var wisp = Path()
                wisp.move(to: CGPoint(x: p.x - nx, y: p.y - ny))
                wisp.addQuadCurve(to: CGPoint(x: p.x + nx * length + f.tangent.dx,
                                              y: p.y + ny * length + f.tangent.dy),
                                  control: CGPoint(x: p.x + nx * length, y: p.y + ny * length))
                context.stroke(wisp, with: .color(.white.opacity(0.55)),
                               style: StrokeStyle(lineWidth: 0.45, lineCap: .round))
            }
        }
    }
}

struct CloudCottonHeadMaterialOverlay: View {
    let headShape: MochiCatHeadShape
    let earFlatten: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat

    var body: some View {
        ZStack {
            Canvas { context, size in
                for i in 0..<28 {
                    let x = (CGFloat(i) * 0.618).truncatingRemainder(dividingBy: 1) * size.width
                    let y = (CGFloat(i) * 0.377).truncatingRemainder(dividingBy: 1) * size.height
                    CloudCottonSkin.puff(context: &context, center: CGPoint(x: x, y: y),
                                         radius: 6 + CGFloat(i % 4), opacity: 0.48)
                }
                for i in 0..<90 {
                    let x = (CGFloat(i) * 0.618).truncatingRemainder(dividingBy: 1) * size.width
                    let y = (CGFloat(i) * 0.377).truncatingRemainder(dividingBy: 1) * size.height
                    var fibre = Path()
                    fibre.move(to: CGPoint(x: x, y: y))
                    fibre.addQuadCurve(to: CGPoint(x: x + 1.5, y: y + 2.0),
                                       control: CGPoint(x: x + 2, y: y + 0.5))
                    context.stroke(fibre, with: .color(CloudCottonSkin.colors[0].opacity(0.30)),
                                   style: StrokeStyle(lineWidth: 0.4, lineCap: .round))
                }
            }
            .clipShape(headShape)

            Canvas { context, size in
                let points = sampleHeadPerimeterPoints(
                    in: CGRect(origin: .zero, size: size), earFlatten: earFlatten,
                    leftEarTwitch: leftEarTwitch, rightEarTwitch: rightEarTwitch)
                var soft = context
                soft.addFilter(.blur(radius: 0.65))
                for (i, point) in points.enumerated() {
                    let radius: CGFloat = point.y < size.height * 0.35 ? 1.1 : 2.0
                    CloudCottonSkin.puff(context: &soft, center: point,
                                         radius: radius + CGFloat(i % 2) * 0.3, opacity: 0.85)
                }
            }
        }
    }
}
