import SwiftUI

// MARK: - 1. 糯米团/果冻梨形猫头轮廓 (Mochi Pear-Shaped Cat Head & Ears Silhouette)
struct MochiCatHeadShape: Shape {
    var earFlatten: CGFloat = 0
    var leftEarTwitch: CGFloat = 0
    var rightEarTwitch: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let ef = min(max(earFlatten, 0), 1)
        let lTwitch = leftEarTwitch * 0.004
        let rTwitch = rightEarTwitch * 0.004

        var path = Path()
        let topCenter = CGPoint(x: w * 0.50, y: h * (0.14 + ef * 0.05))
        let rightEarTip = CGPoint(
            x: w * (0.84 + ef * 0.12 + rTwitch),
            y: h * (0.01 + ef * 0.18 - abs(rTwitch) * 0.6)
        )
        let rightCheekUpper = CGPoint(x: w * 0.90, y: h * 0.36)
        let rightCheekLower = CGPoint(x: w * 0.98, y: h * 0.76)
        let bottomCenter = CGPoint(x: w * 0.50, y: h * 0.98)
        let leftCheekLower = CGPoint(x: w * 0.02, y: h * 0.76)
        let leftCheekUpper = CGPoint(x: w * 0.10, y: h * 0.36)
        let leftEarTip = CGPoint(
            x: w * (0.16 - ef * 0.12 + lTwitch),
            y: h * (0.01 + ef * 0.18 - abs(lTwitch) * 0.6)
        )

