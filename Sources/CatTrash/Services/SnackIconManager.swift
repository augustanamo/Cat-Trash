import AppKit
import SwiftUI

// MARK: - 零食类型与文件映射定义 (SnackType)
public enum SnackType: String, CaseIterable, Sendable {
    case driedFish     // 文档类 -> 干脆小鱼干
    case freezeDried   // 媒体图片/视频 -> 冻干三文鱼块
    case catGrass      // 代码/工程文件 -> 猫草饼干/猫条
    case cannedFood    // 压缩包/安装镜像 -> 马口铁猫罐头
    case snackBox      // 文件夹 -> 豪华零食拼盘盒

    public var displayName: String {
        switch self {
        case .driedFish: return "干脆小鱼干"
        case .freezeDried: return "三文鱼冻干粒"
        case .catGrass: return "猫草薄荷棒"
        case .cannedFood: return "马口铁猫罐头"
        case .snackBox: return "豪华零食拼盘"
        }
    }

    public var emoji: String {
        switch self {
        case .driedFish: return "🐟"
        case .freezeDried: return "🍣"
        case .catGrass: return "🌿"
        case .cannedFood: return "🥫"
        case .snackBox: return "🍱"
        }
    }

    public var crumbColor: Color {
        switch self {
        case .driedFish: return Color(red: 0.96, green: 0.72, blue: 0.28)
        case .freezeDried: return Color(red: 1.00, green: 0.54, blue: 0.46)
        case .catGrass: return Color(red: 0.36, green: 0.86, blue: 0.52)
        case .cannedFood: return Color(red: 0.88, green: 0.42, blue: 0.26)
        case .snackBox: return Color(red: 1.00, green: 0.78, blue: 0.36)
        }
    }
}

// MARK: - 桌面零食图标管理器 (SnackIconManager)
@MainActor
public final class SnackIconManager: ObservableObject {
    public static let shared = SnackIconManager()

    /// 桌面零食摊总开关状态
    @Published public var isSnackStallActive: Bool = false
    /// 记录所有被点化改过图标的文件路径，确保退出或一键复原时 100% 还原
    @Published public private(set) var enchantedFilePaths: Set<String> = []

    private var cachedIcons: [SnackType: NSImage] = [:]

    private init() {}

    // MARK: - 1. 判断文件类型并映射对应零食
    public func snackType(for url: URL) -> SnackType {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue {
            // .app / .rtfd 等 Bundle 除外，普通文件夹映射为零食拼盘盒
            let ext = url.pathExtension.lowercased()
            if ext != "app" && ext != "rtfd" && ext != "pages" {
                return .snackBox
            }
        }

        let lowerName = url.lastPathComponent.lowercased()
        if lowerName.hasSuffix(".tar.gz") || lowerName.hasSuffix(".tgz") {
            return .cannedFood
        }

        switch url.pathExtension.lowercased() {
        case "pdf", "doc", "docx", "pages", "txt", "md", "rtf", "csv", "xls", "xlsx", "ppt", "pptx":
            return .driedFish
        case "png", "jpg", "jpeg", "mp4", "mov", "gif", "heic", "webp", "svg", "mp3", "wav", "m4a":
            return .freezeDried
        case "swift", "js", "ts", "py", "json", "cpp", "c", "h", "html", "css", "sh", "yaml", "yml", "xml":
            return .catGrass
        case "zip", "dmg", "rar", "7z", "tar", "gz", "pkg", "iso":
            return .cannedFood
        default:
            return .freezeDried
        }
    }

    // MARK: - 2. 将指定文件点化替换为零食图标
    @discardableResult
    public func turnToSnack(at fileURL: URL) -> SnackType? {
        guard TrashService.shared.isSafeToTrash(fileURL) else { return nil }
        let type = snackType(for: fileURL)
        let image = iconImage(for: type)
        let success = NSWorkspace.shared.setIcon(image, forFile: fileURL.path, options: [])
        if success {
            enchantedFilePaths.insert(fileURL.path)
            return type
        }
        return nil
    }

    // MARK: - 3. 恢复单个文件的原生系统图标
    public func restoreDefaultIcon(for fileURL: URL) {
        NSWorkspace.shared.setIcon(nil, forFile: fileURL.path, options: [])
        enchantedFilePaths.remove(fileURL.path)
    }

    // MARK: - 4. 开启“桌面零食摊”：批量转化桌面文件为零食图标
    public func enableDesktopSnackStall() {
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: desktopURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }

