import SwiftUI

// MARK: - 样式 D：经典绿色可回收/环卫掀盖大垃圾桶（活动掀盖核心交互）

/// 经典掀盖绿桶整体放大倍率（以桶底为锚点向上放大，大桶显得猫更小巧）
let kGreenBinScale: CGFloat = 1.45
/// 绿桶各图层（画布 96x108，桶底位于 y=95）放大锚点
let kGreenBinAnchor = UnitPoint(x: 0.5, y: 95.0 / 108.0)
/// 掀盖与推盖爪图层（画布 220x180，桶底位于 y=90+41）放大锚点
let kGreenBinLidAnchor = UnitPoint(x: 0.5, y: 131.0 / 180.0)
/// 放大后绿桶桶口相对桶中心的 Y 偏移（桶中心坐标系，向上为负）
let kGreenBinRimY: CGFloat = 41.0 - 76.0 * kGreenBinScale

/// 样式 D（经典绿色可回收/环卫掀盖大垃圾桶 · 后壁：左下侧 3D 黑色橡胶滚轮 + 桶口深森林绿内腔暗槽 + 左侧铰链耳座）
struct GreenWheelieBinBackWallView: View {
    var body: some View {
        ZStack {
            // 1. 地面宽大落地阴影（包含左下橡胶轮接地影）
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.55), .black.opacity(0.24), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 50 * kGreenBinScale
                    )
                )
                .frame(width: 98 * kGreenBinScale, height: 22)
                .offset(x: -2, y: 42)

            Canvas { context, rawSize in
                let size = CGSize(width: rawSize.width / kGreenBinScale, height: rawSize.height / kGreenBinScale)
                context.scaleBy(x: kGreenBinScale, y: kGreenBinScale)
                let cx = size.width * 0.5
                let rimY: CGFloat = 19.0 // 对应 bucketLocalCenter.y - 35
                let botY: CGFloat = 95.0 // 对应 bucketLocalCenter.y + 41

                // 2. 左下角 3D 黑色橡胶滚轮（还原照片左下侧透视黑轮胎、深灰五辐轮毂与银色轴心）
                let wheelCenter = CGPoint(x: cx - 31.5, y: botY - 12.0)
                // (a) 后层轮胎厚度底影
                let tireBackRect = CGRect(x: wheelCenter.x - 8.2, y: wheelCenter.y - 12.5, width: 14.5, height: 25.0)
                context.fill(Path(ellipseIn: tireBackRect), with: .color(Color(white: 0.08)))

                // (b) 轮胎外侧胎面
                let tireFrontRect = CGRect(x: wheelCenter.x - 6.5, y: wheelCenter.y - 12.2, width: 13.5, height: 24.4)
                context.fill(
                    Path(ellipseIn: tireFrontRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(white: 0.28),
                            Color(white: 0.15),
                            Color(white: 0.09)
                        ]),
                        startPoint: CGPoint(x: tireFrontRect.minX, y: tireFrontRect.minY),
                        endPoint: CGPoint(x: tireFrontRect.maxX, y: tireFrontRect.maxY)
                    )
                )
                context.stroke(
                    Path(ellipseIn: tireFrontRect.insetBy(dx: 0.8, dy: 0.8)),
                    with: .color(Color(white: 0.38).opacity(0.65)),
                    lineWidth: 0.8
                )

                // (c) 轮毂内凹盘与 5 根加强轮辐
                let hubRect = CGRect(x: wheelCenter.x - 4.0, y: wheelCenter.y - 7.8, width: 8.2, height: 15.6)
                context.fill(Path(ellipseIn: hubRect), with: .color(Color(white: 0.14)))
                for s in 0..<5 {
                    let a = CGFloat(s) / 5.0 * .pi * 2.0
                    var spoke = Path()
                    spoke.move(to: wheelCenter)
                    spoke.addLine(to: CGPoint(x: wheelCenter.x + cos(a) * 3.6, y: wheelCenter.y + sin(a) * 7.0))
                    context.stroke(spoke, with: .color(Color(white: 0.34)), lineWidth: 1.0)
                }

                // (d) 中央亮银色金属轴头
                let axleRect = CGRect(x: wheelCenter.x - 1.7, y: wheelCenter.y - 2.6, width: 3.4, height: 5.2)
                context.fill(
                    Path(ellipseIn: axleRect),
                    with: .linearGradient(
                        Gradient(colors: [Color(white: 0.94), Color(white: 0.42)]),
                        startPoint: CGPoint(x: axleRect.minX, y: axleRect.minY),
                        endPoint: CGPoint(x: axleRect.maxX, y: axleRect.maxY)
                    )
                )

                // 3. 桶口上方深森林绿内腔暗槽
                var cavityPath = Path()
                cavityPath.move(to: CGPoint(x: cx - 39.5, y: rimY + 2.0))
                cavityPath.addLine(to: CGPoint(x: cx - 34.0, y: rimY - 5.5))
                cavityPath.addLine(to: CGPoint(x: cx + 38.0, y: rimY - 5.5))
                cavityPath.addLine(to: CGPoint(x: cx + 41.5, y: rimY + 2.0))
                cavityPath.addLine(to: CGPoint(x: cx + 35.0, y: rimY + 26.0))
                cavityPath.addLine(to: CGPoint(x: cx - 35.0, y: rimY + 26.0))
                cavityPath.closeSubpath()

                context.fill(
                    cavityPath,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.01, green: 0.11, blue: 0.05), location: 0.0),
                            .init(color: Color(red: 0.02, green: 0.18, blue: 0.09), location: 0.55),
                            .init(color: Color(red: 0.01, green: 0.09, blue: 0.04), location: 1.0)
                        ]),
                        startPoint: CGPoint(x: cx - 38, y: rimY - 5),
                        endPoint: CGPoint(x: cx + 38, y: rimY + 20)
                    )
                )

                // 4. 桶口左侧掀盖铰链耳座与后推把手圆杆
                let hingeMount = CGRect(x: cx - 43.0, y: rimY - 4.0, width: 6.5, height: 6.5)
                context.fill(
                    Path(roundedRect: hingeMount, cornerRadius: 2.0),
                    with: .color(Color(red: 0.03, green: 0.42, blue: 0.19))
                )
            }
            .frame(width: 96 * kGreenBinScale, height: 108 * kGreenBinScale)
            .offset(y: 41 * (1 - kGreenBinScale))
        }
    }
}