        path.move(to: topCenter)
        path.addQuadCurve(
            to: rightEarTip,
            control: CGPoint(x: w * 0.68, y: h * (0.03 + ef * 0.10))
        )
        path.addQuadCurve(
            to: rightCheekUpper,
            control: CGPoint(x: w * (0.93 + ef * 0.06), y: h * (0.14 + ef * 0.12))
        )
        path.addCurve(
            to: bottomCenter,
            control1: CGPoint(x: w * 1.03, y: h * 0.58),
            control2: rightCheekLower
        )
        path.addCurve(
            to: leftCheekUpper,
            control1: leftCheekLower,
            control2: CGPoint(x: -w * 0.03, y: h * 0.58)
        )
        path.addQuadCurve(
            to: leftEarTip,
            control: CGPoint(x: w * (0.07 - ef * 0.06), y: h * (0.14 + ef * 0.12))
        )
        path.addQuadCurve(
            to: topCenter,
            control: CGPoint(x: w * 0.32, y: h * (0.03 + ef * 0.10))
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 2. 六大品种 × 六种专属材质猫头视图 (6-Breed Material Head View)
struct CatHeadView: View {
    let morph: CatMorph
    let stretchRatio: CGFloat
    let stealthPeekLevel: CGFloat
    let interactionState: CatInteractionState
    let idleSubAction: IdleSubAction
    let isBlinking: Bool
    let gazeOffset: CGVector
    let chewPhase: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat
    let headTiltAngle: CGFloat
    let sniffPhase: CGFloat
    var isPeekingUnderLid: Bool = false

    private var earFlattenFactor: CGFloat {
        if stretchRatio > 0.65 {
            return min((stretchRatio - 0.65) / 0.35, 1.0)
        } else if stretchRatio > 0.30 {
            return (stretchRatio - 0.30) * 0.6
        }
        return 0
    }

    var body: some View {
        if morph == .blackShadow {
            // 黑猫专属：无明显猫头硬轮廓，化作一团翻涌呼吸的暗影黑烟 + 黑暗中浮动的发光金黄双眸
            ShadowSmokeHeadView(
                stretchRatio: stretchRatio,
                stealthPeekLevel: stealthPeekLevel,
                interactionState: interactionState,
                isBlinking: isBlinking,
                gazeOffset: gazeOffset,
                chewPhase: chewPhase,
                leftEarTwitch: leftEarTwitch,
                rightEarTwitch: rightEarTwitch
            )
            .rotationEffect(.degrees(Double(headTiltAngle)))
        } else {
            standardCatHeadBody
        }
    }

    private var standardCatHeadBody: some View {
        let headShape = MochiCatHeadShape(
            earFlatten: earFlattenFactor,
            leftEarTwitch: leftEarTwitch,
            rightEarTwitch: rightEarTwitch
        )

        return ZStack {
            // 1. 品种专属底色材质层
            headShape
                .fill(
                    LinearGradient(
                        stops: headGradientStops,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: morph == .blackShadow ? Color.black.opacity(0.85) : .clear,
                    radius: morph == .blackShadow ? 5 : 0
                )

            // 2. 内耳色块（黑猫暗影形态弱化内耳，保持神秘纯黑轮廓）
            if morph != .blackShadow {
                Canvas { context, size in
                    let ef = earFlattenFactor
                    let leftEarCenter = CGPoint(x: size.width * (0.22 - ef * 0.06), y: size.height * (0.21 + ef * 0.08))
                    let rightEarCenter = CGPoint(x: size.width * (0.78 + ef * 0.06), y: size.height * (0.21 + ef * 0.08))
                    for (idx, center) in [leftEarCenter, rightEarCenter].enumerated() {
                        var earInner = Path()
                        let sign: CGFloat = idx == 0 ? -1 : 1
                        earInner.move(to: CGPoint(x: center.x + sign * 4, y: center.y - 8))
                        earInner.addQuadCurve(
                            to: CGPoint(x: center.x + sign * 8, y: center.y + 6),
                            control: CGPoint(x: center.x + sign * 10, y: center.y - 1)
                        )
                        earInner.addQuadCurve(
                            to: CGPoint(x: center.x - sign * 5, y: center.y + 4),
                            control: CGPoint(x: center.x, y: center.y + 8)
                        )
                        earInner.closeSubpath()
                        context.fill(earInner, with: .color(morph.innerEarColor))
                    }
                }
                .clipShape(headShape)
            }

            // 3. 六大品种专属花纹与表面材质层
            breedPatternAndMaterialOverlay(headShape: headShape)

            // 4. 腮红（黑猫暗影形态不画粉腮红，突出金黄发光眼）
            if morph != .blackShadow {
                HStack(spacing: 26) {
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.48, blue: 0.45).opacity(0.38))
                        .frame(width: 9, height: 5)
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.48, blue: 0.45).opacity(0.38))
                        .frame(width: 9, height: 5)
                }
                .offset(y: 9)
            }

            // 5. 低位萌系五官（深缩潜伏只露耳朵时隐藏五官；但经典掀盖绿桶在缝隙里始终露出一双亮晶晶的眼睛！）
            facialFeatures
                .offset(y: 6)
                .opacity(isPeekingUnderLid ? 1.0 : Double(min(max((stealthPeekLevel - 0.15) * 3.2, 0.0), 1.0)))

            // 5B. 经典掀盖绿桶待机时：在盖子顶开的三角暗缝里，为双眸叠加一双亮晶晶的星芒反光
            if isPeekingUnderLid && !isBlinking {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.4, height: 3.4)
                        .shadow(color: .white, radius: 2.5)
                        .offset(x: -1.4 + gazeOffset.dx * 0.15, y: -1.8)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3.4, height: 3.4)
                        .shadow(color: .white, radius: 2.5)
                        .offset(x: -1.4 + gazeOffset.dx * 0.15, y: -1.8)
                }
                .offset(y: 4)
            }

            // 6. 抗拒极限时的脑门生气符号与 "meow" 字样
            if stretchRatio >= 0.45, case .stretching = interactionState {
                Text("💢")
                    .font(.system(size: 10))
                    .offset(x: 22, y: -22)
                Text("meow~")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -36, y: -6)
            }
        }
        .frame(width: 60, height: 52)
        .rotationEffect(.degrees(Double(headTiltAngle)))
        .scaleEffect(
            x: 1.0 + 0.04 * sin(chewPhase),
            y: 1.0 - 0.04 * sin(chewPhase)
        )
    }

    // MARK: - 各品种专属头部渐变色
    private var headGradientStops: [Gradient.Stop] {
        switch morph {
        case .slime:
            // 1. 橘猫果冻：焦糖琥珀橘 -> 奶油白半透明果冻
            return [
                .init(color: Color(red: 0.96, green: 0.50, blue: 0.14), location: 0.0),
                .init(color: Color(red: 0.98, green: 0.68, blue: 0.28), location: 0.55),
                .init(color: Color(red: 1.00, green: 0.91, blue: 0.76), location: 1.0)
            ]
        case .bluePlush:
            // 2. 蓝猫短毛绒：哑光雾霾冰蓝 -> 浅冰蓝毛茸茸面罩
            return [
                .init(color: Color(red: 0.44, green: 0.60, blue: 0.84), location: 0.0),
                .init(color: Color(red: 0.54, green: 0.70, blue: 0.90), location: 0.58),
                .init(color: Color(red: 0.80, green: 0.90, blue: 0.98), location: 1.0)
            ]
        case .calico:
            // 3. 三花羊毛毡：温暖手作米白毛毡底
            return [
                .init(color: Color(red: 0.97, green: 0.94, blue: 0.88), location: 0.0),
                .init(color: Color(red: 0.95, green: 0.91, blue: 0.84), location: 1.0)
            ]
        case .tuxedo:
            // 4. 奶牛橡皮糖：乌黑哑光软胶底（配合正脸白面罩）
            return [
                .init(color: Color(red: 0.14, green: 0.15, blue: 0.18), location: 0.0),
                .init(color: Color(red: 0.20, green: 0.21, blue: 0.25), location: 1.0)
            ]
        case .siamese:
            // 5. 暹罗软糯麻薯：香软糯米皮奶白底 + 深焦糖耳朵
            return [
                .init(color: Color(red: 0.28, green: 0.17, blue: 0.12), location: 0.0),
                .init(color: Color(red: 0.95, green: 0.90, blue: 0.81), location: 0.34),
                .init(color: Color(red: 0.97, green: 0.93, blue: 0.86), location: 1.0)
            ]
        case .blackShadow:
            // 6. 黑猫暗影烟雾：深邃虚空纯黑 + 幽微墨紫边缘
            return [
                .init(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 0.0),
                .init(color: Color(red: 0.11, green: 0.10, blue: 0.15), location: 1.0)
            ]
        }
    }

    // MARK: - 六种材质与花纹叠加层
    @ViewBuilder
    private func breedPatternAndMaterialOverlay(headShape: MochiCatHeadShape) -> some View {
        switch morph {
        case .slime:
            // 1. 橘猫史莱姆：虎斑纹 + 奶油下半脸晕染 + 水润果冻镜面高光斑
            TabbyStripesOverlay(stripeColor: Color(red: 0.78, green: 0.30, blue: 0.06).opacity(0.58))
                .clipShape(headShape)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.97, blue: 0.90).opacity(0.72), .clear],
                        center: UnitPoint(x: 0.5, y: 0.65),
                        startRadius: 2,
                        endRadius: 26
                    )
                )
                .frame(width: 56, height: 38)
                .offset(y: 9)
                .clipShape(headShape)

            // 水滴高光
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.78))
                    .frame(width: 11, height: 4.5)
                    .rotationEffect(.degrees(-24))
                    .offset(x: -11, y: -7)
                Circle()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 3.5, height: 3.5)
                    .offset(x: -17, y: -1)
            }
            .blendMode(.plusLighter)

            headShape
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.88), Color.orange.opacity(0.35), .white.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )

        case .bluePlush:
            // 2. 蓝猫短毛绒（升级真实立体短绒毛层 + 毛茸茸冰蓝面罩 + 炸毛绒簇外轮廓）
            BluePlushHeadMaterialOverlay(
                headShape: headShape,
                earFlatten: earFlattenFactor,
                leftEarTwitch: leftEarTwitch,
                rightEarTwitch: rightEarTwitch
            )

        case .calico:
            // 3. 三花羊毛毡/粗线针织（升级戳戳乐无硬边毛毡色块 + 跨界杂毛丝 + 针织线圈肌理 + 手作锁边飞丝轮廓）
            CalicoFeltHeadMaterialOverlay(
                headShape: headShape,
                earFlatten: earFlattenFactor,
                leftEarTwitch: leftEarTwitch,
                rightEarTwitch: rightEarTwitch
            )

        case .tuxedo:
            // 4. 奶牛猫橡皮糖/软胶：黑白分明倒 V 警长面罩 + 黑白交界硅胶倒角细高光 + 外边缘软胶保护壳倒角反光
            Path { path in
                path.move(to: CGPoint(x: 30, y: 17))
                path.addQuadCurve(to: CGPoint(x: 56, y: 48), control: CGPoint(x: 38, y: 34))
                path.addLine(to: CGPoint(x: 4, y: 48))
                path.addQuadCurve(to: CGPoint(x: 30, y: 17), control: CGPoint(x: 22, y: 34))
                path.closeSubpath()
            }
            .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
            .clipShape(headShape)

            // 黑白交界处的微弱软硅胶倒角反光细线（模拟硅胶双色注塑接缝的立体韧劲感）
            Path { path in
                path.move(to: CGPoint(x: 5, y: 47))
                path.addQuadCurve(to: CGPoint(x: 30, y: 16.5), control: CGPoint(x: 22, y: 33.5))
                path.addQuadCurve(to: CGPoint(x: 55, y: 47), control: CGPoint(x: 38, y: 33.5))
            }
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.25), .white.opacity(0.68), .white.opacity(0.25)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
            )
            .clipShape(headShape)

            // 软硅胶哑光柔滑反光条
            Capsule()
                .fill(Color.white.opacity(0.36))
                .frame(width: 14, height: 3.5)
                .rotationEffect(.degrees(-20))
                .offset(x: -11, y: -8)

            // 外边缘硅胶保护壳倒角细高光线（内缩 1pt 的高张力亮白倒角边）
            headShape
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.75), .white.opacity(0.25), .white.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.2
                )
                .clipShape(headShape)
            headShape
                .stroke(Color.black.opacity(0.35), lineWidth: 0.8)

        case .siamese:
            // 5. 暹罗软糯麻薯/熟芝士：正脸中心深焦糖芝麻糊重点色晕染 + 哑光糯米皮柔边
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.16, blue: 0.11).opacity(0.92),
                            Color(red: 0.42, green: 0.26, blue: 0.18).opacity(0.65),
                            .clear
                        ],
                        center: .center,
                        startRadius: 3,
                        endRadius: 19
                    )
                )
                .frame(width: 38, height: 26)
                .offset(y: 4)
                .clipShape(headShape)

            headShape
                .stroke(Color(red: 1.0, green: 0.97, blue: 0.92).opacity(0.75), lineWidth: 1.4)

        case .blackShadow:
            // 6. 黑猫暗影烟雾：边缘羽化水墨雾气，无杂乱高光
            headShape
                .stroke(
                    Color(red: 0.28, green: 0.24, blue: 0.42).opacity(0.55),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [3, 2])
                )
                .blur(radius: 0.8)
        }
    }

    // MARK: - 五官表情（黑猫拥有专属发光金黄圆眼，暹罗拥有清澈蓝宝石眼）
    @ViewBuilder
    private var facialFeatures: some View {
        let strokeColor: Color = {
            switch morph {
            case .blackShadow: return Color(red: 1.0, green: 0.84, blue: 0.22)
            case .siamese: return Color(red: 0.96, green: 0.88, blue: 0.80)
            default: return Color(red: 0.24, green: 0.11, blue: 0.06)
            }
        }()

        if case .sniffingToEnchant = interactionState {
            ZStack {
                HStack(spacing: 14) {
                    eyeView(gazeOffset: gazeOffset)
                    eyeView(gazeOffset: gazeOffset)
                }
                .offset(y: -2)

                if morph != .blackShadow {
                    VStack(spacing: 1) {
                        InvertedTriangleNoseShape()
                            .fill(Color(red: 0.96, green: 0.42, blue: 0.50))
                            .frame(width: 5.5, height: 4.0)
                        WCatMouthShape()
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                            .frame(width: 9, height: 3.5)
                    }
                    .offset(y: 3)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.yellow)
                    .offset(x: 20, y: -12)
            }
        } else if case .enchanted = interactionState {
            ZStack {
                HStack(spacing: 14) {
                    HappyArcEyeShape()
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: 9, height: 5)
                    HappyArcEyeShape()
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: 9, height: 5)
                }
                .offset(y: -2)
                if morph != .blackShadow {
                    WCatMouthShape()
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .frame(width: 10, height: 4)
                        .offset(y: 4)
                }
            }
        } else if case .targeting = interactionState {
            ZStack {
                HStack(spacing: 14) {
                    if morph == .blackShadow {
                        eyeView(gazeOffset: gazeOffset)
                        eyeView(gazeOffset: gazeOffset)
                    } else {
                        HappyArcEyeShape()
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .frame(width: 9, height: 5)
                        HappyArcEyeShape()
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                            .frame(width: 9, height: 5)
                    }
                }
                .offset(y: -5)

                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.56, green: 0.14, blue: 0.16))
                        .frame(width: 17, height: 14)
                    HStack(spacing: 6) {
                        TriangleFangShape().fill(Color.white).frame(width: 3.5, height: 3.5)
                        TriangleFangShape().fill(Color.white).frame(width: 3.5, height: 3.5)
                    }
                    Circle()
                        .fill(Color(red: 0.96, green: 0.48, blue: 0.52))
                        .frame(width: 11, height: 9)
                        .offset(y: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .offset(y: 5)

                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.yellow)
                    .offset(x: -22, y: 4)
            }
        } else if case .chomping = interactionState {
            VStack(spacing: 3) {
                HStack(spacing: 14) {
                    HappyArcEyeShape()
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: 9, height: 5)
                    HappyArcEyeShape()
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: 9, height: 5)
                }
                WCatMouthShape()
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .frame(width: 11, height: 4.5)
                    .scaleEffect(y: 0.6 + 0.6 * abs(sin(chewPhase)))
            }
        } else if stretchRatio >= 0.35 {
            if morph == .blackShadow {
                // 黑猫被拉长时：只剩两只发光金黄大眼死死盯着光标！
                HStack(spacing: 14) {
                    eyeView(gazeOffset: gazeOffset)
                        .scaleEffect(1.12)
                    eyeView(gazeOffset: gazeOffset)
                        .scaleEffect(1.12)
                }
                .offset(y: -1)
            } else {
                ZStack {
                    HStack(spacing: 12) {
                        Capsule().fill(strokeColor).frame(width: 6, height: 1.6).rotationEffect(.degrees(18))
                        Capsule().fill(strokeColor).frame(width: 6, height: 1.6).rotationEffect(.degrees(-18))
                    }
                    .offset(y: -8)

                    HStack(spacing: 12) {
                        SquintEyeShape(isLeft: true)
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                            .frame(width: 8, height: 6.5)
                        SquintEyeShape(isLeft: false)
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                            .frame(width: 8, height: 6.5)
                    }
                    .offset(y: -2)

                    RoundedTriangleShape()
                        .fill(Color(red: 0.58, green: 0.13, blue: 0.16))
                        .frame(width: 9, height: 8)
                        .overlay(
                            Circle()
                                .fill(Color(red: 0.96, green: 0.48, blue: 0.52))
                                .frame(width: 6, height: 5)
                                .offset(y: 2)
                                .clipShape(RoundedTriangleShape())
                        )
                        .offset(y: 5)
                }
            }
        } else if case .cancelled = interactionState {
            VStack(spacing: 4) {
                HStack(spacing: 14) {
                    Capsule().fill(strokeColor).frame(width: 9, height: 2.2)
                    Capsule().fill(strokeColor).frame(width: 9, height: 2.2)
                }
                if morph != .blackShadow {
                    Capsule().fill(strokeColor).frame(width: 6, height: 1.8)
                }
            }
        } else {
            // 默认待机状态（黑猫平时只露一双发光金黄大圆眼在黑暗中浮动）
            ZStack {
                HStack(spacing: 15) {
                    if isBlinking {
                        Capsule().fill(strokeColor).frame(width: 8.5, height: 2.0)
                        Capsule().fill(strokeColor).frame(width: 8.5, height: 2.0)
                    } else {
                        eyeView(gazeOffset: gazeOffset)
                        eyeView(gazeOffset: gazeOffset)
                    }
                }
                .offset(y: -1)

                if morph != .blackShadow {
                    let sniffOffset = (idleSubAction == .sniffing) ? sin(sniffPhase) * 1.6 : 0.0
                    VStack(spacing: 0.5) {
                        InvertedTriangleNoseShape()
                            .fill(noseColor)
                            .frame(width: 4.5, height: 3.2)
                        WCatMouthShape()
                            .stroke(strokeColor.opacity(0.85), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                            .frame(width: 8, height: 3.2)
                    }
                    .offset(y: 3.5 + sniffOffset)

                    if idleSubAction == .sniffing {
                        HStack(spacing: 30) {
                            Capsule().fill(Color.white.opacity(0.8)).frame(width: 7, height: 1.2)
                                .rotationEffect(.degrees(Double(sin(sniffPhase) * 14)))
                            Capsule().fill(Color.white.opacity(0.8)).frame(width: 7, height: 1.2)
                                .rotationEffect(.degrees(Double(-sin(sniffPhase) * 14)))
                        }
                        .offset(y: 4)
                    }
                }
            }
        }
    }

    private var noseColor: Color {
        switch morph {
        case .bluePlush: return Color(red: 0.24, green: 0.18, blue: 0.42)
        case .siamese: return Color(red: 0.20, green: 0.12, blue: 0.10)
        default: return Color(red: 0.92, green: 0.44, blue: 0.46)
        }
    }

    @ViewBuilder
    private func eyeView(gazeOffset: CGVector) -> some View {
        switch morph {
        case .blackShadow:
            // 黑猫专属：在黑暗中浮动的明亮金黄色发光圆眼
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.92, blue: 0.28),
                                Color(red: 0.96, green: 0.68, blue: 0.06)
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 5
                        )
                    )
                    .frame(width: 9.5, height: 9.5)
                    .shadow(color: Color.yellow.opacity(0.65), radius: 3)

                // 竖瞳与高光
                Ellipse()
                    .fill(Color.black)
                    .frame(width: 3.2, height: 7.0)
                    .offset(x: gazeOffset.dx * 0.28, y: -gazeOffset.dy * 0.25)

                Circle()
                    .fill(Color.white)
                    .frame(width: 2.5, height: 2.5)
                    .offset(x: -1.5, y: -1.6)
            }
        case .siamese:
            // 暹罗专属：清澈冰蓝宝石眼
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.32, green: 0.78, blue: 0.98),
                                Color(red: 0.12, green: 0.36, blue: 0.72)
                            ],
                            center: .bottom,
                            startRadius: 1,
                            endRadius: 5
                        )
                    )
                    .frame(width: 8.8, height: 8.8)
                    .offset(x: gazeOffset.dx * 0.25, y: -gazeOffset.dy * 0.25)

                Circle()
                    .fill(Color(red: 0.06, green: 0.14, blue: 0.32))
                    .frame(width: 4.5, height: 4.5)
                    .offset(x: gazeOffset.dx * 0.25, y: -gazeOffset.dy * 0.25)

                Circle()
                    .fill(Color.white)
                    .frame(width: 2.8, height: 2.8)
                    .offset(x: -1.4, y: -1.6)
            }
        default:
            GlossyBeanEyeView(gazeOffset: gazeOffset)
        }
    }
}

