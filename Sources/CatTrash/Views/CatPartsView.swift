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

func sampleHeadPerimeterPoints(
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
