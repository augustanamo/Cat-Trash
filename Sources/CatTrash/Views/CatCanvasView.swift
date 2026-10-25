import SwiftUI

// MARK: - 1. 垃圾桶后壁视图（支持 4 种垃圾桶样式切换）
struct BasketBackWallView: View {
    var binStyle: TrashBinStyle = CatPreferences.shared.selectedBinStyle

    var body: some View {
        switch binStyle {
        case .macOSFrosted:
            MacOSFrostedBackWallView()
        case .greenWheelieBin:
            GreenWheelieBinBackWallView()
        case .streetMetalBox:
            StreetMetalBoxBackWallView()
        case .metalMesh:
            MetalMeshBackWallView()
        }
    }
}

/// 样式 A（macOS 原生一体成型方圆角磨砂桶 · 后壁：无凸起包边、无杂物，纯粹一体注塑磨砂内壁）
struct MacOSFrostedBackWallView: View {
    var body: some View {
        ZStack {
            // 1. 桌面柔和圆角矩形接触阴影
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.38), .black.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
                .frame(width: 80, height: 16)
                .offset(y: 34)

            // 2. 一体成型桶后壁内腔（无外加包边圈，仅靠桶壁厚度切面与柔和冷灰白磨砂渐变呈现体积）
            MacOSBinShellShape(isFrontHalf: false)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.72, green: 0.74, blue: 0.78), location: 0.0),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.87), location: 0.14),
                            .init(color: Color(red: 0.75, green: 0.77, blue: 0.80), location: 0.50),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.87), location: 0.86),
                            .init(color: Color(red: 0.70, green: 0.72, blue: 0.76), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    MacOSBinShellShape(isFrontHalf: false)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.35), location: 0.0),
                                    .init(color: Color(red: 0.50, green: 0.52, blue: 0.56).opacity(0.35), location: 0.25),
                                    .init(color: Color(red: 0.38, green: 0.40, blue: 0.44).opacity(0.55), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .frame(width: 78, height: 74)

            // 3. 桶壁顶部一体平切面微高光（非独立凸边，仅为桶壁自身厚度的顶截面反光）
            MacOSSquircleRimArcShape(isFrontHalf: false)
                .stroke(
                    Color(red: 0.92, green: 0.93, blue: 0.96),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
                .frame(width: 78, height: 11)
                .offset(y: -34)
        }
    }
}

/// 样式 B（街头立式深咖烤漆金属果皮箱 · 后壁：还原照片中的深色方框顶棚、内凹投口暗腔、修长立柜比例与底部镂空底座）
struct StreetMetalBoxBackWallView: View {
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

                // A. 整体深炭褐金属箱体背板
                let fullRect = CGRect(x: leftX, y: topY, width: boxW, height: baseBotY - topY)
                context.fill(
                    Path(fullRect),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.14, green: 0.11, blue: 0.10), location: 0.0),
                            .init(color: Color(red: 0.24, green: 0.19, blue: 0.16), location: 0.55),
                            .init(color: Color(red: 0.34, green: 0.26, blue: 0.21), location: 0.92),
                            .init(color: Color(red: 0.16, green: 0.13, blue: 0.11), location: 1.0)
                        ]),
                        startPoint: CGPoint(x: leftX, y: topY),
                        endPoint: CGPoint(x: rightX, y: topY + 24)
                    )
                )

                // B. 上方投物口内腔右侧暖琥珀环境反光（还原实拍图投口内部右侧暖光质感）
                let recessRect = CGRect(x: leftX + 2.5, y: topY + 2.5, width: boxW - 5.0, height: doorTopY - topY + 4.0)
                context.fill(
                    Path(recessRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.44, green: 0.31, blue: 0.22).opacity(0.65),
                            Color(red: 0.15, green: 0.12, blue: 0.10).opacity(0.92)
                        ]),
                        center: CGPoint(x: rightX - 14, y: topY + 15),
                        startRadius: 2,
                        endRadius: 42
                    )
                )

                // C. 投物口左右两侧内壁立体斜切折面（表现箱体深度）
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
                context.fill(rightInnerWall, with: .color(Color(red: 0.28, green: 0.21, blue: 0.17)))

                // D. 底部镂空金属底座内腔（位于前门板下方）
                let baseInnerRect = CGRect(x: leftX + 3.0, y: doorBotY + 1.5, width: boxW - 6.0, height: baseBotY - doorBotY - 3.0)
                context.fill(
                    Path(baseInnerRect),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.09, green: 0.08, blue: 0.07),
                            Color(red: 0.26, green: 0.19, blue: 0.15),
                            Color(red: 0.12, green: 0.10, blue: 0.09)
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

/// 样式 C（3D 圆柱透视高光金属网格桶 · 后壁）
struct MetalMeshBackWallView: View {
    var body: some View {
        ZStack {
            // 1. 桌面真实双层接触阴影（核心深色接触影 + 外围柔和漫射影）
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.55), .black.opacity(0.24), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 22)
                .offset(y: 35)

            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 58, height: 11)
                .blur(radius: 2.2)
                .offset(y: 34)

            // 2. 桶后壁 3D 弧形内腔底色（上沿贴合桶口后弧，下沿贴合立体桶底）
            CylindricalFrustumShellShape(isFrontHalf: false)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.16, green: 0.18, blue: 0.21).opacity(0.84), location: 0.0),
                            .init(color: Color(red: 0.28, green: 0.30, blue: 0.35).opacity(0.76), location: 0.32),
                            .init(color: Color(red: 0.13, green: 0.15, blue: 0.18).opacity(0.90), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            // 3. 后壁凹面 3D 螺旋金属丝网（向内凹曲透视，比前网略暗以拉开前后空间纵深）
            CylindricalWireMeshShape(isFrontHalf: false, strandCount: 15, twistRadians: .pi * 0.56)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.32).opacity(0.42),
                            Color(white: 0.62).opacity(0.48),
                            Color(white: 0.28).opacity(0.40)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 0.65, lineCap: .round)
                )
                .frame(width: 78, height: 74)
                .clipShape(CylindricalFrustumShellShape(isFrontHalf: false))

            // 4. 桶底真实 3D 旋压拉丝金属内底盘（椭圆透视凹盘 + 环状金属光泽 + 桶底环境光遮蔽阴影）
            ZStack {
                // 内底盘暗钢金属主体
                Ellipse()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.20, green: 0.22, blue: 0.25), location: 0.0),
                                .init(color: Color(red: 0.56, green: 0.59, blue: 0.64), location: 0.30),
                                .init(color: Color(red: 0.30, green: 0.32, blue: 0.36), location: 0.68),
                                .init(color: Color(red: 0.16, green: 0.18, blue: 0.20), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 56, height: 12.5)

                // 旋压金属同心高光环与内凹阴影
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.65),
                                Color.white.opacity(0.45),
                                Color.black.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: 52, height: 10.5)

                Ellipse()
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
                    .frame(width: 34, height: 6.5)
            }
            .offset(y: 26.5)

            // 5. 桶口后半圈高光铬金属卷边（仅绘制上半椭圆弧 + 桶口内壁深色金属凹槽）
            ZStack {
                // 桶口内圈深色金属内壁环
                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.18), location: 0.0),
                                .init(color: Color(white: 0.48), location: 0.32),
                                .init(color: Color(white: 0.22), location: 0.72),
                                .init(color: Color(white: 0.35), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6.2, lineCap: .round)
                    )
                    .offset(y: 1.2)

                // 后半圈立体滚边不锈钢管体
                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.38, green: 0.40, blue: 0.44), location: 0.0),
                                .init(color: Color(red: 0.90, green: 0.93, blue: 0.97), location: 0.28),
                                .init(color: Color(red: 0.52, green: 0.55, blue: 0.60), location: 0.62),
                                .init(color: Color(red: 0.78, green: 0.81, blue: 0.86), location: 0.84),
                                .init(color: Color(red: 0.36, green: 0.38, blue: 0.42), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4.4, lineCap: .round)
                    )

                // 后半圈顶部极细镜面反光丝
                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.92), .white.opacity(0.40)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
                    )
                    .offset(y: -1.1)
            }
            .frame(width: 78, height: 15)
            .offset(y: -34)
        }
    }
}

/// 桶内底部一体式猫猫后脚掌（移除了原本像贴纸一样的三个彩色扁圆点，保持真实 3D 金属桶底质感）
struct BucketBottomPaperAndHindFeetView: View {
    let morph: CatMorph
    let stretchRatio: CGFloat

    private var footColor: Color {
        switch morph {
        case .slime: return Color(red: 1.00, green: 0.88, blue: 0.70)
        case .bluePlush: return Color(red: 0.78, green: 0.88, blue: 0.98)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color.white
        case .siamese: return Color(red: 0.30, green: 0.18, blue: 0.12)
        case .blackShadow: return Color(red: 0.08, green: 0.08, blue: 0.12)
        }
    }

