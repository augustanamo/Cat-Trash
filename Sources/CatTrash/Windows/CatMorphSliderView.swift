import SwiftUI
import AppKit

// MARK: - 迷你猫猫头图标组件 (各品种专属面部、耳朵与花纹)
struct MiniCatHeadIcon: View {
    let morph: CatMorph
    var isSelected: Bool = false

    private var faceColor: Color {
        switch morph {
        case .slime: return Color(red: 0.98, green: 0.65, blue: 0.25)
        case .bluePlush: return Color(red: 0.52, green: 0.68, blue: 0.88)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color(red: 0.18, green: 0.18, blue: 0.22)
        case .siamese: return Color(red: 0.96, green: 0.92, blue: 0.86)
        case .blackShadow: return Color(red: 0.08, green: 0.06, blue: 0.12)
        }
    }

    var body: some View {
        ZStack {
            // 1. 基础猫头轮廓
            MochiCatHeadShape()
                .fill(faceColor)
                .frame(width: 20, height: 16)
                .overlay(
                    MochiCatHeadShape()
                        .stroke(
                            isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.3),
                            lineWidth: isSelected ? 1.2 : 0.5
                        )
                )

            // 2. 各品种专属花纹遮罩
            Group {
                switch morph {
                case .slime:
                    // 橘猫额头虎斑小细线
                    HStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.72, green: 0.26, blue: 0.05)).frame(width: 1.2, height: 4)
                        Rectangle().fill(Color(red: 0.72, green: 0.26, blue: 0.05)).frame(width: 1.2, height: 5)
                        Rectangle().fill(Color(red: 0.72, green: 0.26, blue: 0.05)).frame(width: 1.2, height: 4)
                    }
                    .offset(y: -4)

                case .bluePlush:
                    // 蓝猫软绒白腮帮
                    Circle().fill(Color.white.opacity(0.35)).frame(width: 5, height: 5).offset(x: -5, y: 2)
                    Circle().fill(Color.white.opacity(0.35)).frame(width: 5, height: 5).offset(x: 5, y: 2)

                case .calico:
                    // 三花猫：左耳暖橙色色块 + 右耳炭黑色色块
                    Circle().fill(Color(red: 0.92, green: 0.49, blue: 0.17)).frame(width: 7, height: 7).offset(x: -5, y: -5)
                    Circle().fill(Color(red: 0.22, green: 0.21, blue: 0.20)).frame(width: 7, height: 7).offset(x: 5, y: -5)

                case .tuxedo:
                    // 奶牛猫：下半脸白色 V 字八字开口面具
                    Path { path in
                        path.move(to: CGPoint(x: 10, y: 6))
                        path.addLine(to: CGPoint(x: 15, y: 16))
                        path.addLine(to: CGPoint(x: 5, y: 16))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    .frame(width: 20, height: 16)

                case .siamese:
                    // 暹罗猫：深焦糖色脸罩与耳朵
                    Circle().fill(Color(red: 0.32, green: 0.20, blue: 0.14)).frame(width: 9, height: 8).offset(y: 1)
                    Circle().fill(Color(red: 0.32, green: 0.20, blue: 0.14)).frame(width: 4, height: 4).offset(x: -6, y: -6)
                    Circle().fill(Color(red: 0.32, green: 0.20, blue: 0.14)).frame(width: 4, height: 4).offset(x: 6, y: -6)

                case .blackShadow:
                    // 暗影烟雾：微弱紫色暗光
                    MochiCatHeadShape()
                        .stroke(Color(red: 0.42, green: 0.25, blue: 0.65).opacity(0.7), lineWidth: 1.5)
                        .frame(width: 20, height: 16)
                        .blur(radius: 0.8)
                }
            }

            // 3. 眼睛与小五官
            HStack(spacing: morph == .siamese ? 4.5 : 5.5) {
                eyeDot(isLeft: true)
                eyeDot(isLeft: false)
            }
            .offset(y: 1)
        }
        .frame(width: 22, height: 18)
        .scaleEffect(isSelected ? 1.10 : 0.80)
        .opacity(isSelected ? 1.0 : 0.65)
        .shadow(color: isSelected ? Color.black.opacity(0.40) : .clear, radius: 2.5, x: 0, y: 1)
    }

    @ViewBuilder
    private func eyeDot(isLeft: Bool) -> some View {
        switch morph {
        case .blackShadow:
            // 黑猫专属金黄发光眼
            Circle().fill(Color(red: 1.0, green: 0.85, blue: 0.22)).frame(width: 2.2, height: 2.2)
        case .siamese:
            // 暹罗蓝宝石眼
            Circle().fill(Color(red: 0.25, green: 0.65, blue: 0.95)).frame(width: 2.0, height: 2.0)
        default:
            Circle().fill(Color.black.opacity(0.85)).frame(width: 2.0, height: 2.0)
        }
    }
}