/// 样式 D（经典绿色可回收/环卫掀盖大垃圾桶 · 前壁：高耸 3/4 立体双折面 HDPE 绿塑桶身 + 桶口外翻裙檐与 4 道竖向加强筋 + 白色圆形环保扔垃圾图标）
struct GreenWheelieBinFrontWallView: View {
    var body: some View {
        Canvas { context, rawSize in
            let size = CGSize(width: rawSize.width / kGreenBinScale, height: rawSize.height / kGreenBinScale)
            context.scaleBy(x: kGreenBinScale, y: kGreenBinScale)
            let cx = size.width * 0.5
            let rimY: CGFloat = 19.0       // 对应 bucketLocalCenter.y - 35
            let botY: CGFloat = 95.0       // 对应 bucketLocalCenter.y + 41
            let topLeftX = cx - 37.5
            let topRightX = cx + 38.5
            let botLeftX = cx - 28.0
            let botRightX = cx + 29.0
            // 3/4 视角左侧面与正面的立体转折棱线
            let topCornerX = cx - 15.5
            let botCornerX = cx - 10.5

            // 1. 桶身左侧 3/4 斜切面（受光较亮，带左上角注塑高光反光块）
            var leftFace = Path()
            leftFace.move(to: CGPoint(x: topLeftX, y: rimY + 3.0))
            leftFace.addLine(to: CGPoint(x: topCornerX, y: rimY + 5.0))
            leftFace.addLine(to: CGPoint(x: botCornerX, y: botY))
            leftFace.addQuadCurve(
                to: CGPoint(x: botLeftX, y: botY - 5.5),
                control: CGPoint(x: botLeftX + 2.0, y: botY - 0.5)
            )
            leftFace.closeSubpath()

            context.fill(
                leftFace,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.12, green: 0.76, blue: 0.39), location: 0.0),
                        .init(color: Color(red: 0.07, green: 0.68, blue: 0.33), location: 0.45),
                        .init(color: Color(red: 0.04, green: 0.54, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: topLeftX, y: rimY),
                    endPoint: CGPoint(x: botCornerX, y: botY)
                )
            )