// MARK: - 2B. 黑猫专属：无固定猫头边界的翻涌暗影黑烟团 (Formless Billowing Shadow Smoke Head)
struct ShadowSmokeHeadView: View {
    let stretchRatio: CGFloat
    let stealthPeekLevel: CGFloat
    let interactionState: CatInteractionState
    let isBlinking: Bool
    let gazeOffset: CGVector
    let chewPhase: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
            ZStack {
                // 1. 多层翻滚交叠的暗影水墨烟团（无硬边轮廓，边缘自然羽化消散）
                Canvas { context, size in
                    let center = CGPoint(x: size.width * 0.5, y: size.height * 0.54)

                    // 8 团不同相位慢速翻涌的黑烟云团
                    let puffs: [(dx: CGFloat, dy: CGFloat, r: CGFloat, speed: CGFloat, phase: CGFloat)] = [
                        (0, 2, 23, 1.8, 0.0),
                        (-12, 4, 18, 2.3, 1.1),
                        (12, 4, 18, 2.1, 2.4),
                        (-8, -7, 16, 2.6, 3.5),
                        (8, -7, 16, 2.4, 4.7),
                        (0, 9, 17, 1.9, 5.2),
                        (-15, -2, 13, 3.0, 0.8),
                        (15, -2, 13, 2.8, 2.9)
                    ]

                    for puff in puffs {
                        let wobbleX = sin(t * puff.speed + puff.phase) * 3.2
                        let wobbleY = cos(t * (puff.speed * 0.85) + puff.phase) * 2.8
                        let px = center.x + puff.dx * (1.0 - stretchRatio * 0.18) + wobbleX
                        let py = center.y + puff.dy + wobbleY
                        let rect = CGRect(x: px - puff.r, y: py - puff.r, width: puff.r * 2, height: puff.r * 2)

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .radialGradient(
                                Gradient(stops: [
                                    .init(color: Color.black.opacity(0.95), location: 0.0),
                                    .init(color: Color(red: 0.06, green: 0.05, blue: 0.09).opacity(0.75), location: 0.55),
                                    .init(color: Color(red: 0.12, green: 0.10, blue: 0.18).opacity(0.0), location: 1.0)
                                ]),
                                center: CGPoint(x: px, y: py),
                                startRadius: 2,
                                endRadius: puff.r
                            )
                        )
                    }

                    // 顶部两缕若隐若现向上飘散的暗影烟气尖角（代替死板的猫耳朵，随风摇曳）
                    for side in [-1.0, 1.0] as [CGFloat] {
                        let twitch: CGFloat = (side < 0 ? leftEarTwitch : rightEarTwitch) * 0.25
                        let basePt = CGPoint(x: center.x + side * 13.0, y: center.y - 8.0)
                        let offsetX: CGFloat = side * (16.0 + stretchRatio * 6.0) + sin(t * 3.2 + side) * 3.5 + twitch
                        let offsetY: CGFloat = -26.0 + stretchRatio * 8.0 + cos(t * 2.5 + side) * 2.0
                        let tipPt = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
                        var wisp = Path()
                        wisp.move(to: CGPoint(x: basePt.x - 7, y: basePt.y))
                        wisp.addQuadCurve(
                            to: tipPt,
                            control: CGPoint(x: basePt.x + side * 5, y: basePt.y - 14)
                        )
                        wisp.addQuadCurve(
                            to: CGPoint(x: basePt.x + 7, y: basePt.y + 2),
                            control: CGPoint(x: basePt.x - side * 2, y: basePt.y - 10)
                        )
                        wisp.closeSubpath()

                        context.fill(
                            wisp,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.black.opacity(0.85),
                                    Color(red: 0.08, green: 0.06, blue: 0.12).opacity(0.0)
                                ]),
                                startPoint: basePt,
                                endPoint: tipPt
                            )
                        )
                    }

                    // 周围漂浮消散的细小黑墨微粒
                    for i in 0..<5 {
                        let fi = CGFloat(i)
                        let angle = t * 1.4 + fi * 1.25
                        let dist: CGFloat = 20.0 + sin(t * 2.2 + fi) * 6.0
                        let dx = cos(angle) * dist
                        let dy = sin(angle) * dist - 4.0
                        let r: CGFloat = 2.2 + (i % 2 == 0 ? 1.2 : 0.0)
                        let dotRect = CGRect(x: center.x + dx - r, y: center.y + dy - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: dotRect), with: .color(.black.opacity(0.65)))
                    }
                }
                .blur(radius: 1.6)

                // 2. 黑暗烟雾中浮动的两只金黄色发光大圆眼（无固定鼻嘴轮廓，只在吞食时裂开一道深渊暗红口）
                ZStack {
                    HStack(spacing: 14) {
                        if isBlinking {
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.84, blue: 0.22))
                                .frame(width: 9, height: 2.0)
                                .shadow(color: .yellow.opacity(0.8), radius: 3)
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.84, blue: 0.22))
                                .frame(width: 9, height: 2.0)
                                .shadow(color: .yellow.opacity(0.8), radius: 3)
                        } else {
                            shadowGoldenEye
                            shadowGoldenEye
                        }
                    }
                    .offset(y: 2)

                    if case .targeting = interactionState {
                        // 锁定时在黑烟下方裂开一道神秘漩涡口
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.45, green: 0.06, blue: 0.14), .black],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 9
                                )
                            )
                            .frame(width: 16, height: 12)
                            .offset(y: 13)
                    }
                }
                .opacity(Double(min(max((stealthPeekLevel - 0.05) * 3.0, 0.35), 1.0)))
            }
        }
        .frame(width: 66, height: 58)
    }

    private var shadowGoldenEye: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.94, blue: 0.32),
                            Color(red: 0.96, green: 0.66, blue: 0.04)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 5.5
                    )
                )
                .frame(width: 9.8, height: 9.8)
                .shadow(color: Color.yellow.opacity(0.85), radius: 4)

            Ellipse()
                .fill(Color.black)
                .frame(width: 3.0, height: 7.2)
                .offset(x: gazeOffset.dx * 0.28, y: -gazeOffset.dy * 0.25)

            Circle()
                .fill(Color.white)
                .frame(width: 2.4, height: 2.4)
                .offset(x: -1.5, y: -1.6)
        }
    }
}

