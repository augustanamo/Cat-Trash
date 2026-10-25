import Foundation
import SwiftUI

// MARK: - 猫猫品种与专属材质物理体系 (6 Breeds × 6 Materials)
public enum CatMorph: String, CaseIterable, Identifiable, Codable {
    case slime = "slime"             // 1. 橘猫 · 史莱姆果冻 (Slime / Jelly)
    case bluePlush = "bluePlush"     // 2. 蓝猫 · 短毛绒球 (Short Plush / Pom-Pom)
    case calico = "calico"           // 3. 三花猫 · 羊毛毡针织 (Wool Felt / Knit)
    case tuxedo = "tuxedo"           // 4. 奶牛猫 · 橡皮糖软胶 (Gummy / Rubber)
    case siamese = "siamese"         // 5. 暹罗猫 · 软糯麻薯芝士 (Mochi / Melted Cheese)
    case blackShadow = "blackShadow" // 6. 黑猫 · 暗影水墨烟雾 (Shadow / Smoke Ink)

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .slime: return "橘猫 · 史莱姆果冻"
        case .bluePlush: return "蓝猫 · 短毛绒球"
        case .calico: return "三花 · 羊毛毡针织"
        case .tuxedo: return "奶牛 · 高弹橡皮糖"
        case .siamese: return "暹罗 · 软糯拉丝麻薯"
        case .blackShadow: return "黑猫 · 暗影水墨烟雾"
        }
    }

    public var subtitle: String {
        switch self {
        case .slime: return "高光水润微气泡，DuangDuang果冻抖动回弹"
        case .bluePlush: return "蓬松冰蓝短绒毛，像拽棉花玩偶噗通归位"
        case .calico: return "手作毛毡贴片与绒毛纤维，抱枕般温柔回落"
        case .tuxedo: return "哑光软胶高张力皮筋，松手啪地脆弹跳动"
        case .siamese: return "奶白焦糖高黏度拉丝，慢吞吞吸溜滑回桶内"
        case .blackShadow: return "纯黑烟雾墨滴消散，金黄亮眼黑洞瞬吸归位"
        }
    }

    public var iconName: String {
        switch self {
        case .slime: return "drop.halffull"
        case .bluePlush: return "cloud.fill"
        case .calico: return "scribble.variable"
        case .tuxedo: return "bolt.fill"
        case .siamese: return "flame.fill"
        case .blackShadow: return "moon.stars.fill"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .slime: return Color(red: 1.0, green: 0.60, blue: 0.20)
        case .bluePlush: return Color(red: 0.48, green: 0.64, blue: 0.86)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color(red: 0.16, green: 0.17, blue: 0.20)
        case .siamese: return Color(red: 0.96, green: 0.92, blue: 0.84)
        case .blackShadow: return Color(red: 0.08, green: 0.08, blue: 0.11)
        }
    }

    public var secondaryColor: Color {
        switch self {
        case .slime: return Color(red: 0.96, green: 0.36, blue: 0.16)
        case .bluePlush: return Color(red: 0.78, green: 0.88, blue: 0.98)
        case .calico: return Color(red: 0.92, green: 0.52, blue: 0.22)
        case .tuxedo: return Color(red: 0.96, green: 0.97, blue: 0.99)
        case .siamese: return Color(red: 0.32, green: 0.20, blue: 0.14)
        case .blackShadow: return Color(red: 0.22, green: 0.18, blue: 0.32)
        }
    }

    public var innerEarColor: Color {
        switch self {
        case .slime: return Color(red: 1.0, green: 0.84, blue: 0.62).opacity(0.85)
        case .bluePlush: return Color(red: 0.32, green: 0.24, blue: 0.52)
        case .calico: return Color(red: 0.94, green: 0.68, blue: 0.68)
        case .tuxedo: return Color(red: 0.96, green: 0.62, blue: 0.70)
        case .siamese: return Color(red: 0.24, green: 0.14, blue: 0.10)
        case .blackShadow: return Color(red: 0.15, green: 0.14, blue: 0.20)
        }
    }

    public var isTranslucent: Bool {
        self == .slime || self == .blackShadow
    }

    /// 材质专属：弹簧回弹刚度 k
    public var springStiffness: CGFloat {
        switch self {
        case .slime: return 285.0       // DuangDuang 果冻弹性
        case .bluePlush: return 205.0   // 噗通柔软归位
        case .calico: return 175.0      // 羊毛毡抱枕缓释回落
        case .tuxedo: return 540.0      // 高张力橡皮糖“啪”地脆弹
        case .siamese: return 88.0      // 软糯麻薯慢吞吞“吸溜”滑回
        case .blackShadow: return 420.0 // 黑洞瞬吸收缩
        }
    }

    /// 材质专属：弹簧阻尼系数 c（决定回弹抖动次数还是慢速蠕变）
    public var springDamping: CGFloat {
        switch self {
        case .slime: return 12.0       // 明显 2 次果冻 Jiggle
        case .bluePlush: return 17.5   // 柔和沉闷停稳
        case .calico: return 19.5      // 温润无多余震颤
        case .tuxedo: return 13.0      // 弹力极大，回桶上下弹跳两下
        case .siamese: return 20.5     // 高黏度过阻尼慢滑
        case .blackShadow: return 32.0 // 临界阻尼无声瞬吸
        }
    }

    /// 材质专属：拉拽初始阻力倍率
    public var pullResistanceMultiplier: CGFloat {
        switch self {
        case .slime: return 1.0
        case .bluePlush: return 1.15
        case .calico: return 1.08
        case .tuxedo: return 1.42      // 橡皮糖初期紧绷需要用力拽
        case .siamese: return 0.72     // 麻薯芝士绵软顺滑易拉出
        case .blackShadow: return 0.65 // 烟雾轻灵无阻力
        }
    }

    /// 材质专属：体积守恒中段收窄系数（蓝猫几乎不收窄，奶牛猫像皮筋急剧收窄）
    public var waistNarrowingFactor: CGFloat {
        switch self {
        case .slime: return 0.30
        case .bluePlush: return 0.10   // 短毛绒球整体形变幅度小，保持胖柱状
        case .calico: return 0.24
        case .tuxedo: return 0.54      // 橡皮糖皮筋中段急剧收窄紧绷
        case .siamese: return 0.38     // 芝士麻薯拉丝收窄
        case .blackShadow: return 0.42 // 烟雾流体拉长
        }
    }
}