            // 左上桶壁柔和浅翠绿弧形高光区
            var leftSpec = Path()
            leftSpec.move(to: CGPoint(x: topLeftX + 2.0, y: rimY + 13.0))
            leftSpec.addQuadCurve(
                to: CGPoint(x: topCornerX - 1.5, y: rimY + 26.0),
                control: CGPoint(x: topCornerX - 2.0, y: rimY + 15.0)
            )
            leftSpec.addLine(to: CGPoint(x: botCornerX - 3.0, y: botY - 18.0))
            leftSpec.addLine(to: CGPoint(x: botLeftX + 1.5, y: botY - 24.0))
            leftSpec.closeSubpath()
            context.fill(
                leftSpec,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.36, green: 0.88, blue: 0.56).opacity(0.42),
                        Color(red: 0.18, green: 0.78, blue: 0.42).opacity(0.05)
                    ]),
                    startPoint: CGPoint(x: topLeftX, y: rimY + 14),
                    endPoint: CGPoint(x: topLeftX + 10, y: botY - 20)
                )
            )

            // 2. 桶身正面主面板
            var frontFace = Path()
            frontFace.move(to: CGPoint(x: topCornerX - 0.5, y: rimY + 5.0))
            frontFace.addLine(to: CGPoint(x: topRightX, y: rimY + 3.0))
            frontFace.addLine(to: CGPoint(x: botRightX, y: botY - 3.5))
            frontFace.addQuadCurve(
                to: CGPoint(x: botCornerX - 0.5, y: botY),
                control: CGPoint(x: (botCornerX + botRightX) * 0.5, y: botY + 1.8)
            )
            frontFace.closeSubpath()

            context.fill(
                frontFace,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.14, green: 0.78, blue: 0.40), location: 0.0),
                        .init(color: Color(red: 0.05, green: 0.65, blue: 0.31), location: 0.18),
                        .init(color: Color(red: 0.03, green: 0.56, blue: 0.26), location: 0.65),
                        .init(color: Color(red: 0.02, green: 0.45, blue: 0.20), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: topCornerX, y: rimY),
                    endPoint: CGPoint(x: topRightX, y: rimY)
                )
            )

            // 3/4 转折棱线上的竖向高光带
            var ridgeLine = Path()
            ridgeLine.move(to: CGPoint(x: topCornerX, y: rimY + 6.0))
            ridgeLine.addLine(to: CGPoint(x: botCornerX, y: botY - 1.5))
            context.stroke(
                ridgeLine,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.45, green: 0.92, blue: 0.64).opacity(0.65),
                        Color(red: 0.25, green: 0.82, blue: 0.48).opacity(0.25)
                    ]),
                    startPoint: CGPoint(x: topCornerX, y: rimY + 6),
                    endPoint: CGPoint(x: botCornerX, y: botY)
                ),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
            )

            // 底部圆润加厚底沿高光与暗影线
            var bottomEdge = Path()
            bottomEdge.move(to: CGPoint(x: botLeftX + 1.0, y: botY - 5.2))
            bottomEdge.addLine(to: CGPoint(x: botCornerX, y: botY - 0.8))
            bottomEdge.addQuadCurve(
                to: CGPoint(x: botRightX - 1.0, y: botY - 3.8),
                control: CGPoint(x: (botCornerX + botRightX) * 0.5, y: botY + 0.8)
            )
            context.stroke(
                bottomEdge,
                with: .color(Color(red: 0.24, green: 0.82, blue: 0.48).opacity(0.50)),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
            )

            // 3. 桶口外翻折边裙檐与下方 4 道竖向加强筋
            var underRimShadow = Path()
            underRimShadow.move(to: CGPoint(x: topLeftX - 1.0, y: rimY + 4.5))
            underRimShadow.addLine(to: CGPoint(x: topCornerX, y: rimY + 7.2))
            underRimShadow.addLine(to: CGPoint(x: topRightX + 1.0, y: rimY + 5.2))
            context.stroke(
                underRimShadow,
                with: .color(Color(red: 0.01, green: 0.26, blue: 0.11).opacity(0.75)),
                style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
            )

            let ribOffsets: [(x: CGFloat, yTop: CGFloat, h: CGFloat)] = [
                (topLeftX + 3.2, rimY + 3.2, 8.0),
                (topLeftX + 9.8, rimY + 3.8, 8.8),
                (topLeftX + 16.5, rimY + 4.4, 9.2),
                (topCornerX + 4.2, rimY + 5.0, 8.5)
            ]
            for rib in ribOffsets {
                let ribRect = CGRect(x: rib.x, y: rib.yTop, width: 2.6, height: rib.h)
                context.fill(
                    Path(roundedRect: ribRect, cornerRadius: 0.6),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.34, green: 0.88, blue: 0.55),
                            Color(red: 0.04, green: 0.50, blue: 0.23)
                        ]),
                        startPoint: CGPoint(x: ribRect.minX, y: ribRect.minY),
                        endPoint: CGPoint(x: ribRect.maxX, y: ribRect.maxY)
                    )
                )
                let ribShadow = CGRect(x: rib.x + 2.6, y: rib.yTop + 0.5, width: 1.8, height: rib.h - 0.5)
                context.fill(Path(ribShadow), with: .color(Color(red: 0.01, green: 0.28, blue: 0.12).opacity(0.78)))
            }

            var rimLip = Path()
            rimLip.move(to: CGPoint(x: topLeftX - 4.5, y: rimY - 1.2))
            rimLip.addLine(to: CGPoint(x: topCornerX - 1.0, y: rimY + 1.5))
            rimLip.addLine(to: CGPoint(x: topRightX + 5.5, y: rimY - 0.2))
            rimLip.addLine(to: CGPoint(x: topRightX + 4.8, y: rimY + 4.6))
            rimLip.addLine(to: CGPoint(x: topCornerX - 1.0, y: rimY + 6.4))
            rimLip.addLine(to: CGPoint(x: topLeftX - 4.0, y: rimY + 3.4))
            rimLip.closeSubpath()

            context.fill(
                rimLip,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.26, green: 0.86, blue: 0.50), location: 0.0),
                        .init(color: Color(red: 0.10, green: 0.72, blue: 0.36), location: 0.32),
                        .init(color: Color(red: 0.04, green: 0.56, blue: 0.26), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: topLeftX - 4, y: rimY),
                    endPoint: CGPoint(x: topRightX + 5, y: rimY + 4)
                )
            )

            var rimTopHighlight = Path()
            rimTopHighlight.move(to: CGPoint(x: topLeftX - 4.0, y: rimY - 0.8))
            rimTopHighlight.addLine(to: CGPoint(x: topCornerX - 1.0, y: rimY + 1.8))
            rimTopHighlight.addLine(to: CGPoint(x: topRightX + 5.0, y: rimY + 0.1))
            context.stroke(
                rimTopHighlight,
                with: .color(Color(red: 0.62, green: 0.96, blue: 0.74).opacity(0.85)),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
            )

            // 4. 桶身正面中央白色圆形「请勿乱扔垃圾」丝印标识
            let emblemCenter = CGPoint(x: cx + 7.5, y: rimY + 34.5)
            let emblemR: CGFloat = 8.8
            let emblemRect = CGRect(
                x: emblemCenter.x - emblemR,
                y: emblemCenter.y - emblemR,
                width: emblemR * 2.0,
                height: emblemR * 2.0
            )
            let emblemWhite = Color.white.opacity(0.90)

            context.stroke(Path(ellipseIn: emblemRect), with: .color(emblemWhite), lineWidth: 1.15)
            var drip = Path()
            drip.move(to: CGPoint(x: emblemCenter.x - 4.2, y: emblemCenter.y + emblemR - 0.2))
            drip.addLine(to: CGPoint(x: emblemCenter.x - 4.2, y: emblemCenter.y + emblemR + 2.2))
            context.stroke(drip, with: .color(emblemWhite.opacity(0.85)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))

            let personHead = CGRect(x: emblemCenter.x + 1.4, y: emblemCenter.y - 5.4, width: 2.0, height: 2.0)
            context.fill(Path(ellipseIn: personHead), with: .color(emblemWhite))

            var personBody = Path()
            personBody.move(to: CGPoint(x: emblemCenter.x - 1.8, y: emblemCenter.y - 3.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 2.4, y: emblemCenter.y - 2.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 3.4, y: emblemCenter.y + 0.2))
            personBody.move(to: CGPoint(x: emblemCenter.x + 2.2, y: emblemCenter.y - 2.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 1.8, y: emblemCenter.y + 4.2))
            personBody.move(to: CGPoint(x: emblemCenter.x + 2.5, y: emblemCenter.y + 0.2))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 3.1, y: emblemCenter.y + 4.2))
            context.stroke(personBody, with: .color(emblemWhite), style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round))

            let dotRect = CGRect(x: emblemCenter.x - 2.6, y: emblemCenter.y - 2.2, width: 1.1, height: 1.1)
            context.fill(Path(ellipseIn: dotRect), with: .color(emblemWhite))

            var smallBasket = Path()
            smallBasket.move(to: CGPoint(x: emblemCenter.x - 4.4, y: emblemCenter.y - 0.5))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 3.8, y: emblemCenter.y + 4.0))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 1.2, y: emblemCenter.y + 4.0))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 0.6, y: emblemCenter.y - 0.5))
            smallBasket.closeSubpath()
            context.stroke(smallBasket, with: .color(emblemWhite), lineWidth: 0.75)

            for aIdx in -3...3 {
                let a = CGFloat(aIdx) * 0.22 + .pi * 0.5
                let tx = emblemCenter.x + cos(a) * (emblemR - 2.0)
                let ty = emblemCenter.y + sin(a) * (emblemR - 2.0)
                let tinyRect = CGRect(x: tx - 0.45, y: ty - 0.45, width: 0.9, height: 0.9)
                context.fill(Path(ellipseIn: tinyRect), with: .color(emblemWhite.opacity(0.85)))
            }
        }
        .frame(width: 96 * kGreenBinScale, height: 108 * kGreenBinScale)
        .offset(y: 41 * (1 - kGreenBinScale))
    }
}

