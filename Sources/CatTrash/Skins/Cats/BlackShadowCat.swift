import SwiftUI

// MARK: - 6. 黑猫 · 暗影烟雾 (Black Shadow) 皮肤模块

enum BlackShadowSkin {
    static func configureProfile(_ p: inout ProfiledCatBodyShape) {
        // 暗影烟雾无特定形变约束
    }

    static var cylinderBaseStops: [Gradient.Stop] {
        [
            .init(color: Color(red: 0.06, green: 0.06, blue: 0.09), location: 0.0),
            .init(color: Color(red: 0.12, green: 0.10, blue: 0.18), location: 1.0)
        ]
    }

    static var bellyHighlightColor: Color {
        Color.black.opacity(0.92)
    }

    static func drawBodyTextures(
        context: inout GraphicsContext,
        startPoint: CGPoint,
        endPoint: CGPoint,
        c1: CGPoint,
        c2: CGPoint
    ) {
        // 黑猫暗影烟雾：翻滚的幽暗烟缕与墨水消融感
        for offset in [-10.0, 6.0] as [CGFloat] {
            var smokeWisp = Path()
            smokeWisp.move(to: CGPoint(x: startPoint.x + offset, y: startPoint.y))
            smokeWisp.addCurve(
                to: CGPoint(x: endPoint.x - offset, y: endPoint.y),
                control1: CGPoint(x: c1.x + offset * 1.4, y: c1.y),
                control2: CGPoint(x: c2.x - offset * 1.2, y: c2.y)
            )
            context.stroke(
                smokeWisp,
                with: .color(Color(red: 0.25, green: 0.20, blue: 0.38).opacity(0.45)),
                style: StrokeStyle(lineWidth: 4.0, lineCap: .round)
            )
        }
    }

    @ViewBuilder
    static func bodyEdgeStrokeView(shape: ProfiledCatBodyShape) -> some View {
        // 暗影水墨消散羽化边缘
        shape.stroke(
            Color(red: 0.24, green: 0.20, blue: 0.36).opacity(0.60),
            style: StrokeStyle(lineWidth: 3.0, lineCap: .round, dash: [3, 3])
        )
        .blur(radius: 1.2)
    }