// MARK: - 蓝猫（蓬松柔软毛球 Soft & Fluffy）与三花（手作羊毛毡）高精头部材质组件
struct BluePlushHeadMaterialOverlay: View {
    let headShape: MochiCatHeadShape
    let earFlatten: CGFloat
    let leftEarTwitch: CGFloat
    let rightEarTwitch: CGFloat

    var body: some View {
        ZStack {
            // 1. 外围高斯柔化云朵绒球光晕（圆弧重叠 + 高斯模糊，彻底告别锋利三角锯齿/刺猬感！）
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

                // A. 浅冰蓝云朵柔边下半脸面罩（由多个重叠圆弧柔团构成，边缘柔和过渡）
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

                // B. 柔和顺滑的长绒毛丝束（非尖刺 V 字，而是柔顺弧形细毛束）
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

                // C. 双耳内部蓬松软白绒团
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

                // D. 脸颊两侧深蓝紫色三道绒毛胡须斑纹
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

            // 3. 外沿第二层微柔化圆弧绒毛圈（营造蒲公英/英短蓝猫脸颊的软糯绒球触感）
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

                    // 用柔和圆弧毛束代替尖刺
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
                    context.fill(blob, with: .color(p.color))

                    // 色块交界处 42 根互相穿插的羊毛毡杂毛丝（模拟戳针把色块羊毛戳入米白底毛的手作质感！）
                    let fiberCount = 42
                    for f in 0..<fiberCount {
                        let a = CGFloat(f) / CGFloat(fiberCount) * .pi * 2.0 + CGFloat(pIdx) * 0.4
                        let rFactor = 0.88 + 0.16 * sin(CGFloat(f) * 4.1)
                        let bx = p.cx + cos(a) * p.rx * rFactor
                        let by = p.cy + sin(a) * p.ry * rFactor
                        let fLen: CGFloat = 2.8 + CGFloat(f % 3) * 1.1
                        let dir = a + sin(CGFloat(f) * 2.7) * 0.45

                        var wisp = Path()
                        wisp.move(to: CGPoint(x: bx - cos(dir) * (fLen * 0.5), y: by - sin(dir) * (fLen * 0.5)))
                        wisp.addQuadCurve(
                            to: CGPoint(x: bx + cos(dir) * (fLen * 0.65), y: by + sin(dir) * (fLen * 0.65)),
                            control: CGPoint(x: bx - sin(dir) * 1.0, y: by + cos(dir) * 1.0)
                        )
                        let fColor = (f % 3 == 0) ? creamFiber : ((f % 3 == 1) ? p.color : p.highlight)
                        context.stroke(wisp, with: .color(fColor.opacity(0.90)), style: StrokeStyle(lineWidth: 0.95, lineCap: .round))
                    }

                    // 色块内部戳针凹孔与混纺杂色纤维丝
                    for d in 0..<12 {
                        let a = CGFloat(d) * 1.1 + CGFloat(pIdx)
                        let dist = CGFloat(d % 3 + 1) * 0.24
                        let dx = p.cx + cos(a) * p.rx * dist
                        let dy = p.cy + sin(a) * p.ry * dist
                        var fleck = Path()
                        fleck.move(to: CGPoint(x: dx - 1.2, y: dy - 0.6))
                        fleck.addQuadCurve(to: CGPoint(x: dx + 1.4, y: dy + 0.8), control: CGPoint(x: dx, y: dy - 1.2))
                        context.stroke(fleck, with: .color(p.highlight.opacity(0.72)), style: StrokeStyle(lineWidth: 0.85, lineCap: .round))
                    }
                }

                // B. 漫布全脸的羊毛毡杂毛纤维网（赋予米白底面真实的毛毡戳刺颗粒与纤维交织感，去掉生硬的 V 字纹）
                for i in 0..<55 {
                    let fi = CGFloat(i)
                    let fx = 8.0 + (fi * 17.3).truncatingRemainder(dividingBy: 44.0)
                    let fy = 10.0 + (fi * 11.7).truncatingRemainder(dividingBy: 36.0)
                    let angle = fi * 1.35
                    var microWool = Path()
                    microWool.move(to: CGPoint(x: fx - cos(angle) * 1.8, y: fy - sin(angle) * 1.8))
                    microWool.addQuadCurve(
                        to: CGPoint(x: fx + cos(angle) * 1.8, y: fy + sin(angle) * 1.8),
                        control: CGPoint(x: fx - sin(angle) * 1.0, y: fy + cos(angle) * 1.0)
                    )
                    let c = (i % 2 == 0) ? oatmealFiber.opacity(0.52) : Color.white.opacity(0.75)
                    context.stroke(microWool, with: .color(c), style: StrokeStyle(lineWidth: 0.78, lineCap: .round))
                }
            }
            .clipShape(headShape)