/// 样式 D 专属：可绕左侧铰链动态掀开、顶起、推开与向后大翻转晃荡的 3D 立体绿色桶盖
struct GreenWheelieBinArticulatedLidView: View {
    let lidOpenAngle: CGFloat

    var body: some View {
        Canvas { context, rawSize in
            let size = CGSize(width: rawSize.width / kGreenBinScale, height: rawSize.height / kGreenBinScale)
            context.scaleBy(x: kGreenBinScale, y: kGreenBinScale)
            let hinge = CGPoint(x: size.width * 0.5 - 38.0, y: size.height * 0.5 - 36.0)

            context.translateBy(x: hinge.x, y: hinge.y)
            context.rotate(by: .degrees(-Double(lidOpenAngle)))

            // 1. 桶盖底面内凹暗腔
            var lidUnderside = Path()
            lidUnderside.move(to: CGPoint(x: 2.0, y: 0.5))
            lidUnderside.addLine(to: CGPoint(x: 80.0, y: 0.5))
            lidUnderside.addLine(to: CGPoint(x: 76.0, y: 4.2))
            lidUnderside.addLine(to: CGPoint(x: 6.0, y: 4.2))
            lidUnderside.closeSubpath()
            context.fill(
                lidUnderside,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.01, green: 0.24, blue: 0.10),
                        Color(red: 0.03, green: 0.38, blue: 0.17),
                        Color(red: 0.01, green: 0.20, blue: 0.08)
                    ]),
                    startPoint: CGPoint(x: 2, y: 0),
                    endPoint: CGPoint(x: 80, y: 4)
                )
            )

            // 2. 桶盖上层双阶梯流线拱顶
            var upperCrown = Path()
            upperCrown.move(to: CGPoint(x: 3.5, y: -4.2))
            upperCrown.addLine(to: CGPoint(x: 22.0, y: -9.5))
            upperCrown.addLine(to: CGPoint(x: 48.0, y: -10.2))
            upperCrown.addLine(to: CGPoint(x: 74.5, y: -5.5))
            upperCrown.addLine(to: CGPoint(x: 77.0, y: -1.5))
            upperCrown.addLine(to: CGPoint(x: 2.0, y: -1.5))
            upperCrown.closeSubpath()

            context.fill(
                upperCrown,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.30, green: 0.88, blue: 0.54), location: 0.0),
                        .init(color: Color(red: 0.12, green: 0.76, blue: 0.39), location: 0.48),
                        .init(color: Color(red: 0.05, green: 0.60, blue: 0.28), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 15, y: -10),
                    endPoint: CGPoint(x: 70, y: -1)
                )
            )

            var crownHighlight = Path()
            crownHighlight.move(to: CGPoint(x: 23.0, y: -9.0))
            crownHighlight.addLine(to: CGPoint(x: 47.0, y: -9.6))
            crownHighlight.addLine(to: CGPoint(x: 56.0, y: -5.2))
            crownHighlight.addLine(to: CGPoint(x: 30.0, y: -4.8))
            crownHighlight.closeSubpath()
            context.fill(
                crownHighlight,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.72, green: 0.98, blue: 0.82).opacity(0.78),
                        Color(red: 0.36, green: 0.90, blue: 0.58).opacity(0.25)
                    ]),
                    startPoint: CGPoint(x: 25, y: -9.5),
                    endPoint: CGPoint(x: 52, y: -5.0)
                )
            )

            // 3. 桶盖下沿宽大包边与右侧掀盖外探把手檐
            var lowerFlange = Path()
            lowerFlange.move(to: CGPoint(x: -1.5, y: -2.2))
            lowerFlange.addLine(to: CGPoint(x: 26.0, y: -0.2))
            lowerFlange.addLine(to: CGPoint(x: 82.5, y: -1.8))
            lowerFlange.addLine(to: CGPoint(x: 82.0, y: 2.0))
            lowerFlange.addLine(to: CGPoint(x: 26.0, y: 3.6))
            lowerFlange.addLine(to: CGPoint(x: -1.5, y: 1.5))
            lowerFlange.closeSubpath()

            context.fill(
                lowerFlange,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.22, green: 0.84, blue: 0.48), location: 0.0),
                        .init(color: Color(red: 0.08, green: 0.68, blue: 0.34), location: 0.35),
                        .init(color: Color(red: 0.04, green: 0.52, blue: 0.24), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: 0, y: -2),
                    endPoint: CGPoint(x: 82, y: 3)
                )
            )

            var flangeHighlight = Path()
            flangeHighlight.move(to: CGPoint(x: 0.0, y: -1.6))
            flangeHighlight.addLine(to: CGPoint(x: 26.0, y: 0.4))
            flangeHighlight.addLine(to: CGPoint(x: 81.5, y: -1.2))
            context.stroke(
                flangeHighlight,
                with: .color(Color(red: 0.65, green: 0.97, blue: 0.76).opacity(0.85)),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
            )

            // 4. 盖面左前侧两枚凸起注塑卡扣耳块
            for lugX in [22.0, 29.0] as [CGFloat] {
                let lugRect = CGRect(x: lugX, y: -5.2, width: 4.5, height: 3.2)
                context.fill(
                    Path(roundedRect: lugRect, cornerRadius: 0.8),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.44, green: 0.92, blue: 0.62),
                            Color(red: 0.04, green: 0.48, blue: 0.22)
                        ]),
                        startPoint: CGPoint(x: lugRect.minX, y: lugRect.minY),
                        endPoint: CGPoint(x: lugRect.maxX, y: lugRect.maxY)
                    )
                )
            }
        }
        .frame(width: 220 * kGreenBinScale, height: 180 * kGreenBinScale)
        .offset(y: 41 * (1 - kGreenBinScale))
        .allowsHitTesting(false)
    }
}

