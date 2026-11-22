import Foundation
import AVFoundation
import AppKit

/// 自然音效与触觉反馈引擎：基于 macOS 原生高品质音效采样与变调混音（告别电子蜂鸣感）
@MainActor
public final class CatSoundEngine {
    public static let shared = CatSoundEngine()

    private var activePlayers: [AVAudioPlayer] = []
    private var lastStretchSoundTime: TimeInterval = 0

    private init() {}

    // MARK: - 1. 待机/抚摸呼噜声 (Natural Purr)
    public func playPurr() {
        let prefs = CatPreferences.shared
        guard prefs.vocalSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)
        playSystemSample(named: "Purr", rate: 0.92, volume: vol * 0.55)
    }

    // MARK: - 2. 按材质定制的拖拽拉伸声 (Material-Specific Stretch Sound)
    public func playStretchTick(progress: CGFloat, morph: CatMorph) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastStretchSoundTime > 0.17 else { return }
        lastStretchSoundTime = now

        let prefs = CatPreferences.shared
        guard prefs.vocalSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)
        let p = Float(min(max(progress, 0), 1))

        switch morph {
        case .cloudCotton:
            // 云絮拉伸音只跟随猫咪材质，与桶样式无关。
            playSystemSample(named: "Blow", rate: 0.72 + p * 0.26, volume: vol * 0.26)
            playSystemSample(named: "Bottle", rate: 0.70 + p * 0.18, volume: vol * 0.14)
        case .slime:
            playSystemSample(named: "Pop", rate: 0.75 + p * 0.95, volume: vol * 0.28)
        case .bluePlush:
            playSystemSample(named: "Blow", rate: 0.85 + p * 0.45, volume: vol * 0.22)
        case .calico:
            // 羊毛毡纤维轻微“噗噗”摩擦声
            playSystemSample(named: "Blow", rate: 1.15 + p * 0.55, volume: vol * 0.24)
        case .tuxedo:
            // 高张力橡皮糖紧绷声
            playSystemSample(named: "Tink", rate: 0.90 + p * 1.05, volume: vol * 0.30)
        case .siamese:
            // 软糯麻薯/芝士黏稠“滋溜”拉丝声（告别生硬青蛙叫，使用水润饱满滑音与细微气流）
            playSystemSample(named: "Bottle", rate: 0.88 + p * 0.62, volume: vol * 0.30)
            playSystemSample(named: "Blow", rate: 0.72 + p * 0.38, volume: vol * 0.16)
            playSystemSample(named: "Pop", rate: 0.68 + p * 0.45, volume: vol * 0.18)
        case .blackShadow:
            // 暗影水墨消散轻微风声
            playSystemSample(named: "Blow", rate: 1.55 + p * 0.40, volume: vol * 0.18)
        }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    // MARK: - 3. 抗拒极限小猫咕噜抗议声 (Cute Protest Trill)
    public func playProtestMeow() {
        let prefs = CatPreferences.shared
        guard prefs.vocalSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        // 告别粗糙生硬的青蛙蛙鸣：改用双音阶自然上扬的娇憨奶猫呼噜颤音 (Chirrup)
        playSystemSample(named: "Purr", rate: 1.35, volume: vol * 0.65)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            Task { @MainActor in
                self.playSystemSample(named: "Purr", rate: 1.70, volume: vol * 0.48)
                self.playSystemSample(named: "Blow", rate: 1.45, volume: vol * 0.22)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            Task { @MainActor in
                self.playSystemSample(named: "Bottle", rate: 1.60, volume: vol * 0.30)
            }
        }
    }

    // MARK: - 4. 锁定目标文件清脆提示音 (Target Lock Sparkle)
    public func playTargetLock() {
        let prefs = CatPreferences.shared
        guard prefs.vocalSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        playSystemSample(named: "Bottle", rate: 1.35, volume: vol * 0.55)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            Task { @MainActor in
                self.playSystemSample(named: "Glass", rate: 1.55, volume: vol * 0.45)
            }
        }
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    // MARK: - 5. 吞食嗷呜一口 + 吧唧咀嚼 + 饱嗝圆润萌音 (Chomp & Bubbly Burp)
    public func playChompAndBurp() {
        let prefs = CatPreferences.shared
        guard prefs.chompSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        // 第一口咬下：软润果冻与水滴吞咽脆响 (Crisp Pop + Bottle)
        playSystemSample(named: "Pop", rate: 0.88, volume: vol * 0.85)
        playSystemSample(named: "Bottle", rate: 1.15, volume: vol * 0.50)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

        // 第二下细腻吧唧嘴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            Task { @MainActor in
                self.playSystemSample(named: "Pop", rate: 1.25, volume: vol * 0.60)
            }
        }

        // 第三下吞咽水润滑落声
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            Task { @MainActor in
                self.playSystemSample(named: "Bottle", rate: 0.95, volume: vol * 0.45)
            }
        }

        // 0.50秒后冒出圆润气泡式可爱小饱嗝（移除生硬青蛙叫，改用软弹气泡音）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            Task { @MainActor in
                self.playSystemSample(named: "Bottle", rate: 0.65, volume: vol * 0.52)
                self.playSystemSample(named: "Submarine", rate: 1.70, volume: vol * 0.35)
                self.playSystemSample(named: "Blow", rate: 1.25, volume: vol * 0.28)
            }
        }
    }

    // MARK: - 5B. 按零食种类定制的吞咽音效 (Tailored Snack Eating Sounds)
    public func playSnackChomp(for snackType: SnackType) {
        let prefs = CatPreferences.shared
        guard prefs.chompSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        switch snackType {
        case .driedFish:
            // 干脆小鱼干：极为清脆细腻的“咔嚓咔嚓”咬碎咀嚼声 (Crispy Crunch)
            playSystemSample(named: "Pop", rate: 1.65, volume: vol * 0.72)
            playSystemSample(named: "Tink", rate: 1.35, volume: vol * 0.55)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.45, volume: vol * 0.65)
                    self.playSystemSample(named: "Tink", rate: 1.20, volume: vol * 0.45)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.75, volume: vol * 0.45)
                    self.playSystemSample(named: "Purr", rate: 1.15, volume: vol * 0.38)
                }
            }
        case .freezeDried:
            // 冻干三文鱼块：软糯咀嚼 + 满足小饱嗝
            playChompAndBurp()
        case .catGrass:
            // 猫草薄荷棒：细嚼慢咽 + 清新满足呼噜声
            playSystemSample(named: "Pop", rate: 1.35, volume: vol * 0.60)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.50, volume: vol * 0.55)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                Task { @MainActor in
                    self.playSystemSample(named: "Purr", rate: 1.05, volume: vol * 0.65)
                }
            }
        case .cannedFood:
            // 马口铁猫罐头：金属拉环掀盖清脆“叮”声 + 鲜美肉酱大口咀嚼
            playSystemSample(named: "Ping", rate: 1.45, volume: vol * 0.60)
            playSystemSample(named: "Pop", rate: 1.10, volume: vol * 0.45)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                Task { @MainActor in
                    self.playChompAndBurp()
                }
            }
        case .snackBox:
            // 豪华零食拼盘盒：连盘带肉大口吞食 + 满足呼噜
            playChompAndBurp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                Task { @MainActor in
                    self.playSystemSample(named: "Purr", rate: 0.95, volume: vol * 0.60)
                }
            }
        }
    }

    // MARK: - 5C. 猫爪轻碰点化魔法音效 ("嘭~" Smoke Poof)
    public func playEnchantPoof() {
        let prefs = CatPreferences.shared
        guard prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        playSystemSample(named: "Blow", rate: 1.55, volume: vol * 0.65)
        playSystemSample(named: "Bottle", rate: 1.65, volume: vol * 0.55)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Task { @MainActor in
                self.playSystemSample(named: "Glass", rate: 1.85, volume: vol * 0.45)
            }
        }
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }

    // MARK: - 6. 按材质定制的松手回缩音 (Material-Specific Snap-Back Sound)
    public func playCancelBoing(morph: CatMorph) {
        let prefs = CatPreferences.shared
        guard prefs.vocalSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        switch morph {
        case .cloudCotton:
            // 棉絮轻柔归位，沿用云朵猫的过阻尼回弹。
            playSystemSample(named: "Blow", rate: 0.66, volume: vol * 0.42)
            playSystemSample(named: "Bottle", rate: 0.74, volume: vol * 0.34)
        case .slime:
            // “Duang Duang” 果冻抖动回弹
            playSystemSample(named: "Submarine", rate: 1.38, volume: vol * 0.52)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.05, volume: vol * 0.42)
                }
            }
        case .bluePlush:
            // 短毛绒玩偶沉闷柔软的“噗通”归位
            playSystemSample(named: "Basso", rate: 1.48, volume: vol * 0.48)
            playSystemSample(named: "Blow", rate: 0.85, volume: vol * 0.40)
        case .calico:
            // 羊毛毡抱枕温柔回落 + 轻微“噗噗”摩擦声
            playSystemSample(named: "Blow", rate: 1.15, volume: vol * 0.45)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                Task { @MainActor in
                    self.playSystemSample(named: "Blow", rate: 0.92, volume: vol * 0.35)
                }
            }
        case .tuxedo:
            // 橡皮糖极其清脆利落的“啪！”脆弹 + 上下弹跳两下
            playSystemSample(named: "Funk", rate: 1.85, volume: vol * 0.65)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.45, volume: vol * 0.45)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.25, volume: vol * 0.32)
                }
            }
        case .siamese:
            // 软糯麻薯慢吞吞地“吸溜”一下滑回桶内（告别生硬青蛙叫，改用水灵糯滑弹性回缩）
            playSystemSample(named: "Submarine", rate: 0.85, volume: vol * 0.45)
            playSystemSample(named: "Bottle", rate: 0.88, volume: vol * 0.35)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                Task { @MainActor in
                    self.playSystemSample(named: "Bottle", rate: 1.15, volume: vol * 0.38)
                    self.playSystemSample(named: "Pop", rate: 0.90, volume: vol * 0.30)
                }
            }
        case .blackShadow:
            // 烟雾流体消散幽风与水墨轻柔归位（悠扬舒缓气流，彻底告别硬质回抽感）
            playSystemSample(named: "Blow", rate: 0.95, volume: vol * 0.28)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                Task { @MainActor in
                    self.playSystemSample(named: "Bottle", rate: 1.25, volume: vol * 0.18)
                }
            }
        }
    }

    // MARK: - 7. 垃圾桶物理闭合/底盘沉降微音效 (Bin Physical Closure)
    public func playBinLidClose(bin: TrashBinStyle) {
        let prefs = CatPreferences.shared
        guard prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        switch bin {
        case .greenWheelieBin:
            // 绿色市政塑料盖自然回落：“嗒哒”一声轻巧塑料闭合
            playSystemSample(named: "Bottle", rate: 0.72, volume: vol * 0.32)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 0.95, volume: vol * 0.28)
                }
            }
        case .streetMetalBox:
            // 街头深咖金属箱：沉稳扎实的金属箱体微降共鸣
            playSystemSample(named: "Basso", rate: 1.65, volume: vol * 0.28)
            playSystemSample(named: "Tink", rate: 0.62, volume: vol * 0.22)
        case .macOSFrosted:
            // 现代极简雾面磨砂垃圾桶：极其温润轻巧的触碰归位
            playSystemSample(named: "Bottle", rate: 1.45, volume: vol * 0.26)
        case .metalMesh:
            // 经典金属网格镂空垃圾桶：清爽利落的微弱钢丝弹跳微响
            playSystemSample(named: "Tink", rate: 1.35, volume: vol * 0.28)
        case .bambooBasket:
            // 竹篓落定时的轻柔纤维触碰声。
            playSystemSample(named: "Blow", rate: 0.85, volume: vol * 0.20)
        }
    }

    // MARK: - 底层变速变调采样播放器
    private func playSystemSample(named name: String, rate: Float, volume: Float) {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.rate = min(max(rate, 0.5), 2.0)
            player.volume = min(max(volume, 0.0), 1.0)
            player.prepareToPlay()
            player.play()

            activePlayers.removeAll { !$0.isPlaying }
            activePlayers.append(player)
        } catch {
            // 忽略音频设备异常
        }
    }
}
