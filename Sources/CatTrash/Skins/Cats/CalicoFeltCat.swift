import SwiftUI

// MARK: - 3. 三花猫 · 羊毛毡手作 (Calico Felt) 皮肤模块

enum CalicoFeltSkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        // 羊毛毡：像扯棉花毛条，中段变细
        p.pinch = 0.56
        p.pinchExponent = 1.4
        p.minHalfWidth = 7
        p.endBulge = 1.5
        p.basePoolFlare = 4.0
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.98, green: 0.95, blue: 0.90), location: 0.0),
            .init(color: Color(red: 0.94, green: 0.89, blue: 0.82), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color(red: 1.0, green: 0.98, blue: 0.94).opacity(0.85)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        shape: ProfiledCatBodyShape,
        stretchRatio: CGFloat,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        drawCalicoStretchedFelt(
            context: &context,
            shape: shape,
            stretchRatio: stretchRatio,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    @ViewBuilder
    static func bodyEdgeStrokeView(shape: ProfiledCatBodyShape, stretchRatio: CGFloat) -> some View {
        Canvas { context, _ in
            drawCalicoFeltedEdgeFibers(context: &context, shape: shape, stretchRatio: stretchRatio)
        }
    }

    // MARK: - 内部纹理绘制逻辑
    static func drawCalicoStretchedFelt(
        context: inout GraphicsContext,
        shape: ProfiledCatBodyShape,
        stretchRatio: CGFloat,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) {
        let s = stretchRatio
        let oatmeal = Color(red: 0.82, green: 0.74, blue: 0.64)

        // 1. 顺着拉伸方向的羊毛纤维（中段越拉越稀疏）
        for i in 0..<70 {
            let fi = CGFloat(i)
            let t = 0.04 + (fi * 0.618).truncatingRemainder(dividingBy: 1) * 0.92
            let u = (fi * 0.377).truncatingRemainder(dividingBy: 1) * 2 - 1
            let bell = sin(.pi * t)
            let density = 1 - 0.7 * s * bell
            if CGFloat(i % 10) / 10.0 > density { continue }
            let f = shape.frame(at: t)
            let w = shape.halfWidth(at: t)
            let len: CGFloat = 3.0 + s * 8.0
            let tilt = sin(fi * 2.1) * 0.5 * (1 - s * 0.75)
            let dx = f.tangent.dx * cos(tilt) + f.normal.dx * sin(tilt)
            let dy = f.tangent.dy * cos(tilt) + f.normal.dy * sin(tilt)
            let c = CGPoint(x: f.center.x + f.normal.dx * u * w * 0.85, y: f.center.y + f.normal.dy * u * w * 0.85)
            var fiber = Path()
            fiber.move(to: CGPoint(x: c.x - dx * len * 0.5, y: c.y - dy * len * 0.5))
            fiber.addQuadCurve(
                to: CGPoint(x: c.x + dx * len * 0.5, y: c.y + dy * len * 0.5),
                control: CGPoint(x: c.x + f.normal.dx * 0.9, y: c.y + f.normal.dy * 0.9)
            )
            let col = (i % 2 == 0) ? oatmeal.opacity(0.55 * density) : Color.white.opacity(0.70 * density)
            context.stroke(fiber, with: .color(col), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }

        // 2. 随身体拉伸被等比扯成细长椭圆的橙/黑毛毡色块
        let patches: [(t: CGFloat, side: CGFloat, isOrange: Bool)] = [
            (0.24, 0.45, true),
            (0.50, -0.42, false),
            (0.72, 0.40, true),
            (0.86, -0.45, false)
        ]
        for (idx, patch) in patches.enumerated() {
            let f = shape.frame(at: patch.t)
            let w = shape.halfWidth(at: patch.t)
            let bell = sin(.pi * patch.t)
            let cx = f.center.x + f.normal.dx * patch.side * w
            let cy = f.center.y + f.normal.dy * patch.side * w
            let rx = max(3.0, w * 0.52)              // 横向随腰身变细
            let ry: CGFloat = 8.0 * (1 + s * 2.6)    // 纵向随拉伸拉长
            let base = patch.isOrange
                ? Color(red: 0.92, green: 0.49, blue: 0.17)
                : Color(red: 0.21, green: 0.20, blue: 0.19)
            let hi = patch.isOrange
                ? Color(red: 0.98, green: 0.68, blue: 0.34)
                : Color(red: 0.38, green: 0.36, blue: 0.34)

            func blobPoint(_ a: CGFloat, _ scale: CGFloat) -> CGPoint {
                CGPoint(
                    x: cx + f.tangent.dx * cos(a) * ry * scale + f.normal.dx * sin(a) * rx * scale,
                    y: cy + f.tangent.dy * cos(a) * ry * scale + f.normal.dy * sin(a) * rx * scale
                )
            }

            var blob = Path()
            for i in 0...26 {
                let a = CGFloat(i) / 26 * .pi * 2
                let wob = 1.0 + 0.11 * sin(a * 5 + CGFloat(idx) * 2.1) + 0.07 * cos(a * 7)
                let p = blobPoint(a, wob)
                if i == 0 { blob.move(to: p) } else { blob.addLine(to: p) }
            }
            blob.closeSubpath()
            context.fill(blob, with: .color(base.opacity(0.92 * (1 - 0.3 * s * bell))))

            // 色块边缘顺着拉伸方向被扯出的毛毡纤维
            for k in 0..<30 {
                let a = CGFloat(k) / 30 * .pi * 2 + CGFloat(idx) * 0.5
                let p = blobPoint(a, 0.88 + 0.16 * sin(CGFloat(k) * 3.7))
                let tilt = sin(CGFloat(k) * 2.3) * 0.6 * (1 - s * 0.5)
                let dx = f.tangent.dx * cos(tilt) + f.normal.dx * sin(tilt)
                let dy = f.tangent.dy * cos(tilt) + f.normal.dy * sin(tilt)
                let len: CGFloat = 2.6 + CGFloat(k % 3) * 1.0 + s * 3.0
                var wisp = Path()
                wisp.move(to: CGPoint(x: p.x - dx * len * 0.5, y: p.y - dy * len * 0.5))
                wisp.addLine(to: CGPoint(x: p.x + dx * len * 0.5, y: p.y + dy * len * 0.5))
                let c = (k % 3 == 0) ? Color(red: 0.96, green: 0.92, blue: 0.85) : base
                context.stroke(wisp, with: .color(c.opacity(0.85)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }
            // 戳针混纺杂色
            for d in 0..<7 {
                let a = CGFloat(d) * 0.9 + CGFloat(idx)
                let p = blobPoint(a, CGFloat(d % 3 + 1) * 0.25)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 0.8, y: p.y - 0.8, width: 1.6, height: 1.6)), with: .color(hi.opacity(0.65)))
            }
        }

        // 3. 中段被扯薄：透光度增加
        if s > 0.02 {
            context.blendMode = .destinationOut
            context.fill(
                Path(CGRect(x: -4000, y: -4000, width: 8000, height: 8000)),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.18),
                        .init(color: Color.black.opacity(0.40 * s), location: 0.52),
                        .init(color: .clear, location: 0.86),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            context.blendMode = .normal
        }
    }

    static func drawCalicoFeltedEdgeFibers(context: inout GraphicsContext, shape: ProfiledCatBodyShape, stretchRatio: CGFloat) {
        let e = shape.edges()
        let n = e.left.count
        guard n > 2 else { return }
        let s = stretchRatio
        for side in 0..<2 {
            let pts = side == 0 ? e.left : e.right
            for i in 0..<(n - 1) {
                let t = CGFloat(i) / CGFloat(n - 1)
                let bell = sin(.pi * t)
                // 中段被扯薄后飞丝更稀疏
                if s * bell > 0.45 && i % 2 == 1 { continue }
                let p = pts[i]
                let q = pts[i + 1]
                let center = shape.frame(at: t).center
                let vx = p.x - center.x
                let vy = p.y - center.y
                let vl = max(hypot(vx, vy), 0.001)
                let ox = vx / vl
                let oy = vy / vl
                let tl = max(hypot(q.x - p.x, q.y - p.y), 0.001)
                let tx = (q.x - p.x) / tl
                let ty = (q.y - p.y) / tl
                let len: CGFloat = 2.2 + CGFloat(i % 3) * 0.9 + s * 1.2
                let curl: CGFloat = (i % 2 == 0) ? 1.6 : -1.6
                var wisp = Path()
                wisp.move(to: CGPoint(x: p.x - ox * 0.6, y: p.y - oy * 0.6))
                wisp.addQuadCurve(
                    to: CGPoint(x: p.x + ox * len + tx * curl, y: p.y + oy * len + ty * curl),
                    control: CGPoint(x: p.x + ox * len * 0.6 - tx * curl * 0.6, y: p.y + oy * len * 0.6 - ty * curl * 0.6)
                )
                let color: Color = {
                    if side == 0 && ((t > 0.16 && t < 0.34) || (t > 0.64 && t < 0.80)) {
                        return Color(red: 0.93, green: 0.52, blue: 0.20)
                    } else if side == 1 && ((t > 0.40 && t < 0.60) || t > 0.80) {
                        return Color(red: 0.26, green: 0.25, blue: 0.24)
                    }
                    return Color(red: 0.92, green: 0.86, blue: 0.78)
                }()
                context.stroke(
                    wisp,
                    with: .color(color.opacity(0.86 * (1 - 0.45 * s * bell))),
                    style: StrokeStyle(lineWidth: 0.85, lineCap: .round)
                )
            }
        }
    }
}

// MARK: - 三花羊毛毡头部专属材质与边缘飞丝
struct CalicoFeltHeadMaterialOverlay: View {
    let headShape: MochiCatHeadShape
    let earFlatten: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat

    var body: some View {
        ZStack {
            // 1. 戳戳乐无硬边羊毛毡色块 + 跨界互渗杂毛丝 + 全脸粗纺羊毛纤维网与针织线圈纹
            Canvas { context, size in
                let patches: [(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, color: Color, highlight: Color)] = [
                    // 左上暖橙色羊毛毡色块
                    (14.0, 14.0, 16.5, 15.0, Color(red: 0.92, green: 0.49, blue: 0.17), Color(red: 0.99, green: 0.69, blue: 0.36)),
                    // 右上炭黑色羊毛毡色块
                    (46.5, 14.5, 15.5, 14.0, Color(red: 0.22, green: 0.21, blue: 0.20), Color(red: 0.40, green: 0.38, blue: 0.36)),
                    // 右下腮帮小暖橘毛毡斑
                    (49.5, 34.5, 8.0, 6.2, Color(red: 0.93, green: 0.54, blue: 0.21), Color(red: 0.99, green: 0.74, blue: 0.42))
                ]

                let creamFiber = Color(red: 0.97, green: 0.93, blue: 0.87)
                let oatmealFiber = Color(red: 0.82, green: 0.74, blue: 0.64)

                // A. 绘制戳戳乐不规则羊毛毡色块与边缘交织毛刺
                for (pIdx, p) in patches.enumerated() {
                    var blob = Path()
                    let steps = 28
                    for i in 0...steps {
                        let a = CGFloat(i) / CGFloat(steps) * .pi * 2.0
                        let wobble = 1.0 + 0.10 * sin(a * 6.0 + CGFloat(pIdx) * 1.7) + 0.07 * cos(a * 9.0)
                        let px = p.cx + cos(a) * p.rx * wobble
                        let py = p.cy + sin(a) * p.ry * wobble
                        if i == 0 {
                            blob.move(to: CGPoint(x: px, y: py))
                        } else {
                            blob.addLine(to: CGPoint(x: px, y: py))
                        }
                    }
                    blob.closeSubpath()
                    context.fill(blob, with: .color(p.color.opacity(0.96)))

                    // 色块边缘犬牙交错毛刺飞丝（模拟戳针扎入羊毛底板的纤维交融）
                    let edgeSpikes = 32
                    for k in 0..<edgeSpikes {
                        let a = CGFloat(k) / CGFloat(edgeSpikes) * .pi * 2.0 + CGFloat(pIdx) * 0.4
                        let wobble = 1.0 + 0.10 * sin(a * 6.0 + CGFloat(pIdx) * 1.7)
                        let bx = p.cx + cos(a) * p.rx * wobble
                        let by = p.cy + sin(a) * p.ry * wobble
                        let spikeLen: CGFloat = 2.4 + CGFloat(k % 3) * 1.1
                        let angleJitter = sin(CGFloat(k) * 2.7) * 0.45
                        let dirX = cos(a + angleJitter)
                        let dirY = sin(a + angleJitter)

                        var spike = Path()
                        spike.move(to: CGPoint(x: bx - dirX * 0.8, y: by - dirY * 0.8))
                        spike.addLine(to: CGPoint(x: bx + dirX * spikeLen, y: by + dirY * spikeLen))
                        let spikeCol = (k % 4 == 0) ? p.highlight : p.color
                        context.stroke(
                            spike,
                            with: .color(spikeCol.opacity(0.90)),
                            style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
                        )
                    }

                    // 戳针孔点与深浅混纺微颗粒
                    let needlePokes: [(dx: CGFloat, dy: CGFloat, r: CGFloat)] = [
                        (-3.5, -2.0, 0.7), (2.0, -4.0, 0.8), (4.0, 2.5, 0.65), (-2.0, 3.5, 0.75), (0.0, 0.0, 0.9)
                    ]
                    for poke in needlePokes {
                        let dotRect = CGRect(x: p.cx + poke.dx - poke.r, y: p.cy + poke.dy - poke.r, width: poke.r * 2, height: poke.r * 2)
                        context.fill(Path(ellipseIn: dotRect), with: .color(p.highlight.opacity(0.70)))
                    }
                }

                // B. 色块交界处跨界互渗的异色细纤维
                let crossFibers: [(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat, color: Color)] = [
                    (30.0, 14.0, 4.0, 1.2, Color(red: 0.92, green: 0.49, blue: 0.17)),
                    (31.5, 16.5, -3.5, 0.8, Color(red: 0.22, green: 0.21, blue: 0.20)),
                    (29.0, 19.0, 4.2, -1.0, oatmealFiber),
                    (45.0, 28.0, 3.0, 2.5, Color(red: 0.93, green: 0.54, blue: 0.21)),
                    (47.0, 26.5, -2.5, -2.0, creamFiber)
                ]
                for cf in crossFibers {
                    var strand = Path()
                    strand.move(to: CGPoint(x: cf.x - cf.dx, y: cf.y - cf.dy))
                    strand.addQuadCurve(
                        to: CGPoint(x: cf.x + cf.dx, y: cf.y + cf.dy),
                        control: CGPoint(x: cf.x - cf.dy * 0.5, y: cf.y + cf.dx * 0.5)
                    )
                    context.stroke(strand, with: .color(cf.color.opacity(0.75)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
                }

                // C. 全脸粗纺羊毛纤维网与针织线圈纹
                let fiberGrid: [(x: CGFloat, y: CGFloat, len: CGFloat, rot: CGFloat, col: Color)] = [
                    (18, 28, 5.0, 0.3, creamFiber),
                    (25, 33, 6.0, -0.4, oatmealFiber),
                    (33, 27, 4.5, 0.7, creamFiber),
                    (38, 34, 5.5, -0.2, oatmealFiber),
                    (22, 10, 4.0, 0.5, creamFiber),
                    (40, 11, 4.5, -0.6, creamFiber),
                    (31, 7, 5.0, 0.1, oatmealFiber),
                    (15, 38, 4.0, -0.3, creamFiber),
                    (43, 38, 4.2, 0.4, creamFiber)
                ]
                for fg in fiberGrid {
                    let rx = cos(fg.rot) * fg.len * 0.5
                    let ry = sin(fg.rot) * fg.len * 0.5
                    var strand = Path()
                    strand.move(to: CGPoint(x: fg.x - rx, y: fg.y - ry))
                    strand.addQuadCurve(
                        to: CGPoint(x: fg.x + rx, y: fg.y + ry),
                        control: CGPoint(x: fg.x - ry * 0.6, y: fg.y + rx * 0.6)
                    )
                    context.stroke(strand, with: .color(fg.col.opacity(0.65)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                }
            }
            .clipShape(headShape)

            // 2. 头部外轮廓：纯手工针扎羊毛毡飞翘杂毛圈（粗细长短错落，彻底打破平滑矢量描边）
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let pts = sampleHeadPerimeterPoints(
                    in: rect,
                    earFlatten: earFlatten,
                    leftEarTwitch: leftEarTwitch,
                    rightEarTwitch: rightEarTwitch
                )
                guard pts.count > 2 else { return }
                let center = CGPoint(x: size.width * 0.50, y: size.height * 0.52)

                for i in 0..<pts.count {
                    let p = pts[i]
                    let nextP = pts[(i + 1) % pts.count]
                    let vx = p.x - center.x
                    let vy = p.y - center.y
                    let vlen = max(hypot(vx, vy), 0.001)
                    let ox = vx / vlen
                    let oy = vy / vlen
                    let tx = (nextP.x - p.x)
                    let ty = (nextP.y - p.y)
                    let tlen = max(hypot(tx, ty), 0.001)
                    let normTx = tx / tlen
                    let normTy = ty / tlen

                    // 根据所在部位决定飞丝主色调：左耳橙色、右耳炭黑、脸颊米白色
                    let fiberColor: Color = {
                        if p.x < size.width * 0.42 && p.y < size.height * 0.38 {
                            return Color(red: 0.92, green: 0.49, blue: 0.17)
                        } else if p.x > size.width * 0.58 && p.y < size.height * 0.38 {
                            return Color(red: 0.22, green: 0.21, blue: 0.20)
                        } else if p.x > size.width * 0.70 && p.y > size.height * 0.48 {
                            return (i % 2 == 0) ? Color(red: 0.93, green: 0.54, blue: 0.21) : Color(red: 0.94, green: 0.90, blue: 0.84)
                        } else {
                            return Color(red: 0.95, green: 0.91, blue: 0.85)
                        }
                    }()

                    // A. 主向外翘出的羊毛单纤维
                    let length: CGFloat = 2.4 + CGFloat((i * 7) % 5) * 0.75
                    let curl: CGFloat = ((i % 2 == 0) ? 1.0 : -1.0) * (1.2 + CGFloat(i % 3) * 0.5)
                    let targetX = p.x + ox * length + normTx * curl
                    let targetY = p.y + oy * length + normTy * curl
                    let ctrlX = p.x + ox * length * 0.6 - normTx * curl * 0.4
                    let ctrlY = p.y + oy * length * 0.6 - normTy * curl * 0.4

                    var fiber = Path()
                    fiber.move(to: CGPoint(x: p.x - ox * 0.6, y: p.y - oy * 0.6))
                    fiber.addQuadCurve(to: CGPoint(x: targetX, y: targetY), control: CGPoint(x: ctrlX, y: ctrlY))
                    context.stroke(
                        fiber,
                        with: .color(fiberColor.opacity(0.88)),
                        style: StrokeStyle(lineWidth: 0.95, lineCap: .round)
                    )

                    // B. 间歇出现的针织倒钩毛圈（小弯曲圆弧）
                    if i % 3 == 0 {
                        let loopLen: CGFloat = 1.8 + CGFloat((i * 11) % 4) * 0.5
                        var loop = Path()
                        loop.move(to: p)
                        loop.addCurve(
                            to: CGPoint(x: p.x + normTx * 2.2, y: p.y + normTy * 2.2),
                            control1: CGPoint(x: p.x + ox * loopLen + normTx * 1.0, y: p.y + oy * loopLen + normTy * 1.0),
                            control2: CGPoint(x: p.x + ox * loopLen + normTx * 2.0, y: p.y + oy * loopLen + normTy * 2.0)
                        )
                        context.stroke(
                            loop,
                            with: .color(fiberColor.opacity(0.72)),
                            style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
                        )
                    }
                }
            }
        }
    }
}
