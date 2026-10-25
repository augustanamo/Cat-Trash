import SwiftUI

// MARK: - 猫咪身体绘制主视图（根据品种分发至对应独立皮肤模块）
struct CatBodyLayerView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let morph: CatMorph
    let stretchRatio: CGFloat
    let phase: CGFloat
    var isFrontCompartmentExit: Bool = false
    var rimLocalY: CGFloat? = nil

    /// 按各品种专属体积守恒收窄系数计算中段腰宽（蓝猫最饱满，奶牛橡皮糖最收紧）
    private var waistScale: CGFloat {
        max(0.42, 1.0 - morph.waistNarrowingFactor * pow(stretchRatio, 0.82))
    }

    var body: some View {
        if morph == .blackShadow {
            // 黑猫专属：无固定圆柱边缘轮廓，化作一团从桶底升腾翻涌的暗影黑烟流
            shadowSmokeBodyView
        } else {
            standardBodyView
        }
    }

    /// 黑猫专属：由多层连续交织的正弦波动黑烟丝带与边缘流烟构成的无缝暗影流体（绝不分成一个个黑团）
    private var shadowSmokeBodyView: some View {
        let spine = buildSmokeSpineControlPoints()
        return BlackShadowSkin.shadowSmokeBodyView(
            startPoint: startPoint,
            endPoint: endPoint,
            spine: spine,
            stretchRatio: stretchRatio,
            waistScale: waistScale,
            phase: phase
        )
    }

    private func buildSmokeSpineControlPoints() -> (c1: CGPoint, c2: CGPoint) {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y

        if isFrontCompartmentExit {
            let forwardDip = min(max(dy * 0.22 + 14.0, -2.0), 34.0)
            let c1 = CGPoint(x: startPoint.x + dx * 0.26, y: startPoint.y + forwardDip)
            let c2 = CGPoint(x: startPoint.x + dx * 0.70, y: endPoint.y + min(max(-dy * 0.14, -16.0), 24.0))
            return (c1, c2)
        }

        // 待机或轻微晃动状态：直接使用直线平滑控制点，身体严格保持在桶底与猫头之间，绝不向上冲出或冒头
        if stretchRatio < 0.05 {
            let c1 = CGPoint(x: startPoint.x + dx * 0.33, y: startPoint.y + dy * 0.33)
            let c2 = CGPoint(x: startPoint.x + dx * 0.67, y: startPoint.y + dy * 0.67)
            return (c1, c2)
        }

        // 敞口桶（macOS磨砂桶、户外绿环卫桶、金属网眼纸篓）均为「顶部开口」：
        // 猫猫下半身在桶底，被向任何方向拉出时，身体都必须严格从「顶部桶口」向上探出越过桶沿，
        // 绝不横向切割穿透桶身侧壁！
        if let rimY = rimLocalY {
            let absDx = abs(dx)
            let side: CGFloat = dx < 0 ? -1.0 : (dx > 0 ? 1.0 : 0.0)

            // 基础直拉控制点（适用于高位向上正向拔起拉拽）
            let stdC1 = CGPoint(x: startPoint.x + dx * 0.15, y: startPoint.y + dy * 0.36)
            let stdC2 = CGPoint(x: startPoint.x + dx * 0.70, y: startPoint.y + dy * 0.78)

            // 当向左右横拉、或斜下拉伸时，身体必须经由桶口越过桶沿：
            // 横向偏移越大，越必须从顶部桶口越出
            let sideFactor = min(max((absDx - 10.0) / 25.0, 0), 1.0)
            // 只要高度低于「桶口上方 75pt」（即非超高空向上拔出），都应保持桶口出绳物理规律
            let lowFactor = min(max((endPoint.y - (rimY - 75.0)) / 55.0, 0), 1.0)
            let stretchFactor = min(max((stretchRatio - 0.04) / 0.08, 0), 1.0)
            let drapeK = sideFactor * lowFactor * stretchFactor

            // 桶口越沿控制点：
            // c1 从桶底垂直向上牵引至桶口正上方，x 紧锁在桶口中心附近（微向拉拽侧偏 6pt），确保桶内部分 100% 垂直向上不穿侧壁
            let archC1 = CGPoint(
                x: startPoint.x + side * min(absDx * 0.05, 8.0),
                y: rimY - 38.0
            )
            // c2 从桶口平滑延展至猫头方向
            let archC2 = CGPoint(
                x: startPoint.x + dx * 0.58,
                y: min(rimY - 22.0, endPoint.y - 12.0)
            )

            let c1 = CGPoint(x: stdC1.x + (archC1.x - stdC1.x) * drapeK, y: stdC1.y + (archC1.y - stdC1.y) * drapeK)
            let c2 = CGPoint(x: stdC2.x + (archC2.x - stdC2.x) * drapeK, y: stdC2.y + (archC2.y - stdC2.y) * drapeK)
            return (c1, c2)
        }

        let c1 = CGPoint(x: startPoint.x + dx * 0.18, y: startPoint.y + dy * 0.36)
        let c2 = CGPoint(x: startPoint.x + dx * 0.72, y: startPoint.y + dy * 0.78)
        return (c1, c2)
    }

    private var bodyShape: ProfiledCatBodyShape {
        let spine = buildSmokeSpineControlPoints()
        var p = ProfiledCatBodyShape(
            startPoint: startPoint,
            endPoint: endPoint,
            c1: spine.c1,
            c2: spine.c2,
            stretchRatio: stretchRatio
        )
        p.wobblePhase = phase
        switch morph {
        case .slime:
            OrangeSlimeSkin.configureProfile(&p)
        case .bluePlush:
            BluePlushSkin.configureProfile(&p)
        case .calico:
            CalicoFeltSkin.configureProfile(&p)
        case .tuxedo:
            TuxedoGummySkin.configureProfile(&p)
        case .siamese:
            SiameseCheeseSkin.configureProfile(&p)
        case .blackShadow:
            BlackShadowSkin.configureProfile(&p)
        }
        return p
    }

    private var standardBodyView: some View {
        let shape = bodyShape

        return ZStack {
            // 1. 六大品种专属 3D 圆柱体积与材质纹理绘制
            Canvas { context, _ in
                let dy = endPoint.y - startPoint.y
                let spine = buildSmokeSpineControlPoints()
                let c1 = spine.c1
                let c2 = spine.c2

                let minX = min(startPoint.x, endPoint.x) - 35
                let maxX = max(startPoint.x, endPoint.x) + 35
                let fullRect = Path(CGRect(x: minX - 100, y: min(startPoint.y, endPoint.y) - 100, width: (maxX - minX) + 200, height: abs(dy) + 250))

                // 底层 3D 圆柱侧光阴影与受光渐变底色
                context.fill(
                    fullRect,
                    with: .linearGradient(
                        Gradient(stops: cylinderBaseStops),
                        startPoint: CGPoint(x: minX + 5, y: startPoint.y),
                        endPoint: CGPoint(x: maxX - 5, y: startPoint.y)
                    )
                )

                // 肚皮中央柔和受光纵向渐变光带
                var bellySpine = Path()
                bellySpine.move(to: startPoint)
                bellySpine.addCurve(to: endPoint, control1: c1, control2: c2)
                context.stroke(
                    bellySpine,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: bellyHighlightColor.opacity(0.35), location: 0.0),
                            .init(color: bellyHighlightColor, location: 0.50),
                            .init(color: bellyHighlightColor.opacity(0.20), location: 1.0)
                        ]),
                        startPoint: startPoint,
                        endPoint: endPoint
                    ),
                    style: StrokeStyle(lineWidth: 18.0 * waistScale, lineCap: .round)
                )

                // 2. 六大品种专属材质纹理绘制
                switch morph {
                case .slime:
                    OrangeSlimeSkin.drawBodyTextures(
                        context: &context,
                        shape: shape,
                        startPoint: startPoint,
                        endPoint: endPoint,
                        c1: c1,
                        c2: c2,
                        waistScale: waistScale,
                        phase: phase
                    )
                case .bluePlush:
                    BluePlushSkin.drawBodyTextures(
                        context: &context,
                        shape: shape,
                        stretchRatio: stretchRatio,
                        phase: phase
                    )
                case .calico:
                    CalicoFeltSkin.drawBodyTextures(
                        context: &context,
                        shape: shape,
                        stretchRatio: stretchRatio,
                        startPoint: startPoint,
                        endPoint: endPoint
                    )
                case .tuxedo:
                    TuxedoGummySkin.drawBodyTextures(
                        context: &context,
                        shape: shape,
                        startPoint: startPoint,
                        endPoint: endPoint,
                        c1: c1,
                        c2: c2,
                        waistScale: waistScale
                    )
                case .siamese:
                    SiameseCheeseSkin.drawBodyTextures(
                        context: &context,
                        startPoint: startPoint,
                        endPoint: endPoint,
                        c1: c1,
                        c2: c2,
                        waistScale: waistScale
                    )
                case .blackShadow:
                    BlackShadowSkin.drawBodyTextures(
                        context: &context,
                        startPoint: startPoint,
                        endPoint: endPoint,
                        c1: c1,
                        c2: c2
                    )
                }
            }
            .clipShape(shape)
            // 黑猫越拉越虚化，呈现烟雾消融质感
            .opacity(morph == .blackShadow ? Double(max(0.58, 0.94 - stretchRatio * 0.35)) : 1.0)

            // 2. 各品种专属轮廓边缘质感
            bodyEdgeStrokeView(shape: shape)
        }
    }

    private var cylinderBaseStops: [Gradient.Stop] {
        switch morph {
        case .slime: return OrangeSlimeSkin.cylinderBaseStops
        case .bluePlush: return BluePlushSkin.cylinderBaseStops
        case .calico: return CalicoFeltSkin.cylinderBaseStops
        case .tuxedo: return TuxedoGummySkin.cylinderBaseStops
        case .siamese: return SiameseCheeseSkin.cylinderBaseStops
        case .blackShadow: return BlackShadowSkin.cylinderBaseStops
        }
    }

    private var bellyHighlightColor: Color {
        switch morph {
        case .slime: return OrangeSlimeSkin.bellyHighlightColor
        case .bluePlush: return BluePlushSkin.bellyHighlightColor
        case .calico: return CalicoFeltSkin.bellyHighlightColor
        case .tuxedo: return TuxedoGummySkin.bellyHighlightColor
        case .siamese: return SiameseCheeseSkin.bellyHighlightColor
        case .blackShadow: return BlackShadowSkin.bellyHighlightColor
        }
    }

    @ViewBuilder
    private func bodyEdgeStrokeView(shape: ProfiledCatBodyShape) -> some View {
        switch morph {
        case .slime:
            OrangeSlimeSkin.bodyEdgeStrokeView(shape: shape)
        case .bluePlush:
            BluePlushSkin.bodyEdgeStrokeView(shape: shape, stretchRatio: stretchRatio)
        case .calico:
            CalicoFeltSkin.bodyEdgeStrokeView(shape: shape, stretchRatio: stretchRatio)
        case .tuxedo:
            TuxedoGummySkin.bodyEdgeStrokeView(shape: shape)
        case .siamese:
            SiameseCheeseSkin.bodyEdgeStrokeView(shape: shape)
        case .blackShadow:
            BlackShadowSkin.bodyEdgeStrokeView(shape: shape)
        }
    }
}