        var count = 0
        for file in files {
            if turnToSnack(at: file) != nil {
                count += 1
            }
        }
        isSnackStallActive = true
        TrashService.shared.lastStatusMessage = "✨ 桌面零食摊已开张！已将 \(count) 个桌面文件点化为美味猫零食~"
    }

    // MARK: - 5. 一键恢复桌面及所有已点化文件的原生图标（退出应用时自动调用）
    public func resetAllDesktopIcons() {
        // 先还原所有记录在案的已点化路径
        for path in enchantedFilePaths {
            NSWorkspace.shared.setIcon(nil, forFile: path, options: [])
        }
        enchantedFilePaths.removeAll()

        // 再扫描一遍桌面目录确保彻底清除自定义图标
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        if let files = try? FileManager.default.contentsOfDirectory(
            at: desktopURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for file in files {
                NSWorkspace.shared.setIcon(nil, forFile: file.path, options: [])
            }
        }

        isSnackStallActive = false
        TrashService.shared.lastStatusMessage = "🧹 已一键还原桌面所有文件的系统原生图标"
    }

    public func toggleSnackStall() {
        if isSnackStallActive {
            resetAllDesktopIcons()
        } else {
            enableDesktopSnackStall()
        }
    }

    // MARK: - 6. 生成高分辨率拟物化零食图标 (256×256 Retina NSImage)
    public func iconImage(for type: SnackType) -> NSImage {
        if let cached = cachedIcons[type] {
            return cached
        }
        let view = SnackArtworkIconView(type: type)
            .frame(width: 256, height: 256)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        let image = renderer.nsImage ?? NSImage(size: NSSize(width: 256, height: 256))
        cachedIcons[type] = image
        return image
    }
}

// MARK: - 5 种零食的高清拟物矢量图标渲染视图
struct SnackArtworkIconView: View {
    let type: SnackType

    var body: some View {
        ZStack {
            // 底部圆角奶油瓷盘背板（让桌面图标清晰醒目且统一）
            RoundedRectangle(cornerRadius: 56, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: badgeBackgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 216, height: 216)
                .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 56, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 6
                        )
                )

            // 中心零食主体绘制
            snackCenterGraphic

            // 右下角可爱猫爪印角标
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 48, height: 48)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.orange)
            }
            .offset(x: 72, y: 72)
        }
        .frame(width: 256, height: 256)
    }

    private var badgeBackgroundColors: [Color] {
        switch type {
        case .driedFish:
            return [Color(red: 1.0, green: 0.94, blue: 0.78), Color(red: 0.98, green: 0.78, blue: 0.42)]
        case .freezeDried:
            return [Color(red: 1.0, green: 0.90, blue: 0.88), Color(red: 0.98, green: 0.66, blue: 0.60)]
        case .catGrass:
            return [Color(red: 0.88, green: 0.98, blue: 0.88), Color(red: 0.56, green: 0.90, blue: 0.66)]
        case .cannedFood:
            return [Color(red: 0.88, green: 0.94, blue: 1.0), Color(red: 0.58, green: 0.76, blue: 0.96)]
        case .snackBox:
            return [Color(red: 1.0, green: 0.92, blue: 0.80), Color(red: 0.96, green: 0.64, blue: 0.36)]
        }
    }

    @ViewBuilder
    private var snackCenterGraphic: some View {
        switch type {
        case .driedFish:
            // 金黄酥脆小鱼干
            ZStack {
                Image(systemName: "fish.fill")
                    .font(.system(size: 112, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.58, blue: 0.14),
                                Color(red: 0.78, green: 0.36, blue: 0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(-22))
                    .shadow(color: .brown.opacity(0.35), radius: 6, y: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.yellow)
                    .offset(x: -52, y: -48)
            }

        case .freezeDried:
            // 冻干三文鱼肉块
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.52, blue: 0.42),
                                    Color(red: 0.92, green: 0.34, blue: 0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.65), lineWidth: 3)
                        )
                        .rotationEffect(.degrees(Double(i * 22 - 18)))
                        .offset(
                            x: CGFloat(i == 0 ? -26 : (i == 1 ? 26 : 0)),
                            y: CGFloat(i == 2 ? -24 : 18)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                }
            }

        case .catGrass:
            // 猫草薄荷饼干棒
            ZStack {
                ForEach([-20.0, 12.0], id: \.self) { angle in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.78, blue: 0.38),
                                    Color(red: 0.14, green: 0.56, blue: 0.24)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 36, height: 128)
                        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 2.5))
                        .rotationEffect(.degrees(angle))
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                }
                Image(systemName: "leaf.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color(red: 0.18, green: 0.85, blue: 0.36))
                    .offset(x: 24, y: -32)
            }

        case .cannedFood:
            // 马口铁猫罐头
            ZStack {
                // 罐身
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.72), Color(white: 0.95), Color(white: 0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 132, height: 108)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

                // 罐身橘色腰封标签
                Rectangle()
                    .fill(Color(red: 0.96, green: 0.48, blue: 0.18))
                    .frame(width: 132, height: 52)
                    .overlay(
                        Image(systemName: "fish.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    )

                // 罐顶金属盖与拉环
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.92), Color(white: 0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 132, height: 36)
                    .overlay(Ellipse().stroke(Color.white, lineWidth: 3))
                    .offset(y: -46)
            }

        case .snackBox:
            // 文件夹 -> 豪华零食拼盘盒
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.92, green: 0.28, blue: 0.24))
                    .frame(width: 142, height: 116)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(red: 1.0, green: 0.95, blue: 0.86))
                            .frame(width: 124, height: 98)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

                HStack(spacing: 8) {
                    Text("🐟").font(.system(size: 40))
                    Text("🍤").font(.system(size: 40))
                }
            }
        }
    }
}
