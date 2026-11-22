import SwiftUI
import AppKit

// MARK: - 迷你垃圾桶图标组件 (拟物微缩矢量)
struct MiniBinIcon: View {
    let style: TrashBinStyle

    var body: some View {
        ZStack {
            switch style {
            case .macOSFrosted:
                // 1. 苹果原生磨砂方圆角桶
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.93, blue: 1.0).opacity(0.85),
                                Color(red: 0.60, green: 0.78, blue: 0.95).opacity(0.70)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 17, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 0.8)
                    )

            case .greenWheelieBin:
                // 2. 经典掀盖绿色环卫垃圾桶 (翻盖 + 桶身 + 小滚轮)
                VStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.12, green: 0.45, blue: 0.24))
                        .frame(width: 19, height: 3)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(red: 0.18, green: 0.60, blue: 0.32))
                        .frame(width: 15, height: 12)
                    HStack(spacing: 9) {
                        Circle().fill(Color.black.opacity(0.85)).frame(width: 2.8, height: 2.8)
                        Circle().fill(Color.black.opacity(0.85)).frame(width: 2.8, height: 2.8)
                    }
                }
                .frame(width: 20, height: 19)

            case .streetMetalBox:
                // 3. 街头不锈钢果皮箱 (金属顶棚 + 投递暗格口 + 深咖门板)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.75, green: 0.77, blue: 0.80))
                        .frame(width: 16, height: 2.5)
                    Rectangle()
                        .fill(Color.black.opacity(0.90))
                        .frame(width: 12, height: 2)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(red: 0.30, green: 0.22, blue: 0.18))
                        .frame(width: 14, height: 12)
                }
                .frame(width: 18, height: 19)

            case .metalMesh:
                // 4. 3D 金属网眼纸篓 (上卷边 + 网眼圆柱 + 旋压底座)
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color(red: 0.80, green: 0.82, blue: 0.86))
                        .frame(width: 17, height: 2)
                    ZStack {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(red: 0.35, green: 0.40, blue: 0.48).opacity(0.40))
                            .frame(width: 14, height: 12)
                        HStack(spacing: 2) {
                            ForEach(0..<3) { _ in
                                Rectangle().fill(Color.white.opacity(0.55)).frame(width: 0.7, height: 10)
                            }
                        }
                    }
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.70, green: 0.72, blue: 0.76))
                        .frame(width: 13, height: 2)
                }
                .frame(width: 18, height: 18)
            case .bambooBasket:
                VStack(spacing: 1) {
                    Capsule()
                        .fill(Color(red: 0.88, green: 0.82, blue: 0.60))
                        .frame(width: 18, height: 3)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(red: 0.60, green: 0.54, blue: 0.35))
                        .frame(width: 15, height: 12)
                        .overlay(
                            Image(systemName: "basket")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color(red: 0.98, green: 0.94, blue: 0.76))
                        )
                }
                .frame(width: 18, height: 18)
            }
        }
    }
}

// MARK: - 浮动菜单共用布局（绘制、鼠标穿透与自动收起使用同一份尺寸）
struct FloatingControlsLayout {
    static let binButtonSize: CGFloat = 28
    static let binSpacing: CGFloat = 6
    static let binColumns = 2
    static let maximumBinRows = 4

    let style: TrashBinStyle
    var binCount: Int = TrashBinStyle.allCases.count

    var binGridSize: CGSize {
        let columns = min(Self.binColumns, max(binCount, 1))
        let rows = min(Self.maximumBinRows, max(1, (binCount + columns - 1) / columns))
        return CGSize(
            width: CGFloat(columns) * Self.binButtonSize + CGFloat(columns - 1) * Self.binSpacing,
            height: CGFloat(rows) * Self.binButtonSize + CGFloat(rows - 1) * Self.binSpacing
        )
    }

    var binsOffsetX: CGFloat {
        style.sideClearance + (binGridSize.width - Self.binButtonSize) / 2
    }

    var controlFrames: [CGRect] {
        [
            CGRect(x: -111, y: style.topSliderOffsetY - 14, width: 222, height: 28),
            CGRect(x: binsOffsetX - binGridSize.width / 2 - 3,
                   y: -binGridSize.height / 2 - 3,
                   width: binGridSize.width + 6, height: binGridSize.height + 6),
            CGRect(x: -style.sideClearance - 17, y: -36, width: 34, height: 72)
        ]
    }

    func contains(screenPoint: CGPoint, bucketCenter: CGPoint, scale: CGFloat) -> Bool {
        let s = max(scale, 0.01)
        let local = CGPoint(x: (screenPoint.x - bucketCenter.x) / s,
                            y: (bucketCenter.y - screenPoint.y) / s)
        return controlFrames.contains { $0.contains(local) }
    }
}

// MARK: - 右侧悬浮群组：垃圾桶样式独立图标按钮
struct StandaloneBinButton: View {
    let style: TrashBinStyle
    @ObservedObject var prefs = CatPreferences.shared