// MARK: - 4. 辅助几何 Shapes
struct RoundedTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.35)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.35)
        )
        path.closeSubpath()
        return path
    }
}

struct WCatMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 0.8))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.width * 0.25, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 0.8),
            control: CGPoint(x: rect.width * 0.75, y: rect.maxY)
        )
        return path
    }
}

struct SquintEyeShape: Shape {
    let isLeft: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isLeft {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        return path
    }
}

struct HappyArcEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - 3)
        )
        return path
    }
}

struct TriangleFangShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 5. 组合主视图：后壁 -> 桶内猫下半身 -> 拉伸果冻身体与猫头 -> 前金属细网格 -> 桶沿爪子与小尾巴
public struct CatTrashSceneView: View {
    @ObservedObject var physics = CatPhysicsEngine.shared
    @ObservedObject var prefs = CatPreferences.shared
    let canvasSize: CGSize

    public init(canvasSize: CGSize) {
        self.canvasSize = canvasSize
    }

    private var bucketLocalCenter: CGPoint {
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            return CGPoint(
                x: physics.bucketScreenCenter.x - screen.frame.minX,
                y: canvasSize.height - (physics.bucketScreenCenter.y - screen.frame.minY)
            )
        }
        return CGPoint(x: canvasSize.width - 75, y: canvasSize.height - 75)
    }

    private var widgetScale: CGFloat {
        max(CGFloat(prefs.widgetScale), 0.5)
    }

    private var bucketAnchor: UnitPoint {
        UnitPoint(
            x: bucketLocalCenter.x / max(canvasSize.width, 1),
            y: bucketLocalCenter.y / max(canvasSize.height, 1)
        )
    }

    private var isStreetBox: Bool {
        prefs.selectedBinStyle == .streetMetalBox
    }

    private var isGreenWheelie: Bool {
        prefs.selectedBinStyle == .greenWheelieBin
    }

    /// 桶口 Y（缩放容器局部坐标）
    private var rimLocalY: CGFloat {
        bucketLocalCenter.y + (isGreenWheelie ? kGreenBinRimY : -34.0)
    }

    /// 街头金属果皮箱模式下，猫猫是否已经挣脱门板从「上方正面暗格」向前钻出箱外
    private var isPoppedOutOfStreetCompartment: Bool {
        isStreetBox && !physics.arePawsClingingToRim && currentStretchRatio >= 0.12
    }

    /// 身体起始点：敞口桶位于桶底内部；街头果皮箱位于「上方暗格」内部（门板上沿后方）
    private var catBaseLocalPoint: CGPoint {
        if isStreetBox {
            return CGPoint(x: bucketLocalCenter.x, y: bucketLocalCenter.y - 26)
        }
        return CGPoint(x: bucketLocalCenter.x, y: bucketLocalCenter.y + 15)
    }

    /// 缩放容器内部的猫头局部坐标（经 scaleEffect 放大后与屏幕鼠标绝对位置 1:1 对齐）
    private var catHeadLocalPoint: CGPoint {
        let s = widgetScale
        let breathY = sin(physics.breathingPhase) * 1.8
        return CGPoint(
            x: bucketLocalCenter.x + physics.headDisplacement.dx / s,
            y: bucketLocalCenter.y - physics.restingHeadYOffset - physics.headDisplacement.dy / s + breathY
        )
    }

    /// 屏幕实际像素坐标系下的猫头位置（供悬浮提示气泡定位）
    private var screenHeadLocalPoint: CGPoint {
        let s = widgetScale
        let breathY = sin(physics.breathingPhase) * 1.8 * s
        return CGPoint(
            x: bucketLocalCenter.x + physics.headDisplacement.dx,
            y: bucketLocalCenter.y - physics.restingHeadYOffset * s - physics.headDisplacement.dy + breathY
        )
    }

    private var currentStretchRatio: CGFloat {
        let dist = hypot(
            catHeadLocalPoint.x - bucketLocalCenter.x,
            catHeadLocalPoint.y - (bucketLocalCenter.y - physics.restingHeadYOffset)
        )
        return min(dist / 260.0, 1.0)
    }

    /// 街头果皮箱从暗格往外挤出瞬间的扁头挤压形变系数
    private var compartmentSqueezeFactor: CGFloat {
        guard isStreetBox else { return 0 }
        if currentStretchRatio > 0.02 && currentStretchRatio < 0.24 {
            return sin((currentStretchRatio - 0.02) / 0.22 * .pi)
        }
        return 0
    }

    /// 爪子跟随位置：潜伏探头或拖拽初段死扣桶沿/门板上沿时固定在边缘，脱落拉长后跟随猫头下颌
    private var pawsLocalPoint: CGPoint {
        if physics.arePawsClingingToRim || currentStretchRatio < 0.16 {
            if isStreetBox {
                // 街头果皮箱：两只爪子扒在深咖色前门板上沿（避开中间小银锁孔）
                return CGPoint(x: bucketLocalCenter.x, y: bucketLocalCenter.y - 24.5)
            }
            if isGreenWheelie {
                // 放大后的绿桶：爪子扒在高高的桶口折边上
                return CGPoint(x: bucketLocalCenter.x + 4, y: bucketLocalCenter.y + kGreenBinRimY + 3)
            }
            return CGPoint(x: bucketLocalCenter.x, y: bucketLocalCenter.y - 31)
        } else {
            return CGPoint(
                x: catHeadLocalPoint.x,
                y: catHeadLocalPoint.y + 20
            )
        }
    }

    @ViewBuilder
    private var catAssemblyView: some View {
        ZStack {
            CatBodyLayerView(
                startPoint: catBaseLocalPoint,
                endPoint: catHeadLocalPoint,
                morph: prefs.selectedMorph,
                stretchRatio: currentStretchRatio,
                phase: physics.breathingPhase,
                isFrontCompartmentExit: isStreetBox,
                rimLocalY: isStreetBox ? nil : rimLocalY
            )

            if !isStreetBox {
                BucketBottomPaperAndHindFeetView(
                    morph: prefs.selectedMorph,
                    stretchRatio: currentStretchRatio
                )
                .position(bucketLocalCenter)
            }

            CatHeadView(
                morph: prefs.selectedMorph,
                stretchRatio: currentStretchRatio,
                stealthPeekLevel: physics.stealthPeekLevel,
                interactionState: physics.state,
                idleSubAction: physics.idleSubAction,
                isBlinking: physics.isBlinking,
                gazeOffset: physics.pupilGazeOffset,
                chewPhase: physics.chewPhase,
                leftEarTwitch: physics.leftEarTwitchAngle,
                rightEarTwitch: physics.rightEarTwitchAngle,
                headTiltAngle: physics.headTiltAngle,
                sniffPhase: physics.sniffPhase,
                isPeekingUnderLid: isGreenWheelie && currentStretchRatio < 0.12
            )
            .scaleEffect(
                x: 1.0 + compartmentSqueezeFactor * 0.11 + physics.lidBonkHeadSquish * 0.14,
                y: 1.0 - compartmentSqueezeFactor * 0.14 - physics.lidBonkHeadSquish * 0.16
            )
            .position(catHeadLocalPoint)
        }
    }

    public var body: some View {
        ZStack {
            // 0. 桌面测试废纸团（如有生成）
            ForEach(physics.virtualSnacks) { snack in
                virtualSnackView(snack)
            }

            // 1~6. 可自由无损缩放的猫咪与废纸篓整体组件（以桶中心为锚点等比缩放）
            ZStack {
                // 1. 垃圾桶后壁内阴影层 + 暗格内腔
                BasketBackWallView(binStyle: prefs.selectedBinStyle)
                    .position(bucketLocalCenter)

                // 2. 桶沿右侧探出的小翘尾巴（仅无盖敞口桶露出桶沿小尾巴；街头果皮箱与掀盖绿环卫桶不悬空露尾）
                if !isStreetBox && !isGreenWheelie && (physics.stealthPeekLevel > 0.35 || currentStretchRatio > 0.05) {
                    CatTailOnRimView(morph: prefs.selectedMorph, phase: physics.breathingPhase)
                        .position(x: bucketLocalCenter.x + 42, y: bucketLocalCenter.y - 43)
                }

                // 3. 猫咪完整图层（位于前景桶壁后方；街头果皮箱暗格潜伏阶段受暗格顶棚裁剪）
                if isStreetBox {
                    if !isPoppedOutOfStreetCompartment {
                        catAssemblyView
                            .clipShape(StreetBoxCompartmentClipShape(bucketCenter: bucketLocalCenter))
                    }
                } else {
                    catAssemblyView
                }

                // 3B. 经典掀盖绿环卫桶专属：当猫猫像掀开地下道井盖一样伸出一只爪子往上推盖子时，绘制撑住桶盖底面的猫爪
                if isGreenWheelie && physics.lidPawPushProgress > 0.01 {
                    GreenBinLidPushingPawView(
                        morph: prefs.selectedMorph,
                        lidOpenAngle: physics.lidOpenAngle,
                        pushProgress: physics.lidPawPushProgress
                    )
                    .position(bucketLocalCenter)
                }

                // 4. 垃圾桶前景层（macOS 一体磨砂壁 / 经典掀盖绿桶身 / 街头果皮箱深咖前门板与外框 / 3D 金属网格）
                BasketFrontMeshView(binStyle: prefs.selectedBinStyle)
                    .position(bucketLocalCenter)

                // 4B. 经典掀盖绿环卫桶专属：动态旋转的活动绿色桶盖（待机被猫头/耳朵顶开一道三角缝、微动作被顶得咣当开合或被单爪推起、拖拽时向后大翻转晃荡！）
                if isGreenWheelie {
                    GreenWheelieBinArticulatedLidView(lidOpenAngle: physics.lidOpenAngle)
                        .position(bucketLocalCenter)
                }

                // 5. 街头果皮箱「从上方暗格向前拖出」阶段：猫猫身体与脑袋从暗格窗口向前钻出，越过前门板与外框并投下立体阴影！
                if isPoppedOutOfStreetCompartment {
                    catAssemblyView
                        .shadow(color: Color.black.opacity(0.45), radius: 5, x: 0, y: 4)
                }

                // 6. 潜伏偷伸爪 / 探头搭桶沿或门板上沿 / 扒拉门板死命扣住 / 脱落拉伸粉肉垫爪子
                MeltingRimPawsView(
                    morph: prefs.selectedMorph,
                    stretchRatio: currentStretchRatio,
                    stealthPeekLevel: physics.stealthPeekLevel,
                    idleSubAction: physics.idleSubAction,
                    sneakPawPhase: physics.sneakPawPhase,
                    arePawsClingingToRim: physics.arePawsClingingToRim
                )
                .position(pawsLocalPoint)

                // 7. 右键触发：悬浮在周围的分开独立控制按钮（上方进度条 + 右侧垃圾桶icon按钮 + 左侧修改文件/退出）
                if physics.isFloatingMenuVisible {
                    FloatingSurroundingControlsView(
                        bucketCenter: bucketLocalCenter,
                        canvasSize: canvasSize,
                        isGreenWheelie: isGreenWheelie
                    )
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(widgetScale, anchor: bucketAnchor)

            // 7. 锁定文件或按住 Option 点化零食时的浮动提示胶囊
            if case .sniffingToEnchant(_, let snackName) = physics.state {
                Text("✨ 嗅嗅~ 松手点化为「\(snackName)」")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.78), in: Capsule())
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.75), lineWidth: 1.0))
                    .position(x: screenHeadLocalPoint.x, y: screenHeadLocalPoint.y - 42 * widgetScale)
            } else if case .targeting(let fileName, _) = physics.state {
                Text("chomp! 松手吞掉「\(fileName)」(按 ⌥ 点化零食)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 0.8))
                    .position(x: screenHeadLocalPoint.x, y: screenHeadLocalPoint.y - 42 * widgetScale)
            }

            // 8. 吞食碎屑与饱嗝粒子层
            ForEach(physics.particles) { particle in
                particleView(particle)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    @ViewBuilder
    private func virtualSnackView(_ snack: VirtualSnackItem) -> some View {
        let localPos = screenToLocal(snack.screenPosition)
        VStack(spacing: 2) {
            Text(snack.emoji)
                .font(.system(size: 22))
            Text(snack.title)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.55), in: Capsule())
        }
        .position(localPos)
    }

    @ViewBuilder
    private func particleView(_ p: EffectParticle) -> some View {
        let localPos = screenToLocal(p.position)
        switch p.kind {
        case .crumb(let color):
            Circle()
                .fill(color)
                .frame(width: 5.5 * p.scale, height: 5.5 * p.scale)
                .opacity(p.opacity)
                .position(localPos)
        case .sparkle:
            Image(systemName: "sparkle")
                .font(.system(size: 10 * p.scale, weight: .bold))
                .foregroundStyle(.yellow)
                .opacity(p.opacity)
                .position(localPos)
        case .burpBubble:
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1.2)
                .background(Circle().fill(Color.white.opacity(0.22)))
                .frame(width: 11 * p.scale, height: 11 * p.scale)
                .opacity(p.opacity)
                .position(localPos)
        case .heartOrText(let text):
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.orange.opacity(0.85), in: Capsule())
                .opacity(p.opacity)
                .position(localPos)
        }
    }

    private func screenToLocal(_ screenPt: CGPoint) -> CGPoint {
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            return CGPoint(
                x: screenPt.x - screen.frame.minX,
                y: canvasSize.height - (screenPt.y - screen.frame.minY)
            )
        }
        return screenPt
    }
}
