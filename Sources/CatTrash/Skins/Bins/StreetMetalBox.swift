import SwiftUI

// MARK: - 样式 B：街头立式深咖烤漆金属果皮箱（修长立式箱体 + 上方正面暗格投物口 + 底部镂空底座）

/// 街头金属果皮箱专属：当猫猫缩在暗格内（尚未被拽出暗格窗口）时的暗格内部裁剪蒙版，防止耳朵穿出顶棚或两侧铁板，且严格封闭在底部承重面板之上
struct StreetBoxCompartmentClipShape: Shape {
    let bucketCenter: CGPoint

    func path(in rect: CGRect) -> Path {
        let doorBotY = bucketCenter.y + 53.5
        let topY = bucketCenter.y - 55.5
        let boxInnerRect = CGRect(
            x: bucketCenter.x - 34.5,
            y: topY,
            width: 69.0,
            height: max(doorBotY - topY, 0)
        )
        return Path(boxInnerRect)
    }
}

/// 街头金属果皮箱专属：钻出正面窗口阶段的前景裁剪。
/// 仅裁切箱体正面门板矩形区域（防止门板区域内部穿模），箱体两侧及外部所有空间均完全放开，绝不切断外部延展的猫咪身体与头部！
struct StreetBoxPoppedCatClipShape: Shape {
    let bucketCenter: CGPoint

    func path(in rect: CGRect) -> Path {
        let boxLeft = bucketCenter.x - 37.0
        let boxRight = bucketCenter.x + 37.0
        let doorTopY = bucketCenter.y - 25.5
        let doorBotY = bucketCenter.y + 66.0

        var path = Path()
        // 1. 顶部整个水平区域 (y <= doorTopY)，包括箱子上方投物口与全屏上方桌面
        path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: max(doorTopY, 0)))

        // 2. 箱体左侧整个外部桌面空间 (x < boxLeft)，完全放开，确保向左拉伸时猫头与身体完整无缺
        if boxLeft > 0 {
            path.addRect(CGRect(x: 0, y: doorTopY, width: max(boxLeft, 0), height: max(rect.height - doorTopY, 0)))
        }

        // 3. 箱体右侧整个外部桌面空间 (x > boxRight)，完全放开，确保向右拉伸时猫头与身体完整无缺
        if boxRight < rect.width {
            path.addRect(CGRect(x: boxRight, y: doorTopY, width: max(rect.width - boxRight, 0), height: max(rect.height - doorTopY, 0)))
        }

        // 4. 箱体正下方地面区域 (y > doorBotY)
        path.addRect(CGRect(x: boxLeft, y: doorBotY, width: max(boxRight - boxLeft, 0), height: max(rect.height - doorBotY, 0)))

        return path
    }
}

/// 街头果皮箱专属：夜晚小夜灯前景漫射光效
struct StreetBoxNightAmbientView: View {
    @ObservedObject var lighting = EnvironmentLightingManager.shared

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let topY: CGFloat = 10.0 // 对应顶棚下沿
            let nightK = lighting.nightFactor
            let breathe = sin(lighting.lampBreathingPhase)
            let lampAlpha = (0.50 + 0.10 * breathe) * nightK

            // 顶棚正中央精致小夜灯的微型发光点
            var lampLine = Path()
            lampLine.move(to: CGPoint(x: cx - 4.5, y: topY))
            lampLine.addLine(to: CGPoint(x: cx + 4.5, y: topY))
            context.stroke(
                lampLine,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.clear,
                        Color(red: 1.0, green: 0.96, blue: 0.80).opacity(0.95 * lampAlpha),
                        Color(red: 1.0, green: 0.92, blue: 0.65).opacity(0.95 * lampAlpha),
                        Color.clear
                    ]),
                    startPoint: CGPoint(x: cx - 4.5, y: topY),
                    endPoint: CGPoint(x: cx + 4.5, y: topY)
                ),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
            )

            // 向下照射的小巧柔和微束光晕（小聚光射灯质感，精致不喧宾夺主）
            let glowRect = CGRect(x: cx - 13.0, y: topY - 2.0, width: 26.0, height: 20.0)
            context.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.35 * lampAlpha),
                        Color(red: 0.96, green: 0.75, blue: 0.35).opacity(0.12 * lampAlpha),
                        Color.clear
                    ]),
                    center: CGPoint(x: cx, y: topY + 2.0),
                    startRadius: 1,
                    endRadius: 13.0
                )
            )
        }
        .frame(width: 82, height: 124)
        .offset(y: 8)
        .allowsHitTesting(false)
    }
}

