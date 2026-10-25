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
            // 软糯麻薯/芝士黏稠“滋溜”声
            playSystemSample(named: "Frog", rate: 0.72 + p * 0.48, volume: vol * 0.25)
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

        // 高音调 Purr 颤音叠加清脆小咕噜声，自然不刺耳
        playSystemSample(named: "Purr", rate: 1.55, volume: vol * 0.65)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            Task { @MainActor in
                self.playSystemSample(named: "Frog", rate: 1.45, volume: vol * 0.42)
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

    // MARK: - 5. 吞食嗷呜一口 + 吧唧咀嚼 + 小饱嗝 (Chomp & Cute Burp)
    public func playChompAndBurp() {
        let prefs = CatPreferences.shared
        guard prefs.chompSoundEnabled && prefs.soundVolume > 0.01 else { return }
        let vol = Float(prefs.soundVolume)

        // 第一口咬下 (Crisp Pop + Funk)
        playSystemSample(named: "Pop", rate: 0.82, volume: vol * 0.85)
        playSystemSample(named: "Funk", rate: 1.45, volume: vol * 0.55)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)

        // 第二下吧唧嘴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            Task { @MainActor in
                self.playSystemSample(named: "Pop", rate: 1.18, volume: vol * 0.65)
            }
        }

        // 第三下吞咽水滴声
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.29) {
            Task { @MainActor in
                self.playSystemSample(named: "Bottle", rate: 1.05, volume: vol * 0.50)
            }
        }

        // 0.52秒后冒出可爱小饱嗝
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            Task { @MainActor in
                self.playSystemSample(named: "Frog", rate: 0.76, volume: vol * 0.58)
                self.playSystemSample(named: "Blow", rate: 1.35, volume: vol * 0.35)
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
            // 干脆小鱼干：清脆咔嚓咀嚼声 (Crunch)
            playSystemSample(named: "Tink", rate: 1.45, volume: vol * 0.65)
            playSystemSample(named: "Funk", rate: 1.65, volume: vol * 0.75)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                Task { @MainActor in
                    self.playSystemSample(named: "Pop", rate: 1.25, volume: vol * 0.70)
                    self.playSystemSample(named: "Tink", rate: 1.20, volume: vol * 0.55)
                }
            }
        case .freezeDried:
            // 冻干三文鱼块：软糯咀嚼 + 打饱嗝
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
            // 马口铁猫罐头：金属撬盖“叮”声 + 大快朵颐吧唧嘴
            playSystemSample(named: "Glass", rate: 1.75, volume: vol * 0.65)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
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
            // 软糯麻薯慢吞吞地“吸溜”一下滑回桶内
            playSystemSample(named: "Submarine", rate: 0.72, volume: vol * 0.50)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                Task { @MainActor in
                    self.playSystemSample(named: "Frog", rate: 0.86, volume: vol * 0.42)
                }
            }
        case .blackShadow:
            // 吸墨器/黑洞无声收缩 + 轻微风声与水墨滴落声
            playSystemSample(named: "Blow", rate: 1.75, volume: vol * 0.32)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
                Task { @MainActor in
                    self.playSystemSample(named: "Bottle", rate: 1.60, volume: vol * 0.28)
                }
            }
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