            // 2. 头部外廓手作毛毡锁边缝线 + 细密弯曲的羊毛飞丝毛刺边
            Canvas { context, size in
                let pts = sampleHeadPerimeterPoints(
                    in: CGRect(origin: .zero, size: size),
                    earFlatten: earFlatten,
                    leftEarTwitch: leftEarTwitch,
                    rightEarTwitch: rightEarTwitch
                )
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
                let count = pts.count
                guard count > 4 else { return }

                // (a) 粗纺毛线轮廓底边
                let headPath = headShape.path(in: CGRect(origin: .zero, size: size))
                context.stroke(
                    headPath,
                    with: .color(Color(red: 0.84, green: 0.76, blue: 0.65).opacity(0.92)),
                    style: StrokeStyle(lineWidth: 1.9, lineCap: .round, dash: [2.2, 1.6])
                )

                // (b) 沿外框放射的弯曲羊毛飞丝 + 手作锁边针脚 (Blanket Stitch)
                for i in 0..<count {
                    let pt = pts[i]
                    let vx = pt.x - center.x
                    let vy = pt.y - center.y
                    let vLen = max(hypot(vx, vy), 0.001)
                    let outX = vx / vLen
                    let outY = vy / vLen
                    let tanX = -outY
                    let tanY = outX

                    // 根据所在部位匹配对应色块的羊毛飞丝颜色
                    let fiberColor: Color = {
                        if pt.x < 26 && pt.y < 27 {
                            return Color(red: 0.92, green: 0.50, blue: 0.18)
                        } else if pt.x > 34 && pt.y < 26 {
                            return Color(red: 0.25, green: 0.24, blue: 0.23)
                        }
                        return Color(red: 0.92, green: 0.86, blue: 0.77)
                    }()

                    let wispLen: CGFloat = 2.0 + CGFloat(i % 3) * 0.85
                    let curl: CGFloat = (i % 2 == 0) ? 1.4 : -1.4
                    var wisp = Path()
                    wisp.move(to: CGPoint(x: pt.x - outX * 0.5, y: pt.y - outY * 0.5))
                    wisp.addQuadCurve(
                        to: CGPoint(x: pt.x + outX * wispLen + tanX * curl, y: pt.y + outY * wispLen + tanY * curl),
                        control: CGPoint(x: pt.x + outX * (wispLen * 0.6) - tanX * curl * 0.6, y: pt.y + outY * (wispLen * 0.6) - tanY * curl * 0.6)
                    )
                    context.stroke(wisp, with: .color(fiberColor.opacity(0.88)), style: StrokeStyle(lineWidth: 0.85, lineCap: .round))

                    // 每隔 3 步画一道手作毯边锁针缝合线迹
                    if i % 3 == 0 {
                        var stitch = Path()
                        stitch.move(to: CGPoint(x: pt.x - outX * 2.3, y: pt.y - outY * 2.3))
                        stitch.addLine(to: CGPoint(x: pt.x + outX * 0.7, y: pt.y + outY * 0.7))
                        context.stroke(
                            stitch,
                            with: .color(Color(red: 0.68, green: 0.58, blue: 0.46).opacity(0.78)),
                            style: StrokeStyle(lineWidth: 0.95, lineCap: .round)
                        )
                    }
                }
            }
        }
    }
}

