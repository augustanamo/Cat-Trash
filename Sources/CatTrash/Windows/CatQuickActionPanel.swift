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
            }
        }
    }
}

// MARK: - 右侧悬浮群组：垃圾桶样式的独立拟物 icon 按钮 (单列流线型排布，未来可支持任意多款皮肤扩展)
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
                .frame(width: 28, height: 28)
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
    }
}

struct StandaloneTrashBinsColumn: View {
    @ObservedObject var prefs = CatPreferences.shared
    private let allStyles = TrashBinStyle.allCases

    var body: some View {
        // 单列纵向排布：宽度仅 28pt，紧凑不占横向空间，未来皮肤增加时可流畅纵向扩展或滚动
        if allStyles.count <= 4 {
            VStack(spacing: 5) {
                ForEach(allStyles, id: \.self) { style in
                    StandaloneBinButton(style: style)
                }
            }
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 5) {
                    ForEach(allStyles, id: \.self) { style in
                        StandaloneBinButton(style: style)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(width: 32, height: 136)
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
        CatMorphSliderView(model: sliderModel, trackWidth: 175)
    }
}

// MARK: - 悬浮在猫桶周围的独立按钮群组（上方进度条 + 右侧垃圾桶icon按钮 + 左侧修改/退出）
public struct FloatingSurroundingControlsView: View {
    let bucketCenter: CGPoint
    let canvasSize: CGSize
    let isGreenWheelie: Bool

    public init(bucketCenter: CGPoint, canvasSize: CGSize, isGreenWheelie: Bool = false) {
        self.bucketCenter = bucketCenter
        self.canvasSize = canvasSize
        self.isGreenWheelie = isGreenWheelie
    }

    /// 上方进度条的 Y 偏移（在猫头与桶沿正上方悬浮，充裕空隙不遮挡猫耳与主界面）
    private var topSliderY: CGFloat {
        bucketCenter.y - (isGreenWheelie ? 82 : 72)
    }

    private var clampedTopSliderPosition: CGPoint {
        let halfW: CGFloat = 175 / 2
        let targetX = min(max(bucketCenter.x, halfW + 8), canvasSize.width - halfW - 8)
        let targetY = max(topSliderY, 16)
        return CGPoint(x: targetX, y: targetY)
    }

    private var clampedRightPosition: CGPoint {
        let halfW: CGFloat = 16
        let targetX = min(bucketCenter.x + 48, canvasSize.width - halfW - 6)
        let targetY = min(max(bucketCenter.y, 70), canvasSize.height - 70)
        return CGPoint(x: targetX, y: targetY)
    }

    private var clampedLeftPosition: CGPoint {
        let halfW: CGFloat = 16
        let targetX = max(bucketCenter.x - 48, halfW + 6)
        let targetY = min(max(bucketCenter.y, 35), canvasSize.height - 35)
        return CGPoint(x: targetX, y: targetY)
    }

    public var body: some View {
        ZStack {
            // 1. 上方悬浮进度条（纯粹的一根条，每个档位是猫猫头，左侧是当前猫猫拉伸身体）
            StandaloneMorphSliderBar()
                .position(clampedTopSliderPosition)

            // 2. 右侧悬浮垃圾桶 icon 按钮（单列纵向排布，不挤占横向空间，可扩展任意多款皮肤）
            StandaloneTrashBinsColumn()
                .position(clampedRightPosition)

            // 3. 左侧悬浮：修改文件按钮（反选是恢复）+ 退出按钮（纯 icon，无文字）
            StandaloneLeftControls()
                .position(clampedLeftPosition)
        }
    }
}