    var body: some View {
        ZStack {
            // 蹬在桶底的同材质小后脚掌（黑猫暗影烟雾形态不显示实体脚掌，保持一团黑烟沉在桶底）
            if morph != .blackShadow {
                HStack(spacing: 16) {
                    Capsule()
                        .fill(footColor)
                        .frame(width: 11, height: 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 0.8))
                        .rotationEffect(.degrees(14))
                    Capsule()
                        .fill(footColor)
                        .frame(width: 11, height: 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 0.8))
                        .rotationEffect(.degrees(-14))
                }
                .offset(y: 19 - min(stretchRatio * 6, 5))
            }
        }
        .frame(width: 74, height: 70)
    }
}

// MARK: - 2. 垃圾桶前景视图（支持 4 种垃圾桶样式切换）
struct BasketFrontMeshView: View {
    var binStyle: TrashBinStyle = CatPreferences.shared.selectedBinStyle

    var body: some View {
        switch binStyle {
        case .macOSFrosted:
            MacOSFrostedFrontWallView()
        case .greenWheelieBin:
            GreenWheelieBinFrontWallView()
        case .streetMetalBox:
            StreetMetalBoxFrontWallView()
        case .metalMesh:
            MetalMeshFrontWallView()
        }
    }
}

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

                // 3. 桶口上方深森林绿内腔暗槽（使猫猫躲在盖子三角缝隙里时，亮晶晶的眼睛在深暗背景衬托下格外醒目！）
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

            // 左上桶壁柔和浅翠绿弧形高光区（还原实拍图左侧面的塑料反光）
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

            // 2. 桶身正面主面板（经典环卫深翠绿渐变 + 立体转折高光棱）
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

            // 3. 桶口外翻折边裙檐 (Projecting Rim Collar) 与下方 4 道竖向三角加强筋 (Gussets)
            // (a) 裙檐下方阴影带
            var underRimShadow = Path()
            underRimShadow.move(to: CGPoint(x: topLeftX - 1.0, y: rimY + 4.5))
            underRimShadow.addLine(to: CGPoint(x: topCornerX, y: rimY + 7.2))
            underRimShadow.addLine(to: CGPoint(x: topRightX + 1.0, y: rimY + 5.2))
            context.stroke(
                underRimShadow,
                with: .color(Color(red: 0.01, green: 0.26, blue: 0.11).opacity(0.75)),
                style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
            )

            // (b) 左侧与转角处的 4 道经典注塑竖向加强筋（还原照片桶口下方四块立筋结构）
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
                // 加强筋右侧深绿投影
                let ribShadow = CGRect(x: rib.x + 2.6, y: rib.yTop + 0.5, width: 1.8, height: rib.h - 0.5)
                context.fill(Path(ribShadow), with: .color(Color(red: 0.01, green: 0.28, blue: 0.12).opacity(0.78)))
            }

            // (c) 桶口外翻宽折边主体（左斜前折角立体裙边）
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

            // 桶口折边上沿翠白高光棱线
            var rimTopHighlight = Path()
            rimTopHighlight.move(to: CGPoint(x: topLeftX - 4.0, y: rimY - 0.8))
            rimTopHighlight.addLine(to: CGPoint(x: topCornerX - 1.0, y: rimY + 1.8))
            rimTopHighlight.addLine(to: CGPoint(x: topRightX + 5.0, y: rimY + 0.1))
            context.stroke(
                rimTopHighlight,
                with: .color(Color(red: 0.62, green: 0.96, blue: 0.74).opacity(0.85)),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round)
            )

            // 4. 桶身正面中央白色圆形「请勿乱扔垃圾」丝印标识（严格还原实拍图白圈+网格篓+小人图标）
            let emblemCenter = CGPoint(x: cx + 7.5, y: rimY + 34.5)
            let emblemR: CGFloat = 8.8
            let emblemRect = CGRect(
                x: emblemCenter.x - emblemR,
                y: emblemCenter.y - emblemR,
                width: emblemR * 2.0,
                height: emblemR * 2.0
            )
            let emblemWhite = Color.white.opacity(0.90)

            // (a) 外圈白环 + 左下角丝印油墨微滴（还原照片细节）
            context.stroke(Path(ellipseIn: emblemRect), with: .color(emblemWhite), lineWidth: 1.15)
            var drip = Path()
            drip.move(to: CGPoint(x: emblemCenter.x - 4.2, y: emblemCenter.y + emblemR - 0.2))
            drip.addLine(to: CGPoint(x: emblemCenter.x - 4.2, y: emblemCenter.y + emblemR + 2.2))
            context.stroke(drip, with: .color(emblemWhite.opacity(0.85)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))

            // (b) 圈内右侧站立小人
            let personHead = CGRect(x: emblemCenter.x + 1.4, y: emblemCenter.y - 5.4, width: 2.0, height: 2.0)
            context.fill(Path(ellipseIn: personHead), with: .color(emblemWhite))

            var personBody = Path()
            // 手臂向左上伸出扔垃圾
            personBody.move(to: CGPoint(x: emblemCenter.x - 1.8, y: emblemCenter.y - 3.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 2.4, y: emblemCenter.y - 2.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 3.4, y: emblemCenter.y + 0.2))
            // 躯干与双腿
            personBody.move(to: CGPoint(x: emblemCenter.x + 2.2, y: emblemCenter.y - 2.6))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 1.8, y: emblemCenter.y + 4.2))
            personBody.move(to: CGPoint(x: emblemCenter.x + 2.5, y: emblemCenter.y + 0.2))
            personBody.addLine(to: CGPoint(x: emblemCenter.x + 3.1, y: emblemCenter.y + 4.2))
            context.stroke(personBody, with: .color(emblemWhite), style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round))

            // (c) 圈内左侧小网篓与落下的垃圾点
            let dotRect = CGRect(x: emblemCenter.x - 2.6, y: emblemCenter.y - 2.2, width: 1.1, height: 1.1)
            context.fill(Path(ellipseIn: dotRect), with: .color(emblemWhite))

            var smallBasket = Path()
            smallBasket.move(to: CGPoint(x: emblemCenter.x - 4.4, y: emblemCenter.y - 0.5))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 3.8, y: emblemCenter.y + 4.0))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 1.2, y: emblemCenter.y + 4.0))
            smallBasket.addLine(to: CGPoint(x: emblemCenter.x - 0.6, y: emblemCenter.y - 0.5))
            smallBasket.closeSubpath()
            context.stroke(smallBasket, with: .color(emblemWhite), lineWidth: 0.75)

            // (d) 底部弧形小字点阵
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

/// 样式 D 专属：可绕左侧铰链动态掀开、顶起、推开与向后大翻转晃荡的 3D 立体绿色桶盖！
struct GreenWheelieBinArticulatedLidView: View {
    let lidOpenAngle: CGFloat

    var body: some View {
        Canvas { context, rawSize in
            let size = CGSize(width: rawSize.width / kGreenBinScale, height: rawSize.height / kGreenBinScale)
            context.scaleBy(x: kGreenBinScale, y: kGreenBinScale)
            // 铰链支点定位于画布 (48 - 38 = 10, 54 - 36 = 18) 附近，为向后翻转 >120° 预留充足左侧画布空间
            let hinge = CGPoint(x: size.width * 0.5 - 38.0, y: size.height * 0.5 - 36.0)

            context.translateBy(x: hinge.x, y: hinge.y)
            context.rotate(by: .degrees(-Double(lidOpenAngle)))

            // 在以左端铰链 (0, 0) 为原点的局部坐标系中绘制 3D 阶梯拱形绿桶盖（总宽约 82pt）
            // 1. 桶盖底面内凹暗腔（当盖子被猫头顶开或向后翻开时，露出桶盖内侧立体暗绿凹槽！）
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

            // 2. 桶盖上层双阶梯流线拱顶（还原实拍图顶部阶梯隆起加强筋造型）
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

            // 拱顶中央亮白绿镜面反光斜坡（还原照片盖子顶部的亮光面）
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

            // 桶盖前缘高光折线
            var flangeHighlight = Path()
            flangeHighlight.move(to: CGPoint(x: 0.0, y: -1.6))
            flangeHighlight.addLine(to: CGPoint(x: 26.0, y: 0.4))
            flangeHighlight.addLine(to: CGPoint(x: 81.5, y: -1.2))
            context.stroke(
                flangeHighlight,
                with: .color(Color(red: 0.65, green: 0.97, blue: 0.76).opacity(0.85)),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
            )

            // 4. 盖面左前侧两枚凸起注塑卡扣耳块（还原照片盖子上的两个立体凸起块）
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

/// 样式 D 专属：猫猫像掀开地下道井盖一样，从桶内伸出一只爪子往上推开绿色桶盖！
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
            // 爪子顶在距离左侧铰链 60pt 处的桶盖底面上
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

/// 样式 A：macOS 原生一体成型方圆角（Squircle）半透明磨砂白桶前壁（完全无边框、无内框线、无外凸圈，纯粹一体柔和过渡！）
struct MacOSFrostedFrontWallView: View {
    var body: some View {
        ZStack {
            // 1. 纯粹一体成型磨砂白半透明主体（无任何描边或内框线，完全靠平滑渐变表现方圆角桶壁厚度与漫反射）
            MacOSBinShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.90, green: 0.92, blue: 0.94).opacity(0.92), location: 0.0),
                            .init(color: Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.86), location: 0.08),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.88).opacity(0.75), location: 0.18),
                            .init(color: Color(red: 0.78, green: 0.80, blue: 0.84).opacity(0.70), location: 0.50),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.88).opacity(0.75), location: 0.82),
                            .init(color: Color(red: 0.95, green: 0.96, blue: 0.98).opacity(0.86), location: 0.92),
                            .init(color: Color(red: 0.88, green: 0.90, blue: 0.93).opacity(0.92), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            // 2. 垂直方向柔和漫射过渡（顶部与底部微亮、中段通透，无任何硬边分割）
            MacOSBinShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.45), location: 0.0),
                            .init(color: Color.white.opacity(0.10), location: 0.16),
                            .init(color: Color.clear, location: 0.55),
                            .init(color: Color(red: 0.68, green: 0.70, blue: 0.74).opacity(0.24), location: 0.85),
                            .init(color: Color.white.opacity(0.58), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 78, height: 74)

            // 3. 桶壁顶部一体平切面微光（与桶身完全齐平，无外凸阴影或包边）
            MacOSSquircleRimArcShape(isFrontHalf: true)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.93, blue: 0.96),
                            Color.white,
                            Color(red: 0.94, green: 0.95, blue: 0.98),
                            Color.white,
                            Color(red: 0.90, green: 0.92, blue: 0.95)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                )
                .frame(width: 78, height: 11)
                .offset(y: -34)
        }
    }
}