/// 样式 D 专属：猫猫从桶内伸出一只爪子推开绿色桶盖
struct GreenBinLidPushingPawView: View {
    let morph: CatMorph
    let lidOpenAngle: CGFloat
    let pushProgress: CGFloat

    private var pawFill: Color {
        switch morph {
        case .slime: return Color(red: 0.99, green: 0.74, blue: 0.34)
        case .bluePlush: return Color(red: 0.64, green: 0.80, blue: 0.96)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color.white
        case .siamese: return Color(red: 0.32, green: 0.19, blue: 0.13)
        case .blackShadow: return Color(red: 0.08, green: 0.08, blue: 0.12)
        }
    }

    var body: some View {
        Canvas { context, rawSize in
            let size = CGSize(width: rawSize.width / kGreenBinScale, height: rawSize.height / kGreenBinScale)
            context.scaleBy(x: kGreenBinScale, y: kGreenBinScale)
            guard pushProgress > 0.02 else { return }
            let hinge = CGPoint(x: size.width * 0.5 - 38.0, y: size.height * 0.5 - 36.0)
            let rad = -lidOpenAngle * .pi / 180.0
            let r: CGFloat = 58.0
            let contactPt = CGPoint(
                x: hinge.x + cos(rad) * r,
                y: hinge.y + sin(rad) * r + 2.5
            )
            let basePt = CGPoint(
                x: size.width * 0.5 + 16.0,
                y: size.height * 0.5 - 31.0
            )
            let currentTip = CGPoint(
                x: basePt.x + (contactPt.x - basePt.x) * pushProgress,
                y: basePt.y + (contactPt.y - basePt.y) * pushProgress
            )

            // 1. 向上伸出的圆润前臂柱
            var arm = Path()
            arm.move(to: basePt)
            arm.addQuadCurve(
                to: currentTip,
                control: CGPoint(x: (basePt.x + currentTip.x) * 0.5 + 4.0, y: (basePt.y + currentTip.y) * 0.5)
            )
            context.stroke(
                arm,
                with: .color(pawFill),
                style: StrokeStyle(lineWidth: 10.5, lineCap: .round)
            )
            context.stroke(
                arm,
                with: .color(Color.white.opacity(morph == .blackShadow ? 0.15 : 0.65)),
                style: StrokeStyle(lineWidth: 11.5, lineCap: .round)
            )
            context.stroke(
                arm,
                with: .color(pawFill),
                style: StrokeStyle(lineWidth: 9.8, lineCap: .round)
            )

            // 2. 撑住盖子底面的小肉垫猫爪掌心
            let padCenter = currentTip
            let padRect = CGRect(x: padCenter.x - 6.0, y: padCenter.y - 4.5, width: 12.0, height: 9.0)
            context.fill(Path(ellipseIn: padRect), with: .color(pawFill))
            let pinkBean = Color(red: 0.96, green: 0.56, blue: 0.60)
            for bx in [-3.0, 0.0, 3.0] as [CGFloat] {
                let beanRect = CGRect(x: padCenter.x + bx - 1.2, y: padCenter.y - 3.2, width: 2.4, height: 2.4)
                context.fill(Path(ellipseIn: beanRect), with: .color(pinkBean))
            }
        }
        .frame(width: 220 * kGreenBinScale, height: 180 * kGreenBinScale)
        .offset(y: 41 * (1 - kGreenBinScale))
        .allowsHitTesting(false)
    }
}
