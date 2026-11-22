import Foundation
import SwiftUI

// MARK: - 昼夜光照模式 (Day/Night Environmental Mode)
public enum DayNightMode: String, CaseIterable, Identifiable, Codable {
    case auto = "auto"           // 自动（跟随系统时间：晚 20:00 至早 06:00 自动入夜）
    case alwaysDay = "alwaysDay"   // 常驻白天自然光照
    case alwaysNight = "alwaysNight" // 常驻夜晚静谧灯光与幽微光效

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .auto: return "自动跟随系统时间 (晚 8 点后入夜)"
        case .alwaysDay: return "常驻白天 (明亮自然光)"
        case .alwaysNight: return "常驻夜晚 (夜灯光晕与明眸)"
        }
    }

    public var shortName: String {
        switch self {
        case .auto: return "跟随系统"
        case .alwaysDay: return "常驻白天"
        case .alwaysNight: return "常驻夜晚"
        }
    }
}

// MARK: - 全局环境光照状态管理器 (纯视觉光影感知，不触发任何弹窗通知)
@MainActor
public final class EnvironmentLightingManager: ObservableObject {
    public static let shared = EnvironmentLightingManager()

    /// 昼夜过渡插值 (0.0 纯白天 ~ 1.0 纯夜晚)
    @Published public var nightFactor: CGFloat = 0.0

    /// 是否处于夜间状态
    @Published public var isNight: Bool = false

    /// 当前环境阶段：0=清晨/白天, 1=黄昏傍晚, 2=深夜静谧
    @Published public var timePhaseDescription: String = "自然日光"

    /// 街头果皮箱景观小夜灯呼吸相位
    @Published public var lampBreathingPhase: CGFloat = 0.0

    private var checkTimer: Timer?
    private var animationTimer: Timer?
    private var targetNightFactor: CGFloat = 0.0

    private init() {
        updateTargetFactor(immediate: true)
        startTimers()
    }

    /// 启动后台定时检查器（低功耗按需过渡，平时零高频轮询）
    private func startTimers() {
        // 每 30 秒检查一次系统时间变动与模式设置
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTargetFactor(immediate: false)
            }
        }
        if let checkTimer {
            RunLoop.main.add(checkTimer, forMode: .common)
        }
    }

    private func ensureTransitionTimerRunning() {
        guard animationTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stepAnimation()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func stopTransitionTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    /// 根据系统时间计算当前夜间目标深度
    public func updateTargetFactor(immediate: Bool = false) {
        let mode = CatPreferences.shared.dayNightMode
        let newDescription: String

        switch mode {
        case .alwaysDay:
            targetNightFactor = 0.0
            newDescription = "常驻白昼 · 明朗自然光"
        case .alwaysNight:
            targetNightFactor = 1.0
            newDescription = "常驻深夜 · 静谧夜灯常亮"
        case .auto:
            let calendar = Calendar.current
            let now = Date()
            let hour = calendar.component(.hour, from: now)
            let minute = calendar.component(.minute, from: now)
            let timeInHours = Double(hour) + Double(minute) / 60.0

            // 规则：
            // 06:00 ~ 18:30: 白天自然日光 (0.0)
            // 18:30 ~ 20:00: 黄昏入夜平滑过渡 (0.0 -> 1.0)
            // 20:00 ~ 05:30: 深夜景观灯点亮、猫眼更亮 (1.0)
            // 05:30 ~ 06:30: 拂晓晨曦平滑过渡 (1.0 -> 0.0)
            if timeInHours >= 20.0 || timeInHours < 5.5 {
                targetNightFactor = 1.0
                newDescription = "深夜静谧 · 景观夜灯点亮中"
            } else if timeInHours >= 18.5 && timeInHours < 20.0 {
                let progress = (timeInHours - 18.5) / 1.5
                targetNightFactor = CGFloat(progress)
                newDescription = "暮色黄昏 · 夜灯渐亮"
            } else if timeInHours >= 5.5 && timeInHours < 6.5 {
                let progress = 1.0 - (timeInHours - 5.5) / 1.0
                targetNightFactor = CGFloat(progress)
                newDescription = "破晓晨光 · 夜灯隐退"
            } else {
                targetNightFactor = 0.0
                newDescription = "自然采光 · 阳光明朗"
            }
        }

        if timePhaseDescription != newDescription {
            timePhaseDescription = newDescription
        }

        if immediate {
            stopTransitionTimer()
            if abs(nightFactor - targetNightFactor) > 0.0005 {
                nightFactor = targetNightFactor
            }
            let newIsNight = targetNightFactor > 0.4
            if isNight != newIsNight {
                isNight = newIsNight
            }
        } else if abs(nightFactor - targetNightFactor) > 0.002 {
            ensureTransitionTimerRunning()
        }
    }

    private func stepAnimation() {
        // 平滑插值走向目标光照度，过渡完成后立即停止定时器以达到零待机 CPU 消耗
        if abs(nightFactor - targetNightFactor) > 0.002 {
            nightFactor += (targetNightFactor - nightFactor) * 0.12
            let newIsNight = nightFactor > 0.35
            if isNight != newIsNight {
                isNight = newIsNight
            }
        } else {
            if abs(nightFactor - targetNightFactor) > 0.0001 {
                nightFactor = targetNightFactor
            }
            let newIsNight = targetNightFactor > 0.35
            if isNight != newIsNight {
                isNight = newIsNight
            }
            stopTransitionTimer()
        }
    }
}