// MARK: - 左侧身体样式进度条 (随选中的猫咪品种呈现拉伸身体质感)
struct CatMorphBodyTrackView: View {
    let morph: CatMorph
    let fillWidth: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            // 各品种专属身体底色与渐变
            switch morph {
            case .slime:
                // 橘猫果冻：橙黄纵向光泽 + 顶面白高光 + 虎斑小条纹
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: OrangeSlimeSkin.cylinderBaseStops, startPoint: .top, endPoint: .bottom))
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .frame(height: 2.5)
                        .offset(y: -4)
                        .padding(.horizontal, 4)
                    HStack(spacing: 22) {
                        ForEach(0..<6) { _ in
                            Capsule()
                                .fill(Color(red: 0.72, green: 0.26, blue: 0.05).opacity(0.55))
                                .frame(width: 3, height: 9)
                                .rotationEffect(.degrees(18))
                        }
                    }
                    .padding(.leading, 10)
                }

            case .bluePlush:
                // 蓝猫短毛绒：柔蓝丝绒 + 肚皮微光
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: BluePlushSkin.cylinderBaseStops, startPoint: .top, endPoint: .bottom))
                    Capsule()
                        .fill(Color(red: 0.85, green: 0.93, blue: 1.0).opacity(0.55))
                        .frame(height: 4)
                        .blur(radius: 1.0)
                        .padding(.horizontal, 4)
                }

            case .calico:
                // 三花羊毛毡：燕麦米底 + 手作戳针橙黑毛毡斑块
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: CalicoFeltSkin.cylinderBaseStops, startPoint: .top, endPoint: .bottom))
                    HStack(spacing: 16) {
                        Ellipse()
                            .fill(Color(red: 0.92, green: 0.49, blue: 0.17).opacity(0.90))
                            .frame(width: 14, height: 8)
                        Ellipse()
                            .fill(Color(red: 0.22, green: 0.21, blue: 0.20).opacity(0.88))
                            .frame(width: 12, height: 7)
                        Ellipse()
                            .fill(Color(red: 0.92, green: 0.49, blue: 0.17).opacity(0.90))
                            .frame(width: 13, height: 8)
                    }
                    .padding(.leading, 8)
                }

            case .tuxedo:
                // 奶牛橡皮糖：深灰软胶底 + 倒角双高光边
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: TuxedoGummySkin.cylinderBaseStops, startPoint: .top, endPoint: .bottom))
                    Capsule()
                        .fill(Color.white.opacity(0.40))
                        .frame(height: 2)
                        .offset(y: -4)
                        .padding(.horizontal, 4)
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(height: 2.5)
                        .offset(y: 4)
                        .padding(.horizontal, 4)
                }

            case .siamese:
                // 暹罗芝士：横向象牙白渐变至焦糖棕 + 芝士拉丝高光
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: SiameseCheeseSkin.cylinderBaseStops, startPoint: .leading, endPoint: .trailing))
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(height: 2)
                        .padding(.horizontal, 4)
                }

            case .blackShadow:
                // 黑猫暗影：深邃暗影黑 + 幽暗紫雾流动
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(stops: BlackShadowSkin.cylinderBaseStops, startPoint: .leading, endPoint: .trailing))
                    Capsule()
                        .fill(Color(red: 0.38, green: 0.22, blue: 0.62).opacity(0.55))
                        .frame(height: 6)
                        .blur(radius: 2.0)
                        .padding(.horizontal, 4)
                }
            }

            // 最左侧的小尾巴 / 足部收边小弧圈
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 6, height: 6)
                .offset(x: 4)
        }
        .frame(width: max(fillWidth, 14), height: 16)
        .clipShape(Capsule())
    }
}

// MARK: - 滑动状态控制器 (ObservableObject，不依赖宏)
public final class CatMorphSliderModel: ObservableObject {
    @Published public var dragIndex: CGFloat? = nil
    public init() {}
}