/// 样式 B：街头立式深咖烤漆金属果皮箱 · 前景（修长立式立柜 + 深咖哑光金属长门板 + 顶部银色锁孔 + 激光镂空「扔垃圾小人」标志 + 加强筋折线 + 外围黑褐钢框与镂空底座）
struct StreetMetalBoxFrontWallView: View {
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

            // 1. 深咖色哑光烤漆金属加长前门板主体
            let doorRect = CGRect(x: leftX + 2.2, y: doorTopY, width: boxW - 4.4, height: doorBotY - doorTopY)
            context.fill(
                Path(roundedRect: doorRect, cornerRadius: 1.2),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.43, green: 0.34, blue: 0.29), location: 0.0),
                        .init(color: Color(red: 0.36, green: 0.28, blue: 0.24), location: 0.45),
                        .init(color: Color(red: 0.28, green: 0.22, blue: 0.18), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: doorRect.minX, y: doorRect.minY),
                    endPoint: CGPoint(x: doorRect.maxX, y: doorRect.maxY)
                )
            )

            // 门板表面柔和金属漫反射光斑
            context.fill(
                Path(roundedRect: doorRect, cornerRadius: 1.2),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.55, green: 0.44, blue: 0.37).opacity(0.32),
                        Color.clear
                    ]),
                    center: CGPoint(x: doorRect.minX + 18, y: doorRect.minY + 24),
                    startRadius: 2,
                    endRadius: 52
                )
            )

            // 门板中段横向隐式折弯加强筋（增加修长金属箱体的细节与硬朗结构感）
            let midRibY = doorTopY + (doorBotY - doorTopY) * 0.55
            var midRib = Path()
            midRib.move(to: CGPoint(x: doorRect.minX + 1.0, y: midRibY))
            midRib.addLine(to: CGPoint(x: doorRect.maxX - 1.0, y: midRibY))
            context.stroke(midRib, with: .color(Color.black.opacity(0.35)), lineWidth: 0.8)
            var midRibHighlight = Path()
            midRibHighlight.move(to: CGPoint(x: doorRect.minX + 1.0, y: midRibY + 0.8))
            midRibHighlight.addLine(to: CGPoint(x: doorRect.maxX - 1.0, y: midRibY + 0.8))
            context.stroke(midRibHighlight, with: .color(Color.white.opacity(0.18)), lineWidth: 0.6)

            // 2. 前门板顶部正中央的微型银色圆锁孔
            let lockCenter = CGPoint(x: cx, y: doorTopY + 4.6)
            let lockOuter = CGRect(x: lockCenter.x - 2.3, y: lockCenter.y - 2.3, width: 4.6, height: 4.6)
            context.fill(
                Path(ellipseIn: lockOuter),
                with: .linearGradient(
                    Gradient(colors: [Color(white: 0.92), Color(white: 0.50)]),
                    startPoint: CGPoint(x: lockOuter.minX, y: lockOuter.minY),
                    endPoint: CGPoint(x: lockOuter.maxX, y: lockOuter.maxY)
                )
            )
            let keyhole = CGRect(x: lockCenter.x - 0.55, y: lockCenter.y - 1.0, width: 1.1, height: 2.0)
            context.fill(Path(roundedRect: keyhole, cornerRadius: 0.4), with: .color(.black.opacity(0.85)))

            // 门板上沿折弯金属高光棱线
            var doorTopHighlight = Path()
            doorTopHighlight.move(to: CGPoint(x: doorRect.minX + 0.5, y: doorTopY + 0.6))
            doorTopHighlight.addLine(to: CGPoint(x: doorRect.maxX - 0.5, y: doorTopY + 0.6))
            context.stroke(
                doorTopHighlight,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.78).opacity(0.55),
                        Color(white: 0.92).opacity(0.75),
                        Color(white: 0.65).opacity(0.45)
                    ]),
                    startPoint: CGPoint(x: doorRect.minX, y: doorTopY),
                    endPoint: CGPoint(x: doorRect.maxX, y: doorTopY)
                ),
                style: StrokeStyle(lineWidth: 0.9)
            )

            // 门板下沿内卷阴影与横缝
            let bottomSlotRect = CGRect(x: doorRect.minX, y: doorBotY - 1.8, width: doorRect.width, height: 2.2)
            context.fill(Path(bottomSlotRect), with: .color(Color.black.opacity(0.75)))

            // 3. 右上角激光镂空「扔垃圾小人」标志（还原照片右上角经典果皮箱标识）
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

            // (c) 小人双腿 (| |)
            var legs = Path()
            legs.move(to: CGPoint(x: ix - 1.5, y: iy + 8.2))
            legs.addLine(to: CGPoint(x: ix - 1.5, y: iy + 13.0))
            legs.move(to: CGPoint(x: ix + 0.4, y: iy + 8.2))
            legs.addLine(to: CGPoint(x: ix + 0.4, y: iy + 13.0))
            context.stroke(legs, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.15, lineCap: .butt))

            // (d) 正在扔下的垃圾小方点
            let trashDot = CGRect(x: ix + 3.8, y: iy + 6.4, width: 1.5, height: 1.5)
            context.fill(Path(trashDot), with: .color(iconColor))

            // (e) 右下方U型小垃圾桶 (⊔)
            var miniBin = Path()
            miniBin.move(to: CGPoint(x: ix + 2.8, y: iy + 9.2))
            miniBin.addLine(to: CGPoint(x: ix + 2.8, y: iy + 12.8))
            miniBin.addLine(to: CGPoint(x: ix + 6.2, y: iy + 12.8))
            miniBin.addLine(to: CGPoint(x: ix + 6.2, y: iy + 9.2))
            context.stroke(miniBin, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.1, lineCap: .butt, lineJoin: .miter))

            // 4. 外围黑褐色烤漆方钢立柱框架与底部镂空底座横梁
            let frameColor = Color(red: 0.14, green: 0.12, blue: 0.11)
            // 左侧立柱
            context.fill(Path(CGRect(x: leftX, y: topY, width: 2.3, height: baseBotY - topY)), with: .color(frameColor))
            // 右侧立柱
            context.fill(Path(CGRect(x: rightX - 2.3, y: topY, width: 2.3, height: baseBotY - topY)), with: .color(frameColor))
            // 顶部横梁与高光细线
            context.fill(Path(CGRect(x: leftX, y: topY, width: boxW, height: 2.2)), with: .color(frameColor))
            var topFrameHighlight = Path()
            topFrameHighlight.move(to: CGPoint(x: leftX + 0.5, y: topY + 0.5))
            topFrameHighlight.addLine(to: CGPoint(x: rightX - 0.5, y: topY + 0.5))
            context.stroke(topFrameHighlight, with: .color(Color(white: 0.65).opacity(0.55)), lineWidth: 0.7)

            // 门板下方中横梁 + 底部接地底横梁
            context.fill(Path(CGRect(x: leftX, y: doorBotY, width: boxW, height: 2.0)), with: .color(frameColor))
            context.fill(Path(CGRect(x: leftX, y: baseBotY - 2.0, width: boxW, height: 2.0)), with: .color(frameColor))
        }
        .frame(width: 82, height: 124)
        .offset(y: 8)
    }
}