    var body: some View {
        let isSelected = (prefs.selectedBinStyle == style)
        Button(action: {
            guard prefs.selectedBinStyle != style else { return }
            prefs.selectedBinStyle = style
            CatSoundEngine.shared.playPurr()
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }) {
            MiniBinIcon(style: style)
                .frame(width: FloatingControlsLayout.binButtonSize, height: FloatingControlsLayout.binButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(
                            isSelected ? Color.blue : Color.white.opacity(0.20),
                            lineWidth: isSelected ? 1.5 : 0.6
                        )
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.4) : Color.black.opacity(0.30), radius: 3, x: 0, y: 1.5)
        }
        .buttonStyle(.plain)
        .help(style.displayName)
        .accessibilityLabel(style.displayName)
        .accessibilityValue(isSelected ? "已选中" : "未选中")
    }
}

struct StandaloneTrashBinsGrid: View {
    private let allStyles = TrashBinStyle.allCases
    private let columns = Array(
        repeating: GridItem(.fixed(FloatingControlsLayout.binButtonSize), spacing: FloatingControlsLayout.binSpacing),
        count: FloatingControlsLayout.binColumns
    )

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: FloatingControlsLayout.binSpacing) {
            ForEach(allStyles, id: \.self) { style in
                StandaloneBinButton(style: style)
            }
        }
    }

    var body: some View {
        let size = FloatingControlsLayout(style: .macOSFrosted).binGridSize
        if allStyles.count <= FloatingControlsLayout.binColumns * FloatingControlsLayout.maximumBinRows {
            grid.frame(width: size.width, height: size.height)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                grid
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

// MARK: - 左侧悬浮群组：修改文件按钮（反选是恢复）+ 退出按钮 (纯 icon，无文字，无外包面板)
struct StandaloneLeftControls: View {
    @ObservedObject var snackManager = SnackIconManager.shared

    var body: some View {
        VStack(spacing: 6) {
            // 1. 修改文件按钮 (纯 icon：反选是恢复)
            Button(action: {
                snackManager.toggleSnackStall()
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }) {
                Image(systemName: snackManager.isSnackStallActive ? "arrow.uturn.backward" : "wand.and.stars")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(snackManager.isSnackStallActive ? Color.orange : Color.yellow)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(snackManager.isSnackStallActive ? Color.orange.opacity(0.35) : Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(
                                snackManager.isSnackStallActive ? Color.orange : Color.white.opacity(0.20),
                                lineWidth: snackManager.isSnackStallActive ? 1.4 : 0.6
                            )
                    )
                    .shadow(color: Color.black.opacity(0.30), radius: 3, x: 0, y: 1.5)
            }
            .buttonStyle(.plain)
            .help(snackManager.isSnackStallActive ? "恢复文件图标" : "修改桌面文件为零食")

            // 2. 退出按钮 (纯 icon)
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 0.6)
                    )
                    .shadow(color: Color.black.opacity(0.30), radius: 3, x: 0, y: 1.5)
            }
            .buttonStyle(.plain)
            .help("退出 Cat Trash")
        }
    }
}

// MARK: - 上方悬浮群组：猫咪形态进度条 (纯粹的一根悬浮条，无外包卡片面板)
struct StandaloneMorphSliderBar: View {
    @ObservedObject var sliderModel: CatMorphSliderModel = CatPhysicsEngine.shared.morphSliderModel

    var body: some View {
        CatMorphSliderView(model: sliderModel, trackWidth: 198)
    }
}

// MARK: - 悬浮在猫桶周围的独立按钮群组（上方进度条 + 右侧垃圾桶icon按钮 + 左侧修改/退出）
public struct FloatingSurroundingControlsView: View, Equatable {
    public let isVisible: Bool
    public let binStyle: TrashBinStyle

    public init(isVisible: Bool, binStyle: TrashBinStyle) {
        self.isVisible = isVisible
        self.binStyle = binStyle
    }

    private var layout: FloatingControlsLayout {
        FloatingControlsLayout(style: binStyle)
    }

    public var body: some View {
        ZStack {
            // 1. 上方悬浮进度条（原地在正上方以自身中心缩放淡入，绝不从屏幕左上角飞入）
            StandaloneMorphSliderBar()
                .offset(y: layout.style.topSliderOffsetY)
                .scaleEffect(isVisible ? 1.0 : 0.76, anchor: .center)
                .opacity(isVisible ? 1.0 : 0.0)

            // 2. 右侧悬浮垃圾桶 icon 按钮（原地在右侧以自身中心缩放淡入）
            StandaloneTrashBinsGrid()
                .offset(x: layout.binsOffsetX)
                .scaleEffect(isVisible ? 1.0 : 0.76, anchor: .center)
                .opacity(isVisible ? 1.0 : 0.0)

            // 3. 左侧悬浮：修改文件按钮 + 退出按钮（原地在左侧以自身中心缩放淡入）
            StandaloneLeftControls()
                .offset(x: -layout.style.sideClearance)
                .scaleEffect(isVisible ? 1.0 : 0.76, anchor: .center)
                .opacity(isVisible ? 1.0 : 0.0)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isVisible)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: binStyle)
    }
}