/// 样式 B：街头立式深咖烤漆金属果皮箱 · 后壁
struct StreetMetalBoxBackWallView: View {
    @ObservedObject var lighting = EnvironmentLightingManager.shared

    var body: some View {
        ZStack {
            // 1. 地面矩形落地阴影（加长后下移至接地底部）
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.55), .black.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 46
                    )
                )
                .frame(width: 88, height: 16)
                .offset(y: 67)

            // 2. 立式金属箱整体深黑褐外框背板与内凹投物口暗腔（立式修长立柜比例）
            Canvas { context, size in
                let cx = size.width * 0.5
                let boxW: CGFloat = 74.0
                let leftX = cx - boxW * 0.5
                let rightX = cx + boxW * 0.5
                let topY: CGFloat = 2.0       // 对应 bucketLocalCenter.y - 52
                let doorTopY: CGFloat = 28.0  // 对应前门板上沿 (bucketLocalCenter.y - 26)
                let doorBotY: CGFloat = 108.0 // 对应加长后的前门板下沿 (bucketLocalCenter.y + 54)
                let baseBotY: CGFloat = 120.0 // 对应底部镂空底座底边 (bucketLocalCenter.y + 66)

                let nightK = lighting.nightFactor
                let breathe = sin(lighting.lampBreathingPhase)

                // A. 整体深炭褐金属箱体背板（入夜后略微压暗加深）
                let fullRect = CGRect(x: leftX, y: topY, width: boxW, height: baseBotY - topY)
                let backColor1 = Color(red: 0.14 - 0.05 * nightK, green: 0.11 - 0.04 * nightK, blue: 0.10 - 0.03 * nightK)
                let backColor2 = Color(red: 0.24 - 0.08 * nightK, green: 0.19 - 0.06 * nightK, blue: 0.16 - 0.05 * nightK)
                let backColor3 = Color(red: 0.34 - 0.10 * nightK, green: 0.26 - 0.08 * nightK, blue: 0.21 - 0.07 * nightK)
                let backColor4 = Color(red: 0.16 - 0.06 * nightK, green: 0.13 - 0.05 * nightK, blue: 0.11 - 0.04 * nightK)

                context.fill(
                    Path(fullRect),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: backColor1, location: 0.0),
                            .init(color: backColor2, location: 0.55),
                            .init(color: backColor3, location: 0.92),
                            .init(color: backColor4, location: 1.0)
                        ]),
                        startPoint: CGPoint(x: leftX, y: topY),
                        endPoint: CGPoint(x: rightX, y: topY + 24)
                    )
                )

                // B. 上方投物口内腔反光：白天为暖琥珀自然漫反射，夜晚转为景观小夜灯温润鹅黄色向下倾泻光晕
                let recessRect = CGRect(x: leftX + 2.5, y: topY + 2.5, width: boxW - 5.0, height: doorTopY - topY + 4.0)
                let recessCenter = CGPoint(x: rightX - 14, y: topY + 15)
                context.fill(
                    Path(recessRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.44, green: 0.31, blue: 0.22).opacity(0.65 * (1.0 - nightK * 0.5)),
                            Color(red: 0.15, green: 0.12, blue: 0.10).opacity(0.92)
                        ]),
                        center: recessCenter,
                        startRadius: 2,
                        endRadius: 42
                    )
                )

                // 顶棚正中央的小夜灯物理微型灯座与聚光投射
                let fixtureRect = CGRect(x: cx - 4.5, y: topY + 0.6, width: 9.0, height: 2.0)
                context.fill(Path(roundedRect: fixtureRect, cornerRadius: 0.6), with: .color(Color(red: 0.12, green: 0.10, blue: 0.09)))

                // 夜间景观小夜灯：小巧微束筒灯聚光与暖光灯珠
                if nightK > 0.05 {
                    let lampIntensity = (0.75 + 0.12 * breathe) * nightK
                    let lampGlowRect = CGRect(x: cx - 12.0, y: topY + 1.2, width: 24.0, height: 18.0)
                    context.fill(
                        Path(ellipseIn: lampGlowRect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color(red: 1.0, green: 0.90, blue: 0.60).opacity(0.65 * lampIntensity),
                                Color(red: 0.96, green: 0.72, blue: 0.32).opacity(0.28 * lampIntensity),
                                Color.clear
                            ]),
                            center: CGPoint(x: cx, y: topY + 2.5),
                            startRadius: 1,
                            endRadius: 12.0
                        )
                    )

                    // 微型发光灯芯亮珠
                    let bulbRect = CGRect(x: cx - 2.2, y: topY + 0.8, width: 4.4, height: 1.4)
                    context.fill(
                        Path(roundedRect: bulbRect, cornerRadius: 0.6),
                        with: .color(Color(red: 1.0, green: 0.96, blue: 0.82).opacity(0.95 * lampIntensity))
                    )
                }

                // C. 投物口左右两侧内壁立体斜切折面
                var leftInnerWall = Path()
                leftInnerWall.move(to: CGPoint(x: leftX, y: topY))
                leftInnerWall.addLine(to: CGPoint(x: leftX + 5.5, y: topY + 4.0))
                leftInnerWall.addLine(to: CGPoint(x: leftX + 5.5, y: doorTopY + 2.0))
                leftInnerWall.addLine(to: CGPoint(x: leftX, y: doorTopY + 2.0))
                leftInnerWall.closeSubpath()
                context.fill(leftInnerWall, with: .color(Color(red: 0.10, green: 0.09, blue: 0.08)))

                var rightInnerWall = Path()
                rightInnerWall.move(to: CGPoint(x: rightX, y: topY))
                rightInnerWall.addLine(to: CGPoint(x: rightX - 5.5, y: topY + 4.0))
                rightInnerWall.addLine(to: CGPoint(x: rightX - 5.5, y: doorTopY + 2.0))
                rightInnerWall.addLine(to: CGPoint(x: rightX, y: doorTopY + 2.0))
                rightInnerWall.closeSubpath()
                let rightWallColor = (nightK > 0.05)
                    ? Color(red: 0.28 + 0.12 * nightK, green: 0.21 + 0.08 * nightK, blue: 0.17)
                    : Color(red: 0.28, green: 0.21, blue: 0.17)
                context.fill(rightInnerWall, with: .color(rightWallColor))

                // D. 底部镂空金属底座与内胆底板
                // (1) 内胆结实底部承重面板（底部面板，封闭内胆，阻止垃圾与猫猫下落）
                let shelfRect = CGRect(x: leftX + 2.5, y: doorBotY - 4.0, width: boxW - 5.0, height: 4.5)
                context.fill(
                    Path(shelfRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.18, green: 0.15, blue: 0.13),
                            Color(red: 0.10, green: 0.08, blue: 0.07)
                        ]),
                        startPoint: CGPoint(x: leftX, y: doorBotY - 4.0),
                        endPoint: CGPoint(x: leftX, y: doorBotY + 0.5)
                    )
                )

                // (2) 底部镂空底座内腔背影（脚架之间的通透阴影）
                let baseInnerRect = CGRect(x: leftX + 3.0, y: doorBotY + 1.5, width: boxW - 6.0, height: baseBotY - doorBotY - 3.0)
                context.fill(
                    Path(baseInnerRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.07, green: 0.06, blue: 0.05),
                            Color(red: 0.14, green: 0.11, blue: 0.09),
                            Color(red: 0.08, green: 0.07, blue: 0.06)
                        ]),
                        startPoint: CGPoint(x: leftX, y: doorBotY),
                        endPoint: CGPoint(x: rightX, y: baseBotY)
                    )
                )
            }
            .frame(width: 82, height: 124)
            .offset(y: 8)
        }
    }
}