/// Apple Squircle（超椭圆 $n = 4.6$）方圆角透视桶口弧线：
/// 与普通正椭圆不同，Squircle 在中段 ~70% 宽度上近乎平直，仅在左右两端呈现紧凑的圆角矩形转折，完美还原 macOS 废纸篓「方中带圆」的桶口！
struct MacOSSquircleRimArcShape: Shape {
    let isFrontHalf: Bool

    static func squirclePoint(theta: CGFloat, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, isFrontHalf: Bool) -> CGPoint {
        let cosT = cos(theta)
        let sinT = max(0, sin(theta))
        let signX: CGFloat = cosT >= 0 ? 1.0 : -1.0
        // 超椭圆指数 n = 4.6 -> 2/n = 0.435，使前后沿平直、四角圆润
        let x = cx - rx * signX * pow(abs(cosT), 0.435)
        let yOffset = ry * pow(sinT, 0.435)
        let y = isFrontHalf ? (cy + yOffset) : (cy - yOffset)
        return CGPoint(x: x, y: y)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        let steps = 40
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let pt = Self.squirclePoint(theta: theta, cx: cx, cy: cy, rx: rx, ry: ry, isFrontHalf: isFrontHalf)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        return path
    }
}

/// macOS 原生方圆角（Squircle）半壳轮廓：
/// 上沿严格贴合方圆角 Squircle 桶口，两侧斜向收窄，底部为平直底边 + 左右紧凑圆角（非圆形弧底！）
struct MacOSBinShellShape: Shape {
    let isFrontHalf: Bool

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 65.5
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 29.5
        let ryTop: CGFloat = 5.5
        let cornerR: CGFloat = 8.5
        let steps = 40

        var path = Path()
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let pt = MacOSSquircleRimArcShape.squirclePoint(
                theta: theta,
                cx: cx,
                cy: topY,
                rx: rTop,
                ry: ryTop,
                isFrontHalf: isFrontHalf
            )
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }

        // 右侧直斜壁 -> 右下紧凑圆角 -> 平直底边 -> 左下紧凑圆角 -> 左侧直斜壁
        path.addLine(to: CGPoint(x: cx + rBot, y: botY - cornerR))
        path.addQuadCurve(
            to: CGPoint(x: cx + rBot - cornerR, y: botY),
            control: CGPoint(x: cx + rBot - 0.6, y: botY - 0.4)
        )
        // 平直微弧底边（还原参考图方圆角平底）
        path.addQuadCurve(
            to: CGPoint(x: cx - rBot + cornerR, y: botY),
            control: CGPoint(x: cx, y: botY + 0.9)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx - rBot, y: botY - cornerR),
            control: CGPoint(x: cx - rBot + 0.6, y: botY - 0.4)
        )
        path.closeSubpath()
        return path
    }
}

/// 样式 B：前景 3D 曲面高光金属菱形网 + 真实 3D 弧形旋压金属底座 + 立体滚边顶圈
struct MetalMeshFrontWallView: View {
    var body: some View {
        ZStack {
            // 1. 圆柱体前表面立体高光与暗部体积罩染（严格从桶口前弧下方开始，绝不在椭圆桶口中间出现水平切线！）
            CylindricalFrustumShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.32), location: 0.0),
                            .init(color: Color.white.opacity(0.22), location: 0.25),
                            .init(color: Color(white: 0.75).opacity(0.06), location: 0.56),
                            .init(color: Color.white.opacity(0.14), location: 0.80),
                            .init(color: Color.black.opacity(0.38), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            // 2. 3D 圆柱透视编织金属丝网（底层暗部阴影丝 + 顶层拉丝镀铬高光丝，两侧边缘自然圆柱透视加密）
            ZStack {
                // 铁丝网立体背阴层
                CylindricalWireMeshShape(isFrontHalf: true, strandCount: 16, twistRadians: .pi * 0.58)
                    .stroke(
                        Color.black.opacity(0.48),
                        style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round)
                    )
                    .offset(y: 0.45)

                // 铁丝网高光镀铬金属丝层
                CylindricalWireMeshShape(isFrontHalf: true, strandCount: 16, twistRadians: .pi * 0.58)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.38, green: 0.41, blue: 0.45).opacity(0.85), location: 0.0),
                                .init(color: Color(red: 0.96, green: 0.98, blue: 1.00).opacity(0.95), location: 0.26),
                                .init(color: Color(red: 0.56, green: 0.60, blue: 0.65).opacity(0.82), location: 0.58),
                                .init(color: Color(red: 0.86, green: 0.89, blue: 0.94).opacity(0.90), location: 0.82),
                                .init(color: Color(red: 0.34, green: 0.37, blue: 0.41).opacity(0.85), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 0.78, lineCap: .round, lineJoin: .round)
                    )
            }
            .frame(width: 78, height: 74)
            .clipShape(CylindricalFrustumShellShape(isFrontHalf: true))

            // 3. 桶身左右两侧立体金属母线轮廓（带高光倒角）
            CylindricalSideEdgesShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.88).opacity(0.85),
                            Color(white: 0.50).opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.15
                )
                .frame(width: 78, height: 74)

            // 4. 真实 3D 弧形旋压金属底座裙边（上下沿遵循圆柱椭圆透视弧度，彻底告别扁平胶囊贴片！）
            SpunMetalBaseCollarView()
                .frame(width: 78, height: 74)

            // 5. 顶部加厚高光镀铬金属卷边圈（前半圈下弧，与后半圈在左右两端无缝衔接）
            ZStack {
                // 卷边下沿立体暗部投影
                FrontRimArcShape()
                    .stroke(
                        Color.black.opacity(0.45),
                        style: StrokeStyle(lineWidth: 5.2, lineCap: .round)
                    )
                    .offset(y: 1.1)

                // 镀铬不锈钢卷边主体（多段各向异性金属圆柱高光）
                FrontRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.34, green: 0.36, blue: 0.40), location: 0.0),
                                .init(color: Color(red: 0.72, green: 0.75, blue: 0.80), location: 0.14),
                                .init(color: Color(red: 0.98, green: 0.99, blue: 1.00), location: 0.28),
                                .init(color: Color(red: 0.54, green: 0.57, blue: 0.62), location: 0.56),
                                .init(color: Color(red: 0.88, green: 0.91, blue: 0.95), location: 0.80),
                                .init(color: Color(red: 0.32, green: 0.34, blue: 0.38), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4.8, lineCap: .round)
                    )

                // 卷边上沿锐利高光反射线
                FrontRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.25), location: 0.0),
                                .init(color: .white.opacity(0.98), location: 0.28),
                                .init(color: .white.opacity(0.45), location: 0.58),
                                .init(color: .white.opacity(0.88), location: 0.82),
                                .init(color: .white.opacity(0.20), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
                    )
                    .offset(y: -1.15)
            }
            .frame(width: 78, height: 15)
            .offset(y: -34)
        }
    }
}

// MARK: - 真实 3D 圆柱透视几何组件 (3D Cylindrical Frustum Geometry)

/// 真实 3D 旋压金属底座环视图（沿圆柱底部椭圆弧包覆，带顶唇倒角、拉丝铬面反射与底沿高光）
struct SpunMetalBaseCollarView: View {
    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            // 底座上沿与下沿的 3D 椭圆参数
            let topY: CGFloat = 57.5
            let botY: CGFloat = 66.2
            let rTop: CGFloat = 30.8
            let rBot: CGFloat = 29.5
            let ryTop: CGFloat = 5.4
            let ryBot: CGFloat = 6.2