    /// 黑猫专属：由多层连续交织的正弦波动黑烟丝带与边缘流烟构成的无缝暗影流体（绝不分成一个个黑团）
    @ViewBuilder
    static func shadowSmokeBodyView(
        startPoint: CGPoint,
        endPoint: CGPoint,
        spine: (c1: CGPoint, c2: CGPoint),
        stretchRatio: CGFloat,
        waistScale: CGFloat,
        phase: CGFloat
    ) -> some View {
        ZStack {
            // 第一层：外围大范围柔化暗影雾气光晕（高模糊连续流体包络）
            Canvas { context, _ in
                let mistPath = buildUndulatingSmokeEnvelope(
                    startPoint: startPoint,
                    endPoint: endPoint,
                    c1: spine.c1,
                    c2: spine.c2,
                    baseHalfW: 27,
                    headHalfW: 24,
                    waveAmp: 4.5 + stretchRatio * 6.0,
                    waveFreq: 7.0,
                    phaseOffset: 0.0,
                    stretchRatio: stretchRatio,
                    phase: phase
                )
                let mistMid = 0.42 * Double(1 - stretchRatio * 0.75)
                context.fill(
                    mistPath,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color.black.opacity(0.65), location: 0.0),
                            .init(color: Color(red: 0.08, green: 0.06, blue: 0.14).opacity(mistMid), location: 0.55),
                            .init(color: Color.black.opacity(0.60), location: 1.0)
                        ]),
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )
            }
            .blur(radius: 6.5)

            // 第二层：核心连续暗影流 + 4 股交织升腾的连续黑烟丝带（完全连续的 Path，无任何断节圆团）
            Canvas { context, _ in
                // A. 中心连续浓墨暗影主躯干（边缘随相位如火焰/黑烟般柔和起伏）
                let coreEnvelope = buildUndulatingSmokeEnvelope(
                    startPoint: startPoint,
                    endPoint: endPoint,
                    c1: spine.c1,
                    c2: spine.c2,
                    baseHalfW: 21,
                    headHalfW: 19,
                    waveAmp: 3.0 + stretchRatio * 4.5,
                    waveFreq: 9.0,
                    phaseOffset: 1.2,
                    stretchRatio: stretchRatio,
                    phase: phase
                )
                let s = Double(stretchRatio)
                let fadeAlpha = Double(max(0.68, 0.96 - stretchRatio * 0.22))
                context.fill(
                    coreEnvelope,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color.black.opacity(fadeAlpha), location: 0.0),
                            .init(color: Color(red: 0.05, green: 0.04, blue: 0.08).opacity(fadeAlpha * (1 - 0.45 * s)), location: 0.30),
                            .init(color: Color(red: 0.06, green: 0.04, blue: 0.10).opacity(fadeAlpha * (1 - 0.82 * s)), location: 0.62),
                            .init(color: Color.black.opacity(fadeAlpha * (1 - 0.55 * s)), location: 0.88),
                            .init(color: Color.black.opacity(fadeAlpha * 0.85), location: 1.0)
                        ]),
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                )

                // B. 4 股沿脊柱连续缠绕上升的半透明黑烟流线丝带
                let ribbonConfigs: [(offset: CGFloat, freq: CGFloat, speed: CGFloat, width: CGFloat, alpha: Double)] = [
                    (-9.0, 6.5, 2.4, 12.0, 0.55),
                    (9.0, 7.5, -2.1, 12.0, 0.55),
                    (-4.5, 10.0, 3.0, 8.5, 0.40),
                    (5.0, 8.5, -2.8, 9.0, 0.42)
                ]

                for cfg in ribbonConfigs {
                    var ribbon = Path()
                    let samples = 48
                    for i in 0...samples {
                        let t = CGFloat(i) / CGFloat(samples)
                        let pt = cubicBezierPoint(t: t, p0: startPoint, c1: spine.c1, c2: spine.c2, p3: endPoint)
                        let pinch = 1.0 - 0.36 * sin(.pi * t) * stretchRatio
                        let wave = sin(t * cfg.freq - phase * cfg.speed) * (4.0 + stretchRatio * 3.5)
                        let x = pt.x + (cfg.offset + wave) * pinch
                        let y = pt.y
                        if i == 0 {
                            ribbon.move(to: CGPoint(x: x, y: y))
                        } else {
                            ribbon.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    context.stroke(
                        ribbon,
                        with: .linearGradient(
                            Gradient(stops: [
                                .init(color: Color.black.opacity(cfg.alpha), location: 0.0),
                                .init(color: Color.black.opacity(cfg.alpha * (1 - 0.85 * s)), location: 0.6),
                                .init(color: Color.black.opacity(cfg.alpha * (1 - 0.4 * s)), location: 1.0)
                            ]),
                            startPoint: startPoint,
                            endPoint: endPoint
                        ),
                        style: StrokeStyle(lineWidth: cfg.width * waistScale, lineCap: .round, lineJoin: .round)
                    )
                }

                // C. 两侧边缘向上剥离消散的丝状流烟
                for tBase in [0.22, 0.42, 0.62, 0.80] as [CGFloat] {
                    let side: CGFloat = (Int(tBase * 10) % 2 == 0) ? -1.0 : 1.0
                    let pStart = cubicBezierPoint(t: tBase, p0: startPoint, c1: spine.c1, c2: spine.c2, p3: endPoint)
                    let pEnd = cubicBezierPoint(t: min(tBase + 0.14, 0.98), p0: startPoint, c1: spine.c1, c2: spine.c2, p3: endPoint)
                    let pinch = 1.0 - 0.36 * sin(.pi * tBase) * stretchRatio
                    let edgeX = pStart.x + side * 18.0 * pinch

                    var wisp = Path()
                    wisp.move(to: CGPoint(x: edgeX, y: pStart.y))
                    wisp.addQuadCurve(
                        to: CGPoint(
                            x: pEnd.x + side * (25.0 * pinch + sin(phase * 2.5 + tBase * 10) * 4.0),
                            y: pEnd.y - 8.0
                        ),
                        control: CGPoint(x: edgeX + side * 8.0, y: (pStart.y + pEnd.y) * 0.5)
                    )
                    context.stroke(
                        wisp,
                        with: .linearGradient(
                            Gradient(colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)]),
                            startPoint: CGPoint(x: edgeX, y: pStart.y),
                            endPoint: CGPoint(x: edgeX, y: pEnd.y - 8.0)
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                }
            }
            .blur(radius: 2.6)
        }
    }

    /// 构建两侧带连续烟浪起伏的无缝闭合流体轮廓
    static func buildUndulatingSmokeEnvelope(
        startPoint: CGPoint,
        endPoint: CGPoint,
        c1: CGPoint,
        c2: CGPoint,
        baseHalfW: CGFloat,
        headHalfW: CGFloat,
        waveAmp: CGFloat,
        waveFreq: CGFloat,
        phaseOffset: CGFloat,
        stretchRatio: CGFloat,
        phase: CGFloat
    ) -> Path {
        let samples = 50
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []
        leftPoints.reserveCapacity(samples + 1)
        rightPoints.reserveCapacity(samples + 1)

        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let pt = cubicBezierPoint(t: t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            let baseW = baseHalfW + (headHalfW - baseHalfW) * t
            let bell = sin(.pi * t)
            let pinchFactor = 1.0 - 0.42 * bell * min(stretchRatio, 1.2)
            let currentHalfW = max(5.0, baseW * pinchFactor)

            let wave1 = sin(t * waveFreq - phase * 1.8 + phaseOffset) * waveAmp
            let wave2 = cos(t * (waveFreq * 1.4) + phase * 2.2) * (waveAmp * 0.6)
            let leftWave = (wave1 + wave2) * bell
            let rightWave = (wave1 - wave2) * bell

            let lx = pt.x - currentHalfW + leftWave
            let rx = pt.x + currentHalfW + rightWave
            leftPoints.append(CGPoint(x: lx, y: pt.y))
            rightPoints.append(CGPoint(x: rx, y: pt.y))
        }

        var path = Path()
        guard let firstLeft = leftPoints.first else { return path }
        path.move(to: firstLeft)
        for pt in leftPoints.dropFirst() {
            path.addLine(to: pt)
        }
        for pt in rightPoints.reversed() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}