// MARK: - 潜伏待机随机小动作类型 (Stealth & Idle Micro-Actions)
public enum IdleSubAction: Equatable {
    /// 默认深缩潜伏：完全缩在桶底，桶沿上方只露两只尖耳朵
    case stealth
    /// 暗中探头 (Peek-a-boo)：爪子搭上桶沿，缓缓探出半张脸左右打量后缩回
    case peekABoo
    /// 盯梢鼠标 (Cursor Tracker)：鼠标经过警戒范围时探出半个头紧盯光标，久留则歪头
    case cursorTracker(isTiltingHead: Bool)
    /// 鼠标贴近桶沿悬停 (Alert Hover)：耳朵立起，从桶沿上方冒出半双眼睛警惕观察
    case alertHover
    /// 嗅闻气味 (Sniffing)：探出小粉鼻和胡须抽动两下闻味道
    case sniffing
    /// 偷伸爪子 (Sneak Paw)：趁没人动它，悄悄从桶沿伸出一只小爪子抓两下迅速缩回
    case sneakPaw
    /// 打哈欠冒气泡 (Bubble Yawn)：桶底冒出气泡到桶口“啵”地破掉，耳朵震颤一下
    case bubbleYawn
    /// 经典绿环卫桶专属：猫猫在桶里用脑袋“咣当”一声把绿盖子顶得开合晃动一下
    case lidHeadBump
    /// 经典绿环卫桶专属：猫猫伸出一只爪子像掀井盖一样把绿盖子往上推开，探出半个脑袋左右看，再松手“啪嗒”落回脑袋上
    case lidPawPushPeek
}

// MARK: - 表情与动效状态阶段 (State Machine)
public enum CatInteractionState: Equatable {
    /// 待机 (Idle)：眼神游移、偶尔打瞌睡、身体微幅呼吸起伏
    case idle
    /// 被拽出 (Pulling 0% ~ 40%)：略微诧异，两手挣扎着抓桶沿
    case pulling(progress: CGFloat)
    /// 抗拒极限 (Stretching 40% ~ 100%)：闭眼龇牙、飞机耳、满脸抗拒
    case stretching(progress: CGFloat)
    /// 锁定文件 (Targeting)：悬停文件上方或拖拽文件靠近，张大嘴巴、眼睛发亮
    case targeting(fileName: String, fileCount: Int)
    /// 好奇嗅闻点化 (Sniffing / Enchanting)：按住 Option 靠近桌面文件，准备把文件变成猫零食
    case sniffingToEnchant(fileName: String, snackName: String)
    /// 点化成功 (Enchanted)：猫爪轻拍文件，“嘭”地把文件变成零食图标
    case enchanted(fileName: String, snackName: String)
    /// 吞食回弹 (Chomp & Snap)：松手确认删除瞬间吞下文件、弹回桶内、咀嚼打嗝揉肚子
    case chomping(fileName: String)
    /// 取消/傲娇白眼 (Cancelled)：拖到空白处松手，缩回桶内露出如释重负的白眼表情
    case cancelled