/// 样式 B：街头立式深咖烤漆金属果皮箱 · 前景
struct StreetMetalBoxFrontWallView: View {
    @ObservedObject var lighting = EnvironmentLightingManager.shared

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let boxW: CGFloat = 74.0
            let leftX = cx - boxW * 0.5
            let rightX = cx + boxW * 0.5
            let topY: CGFloat = 2.0       // 遮雨顶棚顶边 (bucketLocalCenter.y - 52)
            let doorTopY: CGFloat = 28.0  // 前门板上沿 (bucketLocalCenter.y - 26)
            let doorBotY: CGFloat = 108.0 // 加长后的前门板下沿 (bucketLocalCenter.y + 54)
            let baseBotY: CGFloat = 120.0 // 底部底座下沿 (bucketLocalCenter.y + 66)

            let nightK = lighting.nightFactor
            let breathe = sin(lighting.lampBreathingPhase)

            // 1. 深咖色哑光烤漆金属加长前门板主体（夜间自然转为静谧沉稳深色）
            let doorRect = CGRect(x: leftX + 2.2, y: doorTopY, width: boxW - 4.4, height: doorBotY - doorTopY)
            let doorColor1 = Color(red: 0.43 - 0.12 * nightK, green: 0.34 - 0.10 * nightK, blue: 0.29 - 0.08 * nightK)
            let doorColor2 = Color(red: 0.36 - 0.10 * nightK, green: 0.28 - 0.08 * nightK, blue: 0.24 - 0.06 * nightK)
            let doorColor3 = Color(red: 0.28 - 0.08 * nightK, green: 0.22 - 0.06 * nightK, blue: 0.18 - 0.04 * nightK)