/// 沿 MochiCatHeadShape 的 6 段贝塞尔曲线均匀采样 60 个轮廓点，供蓝猫炸毛绒簇与三花羊毛毡飞丝精准贴合耳朵与脸颊轮廓
fileprivate func sampleHeadPerimeterPoints(
    in rect: CGRect,
    earFlatten: CGFloat,
    leftEarTwitch: CGFloat,
    rightEarTwitch: CGFloat
) -> [CGPoint] {
    let w = rect.width
    let h = rect.height
    let ef = min(max(earFlatten, 0), 1)
    let lTwitch = leftEarTwitch * 0.004
    let rTwitch = rightEarTwitch * 0.004

    let topCenter = CGPoint(x: w * 0.50, y: h * (0.14 + ef * 0.05))
    let rightEarTip = CGPoint(
        x: w * (0.84 + ef * 0.12 + rTwitch),
        y: h * (0.01 + ef * 0.18 - abs(rTwitch) * 0.6)
    )
    let rightCheekUpper = CGPoint(x: w * 0.90, y: h * 0.36)
    let rightCheekLower = CGPoint(x: w * 0.98, y: h * 0.76)
    let bottomCenter = CGPoint(x: w * 0.50, y: h * 0.98)
    let leftCheekLower = CGPoint(x: w * 0.02, y: h * 0.76)
    let leftCheekUpper = CGPoint(x: w * 0.10, y: h * 0.36)
    let leftEarTip = CGPoint(
        x: w * (0.16 - ef * 0.12 + lTwitch),
        y: h * (0.01 + ef * 0.18 - abs(lTwitch) * 0.6)
    )

    var points: [CGPoint] = []
    points.reserveCapacity(60)

    func quadPt(_ t: CGFloat, _ p0: CGPoint, _ c: CGPoint, _ p1: CGPoint) -> CGPoint {
        let u = 1.0 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * c.x + t * t * p1.x,
            y: u * u * p0.y + 2 * u * t * c.y + t * t * p1.y
        )
    }

    func cubicPt(_ t: CGFloat, _ p0: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ p1: CGPoint) -> CGPoint {
        let u = 1.0 - t
        let uu = u * u
        let tt = t * t
        return CGPoint(
            x: uu * u * p0.x + 3 * uu * t * c1.x + 3 * u * tt * c2.x + tt * t * p1.x,
            y: uu * u * p0.y + 3 * uu * t * c1.y + 3 * u * tt * c2.y + tt * t * p1.y
        )
    }

    let cTopRight = CGPoint(x: w * 0.68, y: h * (0.03 + ef * 0.10))
    for i in 0..<8 { points.append(quadPt(CGFloat(i) / 8.0, topCenter, cTopRight, rightEarTip)) }

    let cRightOuterEar = CGPoint(x: w * (0.93 + ef * 0.06), y: h * (0.14 + ef * 0.12))
    for i in 0..<9 { points.append(quadPt(CGFloat(i) / 9.0, rightEarTip, cRightOuterEar, rightCheekUpper)) }

    let cRightCheek1 = CGPoint(x: w * 1.03, y: h * 0.58)
    for i in 0..<13 { points.append(cubicPt(CGFloat(i) / 13.0, rightCheekUpper, cRightCheek1, rightCheekLower, bottomCenter)) }

    let cLeftCheek2 = CGPoint(x: -w * 0.03, y: h * 0.58)
    for i in 0..<13 { points.append(cubicPt(CGFloat(i) / 13.0, bottomCenter, leftCheekLower, cLeftCheek2, leftCheekUpper)) }

    let cLeftOuterEar = CGPoint(x: w * (0.07 - ef * 0.06), y: h * (0.14 + ef * 0.12))
    for i in 0..<9 { points.append(quadPt(CGFloat(i) / 9.0, leftCheekUpper, cLeftOuterEar, leftEarTip)) }

    let cTopLeft = CGPoint(x: w * 0.32, y: h * (0.03 + ef * 0.10))
    for i in 0..<8 { points.append(quadPt(CGFloat(i) / 8.0, leftEarTip, cTopLeft, topCenter)) }

    return points
}