            // 1. 构造 3D 弧形金属底座裙边闭合路径
            var collar = Path()
            let steps = 36
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi // 0 (左) -> pi (右)
                let x = cx - rTop * cos(theta)
                let y = topY + ryTop * sin(theta)
                if i == 0 {
                    collar.move(to: CGPoint(x: x, y: y))
                } else {
                    collar.addLine(to: CGPoint(x: x, y: y))
                }
            }
            for i in stride(from: steps, through: 0, by: -1) {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rBot * cos(theta)
                let y = botY + ryBot * sin(theta)
                collar.addLine(to: CGPoint(x: x, y: y))
            }
            collar.closeSubpath()

            // 填充高光泽各向异性拉丝不锈钢渐变
            context.fill(
                collar,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.22, green: 0.24, blue: 0.27), location: 0.0),
                        .init(color: Color(red: 0.62, green: 0.65, blue: 0.70), location: 0.15),
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.00), location: 0.29),
                        .init(color: Color(red: 0.46, green: 0.49, blue: 0.54), location: 0.55),
                        .init(color: Color(red: 0.80, green: 0.83, blue: 0.88), location: 0.79),
                        .init(color: Color(red: 0.20, green: 0.22, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx - rTop, y: topY),
                    endPoint: CGPoint(x: cx + rTop, y: topY)
                )
            )

            // 叠加垂直方向微暗底部接地环境遮蔽
            context.fill(
                collar,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(0.12), location: 0.0),
                        .init(color: Color.clear, location: 0.45),
                        .init(color: Color.black.opacity(0.38), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx, y: topY),
                    endPoint: CGPoint(x: cx, y: botY + ryBot)
                )
            )

            // 2. 底座上沿立体金属台阶高光弧（网格插入金属底座的压边环）
            var topLip = Path()
            var topShadow = Path()
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rTop * cos(theta)
                let y = topY + ryTop * sin(theta)
                if i == 0 {
                    topLip.move(to: CGPoint(x: x, y: y))
                    topShadow.move(to: CGPoint(x: x, y: y - 0.9))
                } else {
                    topLip.addLine(to: CGPoint(x: x, y: y))
                    topShadow.addLine(to: CGPoint(x: x, y: y - 0.9))
                }
            }
            context.stroke(topShadow, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            context.stroke(
                topLip,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.25), location: 0.0),
                        .init(color: .white.opacity(0.95), location: 0.29),
                        .init(color: .white.opacity(0.40), location: 0.58),
                        .init(color: .white.opacity(0.85), location: 0.80),
                        .init(color: .white.opacity(0.20), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx - rTop, y: topY),
                    endPoint: CGPoint(x: cx + rTop, y: topY)
                ),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
            )

            // 3. 底座下沿圆润金属收口高光弧
            var botLip = Path()
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rBot * cos(theta)
                let y = botY + ryBot * sin(theta)
                if i == 0 {
                    botLip.move(to: CGPoint(x: x, y: y))
                } else {
                    botLip.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                botLip,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.35),
                        Color(white: 0.88),
                        Color(white: 0.45),
                        Color(white: 0.75),
                        Color(white: 0.30)
                    ]),
                    startPoint: CGPoint(x: cx - rBot, y: botY),
                    endPoint: CGPoint(x: cx + rBot, y: botY)
                ),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
            )
        }
    }
}

/// 3D 圆台前后半壳裁剪轮廓：
/// - `isFrontHalf == true` 时，上边界严格沿着桶口**前半圈下弧**走，绝不横切椭圆桶口！
/// - `isFrontHalf == false` 时，上边界沿着桶口**后半圈上弧**走，包覆整个桶后壁内腔。
struct CylindricalFrustumShellShape: Shape {
    let isFrontHalf: Bool

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 57.8
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 30.8
        let ryTop: CGFloat = 7.5
        let ryBot: CGFloat = 5.4
        let steps = 32

        var path = Path()
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let x = cx - rTop * cos(theta)
            let y = isFrontHalf ? (topY + ryTop * sin(theta)) : (topY - ryTop * sin(theta))
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        for i in stride(from: steps, through: 0, by: -1) {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let x = cx - rBot * cos(theta)
            // 前后半壳底部均汇聚于 3D 底座环下弧，保证后壁完全填满桶内背景
            let y = botY + ryBot * sin(theta)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}

/// 真实 3D 圆柱螺旋金属编织网 Shape（自带圆柱边缘透视压缩与弧形空间弯曲，非平面直线！）
struct CylindricalWireMeshShape: Shape {
    let isFrontHalf: Bool
    let strandCount: Int
    let twistRadians: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 58.2
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 30.8
        let ryTop: CGFloat = 7.5
        let ryBot: CGFloat = 5.4

        let dTheta = .pi / CGFloat(strandCount)
        let vSteps = 22
        let signY: CGFloat = isFrontHalf ? 1.0 : -1.0

        // 1. 左右双向螺旋交织金属丝（在 3D 圆台表面呈螺旋线投影）
        for dir in [-1.0, 1.0] as [CGFloat] {
            for k in -strandCount...(strandCount * 2) {
                let thetaStart = CGFloat(k) * dTheta
                var isPenDown = false

                for step in 0...vSteps {
                    let v = CGFloat(step) / CGFloat(vSteps)
                    let theta = thetaStart + dir * twistRadians * v

                    if theta >= -0.02 && theta <= .pi + 0.02 {
                        let clampedTheta = min(max(theta, 0.0), .pi)
                        let r = rTop + (rBot - rTop) * v
                        let ry = ryTop + (ryBot - ryTop) * v
                        let yAxis = topY + (botY - topY) * v

                        let x = cx - r * cos(clampedTheta)
                        let y = yAxis + signY * ry * sin(clampedTheta)
                        let pt = CGPoint(x: x, y: y)

                        if !isPenDown {
                            path.move(to: pt)
                            isPenDown = true
                        } else {
                            path.addLine(to: pt)
                        }
                    } else {
                        isPenDown = false
                    }
                }
            }
        }

        // 2. 桶身中段 3D 弧形加强金属箍线（遵循圆柱透视弧度，进一步强化立体圆柱感）
        let ringV: CGFloat = 0.46
        let ringR = rTop + (rBot - rTop) * ringV
        let ringRy = ryTop + (ryBot - ryTop) * ringV
        let ringYAxis = topY + (botY - topY) * ringV
        for i in 0...28 {
            let theta = CGFloat(i) / 28.0 * .pi
            let x = cx - ringR * cos(theta)
            let y = ringYAxis + signY * ringRy * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

/// 桶身左右两侧立体金属边线
struct CylindricalSideEdgesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        path.move(to: CGPoint(x: cx - 39.0, y: 3.0))
        path.addLine(to: CGPoint(x: cx - 29.5, y: 66.0))
        path.move(to: CGPoint(x: cx + 39.0, y: 3.0))
        path.addLine(to: CGPoint(x: cx + 29.5, y: 66.0))
        return path
    }
}

/// 桶口后半圈上弧 Shape（0 -> pi，向上拱起）
struct BackRimArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        for i in 0...30 {
            let theta = CGFloat(i) / 30.0 * .pi
            let x = cx - rx * cos(theta)
            let y = cy - ry * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

/// 桶口前半圈下弧 Shape（0 -> pi，向下弯垂，与后半圈在左右两端点精确闭合）
struct FrontRimArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        for i in 0...30 {
            let theta = CGFloat(i) / 30.0 * .pi
            let x = cx - rx * cos(theta)
            let y = cy + ry * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

/// 桶内腔体 + 桶口上方联合裁剪蒙版：让猫猫身体从桶底到桶外连成完整不断开的一体，同时桶内部分不超出网格桶侧壁與 3D 桶底弧线
struct BucketAndAboveClipShape: Shape {
    let bucketCenter: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rimY = bucketCenter.y - 34.0
        let botY = bucketCenter.y + 26.5
        let topHalfW: CGFloat = 38.2
        let botHalfW: CGFloat = 29.5

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rimY))
        path.addLine(to: CGPoint(x: bucketCenter.x + topHalfW, y: rimY))
        path.addLine(to: CGPoint(x: bucketCenter.x + botHalfW, y: botY))
        path.addQuadCurve(
            to: CGPoint(x: bucketCenter.x - botHalfW, y: botY),
            control: CGPoint(x: bucketCenter.x, y: botY + 8.5)
        )
        path.addLine(to: CGPoint(x: bucketCenter.x - topHalfW, y: rimY))
        path.addLine(to: CGPoint(x: rect.minX, y: rimY))
        path.closeSubpath()
        return path
    }
}

/// 桶口以下、桶身轮廓以外的区域（配合 eoFill：整片桶口以下矩形 减去 桶身梯形）
struct OutsideBelowRimClipShape: Shape {
    let rimY: CGFloat
    let botY: CGFloat
    let centerX: CGFloat
    let topHalfW: CGFloat
    let botHalfW: CGFloat

    func path(in rect: CGRect) -> Path {
        // 与「桶内+桶口上方」图层上下重叠 2pt，消除两层抗锯齿拼缝产生的贯穿屏幕细线
        let top = rimY - 2.0
        var path = Path()
        path.addRect(CGRect(x: rect.minX, y: top, width: rect.width, height: max(rect.maxY - top, 0)))
        var bin = Path()
        bin.move(to: CGPoint(x: centerX - topHalfW, y: top))
        bin.addLine(to: CGPoint(x: centerX + topHalfW, y: top))
        bin.addLine(to: CGPoint(x: centerX + botHalfW, y: botY))
        bin.addLine(to: CGPoint(x: centerX - botHalfW, y: botY))
        bin.closeSubpath()
        path.addPath(bin)
        return path
    }
}

