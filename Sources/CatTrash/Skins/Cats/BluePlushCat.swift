import SwiftUI

// MARK: - 2. 蓝猫 · 短毛绒球 (Short Plush / Pom-Pom) 皮肤模块

enum BluePlushSkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        // 毛绒球：几乎不收腰，保持蓬松饱满
        p.pinch = 0.14
        p.pinchExponent = 1.2
        p.minHalfWidth = 16
        p.endBulge = 1.5
        p.basePoolFlare = 2.0
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.56, green: 0.72, blue: 0.92), location: 0.0),
            .init(color: Color(red: 0.46, green: 0.62, blue: 0.85), location: 0.55),
            .init(color: Color(red: 0.36, green: 0.50, blue: 0.76), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color(red: 0.78, green: 0.88, blue: 0.98).opacity(0.85)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        shape: ProfiledCatBodyShape,
        stretchRatio: CGFloat,
        phase: CGFloat
    ) {
        var soft = context
        soft.addFilter(.blur(radius: 0.9))
        let lanes = 11
        let n = 36
        for l in 0..<lanes {
            let u = (CGFloat(l) / CGFloat(lanes - 1)) * 2 - 1
            var strand = Path()
            for i in 0...n {
                let t = 0.03 + 0.95 * CGFloat(i) / CGFloat(n)
                let f = shape.frame(at: t)
                let w = shape.halfWidth(at: t)
                // 拉得越长毛束越直
                let sway = sin(t * 7 + CGFloat(l) * 1.3 + phase * 0.8) * 1.1 * (1 - stretchRatio * 0.7)
                let off = u * w * 0.86 + sway
                let p = CGPoint(x: f.center.x + f.normal.dx * off, y: f.center.y + f.normal.dy * off)
                if i == 0 { strand.move(to: p) } else { strand.addLine(to: p) }
            }
            let isBelly = abs(u) < 0.4
            let color: Color = isBelly
                ? Color(red: 0.88, green: 0.95, blue: 1.0)
                : (u > 0 ? Color(red: 0.62, green: 0.77, blue: 0.95) : Color(red: 0.36, green: 0.50, blue: 0.76))
            soft.stroke(
                strand,
                with: .color(color.opacity(0.42)),
                style: StrokeStyle(lineWidth: 3.4 - stretchRatio * 1.2, lineCap: .round, lineJoin: .round)
            )
        }

        // 丝绒细光泽毛丝
        var silk = context
        silk.addFilter(.blur(radius: 0.4))
        for k in 0..<18 {
            let fk = CGFloat(k)
            let u = (fk * 0.377).truncatingRemainder(dividingBy: 1) * 1.6 - 0.8
            let t0 = 0.05 + (fk * 0.618).truncatingRemainder(dividingBy: 1) * 0.70
            let t1 = min(t0 + 0.12 + stretchRatio * 0.14, 0.98)
            var hair = Path()
            for i in 0...8 {
                let t = t0 + (t1 - t0) * CGFloat(i) / 8
                let f = shape.frame(at: t)
                let off = u * shape.halfWidth(at: t) * 0.8
                let p = CGPoint(x: f.center.x + f.normal.dx * off, y: f.center.y + f.normal.dy * off)
                if i == 0 { hair.move(to: p) } else { hair.addLine(to: p) }
            }
            silk.stroke(hair, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        }
    }

    @ViewBuilder
    static func bodyEdgeStrokeView(shape: ProfiledCatBodyShape, stretchRatio: CGFloat) -> some View {
        Canvas { context, _ in
            drawBodyEdge(context: &context, shape: shape, stretchRatio: stretchRatio)
        }
    }

    static func drawBodyEdge(context: inout GraphicsContext, shape: ProfiledCatBodyShape, stretchRatio: CGFloat) {
        let e = shape.edges()
        let n = e.left.count
        guard n > 2 else { return }

        // 1. 高斯柔化圆弧绒团
        var soft = context
        soft.addFilter(.blur(radius: 1.8))
        for side in 0..<2 {
            let pts = side == 0 ? e.left : e.right
            let color = side == 0
                ? Color(red: 0.60, green: 0.75, blue: 0.95)
                : Color(red: 0.40, green: 0.55, blue: 0.80)
            for i in stride(from: 1, to: n - 1, by: 2) {
                let t = CGFloat(i) / CGFloat(n - 1)
                let r: CGFloat = 4.4 - stretchRatio * 1.3 + (i % 4 == 1 ? 0.8 : 0) - sin(.pi * t) * stretchRatio * 0.6
                let p = pts[i]
                soft.fill(
                    Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                    with: .color(color.opacity(0.85))
                )
            }
        }

        // 2. 外沿柔和弧形绒毛线
        var arcCtx = context
        arcCtx.addFilter(.blur(radius: 0.7))
        for side in 0..<2 {
            let pts = side == 0 ? e.left : e.right
            for i in stride(from: 2, to: n - 2, by: 2) {
                let t = CGFloat(i) / CGFloat(n - 1)
                let center = shape.frame(at: t).center
                let p = pts[i]
                let vx = p.x - center.x
                let vy = p.y - center.y
                let vl = max(hypot(vx, vy), 0.001)
                let ox = vx / vl
                let oy = vy / vl
                let a = pts[i - 1]
                let b = pts[i + 1]
                var arc = Path()
                arc.move(to: a)
                arc.addQuadCurve(to: b, control: CGPoint(x: p.x + ox * 2.6, y: p.y + oy * 2.6))
                let c = (i % 4 == 0)
                    ? Color(red: 0.84, green: 0.93, blue: 1.0).opacity(0.70)
                    : Color(red: 0.56, green: 0.72, blue: 0.93).opacity(0.70)
                arcCtx.stroke(arc, with: .color(c), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
            }
        }
    }
}

/// 蓝猫短毛绒头部覆盖层
struct BluePlushHeadMaterialOverlay: View {
    let headShape: MochiCatHeadShape
    let earFlatten: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat

    var body: some View {
        ZStack {
            // 1. 外围高斯柔化云朵绒球光晕
            Canvas { context, size in
                let pts = sampleHeadPerimeterPoints(
                    in: CGRect(origin: .zero, size: size),
                    earFlatten: earFlatten,
                    leftEarTwitch: leftEarTwitch,
                    rightEarTwitch: rightEarTwitch
                )
                for (i, pt) in pts.enumerated() {
                    let isCheek = pt.y > size.height * 0.40
                    let r: CGFloat = isCheek ? (4.2 + CGFloat(i % 2) * 1.1) : (3.0 + CGFloat(i % 2) * 0.8)
                    let puffRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    let puffColor = isCheek
                        ? Color(red: 0.72, green: 0.85, blue: 0.98).opacity(0.85)
                        : Color(red: 0.50, green: 0.66, blue: 0.88).opacity(0.82)
                    context.fill(Path(ellipseIn: puffRect), with: .color(puffColor))
                }
            }
            .blur(radius: 2.0)

            // 2. 头部内部柔顺丝绒毛流 + 云朵柔化冰蓝面罩 + 耳内蓬松绒团 + 脸颊斑纹
            Canvas { context, size in
                let cx = size.width * 0.5
                let cy = size.height * 0.54
                let softDark = Color(red: 0.34, green: 0.49, blue: 0.75)
                let frostFur = Color(red: 0.86, green: 0.94, blue: 1.00)

                let maskPuffs: [(dx: CGFloat, dy: CGFloat, rx: CGFloat, ry: CGFloat)] = [
                    (0, 6.0, 21.0, 14.2),
                    (-11, 5.5, 11.5, 11.0),
                    (11, 5.5, 11.5, 11.0),
                    (-16, 9.0, 8.5, 7.5),
                    (16, 9.0, 8.5, 7.5)
                ]
                for mp in maskPuffs {
                    let rect = CGRect(x: cx + mp.dx - mp.rx, y: cy + mp.dy - mp.ry, width: mp.rx * 2, height: mp.ry * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(red: 0.86, green: 0.94, blue: 1.0).opacity(0.88),
                                Color(red: 0.76, green: 0.88, blue: 0.99).opacity(0.0)
                            ]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: min(mp.rx, mp.ry) * 0.45,
                            endRadius: max(mp.rx, mp.ry)
                        )
                    )
                }

                for i in 0..<28 {
                    let a = CGFloat(i) / 28.0 * .pi * 2.0
                    let rStart: CGFloat = 11.0 + CGFloat(i % 2) * 4.5
                    let rEnd = rStart + 6.5
                    let p0 = CGPoint(x: cx + cos(a) * rStart, y: cy + sin(a) * (rStart * 0.82) - 1.5)
                    let p1 = CGPoint(x: cx + cos(a) * rEnd, y: cy + sin(a) * (rEnd * 0.82) - 1.0)
                    let ctrl = CGPoint(
                        x: (p0.x + p1.x) * 0.5 - sin(a) * 1.8,
                        y: (p0.y + p1.y) * 0.5 + cos(a) * 1.8
                    )
                    var lock = Path()
                    lock.move(to: p0)
                    lock.addQuadCurve(to: p1, control: ctrl)
                    let isLower = p0.y > cy - 1
                    context.stroke(
                        lock,
                        with: .color((isLower ? frostFur : softDark).opacity(0.45)),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )
                }

                let ef = min(max(earFlatten, 0), 1)
                for side in [-1.0, 1.0] as [CGFloat] {
                    let earBaseX = cx + side * (15.0 + ef * 2.5)
                    let earBaseY = size.height * (0.23 + ef * 0.08)
                    let earPuff = CGRect(x: earBaseX - 4.5, y: earBaseY - 4.0, width: 9.0, height: 7.5)
                    context.fill(
                        Path(ellipseIn: earPuff),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(red: 0.92, green: 0.97, blue: 1.0).opacity(0.85),
                                Color(red: 0.80, green: 0.90, blue: 1.0).opacity(0.0)
                            ]),
                            center: CGPoint(x: earBaseX, y: earBaseY),
                            startRadius: 1,
                            endRadius: 4.8
                        )
                    )
                }

                let stripeColor = Color(red: 0.25, green: 0.23, blue: 0.48).opacity(0.85)
                for side in [-1.0, 1.0] as [CGFloat] {
                    for row in -1...1 {
                        let r = CGFloat(row)
                        let sx = cx + side * 17.5
                        let sy = cy + 3.2 + r * 3.8
                        let angle = side * r * 0.20
                        let halfL: CGFloat = (row == 0) ? 4.4 : 3.8
                        var stripe = Path()
                        stripe.move(to: CGPoint(x: sx - cos(angle) * halfL, y: sy - sin(angle) * halfL))
                        stripe.addLine(to: CGPoint(x: sx + cos(angle) * halfL, y: sy + sin(angle) * halfL))
                        context.stroke(stripe, with: .color(stripeColor), style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
                    }
                }
            }
            .clipShape(headShape)

            // 3. 外沿第二层微柔化圆弧绒毛圈
            Canvas { context, size in
                let pts = sampleHeadPerimeterPoints(
                    in: CGRect(origin: .zero, size: size),
                    earFlatten: earFlatten,
                    leftEarTwitch: leftEarTwitch,
                    rightEarTwitch: rightEarTwitch
                )
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
                for (i, pt) in pts.enumerated() {
                    let vx = pt.x - center.x
                    let vy = pt.y - center.y
                    let vLen = max(hypot(vx, vy), 0.001)
                    let outX = vx / vLen
                    let outY = vy / vLen
                    let tanX = -outY
                    let tanY = outX

                    var softArc = Path()
                    let span: CGFloat = 2.6
                    let lift: CGFloat = (pt.y > size.height * 0.42) ? 2.5 : 1.7
                    softArc.move(to: CGPoint(x: pt.x - tanX * span, y: pt.y - tanY * span))
                    softArc.addQuadCurve(
                        to: CGPoint(x: pt.x + tanX * span, y: pt.y + tanY * span),
                        control: CGPoint(x: pt.x + outX * lift, y: pt.y + outY * lift)
                    )
                    let arcColor = (i % 2 == 0)
                        ? Color(red: 0.82, green: 0.92, blue: 1.0).opacity(0.78)
                        : Color(red: 0.58, green: 0.74, blue: 0.94).opacity(0.75)
                    context.stroke(softArc, with: .color(arcColor), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                }
            }
            .blur(radius: 0.75)
        }
    }
}