    public var statusLabel: String {
        switch self {
        case .idle:
            return "待机中 · 呼噜呼噜~"
        case .pulling(let p):
            return "被拽出 (\(Int(p * 100))%) · 喵？干嘛拽我！"
        case .stretching(let p):
            return "抗拒极限 (\(Int(p * 100))%) · 喵嗷！！要断啦！"
        case .targeting(let name, let count):
            if count > 1 {
                return "发现美食 · 准备一口吞掉 \(count) 个文件！"
            }
            return "锁定目标 · 嗷呜！「\(name)」"
        case .sniffingToEnchant(let fileName, let snackName):
            return "嗅嗅~ 松手将「\(fileName)」点化为\(snackName) ✨"
        case .enchanted(_, let snackName):
            return "嘭！猫爪点化成功 · 已变成「\(snackName)」！"
        case .chomping(let name):
            return "吧唧吧唧 · 已吞下「\(name)」~ 嗝！"
        case .cancelled:
            return "略略略 · 吓死本喵了（翻白眼）"
        }
    }
}

// MARK: - 垃圾桶外观样式 (Trash Bin Style)
public enum TrashBinStyle: String, CaseIterable, Identifiable, Codable {
    case macOSFrosted = "macOSFrosted"         // macOS 原生一体无边方圆角磨砂白桶
    case greenWheelieBin = "greenWheelieBin"   // 经典绿色可回收/环卫掀盖大垃圾桶（活动掀盖核心互动）
    case streetMetalBox = "streetMetalBox"     // 街头立式深咖烤漆金属果皮箱（带扔垃圾小人图标）
    case metalMesh = "metalMesh"               // 3D 高光镀铬金属编织网格桶

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .macOSFrosted: return "macOS 磨砂桶"
        case .greenWheelieBin: return "经典掀盖绿桶"
        case .streetMetalBox: return "街头金属果皮箱"
        case .metalMesh: return "3D 金属网格桶"
        }
    }

    public var subtitle: String {
        switch self {
        case .macOSFrosted: return "一体无边方圆角磨砂"
        case .greenWheelieBin: return "活动掀盖 · 推井盖探头"
        case .streetMetalBox: return "烤漆铁箱 · 暗格钻出"
        case .metalMesh: return "镀铬亮银 · 曲面螺旋网"
        }
    }

    public var iconName: String {
        switch self {
        case .macOSFrosted: return "trash.fill"
        case .greenWheelieBin: return "arrow.3.trianglepath"
        case .streetMetalBox: return "archivebox.fill"
        case .metalMesh: return "trash.circle"
        }
    }
}

// MARK: - 常驻位置模式 (Placement Mode)
public enum PlacementMode: String, CaseIterable, Identifiable, Codable {
    case dockBottomRight = "dockBottomRight"
    case freeFloating = "freeFloating"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dockBottomRight: return "吸附屏幕右下角（贴近 Dock 废纸篓）"
        case .freeFloating: return "自由拖放固定于桌面任意位置"
        }
    }
}

// MARK: - 最近删除记录（支持一键从废纸篓找回/撤销）
public struct TrashedRecord: Identifiable {
    public let id = UUID()
    public let originalURL: URL
    public let trashedURL: URL?
    public let timestamp: Date

    public var fileName: String {
        originalURL.lastPathComponent
    }
}

// MARK: - 首期基础设置 (User Preferences)
@MainActor
public final class CatPreferences: ObservableObject {
    public static let shared = CatPreferences()

    @Published public var selectedMorph: CatMorph {
        didSet { UserDefaults.standard.set(selectedMorph.rawValue, forKey: Keys.morph) }
    }

    /// 垃圾桶外观样式（macOS 原生磨砂白桶 / 3D 金属网格桶）
    @Published public var selectedBinStyle: TrashBinStyle {
        didSet { UserDefaults.standard.set(selectedBinStyle.rawValue, forKey: Keys.binStyle) }
    }