/// 经典掀盖绿桶专属：放大后的桶内腔 + 桶口上方联合裁剪蒙版
struct GreenBinAndAboveClipShape: Shape {
    let bucketCenter: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rimY = bucketCenter.y + kGreenBinRimY + 2.0
        let botY = bucketCenter.y + 40.0
        let topHalfW: CGFloat = 38.0 * kGreenBinScale
        let botHalfW: CGFloat = 28.5 * kGreenBinScale
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rimY))
        path.addLine(to: CGPoint(x: bucketCenter.x + topHalfW, y: rimY))
        path.addLine(to: CGPoint(x: bucketCenter.x + botHalfW, y: botY))
        path.addLine(to: CGPoint(x: bucketCenter.x - botHalfW, y: botY))
        path.addLine(to: CGPoint(x: bucketCenter.x - topHalfW, y: rimY))
        path.addLine(to: CGPoint(x: rect.minX, y: rimY))
        path.closeSubpath()
        return path
    }
}

/// 街头金属果皮箱专属：当猫猫缩在暗格内（尚未被拽出暗格窗口）时的暗格内部裁剪蒙版，防止耳朵穿出顶棚或两侧铁板
struct StreetBoxCompartmentClipShape: Shape {
    let bucketCenter: CGPoint

    func path(in rect: CGRect) -> Path {
        let boxInnerRect = CGRect(
            x: bucketCenter.x - 34.5,
            y: bucketCenter.y - 55.5,
            width: 69.0,
            height: 124.0
        )
        return Path(boxInnerRect)
    }
}

// MARK: - 3. 3D 圆柱感三次贝塞尔猫猫身体（支持「敞口桶向上拱出」与「街头果皮箱正面暗格向前钻出」双模式！）
struct StretchedCatBodyShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var baseHalfWidth: CGFloat
    var headHalfWidth: CGFloat
    var waistScale: CGFloat
    var isFrontCompartmentExit: Bool = false

    func path(in rect: CGRect) -> Path {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let dist = hypot(dx, dy)

        let c1Center: CGPoint
        let c2Center: CGPoint
        if isFrontCompartmentExit {
            // 街头金属果皮箱模式：上方有实体铁皮顶棚，猫猫必须从「正面暗格窗口」向前压低身子钻出（c1 向前下方翻越门板上沿，绝不向上穿破顶棚！）
            let forwardDip = min(max(dy * 0.22 + 14.0, -2.0), 34.0)
            c1Center = CGPoint(
                x: startPoint.x + dx * 0.26,
                y: startPoint.y + forwardDip
            )
            c2Center = CGPoint(
                x: startPoint.x + dx * 0.70,
                y: endPoint.y + min(max(-dy * 0.14, -16.0), 24.0)
            )
        } else {
            // 敞口桶模式（macOS 磨砂桶 / 3D 金属网格桶）：始终从桶口正上方垂直向上拱出
            let archLift = max(18, min(dist * 0.48, 115))
            c1Center = CGPoint(
                x: startPoint.x + dx * 0.10,
                y: startPoint.y - archLift
            )
            c2Center = CGPoint(
                x: startPoint.x + dx * 0.68,
                y: endPoint.y + min(dist * 0.18, 32)
            )
        }

        let w1 = max(16, baseHalfWidth * waistScale)
        let w2 = max(16, ((baseHalfWidth + headHalfWidth) * 0.5) * waistScale)

        // 左右两侧平行偏置，连接处保持水平，绝不交叉旋转成三角形
        let leftStart = CGPoint(x: startPoint.x - baseHalfWidth, y: startPoint.y)
        let rightStart = CGPoint(x: startPoint.x + baseHalfWidth, y: startPoint.y)

        let leftEnd = CGPoint(x: endPoint.x - headHalfWidth, y: endPoint.y)
        let rightEnd = CGPoint(x: endPoint.x + headHalfWidth, y: endPoint.y)

        let leftC1 = CGPoint(x: c1Center.x - w1, y: c1Center.y)
        let leftC2 = CGPoint(x: c2Center.x - w2, y: c2Center.y)

        let rightC1 = CGPoint(x: c1Center.x + w1, y: c1Center.y)
        let rightC2 = CGPoint(x: c2Center.x + w2, y: c2Center.y)

        var path = Path()
        path.move(to: leftStart)
        path.addCurve(to: leftEnd, control1: leftC1, control2: leftC2)
        path.addQuadCurve(
            to: rightEnd,
            control: CGPoint(x: endPoint.x, y: endPoint.y - 10)
        )
        path.addCurve(to: rightStart, control1: rightC2, control2: rightC1)
        path.addQuadCurve(
            to: leftStart,
            control: CGPoint(x: startPoint.x, y: startPoint.y + 18)
        )
        path.closeSubpath()
        return path
    }
}

/// 按品种「宽度剖面」沿贝塞尔脊柱逐段采样的身体轮廓：
/// 支持中段细腰收缩（史莱姆/芝士拉丝）、两端外凸弧度（凝胶弹性）、桶口倒三角黏液汇聚（麻薯芝士）与边缘微扰。
struct ProfiledCatBodyShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var c1: CGPoint
    var c2: CGPoint
    var baseHalfWidth: CGFloat = 25
    var headHalfWidth: CGFloat = 23
    var stretchRatio: CGFloat
    /// 中段收细强度（0 不收 ~ 0.9 拉成细丝）
    var pinch: CGFloat = 0.3
    /// 收细曲线指数（越小收细区域越宽）
    var pinchExponent: CGFloat = 1.3
    var minHalfWidth: CGFloat = 10
    /// 两端外凸鼓包（果冻 Duang 感）
    var endBulge: CGFloat = 0
    /// 底部桶口黏液汇聚倒三角外扩
    var basePoolFlare: CGFloat = 0
    var wobblePhase: CGFloat = 0
    var wobbleAmp: CGFloat = 0

    static let samples = 56

    func halfWidth(at t: CGFloat) -> CGFloat {
        let linear = baseHalfWidth * (1 - t) + headHalfWidth * t
        let bell = pow(max(sin(.pi * t), 0), pinchExponent)
        var w = linear * (1 - pinch * stretchRatio * bell)
        let g1 = exp(-pow((t - 0.16) / 0.09, 2))
        let g2 = exp(-pow((t - 0.84) / 0.09, 2))
        w += endBulge * stretchRatio * (g1 + g2)
        if t < 0.30 {
            let f = 1 - t / 0.30
            w += basePoolFlare * stretchRatio * f * f
        }
        w += sin(t * 9 + wobblePhase * 3.2) * wobbleAmp * sin(.pi * t)
        return max(minHalfWidth, w)
    }

    func frame(at t: CGFloat) -> (center: CGPoint, tangent: CGVector, normal: CGVector) {
        let u = 1 - t
        let x = u * u * u * startPoint.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * endPoint.x
        let y = u * u * u * startPoint.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * endPoint.y
        var dx = 3 * u * u * (c1.x - startPoint.x) + 6 * u * t * (c2.x - c1.x) + 3 * t * t * (endPoint.x - c2.x)
        var dy = 3 * u * u * (c1.y - startPoint.y) + 6 * u * t * (c2.y - c1.y) + 3 * t * t * (endPoint.y - c2.y)
        let len = hypot(dx, dy)
        if len < 0.001 {
            dx = endPoint.x - startPoint.x
            dy = endPoint.y - startPoint.y
        }
        let l2 = max(hypot(dx, dy), 0.001)
        let tx = dx / l2
        let ty = dy / l2
        return (CGPoint(x: x, y: y), CGVector(dx: tx, dy: ty), CGVector(dx: -ty, dy: tx))
    }

    func edges() -> (left: [CGPoint], right: [CGPoint]) {
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        let n = Self.samples
        left.reserveCapacity(n + 1)
        right.reserveCapacity(n + 1)
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let f = frame(at: t)
            let w = halfWidth(at: t)
            left.append(CGPoint(x: f.center.x + f.normal.dx * w, y: f.center.y + f.normal.dy * w))
            right.append(CGPoint(x: f.center.x - f.normal.dx * w, y: f.center.y - f.normal.dy * w))
        }
        return (left, right)
    }

    func path(in rect: CGRect) -> Path {
        let e = edges()
        guard let l0 = e.left.first, let lN = e.left.last, let rN = e.right.last, let r0 = e.right.first else {
            return Path()
        }
        let endF = frame(at: 1)
        let startF = frame(at: 0)
        var path = Path()
        path.move(to: l0)
        for p in e.left.dropFirst() { path.addLine(to: p) }
        path.addQuadCurve(
            to: rN,
            control: CGPoint(x: endF.center.x + endF.tangent.dx * 12, y: endF.center.y + endF.tangent.dy * 12)
        )
        for p in e.right.reversed().dropFirst() { path.addLine(to: p) }
        _ = r0
        path.addQuadCurve(
            to: l0,
            control: CGPoint(x: startF.center.x - startF.tangent.dx * 18, y: startF.center.y - startF.tangent.dy * 18)
        )
        _ = lN
        path.closeSubpath()
        return path
    }
}