            context.fill(
                Path(roundedRect: doorRect, cornerRadius: 1.2),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: doorColor1, location: 0.0),
                        .init(color: doorColor2, location: 0.45),
                        .init(color: doorColor3, location: 1.0)
                    ]),
                    startPoint: CGPoint(x: doorRect.minX, y: doorRect.minY),
                    endPoint: CGPoint(x: doorRect.maxX, y: doorRect.maxY)
                )
            )

            // 门板表面柔和金属漫反射光斑（夜晚收敛为微弱冷夜光）
            context.fill(
                Path(roundedRect: doorRect, cornerRadius: 1.2),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.55, green: 0.44, blue: 0.37).opacity(0.32 * (1.0 - nightK * 0.7)),
                        Color.clear
                    ]),
                    center: CGPoint(x: doorRect.minX + 18, y: doorRect.minY + 24),
                    startRadius: 2,
                    endRadius: 52
                )
            )

            // 夜晚微型小夜灯在前门板正上方投下的收敛暖光晕
            if nightK > 0.05 {
                let glowIntensity = (0.50 + 0.10 * breathe) * nightK
                let doorGlowRect = CGRect(x: cx - 12.0, y: doorTopY, width: 24.0, height: 12.0)
                context.fill(
                    Path(ellipseIn: doorGlowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.30 * glowIntensity),
                            Color(red: 0.96, green: 0.72, blue: 0.32).opacity(0.08 * glowIntensity),
                            Color.clear
                        ]),
                        center: CGPoint(x: cx, y: doorTopY + 1.0),
                        startRadius: 1,
                        endRadius: 12.0
                    )
                )
            }

            // 门板中段横向隐式折弯加强筋
            let midRibY = doorTopY + (doorBotY - doorTopY) * 0.55
            var midRib = Path()
            midRib.move(to: CGPoint(x: doorRect.minX + 1.0, y: midRibY))
            midRib.addLine(to: CGPoint(x: doorRect.maxX - 1.0, y: midRibY))
            context.stroke(midRib, with: .color(Color.black.opacity(0.35)), lineWidth: 0.8)
            var midRibHighlight = Path()
            midRibHighlight.move(to: CGPoint(x: doorRect.minX + 1.0, y: midRibY + 0.8))
            midRibHighlight.addLine(to: CGPoint(x: doorRect.maxX - 1.0, y: midRibY + 0.8))
            context.stroke(midRibHighlight, with: .color(Color.white.opacity(0.18 * (1.0 - nightK * 0.4))), lineWidth: 0.6)

            // 2. 前门板顶部正中央的微型银色圆锁孔
            let lockCenter = CGPoint(x: cx, y: doorTopY + 4.6)
            let lockOuter = CGRect(x: lockCenter.x - 2.3, y: lockCenter.y - 2.3, width: 4.6, height: 4.6)
            context.fill(
                Path(ellipseIn: lockOuter),
                with: .linearGradient(
                    Gradient(colors: [Color(white: 0.92 - 0.20 * nightK), Color(white: 0.50 - 0.15 * nightK)]),
                    startPoint: CGPoint(x: lockOuter.minX, y: lockOuter.minY),
                    endPoint: CGPoint(x: lockOuter.maxX, y: lockOuter.maxY)
                )
            )
            let keyhole = CGRect(x: lockCenter.x - 0.55, y: lockCenter.y - 1.0, width: 1.1, height: 2.0)
            context.fill(Path(roundedRect: keyhole, cornerRadius: 0.4), with: .color(.black.opacity(0.85)))

            // 门板上沿折弯金属高光棱线（夜晚被小夜灯照亮呈琥珀暖金微光）
            var doorTopHighlight = Path()
            doorTopHighlight.move(to: CGPoint(x: doorRect.minX + 0.5, y: doorTopY + 0.6))
            doorTopHighlight.addLine(to: CGPoint(x: doorRect.maxX - 0.5, y: doorTopY + 0.6))
            let highlightColors: [Color] = (nightK > 0.05)
                ? [
                    Color(white: 0.55).opacity(0.45),
                    Color(red: 1.0, green: 0.90, blue: 0.65).opacity(0.75),
                    Color(white: 0.55).opacity(0.45)
                  ]
                : [
                    Color(white: 0.78).opacity(0.55),
                    Color(white: 0.92).opacity(0.75),
                    Color(white: 0.65).opacity(0.45)
                  ]
            context.stroke(
                doorTopHighlight,
                with: .linearGradient(
                    Gradient(colors: highlightColors),
                    startPoint: CGPoint(x: doorRect.minX, y: doorTopY),
                    endPoint: CGPoint(x: doorRect.maxX, y: doorTopY)
                ),
                style: StrokeStyle(lineWidth: 0.9)
            )

            // 门板下沿内卷阴影与底部门板横梁（实心底部面板封边，明确区分上方内胆与下方镂空底座）
            let bottomSlotRect = CGRect(x: doorRect.minX, y: doorBotY - 1.8, width: doorRect.width, height: 2.2)
            context.fill(Path(bottomSlotRect), with: .color(Color.black.opacity(0.75)))

            let bottomShelfBeam = CGRect(x: leftX + 1.2, y: doorBotY - 2.5, width: boxW - 2.4, height: 3.5)
            context.fill(
                Path(bottomShelfBeam),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.20, green: 0.16, blue: 0.13),
                        Color(red: 0.12, green: 0.09, blue: 0.08)
                    ]),
                    startPoint: CGPoint(x: leftX, y: doorBotY - 2.5),
                    endPoint: CGPoint(x: leftX, y: doorBotY + 1.0)
                )
            )
            var shelfHighlight = Path()
            shelfHighlight.move(to: CGPoint(x: leftX + 1.5, y: doorBotY - 2.5))
            shelfHighlight.addLine(to: CGPoint(x: rightX - 1.5, y: doorBotY - 2.5))
            context.stroke(shelfHighlight, with: .color(Color.white.opacity(0.12)), lineWidth: 0.6)

            // 3. 右上角激光镂空「扔垃圾小人」标志
            let iconColor = Color(red: 0.11, green: 0.08, blue: 0.07)
            let ix = doorRect.maxX - 14.5
            let iy = doorTopY + 8.5

            // (a) 小人圆头
            let headCircle = CGRect(x: ix - 1.5, y: iy, width: 2.6, height: 2.6)
            context.fill(Path(ellipseIn: headCircle), with: .color(iconColor))

            // (b) 小人肩膀 + 向右平伸手臂 + 左侧躯干竖线
            var bodyArm = Path()
            bodyArm.move(to: CGPoint(x: ix - 2.6, y: iy + 7.2))
            bodyArm.addLine(to: CGPoint(x: ix - 2.6, y: iy + 4.5))
            bodyArm.addQuadCurve(
                to: CGPoint(x: ix - 1.0, y: iy + 3.4),
                control: CGPoint(x: ix - 2.6, y: iy + 3.4)
            )
            bodyArm.addLine(to: CGPoint(x: ix + 3.6, y: iy + 3.4))
            context.stroke(bodyArm, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round))

            // (c) 小人双腿
            var legs = Path()
            legs.move(to: CGPoint(x: ix - 1.5, y: iy + 8.2))
            legs.addLine(to: CGPoint(x: ix - 1.5, y: iy + 13.0))
            legs.move(to: CGPoint(x: ix + 0.4, y: iy + 8.2))
            legs.addLine(to: CGPoint(x: ix + 0.4, y: iy + 13.0))
            context.stroke(legs, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.15, lineCap: .butt))

            // (d) 正在扔下的垃圾小方点
            let trashDot = CGRect(x: ix + 3.8, y: iy + 6.4, width: 1.5, height: 1.5)
            context.fill(Path(trashDot), with: .color(iconColor))

            // (e) 右下方U型小垃圾桶
            var miniBin = Path()
            miniBin.move(to: CGPoint(x: ix + 2.8, y: iy + 9.2))
            miniBin.addLine(to: CGPoint(x: ix + 2.8, y: iy + 12.8))
            miniBin.addLine(to: CGPoint(x: ix + 6.2, y: iy + 12.8))
            miniBin.addLine(to: CGPoint(x: ix + 6.2, y: iy + 9.2))
            context.stroke(miniBin, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.1, lineCap: .butt, lineJoin: .miter))

            // 4. 外围黑褐色烤漆方钢立柱框架与底部镂空底座横梁
            let frameColor = Color(red: 0.14, green: 0.12, blue: 0.11)
            context.fill(Path(CGRect(x: leftX, y: topY, width: 2.3, height: baseBotY - topY)), with: .color(frameColor))
            context.fill(Path(CGRect(x: rightX - 2.3, y: topY, width: 2.3, height: baseBotY - topY)), with: .color(frameColor))
            context.fill(Path(CGRect(x: leftX, y: topY, width: boxW, height: 2.2)), with: .color(frameColor))
            var topFrameHighlight = Path()
            topFrameHighlight.move(to: CGPoint(x: leftX + 0.5, y: topY + 0.5))
            topFrameHighlight.addLine(to: CGPoint(x: rightX - 0.5, y: topY + 0.5))
            context.stroke(topFrameHighlight, with: .color(Color(white: 0.65).opacity(0.55)), lineWidth: 0.7)

            context.fill(Path(CGRect(x: leftX, y: doorBotY, width: boxW, height: 2.0)), with: .color(frameColor))
            context.fill(Path(CGRect(x: leftX, y: baseBotY - 2.0, width: boxW, height: 2.0)), with: .color(frameColor))
        }
        .frame(width: 82, height: 124)
        .offset(y: 8)
    }
}