// MARK: - 猫咪品种滑动切换进度条主视图 (纯粹独立的一根悬浮条，无大外层面板)
struct CatMorphSliderView: View {
    @ObservedObject var prefs = CatPreferences.shared
    @ObservedObject var model: CatMorphSliderModel

    private let morphs = CatMorph.allCases
    var trackWidth: CGFloat = 175
    private let trackHeight: CGFloat = 18

    /// 当前选中的索引
    private var currentIndex: Int {
        morphs.firstIndex(of: prefs.selectedMorph) ?? 0
    }

    /// 滑块当前平滑位置（0.0 ~ 5.0）
    private var effectiveProgress: CGFloat {
        if let drag = model.dragIndex {
            return min(max(drag, 0), CGFloat(morphs.count - 1))
        }
        return CGFloat(currentIndex)
    }

    /// 各档位 X 坐标
    private func stationX(for index: Int) -> CGFloat {
        let margin: CGFloat = 12
        let step = (trackWidth - margin * 2) / CGFloat(morphs.count - 1)
        return margin + CGFloat(index) * step
    }

    private var currentThumbX: CGFloat {
        let margin: CGFloat = 12
        let step = (trackWidth - margin * 2) / CGFloat(morphs.count - 1)
        return margin + effectiveProgress * step
    }

    var body: some View {
        // 纯粹独立的一根悬浮滑动条 (无任何外层大面板)
        ZStack(alignment: .leading) {
            // 1. 底槽 (深色半透明胶囊槽)
            Capsule()
                .fill(Color.black.opacity(0.40))
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.30), radius: 4, x: 0, y: 2)

            // 2. 左侧身体拉伸进度条 (随选中品种变换身体纹理与材质)
            CatMorphBodyTrackView(
                morph: prefs.selectedMorph,
                fillWidth: currentThumbX + 6
            )

            // 3. 6 个档位的微型猫猫头打卡点
            ForEach(0..<morphs.count, id: \.self) { idx in
                let morph = morphs[idx]
                let isCurrent = (idx == currentIndex)
                let xPos = stationX(for: idx)

                MiniCatHeadIcon(morph: morph, isSelected: isCurrent)
                    .position(x: xPos, y: trackHeight * 0.5)
                    .allowsHitTesting(false)
            }

            // 4. 当前拖拽 / 选中的猫猫头高亮滑块
            MiniCatHeadIcon(morph: prefs.selectedMorph, isSelected: true)
                .position(x: currentThumbX, y: trackHeight * 0.5)
                .allowsHitTesting(false)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let margin: CGFloat = 12
                    let step = (trackWidth - margin * 2) / CGFloat(morphs.count - 1)
                    let rawProgress = (value.location.x - margin) / step
                    let clamped = min(max(rawProgress, 0), CGFloat(morphs.count - 1))
                    model.dragIndex = clamped

                    let nearestIndex = Int(round(clamped))
                    if nearestIndex != currentIndex {
                        selectMorph(index: nearestIndex, isDirectClick: false)
                    }
                }
                .onEnded { value in
                    let margin: CGFloat = 12
                    let step = (trackWidth - margin * 2) / CGFloat(morphs.count - 1)
                    let rawProgress = (value.location.x - margin) / step
                    let nearestIndex = min(max(Int(round(rawProgress)), 0), morphs.count - 1)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        model.dragIndex = nil
                        selectMorph(index: nearestIndex)
                    }
                }
        )
    }

    private func selectMorph(index: Int, isDirectClick: Bool = true) {
        guard index >= 0 && index < morphs.count else { return }
        let targetMorph = morphs[index]
        guard targetMorph != prefs.selectedMorph else { return }

        prefs.selectedMorph = targetMorph
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        CatSoundEngine.shared.playPurr()

        if isDirectClick {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                model.dragIndex = nil
            }
        }
    }
}

// MARK: - AppKit 菜单容器 View (确保鼠标点击/拖拽不触发菜单提前退出)
final class CatMorphSliderHostView: NSHostingView<CatMorphSliderView> {
    private let model: CatMorphSliderModel

    init() {
        let model = CatMorphSliderModel()
        self.model = model
        super.init(rootView: CatMorphSliderView(model: model))
        self.frame = NSRect(x: 0, y: 0, width: 272, height: 66)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    required init(rootView: CatMorphSliderView) {
        fatalError("init(rootView:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