struct CatBodyLayerView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let morph: CatMorph
    let stretchRatio: CGFloat
    let phase: CGFloat
    var isFrontCompartmentExit: Bool = false
    /// 敞口/掀盖桶的桶口 Y（局部坐标），用于头部低于桶口时让身体越过桶沿垂挂
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
        ZStack {
            // 第一层：外围大范围柔化暗影雾气光晕（高模糊连续流体包络）
            Canvas { context, _ in
                let spine = buildSmokeSpineControlPoints()
                let mistPath = buildUndulatingSmokeEnvelope(
                    c1: spine.c1,
                    c2: spine.c2,
                    baseHalfW: 27,
                    headHalfW: 24,
                    waveAmp: 4.5 + stretchRatio * 6.0,
                    waveFreq: 7.0,
                    phaseOffset: 0.0
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
                let spine = buildSmokeSpineControlPoints()

                // A. 中心连续浓墨暗影主躯干（边缘随相位如火焰/黑烟般柔和起伏）
                let coreEnvelope = buildUndulatingSmokeEnvelope(
                    c1: spine.c1,
                    c2: spine.c2,
                    baseHalfW: 21,
                    headHalfW: 19,
                    waveAmp: 3.0 + stretchRatio * 4.5,
                    waveFreq: 9.0,
                    phaseOffset: 1.2
                )
                // 自下而上逐渐消散的半透明羽化流（越拉越虚，中上段几乎透明，仅在猫头处重新聚拢）
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

                // B. 4 股沿脊柱连续缠绕上升的半透明黑烟流线丝带（赋予烟雾向上流动的丝滑纹理）
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

                // C. 两侧边缘向上剥离消散的丝状流烟（模拟黑烟边缘拉丝消融感）
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

        // 正常向上或斜上方拉伸：控制点单调递进，身体流畅拉长
        var c1 = CGPoint(x: startPoint.x + dx * 0.18, y: startPoint.y + dy * 0.36)
        var c2 = CGPoint(x: startPoint.x + dx * 0.72, y: startPoint.y + dy * 0.78)

        // 仅当猫头被向两侧拖拽、且高度接近或低于桶口（向外下垂挂）时，身体才需从桶口上方越过桶沿垂下
        if let rimY = rimLocalY {
            let absDx = abs(dx)
            let sideFactor = min(max((absDx - 18.0) / 25.0, 0), 1.0)
            let downFactor = min(max((endPoint.y - (rimY - 15.0)) / 35.0, 0), 1.0)
            let stretchFactor = min(max((stretchRatio - 0.05) / 0.10, 0), 1.0)
            let k = sideFactor * downFactor * stretchFactor

            if k > 0 {
                // 拱顶恰好高出桶沿 14pt，既保证身体半宽越过桶壁时不穿模，又不会飞到半空中
                let archTopY = rimY - 14.0
                let drapeC1 = CGPoint(x: startPoint.x + (dx > 0 ? 8.0 : -8.0), y: archTopY)
                let drapeC2 = CGPoint(x: endPoint.x, y: min(archTopY + 6.0, endPoint.y - 12.0))
                c1 = CGPoint(x: c1.x + (drapeC1.x - c1.x) * k, y: c1.y + (min(drapeC1.y, c1.y) - c1.y) * k)
                c2 = CGPoint(x: c2.x + (drapeC2.x - c2.x) * k, y: c2.y + (drapeC2.y - c2.y) * k)
            }
        }
        return (c1, c2)
    }

    /// 构建两侧带连续烟浪起伏的无缝闭合流体轮廓（采样 50 段，彻底告别离散圆团感）
    private func buildUndulatingSmokeEnvelope(
        c1: CGPoint,
        c2: CGPoint,
        baseHalfW: CGFloat,
        headHalfW: CGFloat,
        waveAmp: CGFloat,
        waveFreq: CGFloat,
        phaseOffset: CGFloat
    ) -> Path {
        let samples = 50
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []
        leftPoints.reserveCapacity(samples + 1)
        rightPoints.reserveCapacity(samples + 1)

        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let pt = cubicBezierPoint(t: t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            let linearW = baseHalfW * (1.0 - t) + headHalfW * t
            let pinch = 1.0 - 0.38 * sin(.pi * t) * stretchRatio
            let halfW = max(10.0, linearW * pinch)

            // 沿脊柱向上流动的连续烟浪起伏
            let leftWave = sin(t * waveFreq - phase * 2.6 + phaseOffset) * waveAmp * sin(.pi * t)
            let rightWave = cos(t * (waveFreq * 1.1) - phase * 2.3 + phaseOffset) * waveAmp * sin(.pi * t)

            leftPoints.append(CGPoint(x: pt.x - halfW + leftWave, y: pt.y))
            rightPoints.append(CGPoint(x: pt.x + halfW + rightWave, y: pt.y))
        }

        var path = Path()
        if let first = leftPoints.first {
            path.move(to: first)
        }
        for pt in leftPoints.dropFirst() {
            path.addLine(to: pt)
        }
        for pt in rightPoints.reversed() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }

    /// 各品种专属身体宽度剖面
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
            // 史莱姆：明显细腰 + 两端外凸凝胶鼓包 + 轻微果冻颤动
            p.pinch = 0.58; p.pinchExponent = 1.6; p.minHalfWidth = 8
            p.endBulge = 5.0; p.basePoolFlare = 4.0; p.wobbleAmp = 1.1
        case .bluePlush:
            // 毛绒球：几乎不收腰，保持蓬松饱满
            p.pinch = 0.14; p.pinchExponent = 1.2; p.minHalfWidth = 16
            p.endBulge = 1.5; p.basePoolFlare = 2.0
        case .calico:
            // 羊毛毡：像扯棉花毛条，中段变细
            p.pinch = 0.56; p.pinchExponent = 1.4; p.minHalfWidth = 7
            p.endBulge = 1.5; p.basePoolFlare = 4.0
        case .tuxedo:
            p.pinch = 0.48; p.pinchExponent = 1.3; p.minHalfWidth = 8
        case .siamese:
            // 芝士拉丝：两头粗中间极细 + 桶口倒三角黏液汇聚
            p.pinch = 0.88; p.pinchExponent = 0.9; p.minHalfWidth = 3.2
            p.endBulge = 3.0; p.basePoolFlare = 17.0; p.wobbleAmp = 0.4
        case .blackShadow:
            break
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

                // A. 圆柱体底色（根据 6 种材质区分渐变）
                context.fill(
                    fullRect,
                    with: .linearGradient(
                        Gradient(stops: cylinderBaseStops),
                        startPoint: CGPoint(x: minX, y: endPoint.y),
                        endPoint: CGPoint(x: maxX, y: startPoint.y)
                    )
                )

                // B. 3D 中心立体肚皮柱（黑猫化作浓墨内核，其余品种为浅色立体圆肚皮）
                var bellySpine = Path()
                bellySpine.move(to: CGPoint(x: startPoint.x - 3, y: startPoint.y + 4))
                bellySpine.addCurve(
                    to: CGPoint(x: endPoint.x - 2, y: endPoint.y + 4),
                    control1: CGPoint(x: c1.x - 3, y: c1.y),
                    control2: CGPoint(x: c2.x - 2, y: c2.y)
                )
                context.stroke(
                    bellySpine,
                    with: .color(bellyHighlightColor),
                    style: StrokeStyle(lineWidth: 22 * waistScale, lineCap: .round)
                )

                // C. 各品种专属拉伸细节纹理
                switch morph {
                case .slime:
                    // 橘猫史莱姆：左侧水润柱面镜面高光带 + 右侧虎斑纹 + 3 颗漂浮气泡
                    drawSpecularRibbon(context: &context, c1: c1, c2: c2, opacity: 0.55)
                    drawSideTabbyStripes(context: &context, c1: c1, c2: c2, color: Color(red: 0.76, green: 0.28, blue: 0.05).opacity(0.48))
                    drawSlimeBubbles(context: &context, c1: c1, c2: c2)

                case .bluePlush:
                    // 蓝猫毛绒：随拉伸被整体纵向扯直的柔软细毛束（柔化，无横截面尖刺）
                    drawSideTabbyStripes(context: &context, c1: c1, c2: c2, color: Color(red: 0.28, green: 0.24, blue: 0.52).opacity(0.30))
                    drawBluePlushSoftStrands(context: &context, shape: shape)

                case .calico:
                    // 三花羊毛毡：像扯棉花毛条——色块被等比扯成细长椭圆，中段纤维变稀疏、透光增加
                    drawCalicoStretchedFelt(context: &context, shape: shape)

                case .tuxedo:
                    // 奶牛橡皮糖：高张力软硅胶哑光柔滑反光带 + 黑白交界硅胶倒角细高光
                    drawSpecularRibbon(context: &context, c1: c1, c2: c2, opacity: 0.35)
                    for side in [-1.0, 1.0] as [CGFloat] {
                        var seam = Path()
                        for i in 0...40 {
                            let t = 0.04 + 0.94 * CGFloat(i) / 40.0
                            let f = shape.frame(at: t)
                            let off = min(11 * waistScale, shape.halfWidth(at: t) * 0.62) * side
                            let p = CGPoint(x: f.center.x - 2.5 + f.normal.dx * off, y: f.center.y + 4 + f.normal.dy * off)
                            if i == 0 { seam.move(to: p) } else { seam.addLine(to: p) }
                        }
                        context.stroke(seam, with: .color(.white.opacity(0.42)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                    }

                case .siamese:
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

                case .blackShadow:
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
            }
            .clipShape(shape)
            // 黑猫越拉越虚化，呈现烟雾消融质感
            .opacity(morph == .blackShadow ? Double(max(0.58, 0.94 - stretchRatio * 0.35)) : 1.0)

            // 2. 各品种专属轮廓边缘质感（果冻水润高光 / 短毛绒蓬松毛边 / 羊毛毡针织纤维边 / 软胶边 / 暗影羽化烟边）
            bodyEdgeStrokeView(shape: shape)
        }
    }

    private var cylinderBaseStops: [Gradient.Stop] {
        switch morph {
        case .slime:
            return [
                .init(color: Color(red: 0.99, green: 0.78, blue: 0.46), location: 0.0),
                .init(color: Color(red: 0.98, green: 0.64, blue: 0.24), location: 0.45),
                .init(color: Color(red: 0.90, green: 0.42, blue: 0.12), location: 1.0)
            ]
        case .bluePlush:
            return [
                .init(color: Color(red: 0.56, green: 0.72, blue: 0.92), location: 0.0),
                .init(color: Color(red: 0.46, green: 0.62, blue: 0.85), location: 0.55),
                .init(color: Color(red: 0.36, green: 0.50, blue: 0.76), location: 1.0)
            ]
        case .calico:
            return [
                .init(color: Color(red: 0.98, green: 0.95, blue: 0.90), location: 0.0),
                .init(color: Color(red: 0.94, green: 0.89, blue: 0.82), location: 1.0)
            ]
        case .tuxedo:
            return [
                .init(color: Color(red: 0.22, green: 0.23, blue: 0.27), location: 0.0),
                .init(color: Color(red: 0.12, green: 0.13, blue: 0.16), location: 1.0)
            ]
        case .siamese:
            return [
                .init(color: Color(red: 0.98, green: 0.95, blue: 0.88), location: 0.0),
                .init(color: Color(red: 0.92, green: 0.85, blue: 0.74), location: 0.70),
                .init(color: Color(red: 0.62, green: 0.46, blue: 0.34), location: 1.0)
            ]
        case .blackShadow:
            return [
                .init(color: Color(red: 0.06, green: 0.06, blue: 0.09), location: 0.0),
                .init(color: Color(red: 0.12, green: 0.10, blue: 0.18), location: 1.0)
            ]
        }
    }

    private var bellyHighlightColor: Color {
        switch morph {
        case .slime: return Color(red: 1.0, green: 0.95, blue: 0.84).opacity(0.82)
        case .bluePlush: return Color(red: 0.82, green: 0.91, blue: 0.99).opacity(0.90)
        case .calico: return Color(red: 1.0, green: 0.98, blue: 0.94).opacity(0.85)
        case .tuxedo: return Color.white.opacity(0.96)
        case .siamese: return Color(red: 1.0, green: 0.98, blue: 0.93).opacity(0.92)
        case .blackShadow: return Color.black.opacity(0.92)
        }
    }

    @ViewBuilder
    private func bodyEdgeStrokeView(shape: ProfiledCatBodyShape) -> some View {
        switch morph {
        case .bluePlush:
            // 毛绒球：沿两侧重叠的柔化圆弧绒团（高斯模糊，蓬松柔软而非尖刺）
            Canvas { context, _ in
                drawBluePlushSoftEdge(context: &context, shape: shape)
            }
        case .calico:
            // 羊毛毡：边缘绷出的细小弯曲羊毛飞丝（中段稀疏）
            Canvas { context, _ in
                drawCalicoFeltedEdgeFibers(context: &context, shape: shape)
            }
        case .tuxedo:
            // 橡皮糖：外边缘软胶保护壳倒角细高光
            ZStack {
                shape.stroke(Color.black.opacity(0.35), lineWidth: 0.9)
                shape
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.75), .white.opacity(0.15), .white.opacity(0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.4
                    )
                    .clipShape(shape)
            }
        case .blackShadow:
            // 暗影水墨消散羽化边缘
            shape.stroke(
                Color(red: 0.24, green: 0.20, blue: 0.36).opacity(0.60),
                style: StrokeStyle(lineWidth: 3.0, lineCap: .round, dash: [3, 3])
            )
            .blur(radius: 1.2)
        default:
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

    // MARK: - 蓝猫（蓬松柔软毛球）：被整体纵向扯直的柔软细毛束 + 柔化圆弧绒团边缘
    private func drawBluePlushSoftStrands(context: inout GraphicsContext, shape: ProfiledCatBodyShape) {
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
                // 拉得越长毛束越直（摆动越小）
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

        // 丝绒细光泽毛丝（分段，随拉伸变长变直）
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

    private func drawBluePlushSoftEdge(context: inout GraphicsContext, shape: ProfiledCatBodyShape) {
        let e = shape.edges()
        let n = e.left.count
        guard n > 2 else { return }

        // 1. 高斯柔化圆弧绒团（重叠圆代替三角尖刺）
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

        // 2. 外沿柔和弧形绒毛线（微柔化）
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

    // MARK: - 三花（羊毛毡）：像扯棉花毛条，色块等比拉长、中段纤维稀疏透光
    private func drawCalicoStretchedFelt(context: inout GraphicsContext, shape: ProfiledCatBodyShape) {
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

    private func drawCalicoFeltedEdgeFibers(context: inout GraphicsContext, shape: ProfiledCatBodyShape) {
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

    private func drawSpecularRibbon(context: inout GraphicsContext, c1: CGPoint, c2: CGPoint, opacity: Double) {
        var specularRibbon = Path()
        specularRibbon.move(to: CGPoint(x: startPoint.x - 13 * waistScale, y: startPoint.y))
        specularRibbon.addCurve(
            to: CGPoint(x: endPoint.x - 12 * waistScale, y: endPoint.y + 6),
            control1: CGPoint(x: c1.x - 13 * waistScale, y: c1.y),
            control2: CGPoint(x: c2.x - 12 * waistScale, y: c2.y)
        )
        context.stroke(
            specularRibbon,
            with: .color(.white.opacity(opacity)),
            style: StrokeStyle(lineWidth: 5.0 * waistScale, lineCap: .round)
        )
    }

    private func drawSideTabbyStripes(context: inout GraphicsContext, c1: CGPoint, c2: CGPoint, color: Color) {
        for t in [0.28, 0.50, 0.72] as [CGFloat] {
            let pt = cubicBezierPoint(t: t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            var stripe = Path()
            stripe.move(to: CGPoint(x: pt.x + 6 * waistScale, y: pt.y - 3))
            stripe.addQuadCurve(
                to: CGPoint(x: pt.x + 24 * waistScale, y: pt.y + 4),
                control: CGPoint(x: pt.x + 16 * waistScale, y: pt.y - 5)
            )
            context.stroke(
                stripe,
                with: .color(color),
                style: StrokeStyle(lineWidth: 4.2, lineCap: .round)
            )
        }
    }

    private func drawSlimeBubbles(context: inout GraphicsContext, c1: CGPoint, c2: CGPoint) {
        let bubbleSpecs: [(t: CGFloat, lateral: CGFloat, radius: CGFloat)] = [
            (0.28 + 0.03 * sin(phase), -4.0, 3.2),
            (0.54 + 0.04 * cos(phase * 1.2), 4.0, 2.4),
            (0.76 + 0.03 * sin(phase * 0.8 + 1.4), -2.5, 3.6)
        ]
        for spec in bubbleSpecs {
            let pt = cubicBezierPoint(t: spec.t, p0: startPoint, c1: c1, c2: c2, p3: endPoint)
            let rect = CGRect(
                x: pt.x + spec.lateral * waistScale - spec.radius,
                y: pt.y - spec.radius,
                width: spec.radius * 2,
                height: spec.radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.32)))
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.65)), lineWidth: 0.8)
        }
    }

    private func cubicBezierPoint(t: CGFloat, p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1.0 - t
        let tt = t * t
        let uu = u * u
        let uuu = uu * u
        let ttt = tt * t

        let x = uuu * p0.x + 3 * uu * t * c1.x + 3 * u * tt * c2.x + ttt * p3.x
        let y = uuu * p0.y + 3 * uu * t * c1.y + 3 * u * tt * c2.y + ttt * p3.y
        return CGPoint(x: x, y: y)
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