// MARK: - 虎斑条纹与豆豆眼子组件
struct TabbyStripesOverlay: View {
    let stripeColor: Color

    var body: some View {
        ZStack {
            HStack(spacing: 3.5) {
                Capsule().fill(stripeColor).frame(width: 2.8, height: 9).offset(y: 1)
                Capsule().fill(stripeColor).frame(width: 3.2, height: 11)
                Capsule().fill(stripeColor).frame(width: 2.8, height: 9).offset(y: 1)
            }
            .offset(y: -15)

            HStack(spacing: 36) {
                VStack(spacing: 2.5) {
                    Capsule().fill(stripeColor).frame(width: 9, height: 2.5).rotationEffect(.degrees(16))
                    Capsule().fill(stripeColor).frame(width: 8, height: 2.2).rotationEffect(.degrees(10))
                }
                VStack(spacing: 2.5) {
                    Capsule().fill(stripeColor).frame(width: 9, height: 2.5).rotationEffect(.degrees(-16))
                    Capsule().fill(stripeColor).frame(width: 8, height: 2.2).rotationEffect(.degrees(-10))
                }
            }
            .offset(y: -1)
        }
    }
}

struct GlossyBeanEyeView: View {
    let gazeOffset: CGVector

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.30, green: 0.14, blue: 0.07),
                            Color(red: 0.14, green: 0.06, blue: 0.03)
                        ],
                        center: .bottom,
                        startRadius: 1,
                        endRadius: 5
                    )
                )
                .frame(width: 8.5, height: 8.8)
                .offset(x: gazeOffset.dx * 0.25, y: -gazeOffset.dy * 0.25)

            Circle()
                .fill(Color.white)
                .frame(width: 3.0, height: 3.0)
                .offset(x: -1.4 + gazeOffset.dx * 0.12, y: -1.6)

            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: 1.4, height: 1.4)
                .offset(x: 1.5, y: 1.6)
        }
    }
}

struct InvertedTriangleNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - 3. 潜伏偷伸爪 / 探头搭桶沿 / 扒拉桶沿死命扣住 / 脱落拉伸粉肉垫爪子
struct MeltingRimPawsView: View {
    let morph: CatMorph
    let stretchRatio: CGFloat
    let stealthPeekLevel: CGFloat
    let idleSubAction: IdleSubAction
    let sneakPawPhase: CGFloat
    let arePawsClingingToRim: Bool