    /// 整体外观尺寸缩放倍率 (0.6x 小巧 ~ 2.6x 细节特写，默认 1.0x)
    @Published public var widgetScale: Double {
        didSet { UserDefaults.standard.set(widgetScale, forKey: Keys.widgetScale) }
    }

    /// 伸展阻尼系数 (0.2 轻松拉长 ~ 1.0 强阻尼高回弹)
    @Published public var stretchDamping: Double {
        didSet { UserDefaults.standard.set(stretchDamping, forKey: Keys.stretchDamping) }
    }

    /// 回弹速度倍率 (0.5 慢速果冻感 ~ 1.8 快速弹射)
    @Published public var snapSpeed: Double {
        didSet { UserDefaults.standard.set(snapSpeed, forKey: Keys.snapSpeed) }
    }

    /// 咀嚼吞咽与饱嗝音效开关
    @Published public var chompSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(chompSoundEnabled, forKey: Keys.chompSound) }
    }

    /// 猫咪叫声、呼噜与拉伸音效开关
    @Published public var vocalSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(vocalSoundEnabled, forKey: Keys.vocalSound) }
    }

    /// 主音量 (0.0 ~ 1.0)
    @Published public var soundVolume: Double {
        didSet { UserDefaults.standard.set(soundVolume, forKey: Keys.soundVolume) }
    }

    /// 常驻位置模式
    @Published public var placementMode: PlacementMode {
        didSet { UserDefaults.standard.set(placementMode.rawValue, forKey: Keys.placementMode) }
    }

    /// 自定义保存的屏幕坐标（桶中心点）
    @Published public var customBucketOriginX: Double {
        didSet { UserDefaults.standard.set(customBucketOriginX, forKey: Keys.originX) }
    }

    @Published public var customBucketOriginY: Double {
        didSet { UserDefaults.standard.set(customBucketOriginY, forKey: Keys.originY) }
    }

    /// 累计吃掉的垃圾文件数
    @Published public var totalTrashedCount: Int {
        didSet { UserDefaults.standard.set(totalTrashedCount, forKey: Keys.totalTrashedCount) }
    }

    private enum Keys {
        static let morph = "catTrash.selectedMorph"
        static let binStyle = "catTrash.selectedBinStyle"
        static let widgetScale = "catTrash.widgetScale"
        static let stretchDamping = "catTrash.stretchDamping"
        static let snapSpeed = "catTrash.snapSpeed"
        static let chompSound = "catTrash.chompSoundEnabled"
        static let vocalSound = "catTrash.vocalSoundEnabled"
        static let soundVolume = "catTrash.soundVolume"
        static let placementMode = "catTrash.placementMode"
        static let originX = "catTrash.originX"
        static let originY = "catTrash.originY"
        static let totalTrashedCount = "catTrash.totalTrashedCount"
    }

    private init() {
        let defaults = UserDefaults.standard
        if let rawMorph = defaults.string(forKey: Keys.morph),
           let morph = CatMorph(rawValue: rawMorph) {
            self.selectedMorph = morph
        } else {
            self.selectedMorph = .slime
        }

        if let rawBin = defaults.string(forKey: Keys.binStyle),
           let bin = TrashBinStyle(rawValue: rawBin) {
            self.selectedBinStyle = bin
        } else {
            self.selectedBinStyle = .macOSFrosted
        }

        let savedScale = defaults.object(forKey: Keys.widgetScale) as? Double ?? 1.0
        self.widgetScale = min(max(savedScale, 0.6), 2.6)
        self.stretchDamping = defaults.object(forKey: Keys.stretchDamping) as? Double ?? 0.55
        self.snapSpeed = defaults.object(forKey: Keys.snapSpeed) as? Double ?? 1.0
        self.chompSoundEnabled = defaults.object(forKey: Keys.chompSound) as? Bool ?? true
        self.vocalSoundEnabled = defaults.object(forKey: Keys.vocalSound) as? Bool ?? true
        self.soundVolume = defaults.object(forKey: Keys.soundVolume) as? Double ?? 0.75

        if let rawPlacement = defaults.string(forKey: Keys.placementMode),
           let mode = PlacementMode(rawValue: rawPlacement) {
            self.placementMode = mode
        } else {
            self.placementMode = .dockBottomRight
        }

        self.customBucketOriginX = defaults.object(forKey: Keys.originX) as? Double ?? -1
        self.customBucketOriginY = defaults.object(forKey: Keys.originY) as? Double ?? -1
        self.totalTrashedCount = defaults.integer(forKey: Keys.totalTrashedCount)
    }
}