    var body: some View {
        if morph == .blackShadow {
            // 黑猫暗影烟雾形态：不画具象实体猫爪与粉肉垫，保持纯粹黑烟流体感
            EmptyView()
        } else if arePawsClingingToRim && stretchRatio > 0.01 {
            HStack(spacing: 20) {
                MeltingDripPaw(morph: morph, isLeft: true)
                    .scaleEffect(x: 0.92, y: 1.18)
                    .offset(y: sin(stretchRatio * 80) * 1.5)
                MeltingDripPaw(morph: morph, isLeft: false)
                    .scaleEffect(x: 0.92, y: 1.18)
                    .offset(y: -sin(stretchRatio * 80) * 1.5)
            }
        } else if stretchRatio >= 0.18 {
            HStack(spacing: 24) {
                StretchedPawWithPad(morph: morph, isLeft: true)
                StretchedPawWithPad(morph: morph, isLeft: false)
            }
        } else if idleSubAction == .sneakPaw {
            MeltingDripPaw(morph: morph, isLeft: false)
                .offset(
                    x: 14 + sin(sneakPawPhase) * 3.5,
                    y: abs(cos(sneakPawPhase)) * 3.0
                )
                .rotationEffect(.degrees(Double(sin(sneakPawPhase) * 18)))
        } else if stealthPeekLevel >= 0.52 {
            HStack(spacing: 16) {
                MeltingDripPaw(morph: morph, isLeft: true)
                MeltingDripPaw(morph: morph, isLeft: false)
            }
            .opacity(Double(min((stealthPeekLevel - 0.50) * 4.0, 1.0)))
        }
    }
}

struct MeltingDripPaw: View {
    let morph: CatMorph
    let isLeft: Bool

    private var pawColors: [Color] {
        switch morph {
        case .slime:
            return [Color(red: 0.98, green: 0.68, blue: 0.28), Color(red: 1.00, green: 0.90, blue: 0.72)]
        case .bluePlush:
            return [Color(red: 0.52, green: 0.68, blue: 0.88), Color(red: 0.78, green: 0.88, blue: 0.98)]
        case .calico:
            return [Color(red: 0.97, green: 0.94, blue: 0.88), Color(red: 0.93, green: 0.54, blue: 0.22)]
        case .tuxedo:
            return [Color.white, Color(white: 0.90)]
        case .siamese:
            return [Color(red: 0.34, green: 0.20, blue: 0.14), Color(red: 0.22, green: 0.12, blue: 0.08)]
        case .blackShadow:
            return [Color(red: 0.10, green: 0.10, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.06)]
        }
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: pawColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 12, height: 15)
                .overlay(
                    Group {
                        if morph == .bluePlush {
                            // 蓝猫毛绒爪：放射状蓬松短毛刺
                            Capsule()
                                .stroke(
                                    Color(red: 0.84, green: 0.93, blue: 1.0),
                                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [1.0, 2.2])
                                )
                        } else if morph == .calico {
                            // 三花羊毛毡爪：毛线锁边针脚
                            Capsule()
                                .stroke(
                                    Color(red: 0.80, green: 0.70, blue: 0.58),
                                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [1.8, 1.8])
                                )
                        } else {
                            Capsule()
                                .stroke(Color.white.opacity(morph == .blackShadow ? 0.15 : 0.70), lineWidth: 1.0)
                        }
                    }
                )
                .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1)
        }
        .rotationEffect(.degrees(isLeft ? 8 : -8))
    }
}

struct StretchedPawWithPad: View {
    let morph: CatMorph
    let isLeft: Bool

    private var pawFill: Color {
        switch morph {
        case .slime: return Color(red: 1.00, green: 0.90, blue: 0.74)
        case .bluePlush: return Color(red: 0.66, green: 0.80, blue: 0.96)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color.white
        case .siamese: return Color(red: 0.30, green: 0.18, blue: 0.12)
        case .blackShadow: return Color(red: 0.09, green: 0.09, blue: 0.12)
        }
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(pawFill)
                .frame(width: 14, height: 12)
                .overlay(
                    Group {
                        if morph == .bluePlush {
                            Ellipse()
                                .stroke(
                                    Color(red: 0.84, green: 0.93, blue: 1.0),
                                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [1.0, 2.0])
                                )
                        } else if morph == .calico {
                            Ellipse()
                                .stroke(
                                    Color(red: 0.80, green: 0.70, blue: 0.58),
                                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [1.8, 1.8])
                                )
                        } else {
                            Ellipse().stroke(Color.white.opacity(morph == .blackShadow ? 0.18 : 0.75), lineWidth: 1)
                        }
                    }
                )

            VStack(spacing: 1) {
                HStack(spacing: 1.5) {
                    Circle().fill(Color(red: 0.95, green: 0.55, blue: 0.58)).frame(width: 2.2, height: 2.2)
                    Circle().fill(Color(red: 0.95, green: 0.55, blue: 0.58)).frame(width: 2.4, height: 2.4).offset(y: -0.8)
                    Circle().fill(Color(red: 0.95, green: 0.55, blue: 0.58)).frame(width: 2.2, height: 2.2)
                }
                Ellipse()
                    .fill(Color(red: 0.95, green: 0.55, blue: 0.58))
                    .frame(width: 5.5, height: 4.0)
            }
        }
        .rotationEffect(.degrees(isLeft ? -22 : 22))
    }
}

/// 桶右侧探出的小翘尾巴（各品种专属材质配色）
struct CatTailOnRimView: View {
    let morph: CatMorph
    let phase: CGFloat

    private var tailColors: [Color] {
        switch morph {
        case .slime:
            return [Color(red: 0.96, green: 0.52, blue: 0.16), Color(red: 1.00, green: 0.78, blue: 0.42)]
        case .bluePlush:
            return [Color(red: 0.44, green: 0.60, blue: 0.84), Color(red: 0.30, green: 0.24, blue: 0.52)]
        case .calico:
            return [Color(red: 0.24, green: 0.23, blue: 0.22), Color(red: 0.93, green: 0.52, blue: 0.20)]
        case .tuxedo:
            return [Color(red: 0.14, green: 0.15, blue: 0.18), Color.white]
        case .siamese:
            return [Color(red: 0.26, green: 0.15, blue: 0.10), Color(red: 0.18, green: 0.10, blue: 0.07)]
        case .blackShadow:
            return [Color(red: 0.06, green: 0.06, blue: 0.08), Color(red: 0.16, green: 0.14, blue: 0.24).opacity(0.6)]
        }
    }

    var body: some View {
        if morph == .blackShadow {
            EmptyView()
        } else {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 14))
                path.addCurve(
                    to: CGPoint(x: 17, y: 6),
                    control1: CGPoint(x: 6, y: 2),
                    control2: CGPoint(x: 16, y: -2)
                )
            }
            .stroke(
                LinearGradient(
                    colors: tailColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 6.5, lineCap: .round)
            )
            .frame(width: 20, height: 18)
            .rotationEffect(.degrees(sin(phase * 0.9) * 8), anchor: .bottomLeading)
        }
    }
}
