import Foundation
import SwiftUI
import AppKit

// MARK: - 史莱姆体内微气泡
public struct SlimeBubble: Identifiable {
    public let id = UUID()
    /// 沿身体脊柱的归一化位置 (0.0 桶底 ~ 1.0 猫头)
    public var spineT: CGFloat
    /// 横向偏移比例 (-0.6 ~ 0.6)
    public var lateralOffset: CGFloat
    /// 气泡半径
    public var radius: CGFloat
    /// 漂浮速度
    public var speed: CGFloat
}

// MARK: - 吞食与打嗝粒子特效
public struct EffectParticle: Identifiable {
    public enum Kind {
        case crumb(Color)
        case sparkle
        case burpBubble
        case heartOrText(String)
    }

    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGVector
    public var scale: CGFloat
    public var opacity: Double
    public var age: TimeInterval
    public var lifetime: TimeInterval
    public var kind: Kind
}

// MARK: - 桌面趣味虚拟废纸团（免权限也可在模式 A 下直接拽猫头捕食）
public struct VirtualSnackItem: Identifiable {
    public let id = UUID()
    public var screenPosition: CGPoint
    public var title: String
    public var emoji: String
    public var linkedFileURL: URL?
}

// MARK: - 核心物理与交互状态机引擎
@MainActor
public final class CatPhysicsEngine: ObservableObject {
    public static let shared = CatPhysicsEngine()

    // MARK: - 核心状态发布
    @Published public var state: CatInteractionState = .idle
    @Published public var bucketScreenCenter: CGPoint = CGPoint(x: 1200, y: 120)

    /// 猫头相对于默认待机位置 (bucketScreenCenter + (0, 48)) 的位移向量（屏幕坐标系：x 向右，y 向上）
    @Published public var headDisplacement: CGVector = .zero
    /// 弹簧物理速度向量
    public var headVelocity: CGVector = .zero

    /// 是否正在被鼠标按住拖拽猫头（模式 A）
    @Published public var isDraggingHead: Bool = false
    /// 是否正在被拖拽移动垃圾桶本体位置
    @Published public var isDraggingBucket: Bool = false
    /// 模式 B：外部文件正在悬停于垃圾桶上方
    @Published public var isExternalFileHovering: Bool = false
    /// 模式 B 悬停时的平滑目标位移
    private var externalHoverTarget: CGVector = .zero

    // MARK: - 待机潜伏与随机微动作参数 (Stealth & Idle Actions)
    @Published public var idleSubAction: IdleSubAction = .stealth
    /// 潜伏探头程度：0.0 完全缩在桶底只露耳朵 ~ 0.45 露半双眼睛 ~ 0.72 露出小鼻子 ~ 1.0 完全探出桶口
    @Published public var stealthPeekLevel: CGFloat = 0.0
    private var targetPeekLevel: CGFloat = 0.0

    @Published public var breathingPhase: CGFloat = 0
    @Published public var isBlinking: Bool = false
    @Published public var leftEarTwitchAngle: CGFloat = 0
    @Published public var rightEarTwitchAngle: CGFloat = 0
    @Published public var pupilGazeOffset: CGVector = .zero
    @Published public var chewPhase: CGFloat = 0
    @Published public var jiggleAmplitude: CGFloat = 0
    /// 歪头角度（盯梢鼠标悬停太久时微微歪头）
    @Published public var headTiltAngle: CGFloat = 0
    /// 偷伸爪子动画进度 (0.0 缩回 ~ 1.0 伸出桶沿抓挠)
    @Published public var sneakPawPhase: CGFloat = 0
    /// 嗅闻时鼻头与胡须抽动相位
    @Published public var sniffPhase: CGFloat = 0
    /// 拖拽初期是否正死命用两只爪子扣住桶沿扒拉
    @Published public var arePawsClingingToRim: Bool = false

    // MARK: - 经典绿环卫桶专属：活动掀盖物理与单爪推井盖状态
    /// 绿色桶盖当前掀开角度（度）：待机被猫头/耳朵顶开一条缝约 16° ~ 单爪推开井盖约 52° ~ 拖拽时向后大翻开并晃荡 118°~138°
    @Published public var lidOpenAngle: CGFloat = 16.5
    private var lidAngularVelocity: CGFloat = 0.0
    /// 猫猫伸出一只爪子像掀开地下道井盖一样往上推盖子的进度 (0.0 收回 ~ 1.0 撑住盖子底面)
    @Published public var lidPawPushProgress: CGFloat = 0.0
    /// 盖子松手“啪嗒”落回猫脑袋上瞬间的压扁弹性形变 (0.0 ~ 1.0)
    @Published public var lidBonkHeadSquish: CGFloat = 0.0
    private var hasTriggeredPawSnapShut: Bool = false

    // MARK: - 气泡、粒子与桌面虚拟废纸团
    @Published public var slimeBubbles: [SlimeBubble] = []
    @Published public var particles: [EffectParticle] = []
    @Published public var virtualSnacks: [VirtualSnackItem] = []

    /// 当前模式 A 锁定的目标文件 URL 或虚拟零食
    public private(set) var lockedTargetFileURL: URL?
    public private(set) var lockedVirtualSnackID: UUID?

    private var timer: Timer?
    private var lastUpdateTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var nextBlinkTime: TimeInterval = 2.5
    private var nextEarTwitchTime: TimeInterval = 3.2
    private var nextIdleActionTime: TimeInterval = 5.0
    private var idleActionEndTime: TimeInterval = 0
    private var cursorHoverStartTime: TimeInterval?
    private var stateResetTask: Task<Void, Never>?
    private var hasPlayedProtestMeowInCurrentStretch: Bool = false

    /// 潜伏深缩时的基准高度与完全探头高度
    public var stealthBaseYOffset: CGFloat {
        switch CatPreferences.shared.selectedBinStyle {
        case .streetMetalBox:
            return 5.5
        case .greenWheelieBin:
            // 经典掀盖绿环卫桶（放大 1.45 倍，桶口约在 y-69）：猫头顶在桶口下方，只在绿盖子顶开的三角缝隙里露出一双亮晶晶的眼睛与顶盖的耳朵！
            return 75.5
        default:
            return 13.5
        }
    }

    public var fullPeekYOffset: CGFloat {
        switch CatPreferences.shared.selectedBinStyle {
        case .streetMetalBox:
            return 27.5
        case .greenWheelieBin:
            return 90.0
        default:
            return 45.0
        }
    }

    /// 动态计算的当前猫头待机基准高度（随潜伏/探头状态平滑升降）
    public var restingHeadYOffset: CGFloat {
        stealthBaseYOffset + stealthPeekLevel * (fullPeekYOffset - stealthBaseYOffset)
    }

    /// 最大视觉拉伸长度（像素）
    public let maxStretchDistance: CGFloat = 850.0

    private init() {
        setupInitialBubbles()
        resetBucketToDefaultCornerIfNeeded()
        startSimulationLoop()
    }

    private func setupInitialBubbles() {
        slimeBubbles = (0..<14).map { _ in
            SlimeBubble(
                spineT: CGFloat.random(in: 0.08...0.92),
                lateralOffset: CGFloat.random(in: -0.55...0.55),
                radius: CGFloat.random(in: 2.5...6.5),
                speed: CGFloat.random(in: 0.06...0.18)
            )
        }
    }

    public func resetBucketToDefaultCornerIfNeeded() {
        let prefs = CatPreferences.shared
        if prefs.placementMode == .freeFloating,
           prefs.customBucketOriginX > 0,
           prefs.customBucketOriginY > 0 {
            bucketScreenCenter = CGPoint(x: prefs.customBucketOriginX, y: prefs.customBucketOriginY)
        } else {
            snapBucketToBottomRightCorner()
        }
    }

    public var scale: CGFloat {
        CGFloat(CatPreferences.shared.widgetScale)
    }

    public func snapBucketToBottomRightCorner() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let s = max(scale, 0.85)
        let targetX = visible.maxX - 72 * s
        let targetY = visible.minY + 68 * s
        bucketScreenCenter = CGPoint(x: targetX, y: targetY)
        CatPreferences.shared.customBucketOriginX = targetX
        CatPreferences.shared.customBucketOriginY = targetY
    }

    /// 计算当前猫头在屏幕坐标系下的绝对位置
    public var currentHeadScreenPoint: CGPoint {
        CGPoint(
            x: bucketScreenCenter.x + headDisplacement.dx,
            y: bucketScreenCenter.y + restingHeadYOffset * scale + headDisplacement.dy
        )
    }

    /// 当前拉伸距离 (0 ~ maxStretchDistance)
    public var currentStretchDistance: CGFloat {
        hypot(headDisplacement.dx, headDisplacement.dy)
    }

    /// 归一化拉伸比例 (0.0 ~ 1.0)
    public var normalizedStretchRatio: CGFloat {
        // 设定 420pt 为 100% 满额表情阈值，更远距离仍可继续阻尼延伸以触达全屏图标
        min(currentStretchDistance / 420.0, 1.0)
    }

    /// 体积守恒模拟：根据当前拉伸比例计算身体中段收窄比例
    public func waistNarrowingScale(for morph: CatMorph) -> CGFloat {
        let ratio = min(currentStretchDistance / 480.0, 1.0)
        let narrowed = 1.0 - morph.waistNarrowingFactor * pow(ratio, 0.75)
        return max(0.24, narrowed)
    }

    // MARK: - 60~120Hz 物理与动效主循环
    private func startSimulationLoop() {
        lastUpdateTime = ProcessInfo.processInfo.systemUptime
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stepSimulation()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stepSimulation() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(max(now - lastUpdateTime, 1.0 / 240.0), 0.05)
        lastUpdateTime = now

        // 1. 呼吸与微动相位更新
        breathingPhase += CGFloat(dt) * 2.4
        if case .chomping = state {
            chewPhase += CGFloat(dt) * 16.0
        } else {
            chewPhase = 0
        }

        // 2. 弹簧阻尼物理回弹（非拖拽且非外部文件悬停状态下）
        if isExternalFileHovering && !isDraggingHead {
            // 模式 B 文件悬停投喂时：平滑跟随目标点，不再与回弹弹簧打架导致抖动
            let lerpFactor = min(CGFloat(dt) * 14.0, 1.0)
            headDisplacement.dx += (externalHoverTarget.dx - headDisplacement.dx) * lerpFactor
            headDisplacement.dy += (externalHoverTarget.dy - headDisplacement.dy) * lerpFactor
            headVelocity = .zero
        } else if !isDraggingHead {
            let prefs = CatPreferences.shared
            let morph = prefs.selectedMorph
            let speedMul = CGFloat(prefs.snapSpeed)
            // 使用各猫咪品种专属材质的刚度 k 与阻尼 c（果冻DuangDuang、毛绒噗通、毛毡缓释、橡皮糖脆弹、麻薯吸溜慢滑、黑猫瞬吸）
            let stiffness: CGFloat = morph.springStiffness * speedMul
            let damping: CGFloat = morph.springDamping * sqrt(speedMul)

            let forceX = -stiffness * headDisplacement.dx - damping * headVelocity.dx
            let forceY = -stiffness * headDisplacement.dy - damping * headVelocity.dy

            headVelocity.dx += forceX * CGFloat(dt)
            headVelocity.dy += forceY * CGFloat(dt)

            headDisplacement.dx += headVelocity.dx * CGFloat(dt)
            // 街头金属果皮箱为正面暗格拉出，允许从前方任意角度回弹；普通敞口桶限制向下穿透桶底
            if prefs.selectedBinStyle == .streetMetalBox {
                headDisplacement.dy += headVelocity.dy * CGFloat(dt)
            } else {
                let minBounceY: CGFloat = min((morph == .tuxedo) ? -16.0 : -9.0, minAllowedHeadDY(forDX: headDisplacement.dx))
                headDisplacement.dy = max(minBounceY, headDisplacement.dy + headVelocity.dy * CGFloat(dt))
            }

            if hypot(headDisplacement.dx, headDisplacement.dy) < 0.25 &&
               hypot(headVelocity.dx, headVelocity.dy) < 2.0 {
                headDisplacement = .zero
                headVelocity = .zero
            }
        }

        // 3. 史莱姆果冻抖动衰减
        if jiggleAmplitude > 0.01 {
            jiggleAmplitude *= pow(0.08, CGFloat(dt))
        } else {
            jiggleAmplitude = 0
        }

        // 4. 更新史莱姆内部微气泡漂浮
        let velMag = hypot(headVelocity.dx, headVelocity.dy)
        for i in slimeBubbles.indices {
            slimeBubbles[i].spineT += (slimeBubbles[i].speed + velMag * 0.0003) * CGFloat(dt)
            if slimeBubbles[i].spineT > 0.95 {
                slimeBubbles[i].spineT = 0.08
                slimeBubbles[i].lateralOffset = CGFloat.random(in: -0.55...0.55)
            }
        }

        // 5. 更新粒子系统（碎屑、星光、打嗝泡泡）
        updateParticles(dt: dt)

        // 6. 更新待机眨眼、抖耳与眼神游移
        updateIdleMicroAnimations(now: now, dt: dt)
    }

    private func updateParticles(dt: TimeInterval) {
        guard !particles.isEmpty else { return }
        var surviving: [EffectParticle] = []
        surviving.reserveCapacity(particles.count)

        for var p in particles {
            p.age += dt
            guard p.age < p.lifetime else { continue }
            p.position.x += p.velocity.dx * CGFloat(dt)
            p.position.y += p.velocity.dy * CGFloat(dt)

            switch p.kind {
            case .crumb:
                p.velocity.dy -= 240.0 * CGFloat(dt) // 重力下落
            case .burpBubble, .heartOrText:
                p.velocity.dy += 28.0 * CGFloat(dt)  // 向上轻飘
                p.position.x += sin(CGFloat(p.age * 7.0)) * 0.45
            case .sparkle:
                p.velocity.dx *= 0.95
                p.velocity.dy *= 0.95
            }

            let lifeProgress = p.age / p.lifetime
            p.opacity = max(0, 1.0 - pow(lifeProgress, 1.6))
            surviving.append(p)
        }
        particles = surviving
    }

    private func updateIdleMicroAnimations(now: TimeInterval, dt: TimeInterval) {
        // 眨眼定时
        if now >= nextBlinkTime {
            isBlinking = true
            nextBlinkTime = now + Double.random(in: 2.8...5.6)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 140_000_000)
                self.isBlinking = false
            }
        }

        // 偶尔像被蚊子叮了一样快速轻弹一下耳朵 (Ear Twitch)
        if now >= nextEarTwitchTime {
            if Bool.random() {
                leftEarTwitchAngle = CGFloat.random(in: -22...16)
            } else {
                rightEarTwitchAngle = CGFloat.random(in: -16...22)
            }
            // 经典掀盖绿桶待机时：耳朵卡在盖子缝隙里，抖耳朵会同步把绿盖子顶得微微颤动！
            if CatPreferences.shared.selectedBinStyle == .greenWheelieBin && state == .idle {
                lidAngularVelocity += CGFloat.random(in: 35...62)
            }
            nextEarTwitchTime = now + Double.random(in: 2.4...5.2)
        }
        leftEarTwitchAngle *= pow(0.015, CGFloat(dt))
        rightEarTwitchAngle *= pow(0.015, CGFloat(dt))
        lidBonkHeadSquish *= pow(0.008, CGFloat(dt))

        let isGreenWheelie = (CatPreferences.shared.selectedBinStyle == .greenWheelieBin)
        let s = max(scale, 0.85)
        let mouseLoc = NSEvent.mouseLocation
        let rimPoint = CGPoint(x: bucketScreenCenter.x, y: bucketScreenCenter.y + (isGreenWheelie ? 66 : 28) * scale)
        let distToRim = hypot(mouseLoc.x - rimPoint.x, mouseLoc.y - rimPoint.y)

        var targetLidAngle: CGFloat = 16.5

        // 仅在 Idle 待机状态下驱动「潜伏深缩 + 随机小动作库」
        if state == .idle && !isDraggingHead && !isExternalFileHovering {
            if distToRim < 68 * s {
                // 1. 鼠标悬停靠近桶沿耳朵位置：耳朵警觉立起，眼睛从桶沿/盖子缝隙冒出一条缝
                idleSubAction = .alertHover
                targetPeekLevel = isGreenWheelie ? 0.34 : 0.46
                targetLidAngle = 25.0
                lidPawPushProgress *= pow(0.01, CGFloat(dt))
                headTiltAngle = 0
                cursorHoverStartTime = nil
            } else if distToRim < 195 * s {
                // 2. 盯梢鼠标 (Cursor Tracker)：进入警戒范围，探出半个脑袋（顶高盖子）紧盯光标；悬停久了会歪头
                if cursorHoverStartTime == nil {
                    cursorHoverStartTime = now
                }
                let hoverDuration = now - (cursorHoverStartTime ?? now)
                let shouldTilt = hoverDuration > 1.8
                idleSubAction = .cursorTracker(isTiltingHead: shouldTilt)
                targetPeekLevel = isGreenWheelie ? 0.56 : 0.68
                targetLidAngle = 35.0
                lidPawPushProgress *= pow(0.01, CGFloat(dt))
                headTiltAngle = shouldTilt ? (mouseLoc.x < bucketScreenCenter.x ? -11.0 : 11.0) : 0
            } else {
                // 3. 鼠标远离：执行默认潜伏或每隔几秒随机触发一次暗中观察/掀盖小动作
                cursorHoverStartTime = nil
                headTiltAngle = 0

                if now < idleActionEndTime {
                    // 正在执行某个随机小动作
                    switch idleSubAction {
                    case .lidHeadBump:
                        // 偶尔“咣当”一声，盖子被猫猫从里面用头顶得开合晃动一下
                        targetPeekLevel = 0.32
                        targetLidAngle = 18.0
                        lidPawPushProgress = 0
                    case .lidPawPushPeek:
                        // 猫猫伸出一只爪子把盖子往上推开（像掀井盖一样），探出半个脑袋看看外面，然后松手“啪嗒”一声盖子落回脑袋上
                        let remaining = idleActionEndTime - now
                        if remaining > 0.72 {
                            // 阶段 1：单爪推开井盖，探出半个脑袋左右张望
                            targetPeekLevel = 0.72
                            targetLidAngle = 52.0
                            lidPawPushProgress += (1.0 - lidPawPushProgress) * min(CGFloat(dt) * 9.0, 1.0)
                        } else {
                            // 阶段 2：突然松开爪子，“啪嗒”一声盖子砸回猫脑袋上！
                            lidPawPushProgress *= pow(0.0005, CGFloat(dt))
                            targetPeekLevel = 0.16
                            targetLidAngle = 16.0
                            if !hasTriggeredPawSnapShut {
                                hasTriggeredPawSnapShut = true
                                lidAngularVelocity = -330.0
                                lidBonkHeadSquish = 1.0
                                leftEarTwitchAngle = -18
                                rightEarTwitchAngle = 18
                                CatSoundEngine.shared.playPurr()
                                let snapPos = CGPoint(x: bucketScreenCenter.x + 18 * scale, y: bucketScreenCenter.y + 42 * scale)
                                particles.append(
                                    EffectParticle(
                                        position: snapPos,
                                        velocity: CGVector(dx: 12, dy: 28),
                                        scale: 0.92,
                                        opacity: 0.95,
                                        age: 0,
                                        lifetime: 0.75,
                                        kind: .heartOrText("啪嗒! 💥")
                                    )
                                )
                            }
                        }
                    case .peekABoo:
                        targetPeekLevel = 0.70
                        targetLidAngle = 38.0
                    case .sniffing:
                        targetPeekLevel = 0.78
                        targetLidAngle = 40.0
                        sniffPhase += CGFloat(dt) * 22.0
                    case .sneakPaw:
                        targetPeekLevel = 0.08
                        targetLidAngle = 22.0
                        sneakPawPhase += CGFloat(dt) * 9.0
                    case .bubbleYawn:
                        targetPeekLevel = 0.12
                        targetLidAngle = 20.0
                    default:
                        targetPeekLevel = isGreenWheelie ? 0.16 : 0.0
                        targetLidAngle = 16.5 + sin(breathingPhase) * 1.3
                    }
                } else {
                    // 回到默认待机：敞口桶缩回桶底只露耳朵；经典掀盖绿桶用头和耳朵把绿盖子顶开一道三角缝（约 16.5°），露出缝隙里亮晶晶的眼睛！
                    idleSubAction = .stealth
                    targetPeekLevel = isGreenWheelie ? 0.16 : 0.0
                    targetLidAngle = 16.5 + sin(breathingPhase) * 1.3
                    sniffPhase = 0
                    sneakPawPhase = 0
                    lidPawPushProgress *= pow(0.01, CGFloat(dt))

                    if now >= nextIdleActionTime {
                        triggerRandomIdleAction(now: now)
                    }
                }
            }
        } else {
            // 非待机状态（被拉拽、锁定或吞食中）：完全探出桶口，绿桶盖由于重力向后大翻开并夸张晃荡！
            targetPeekLevel = 1.0
            headTiltAngle = 0
            sniffPhase = 0
            sneakPawPhase = 0
            lidPawPushProgress = 0

            if isDraggingHead && arePawsClingingToRim && currentStretchDistance < 42 {
                // 刚拽动猫头、爪子还扒着桶沿时：猫头先把盖子向上顶起至 ~78°
                targetLidAngle = 34.0 + min(currentStretchDistance * 1.2, 50.0)
            } else {
                // 拽出猫猫后：盖子由于重力向后翻开（118° ~ 136°），并随拖拽速度和重力夸张地来回晃荡！
                targetLidAngle = 122.0 + min(normalizedStretchRatio * 14.0, 14.0) + sin(breathingPhase * 3.6) * 6.5
                let dragWobble = (headVelocity.dx * 0.06 - headVelocity.dy * 0.04)
                lidAngularVelocity += dragWobble * CGFloat(dt) * 8.0
            }
        }

        // 驱动绿色桶盖的弹簧摆锤物理（向后翻开时低阻尼夸张晃荡，盖合在猫头上时带碰撞反弹）
        let isFlippedBack = (lidOpenAngle > 75.0 || targetLidAngle > 75.0)
        let lidStiffness: CGFloat = isFlippedBack ? 115.0 : 210.0
        let lidDamping: CGFloat = isFlippedBack ? 5.2 : 11.5
        let lidForce = -lidStiffness * (lidOpenAngle - targetLidAngle) - lidDamping * lidAngularVelocity
        lidAngularVelocity += lidForce * CGFloat(dt)
        lidOpenAngle += lidAngularVelocity * CGFloat(dt)

        // 当盖子向下落回猫头顶最小支撑角（约 12.5°）时，发生“咣当/啪嗒”弹性碰撞反弹，绝不穿透猫脑袋！
        let minHeadPropAngle: CGFloat = (state == .idle) ? 12.5 : 8.0
        if lidOpenAngle < minHeadPropAngle {
            lidOpenAngle = minHeadPropAngle
            if lidAngularVelocity < -18.0 {
                lidAngularVelocity = -lidAngularVelocity * 0.46
                lidBonkHeadSquish = min(1.0, abs(lidAngularVelocity) / 140.0)
            } else {
                lidAngularVelocity = 0
            }
        } else if lidOpenAngle > 148.0 {
            lidOpenAngle = 148.0
            lidAngularVelocity = -abs(lidAngularVelocity) * 0.45
        }

        // 平滑插值更新潜伏探头高度
        let peekSpeed: CGFloat = (targetPeekLevel > stealthPeekLevel) ? 7.5 : 4.2
        stealthPeekLevel += (targetPeekLevel - stealthPeekLevel) * min(CGFloat(dt) * peekSpeed, 1.0)

        // 眼神跟随鼠标或警惕左右打量
        let headLoc = currentHeadScreenPoint
        let dx = mouseLoc.x - headLoc.x
        let dy = mouseLoc.y - headLoc.y
        let dist = hypot(dx, dy)
        if case .peekABoo = idleSubAction {
            // 暗中探头时：眼珠警惕地左右扫视桌面
            let lookX = sin(CGFloat(now) * 4.2) * 3.8
            pupilGazeOffset.dx += (lookX - pupilGazeOffset.dx) * min(CGFloat(dt) * 8.0, 1.0)
            pupilGazeOffset.dy = 0.5
        } else if case .lidPawPushPeek = idleSubAction {
            // 单爪推开井盖探出半个脑袋时：好奇地左右打量外面世界
            let lookX = sin(CGFloat(now) * 4.8) * 4.0
            pupilGazeOffset.dx += (lookX - pupilGazeOffset.dx) * min(CGFloat(dt) * 9.0, 1.0)
            pupilGazeOffset.dy = 0.6
        } else if dist > 4 && dist < 450 {
            let maxOffset: CGFloat = 3.8
            let targetX = (dx / dist) * min(dist / 45.0, 1.0) * maxOffset
            let targetY = (dy / dist) * min(dist / 45.0, 1.0) * maxOffset
            pupilGazeOffset.dx += (targetX - pupilGazeOffset.dx) * min(CGFloat(dt) * 10.0, 1.0)
            pupilGazeOffset.dy += (targetY - pupilGazeOffset.dy) * min(CGFloat(dt) * 10.0, 1.0)
        } else {
            pupilGazeOffset.dx *= 0.9
            pupilGazeOffset.dy *= 0.9
        }
    }

    /// 每隔几秒随机触发一个暗中观察小动作（经典掀盖绿桶优先触发「咣当顶盖」与「单爪掀井盖探头」）
    private func triggerRandomIdleAction(now: TimeInterval) {
        if CatPreferences.shared.selectedBinStyle == .greenWheelieBin {
            let greenRoll = Int.random(in: 0..<5)
            if greenRoll <= 1 {
                // 微动作 1：偶尔“咣当”一声，盖子被猫猫从桶里用脑袋顶得开合一下！
                idleSubAction = .lidHeadBump
                idleActionEndTime = now + 1.1
                lidAngularVelocity = 265.0
                leftEarTwitchAngle = -16
                rightEarTwitchAngle = 16
                let clatterPos = CGPoint(x: bucketScreenCenter.x + 16 * scale, y: bucketScreenCenter.y + 44 * scale)
                particles.append(
                    EffectParticle(
                        position: clatterPos,
                        velocity: CGVector(dx: 10, dy: 32),
                        scale: 0.9,
                        opacity: 0.92,
                        age: 0,
                        lifetime: 0.75,
                        kind: .heartOrText("咣当~")
                    )
                )
                nextIdleActionTime = idleActionEndTime + Double.random(in: 3.0...6.0)
                return
            } else if greenRoll <= 3 {
                // 微动作 2：猫猫伸出一只爪子把盖子往上推开（像掀井盖一样），探出半个脑袋看看外面，然后松手“啪嗒”落回脑袋上！
                idleSubAction = .lidPawPushPeek
                hasTriggeredPawSnapShut = false
                lidAngularVelocity = 95.0
                idleActionEndTime = now + 2.45
                nextIdleActionTime = idleActionEndTime + Double.random(in: 3.5...6.8)
                return
            }
        }

        let roll = Int.random(in: 0..<4)
        switch roll {
        case 0:
            // 暗中探头 (Peek-a-boo)
            idleSubAction = .peekABoo
            idleActionEndTime = now + Double.random(in: 1.8...2.6)
        case 1:
            // 嗅闻气味 (Sniffing)
            idleSubAction = .sniffing
            idleActionEndTime = now + Double.random(in: 1.5...2.2)
        case 2:
            // 偷伸爪子 (Sneak Paw)
            idleSubAction = .sneakPaw
            idleActionEndTime = now + Double.random(in: 1.4...2.0)
        default:
            // 打哈欠与冒气泡 (Bubble Yawn)：从桶底冒出气泡到桶口“啵”地破掉，耳朵跟着震颤
            idleSubAction = .bubbleYawn
            idleActionEndTime = now + 1.3
            let bubblePos = CGPoint(x: bucketScreenCenter.x + CGFloat.random(in: -10...10), y: bucketScreenCenter.y + 18)
            particles.append(
                EffectParticle(
                    position: bubblePos,
                    velocity: CGVector(dx: CGFloat.random(in: -8...8), dy: 38),
                    scale: 1.0,
                    opacity: 0.95,
                    age: 0,
                    lifetime: 0.9,
                    kind: .burpBubble
                )
            )
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                self.leftEarTwitchAngle = -20
                self.rightEarTwitchAngle = 20
            }
        }
        nextIdleActionTime = idleActionEndTime + Double.random(in: 4.0...9.5)
    }

    /// 开口在上方的桶：猫头不能直接穿过桶身往下拽；拉到桶身左右外侧后，才允许越过桶沿垂挂到桶外往下（平滑过渡）
    public func minAllowedHeadDY(forDX dx: CGFloat) -> CGFloat {
        let style = CatPreferences.shared.selectedBinStyle
        guard style != .streetMetalBox else { return -.greatestFiniteMagnitude }
        let halfW: CGFloat = (style == .greenWheelieBin ? 58.0 : 42.0) * scale
        let depth: CGFloat = (fullPeekYOffset + 34.0) * scale
        let k = min(max((abs(dx) - halfW) / (34.0 * scale), 0), 1)
        return 6.0 - (6.0 + depth) * k
    }

    // MARK: - 模式 A：用户按住猫头向外拖拽 (Rubber-Band Active Pull)
    public func beginHeadDrag() {
        stateResetTask?.cancel()
        isDraggingHead = true
        headVelocity = .zero
        stealthPeekLevel = 1.0
        targetPeekLevel = 1.0
        arePawsClingingToRim = true
        hasPlayedProtestMeowInCurrentStretch = false
        lockedTargetFileURL = nil
        lockedVirtualSnackID = nil
    }

    public func updateHeadDrag(toScreenPoint cursorScreenPoint: CGPoint, isOptionPressed: Bool = NSEvent.modifierFlags.contains(.option)) {
        guard isDraggingHead else { return }

        let isStreetBox = (CatPreferences.shared.selectedBinStyle == .streetMetalBox)
        let anchor = CGPoint(
            x: bucketScreenCenter.x,
            y: bucketScreenCenter.y + fullPeekYOffset * scale
        )
        let rawDX = cursorScreenPoint.x - anchor.x
        // 敞口桶限制只能从桶口向上方拉出；而街头金属果皮箱是「正面暗格窗口」，允许向正前、左右、斜下或斜上任意方向从暗格里往外拖出！
        let rawDY = isStreetBox ? (cursorScreenPoint.y - anchor.y) : max(minAllowedHeadDY(forDX: rawDX), cursorScreenPoint.y - anchor.y)
        let rawDist = hypot(rawDX, rawDY)

        guard rawDist > 0.5 else {
            headDisplacement = .zero
            arePawsClingingToRim = true
            state = .pulling(progress: 0)
            return
        }

        let morph = CatPreferences.shared.selectedMorph
        let clingThreshold: CGFloat = 68.0 * morph.pullResistanceMultiplier
        let dampingSetting = CGFloat(CatPreferences.shared.stretchDamping) * morph.pullResistanceMultiplier
        let stiffnessScale = max(0.38, 1.0 - (dampingSetting - 0.2) * 0.36)
        let softLimit = maxStretchDistance * stiffnessScale

        let dampedDist: CGFloat
        if rawDist < clingThreshold {
            arePawsClingingToRim = true
            // 爪子死扣桶沿/暗格门板阶段：位移受强阻力抑制
            dampedDist = rawDist * (0.48 / morph.pullResistanceMultiplier)
        } else {
            if arePawsClingingToRim {
                arePawsClingingToRim = false
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
            dampedDist = softLimit * (1.0 - exp(-rawDist / max(softLimit * 0.85, 120.0)))
        }

        let ux = rawDX / rawDist
        let uy = rawDY / rawDist
        if isStreetBox && arePawsClingingToRim {
            // 街头果皮箱初段扒住门板时：猫猫还在暗格内部挣扎，限制向上位移不顶穿暗格顶棚
            headDisplacement = CGVector(
                dx: min(max(ux * dampedDist, -14.0), 14.0),
                dy: min(max(uy * dampedDist, -8.0), 5.0)
            )
        } else {
            headDisplacement = CGVector(dx: ux * dampedDist, dy: uy * dampedDist)
        }

        let ratio = normalizedStretchRatio
        CatSoundEngine.shared.playStretchTick(progress: ratio, morph: morph)

        // 黑猫暗影烟雾形态：拖拽时身体边缘不断飘散细小的墨滴与暗影烟气微粒
        if morph == .blackShadow && Bool.random() {
            let t = CGFloat.random(in: 0.25...0.85)
            let pX = anchor.x + headDisplacement.dx * t + CGFloat.random(in: -16...16)
            let pY = anchor.y + headDisplacement.dy * t + CGFloat.random(in: -10...10)
            particles.append(
                EffectParticle(
                    position: CGPoint(x: pX, y: pY),
                    velocity: CGVector(dx: CGFloat.random(in: -28...28), dy: CGFloat.random(in: 18...52)),
                    scale: CGFloat.random(in: 0.55...1.15),
                    opacity: 0.78,
                    age: 0,
                    lifetime: Double.random(in: 0.35...0.65),
                    kind: .crumb(Color(red: 0.08, green: 0.06, blue: 0.14))
                )
            )
        }

        // 检测鼠标或猫头下方是否锁定了目标文件或桌面虚拟零食
        let headPoint = currentHeadScreenPoint
        if let virtualHit = hitTestVirtualSnack(near: cursorScreenPoint) ?? hitTestVirtualSnack(near: headPoint) {
            if lockedVirtualSnackID != virtualHit.id {
                lockedVirtualSnackID = virtualHit.id
                lockedTargetFileURL = virtualHit.linkedFileURL
                CatSoundEngine.shared.playTargetLock()
            }
            if isOptionPressed, let url = virtualHit.linkedFileURL {
                let sType = SnackIconManager.shared.snackType(for: url)
                state = .sniffingToEnchant(fileName: virtualHit.title, snackName: "\(sType.emoji)\(sType.displayName)")
            } else {
                state = .targeting(fileName: virtualHit.title, fileCount: 1)
            }
            return
        } else {
            lockedVirtualSnackID = nil
        }

        if let detectedURL = DesktopFileDetector.shared.detectFileUnderCursor(appKitScreenPoint: cursorScreenPoint)
            ?? DesktopFileDetector.shared.detectFileUnderCursor(appKitScreenPoint: headPoint) {
            if lockedTargetFileURL != detectedURL {
                lockedTargetFileURL = detectedURL
                CatSoundEngine.shared.playTargetLock()
            }
            if isOptionPressed {
                let sType = SnackIconManager.shared.snackType(for: detectedURL)
                state = .sniffingToEnchant(
                    fileName: detectedURL.lastPathComponent,
                    snackName: "\(sType.emoji)\(sType.displayName)"
                )
            } else {
                state = .targeting(fileName: detectedURL.lastPathComponent, fileCount: 1)
            }
            return
        } else {
            lockedTargetFileURL = nil
        }

        // 未锁定文件时，根据距离划分为 Pulling (0%~40%) 与 Stretching (40%~100%)
        if ratio < 0.40 {
            state = .pulling(progress: ratio)
        } else {
            if !hasPlayedProtestMeowInCurrentStretch {
                hasPlayedProtestMeowInCurrentStretch = true
                CatSoundEngine.shared.playProtestMeow()
            }
            state = .stretching(progress: ratio)
        }
    }

    public func endHeadDrag(atScreenPoint cursorScreenPoint: CGPoint, isOptionPressed: Bool = NSEvent.modifierFlags.contains(.option)) {
        guard isDraggingHead else { return }
        isDraggingHead = false
        arePawsClingingToRim = false

        let swallowPoint = currentHeadScreenPoint
        let isEnchantMode: Bool = {
            if isOptionPressed { return true }
            if case .sniffingToEnchant = state { return true }
            return false
        }()

        // 0. 若按住 Option 处于“猫爪轻碰点化”模式：将目标文件图标转化为对应猫零食，不删除文件！
        if isEnchantMode {
            let targetURL = lockedTargetFileURL
                ?? DesktopFileDetector.shared.detectFileUnderCursor(appKitScreenPoint: cursorScreenPoint)
            lockedTargetFileURL = nil
            lockedVirtualSnackID = nil

            if let url = targetURL, let snackType = SnackIconManager.shared.turnToSnack(at: url) {
                triggerEnchantPoof(
                    fileName: url.lastPathComponent,
                    snackType: snackType,
                    at: swallowPoint
                )
                return
            }
        }

        // 1. 若锁定了桌面虚拟零食团
        if let snackID = lockedVirtualSnackID,
           let idx = virtualSnacks.firstIndex(where: { $0.id == snackID }) {
            let snack = virtualSnacks.remove(at: idx)
            let sType = snack.linkedFileURL.map { SnackIconManager.shared.snackType(for: $0) } ?? .driedFish
            if let fileURL = snack.linkedFileURL {
                TrashService.shared.moveFilesToTrash([fileURL])
            } else {
                CatPreferences.shared.totalTrashedCount += 1
                TrashService.shared.lastStatusMessage = "已一口吞掉测试废纸团「\(snack.title)」！"
            }
            lockedVirtualSnackID = nil
            lockedTargetFileURL = nil
            triggerChompAndSnap(fileName: snack.title, snackType: sType, chompScreenLocation: swallowPoint)
            return
        }

        // 2. 若通过 Accessibility API 锁定了真实桌面/Finder 文件
        let finalURL = lockedTargetFileURL
            ?? DesktopFileDetector.shared.detectFileUnderCursor(appKitScreenPoint: cursorScreenPoint)
        lockedTargetFileURL = nil

        if let targetURL = finalURL {
            let sType = SnackIconManager.shared.snackType(for: targetURL)
            let result = TrashService.shared.moveFilesToTrash([targetURL])
            if result.trashedCount > 0 {
                triggerChompAndSnap(
                    fileName: result.firstFileName ?? targetURL.lastPathComponent,
                    snackType: sType,
                    chompScreenLocation: swallowPoint
                )
                return
            }
        }

        // 3. 拖到空白处松手：触发取消回弹 + 傲娇白眼表情
        let pullDist = currentStretchDistance
        if pullDist > 22 {
            let morph = CatPreferences.shared.selectedMorph
            CatSoundEngine.shared.playCancelBoing(morph: morph)
            jiggleAmplitude = min(pullDist / 160.0, 2.2)
            state = .cancelled
            scheduleReturnToIdle(after: 1.45)
        } else {
            // 轻点抚摸猫头：触发呼噜声与开心微震
            CatSoundEngine.shared.playPurr()
            jiggleAmplitude = 0.65
            spawnHeartParticle(at: swallowPoint, text: "呼噜~ ♥")
            state = .idle
        }
    }

    // MARK: - 模式 B：外部拖拽文件投喂 (Passive Drag & Drop)
    public func onExternalFilesEntered(fileNames: [String]) {
        stateResetTask?.cancel()
        let wasHovering = isExternalFileHovering
        isExternalFileHovering = true
        let first = fileNames.first ?? "文件"
        state = .targeting(fileName: first, fileCount: max(fileNames.count, 1))
        externalHoverTarget = CGVector(dx: 0, dy: 28)
        if !wasHovering {
            CatSoundEngine.shared.playTargetLock()
        }
    }

    public func onExternalFilesUpdated(cursorScreenPoint: CGPoint, fileNames: [String]) {
        isExternalFileHovering = true
        let anchor = CGPoint(x: bucketScreenCenter.x, y: bucketScreenCenter.y + restingHeadYOffset)
        let dx = (cursorScreenPoint.x - anchor.x) * 0.35
        let dy = max(14, (cursorScreenPoint.y - anchor.y) * 0.42 + 20)
        externalHoverTarget = CGVector(
            dx: min(max(dx, -55), 55),
            dy: min(max(dy, 12), 72)
        )
        let first = fileNames.first ?? "文件"
        if case .targeting = state {
            // 保持锁定状态
        } else {
            state = .targeting(fileName: first, fileCount: max(fileNames.count, 1))
        }
    }

    public func onExternalFilesExited() {
        isExternalFileHovering = false
        externalHoverTarget = .zero
        if !isDraggingHead {
            state = .cancelled
            CatSoundEngine.shared.playCancelBoing(morph: CatPreferences.shared.selectedMorph)
            scheduleReturnToIdle(after: 1.1)
        }
    }

    public func onExternalFilesDropped(urls: [URL]) -> Bool {
        isExternalFileHovering = false
        externalHoverTarget = .zero
        let firstSnackType = urls.first.map { SnackIconManager.shared.snackType(for: $0) } ?? .freezeDried
        let result = TrashService.shared.moveFilesToTrash(urls)
        guard result.trashedCount > 0 else {
            state = .cancelled
            scheduleReturnToIdle(after: 1.0)
            return false
        }

        // 猫猫向上一跃接住文件吞下，再由弹簧回弹落回桶中
        headDisplacement = CGVector(dx: 0, dy: 42)
        headVelocity = CGVector(dx: 0, dy: -260)
        let displayTitle = result.trashedCount > 1
            ? "\(result.firstFileName ?? "文件") 等 \(result.trashedCount) 项"
            : (result.firstFileName ?? "文件")
        triggerChompAndSnap(
            fileName: displayTitle,
            snackType: firstSnackType,
            chompScreenLocation: currentHeadScreenPoint
        )
        return true
    }

    // MARK: - 猫爪点化魔法反馈 ("嘭~" Smoke Poof -> 转化为零食图标)
    public func triggerEnchantPoof(fileName: String, snackType: SnackType, at screenPoint: CGPoint) {
        stateResetTask?.cancel()
        state = .enchanted(fileName: fileName, snackName: "\(snackType.emoji)\(snackType.displayName)")
        jiggleAmplitude = 1.6
        CatSoundEngine.shared.playEnchantPoof()
        TrashService.shared.lastStatusMessage = "✨ 嘭！已将「\(fileName)」点化为\(snackType.emoji)\(snackType.displayName)！"

        // 生成“嘭~”烟雾泡泡与零食 Emoji 粒子
        particles.append(
            EffectParticle(
                position: CGPoint(x: screenPoint.x, y: screenPoint.y + 20),
                velocity: CGVector(dx: 0, dy: 45),
                scale: 1.1,
                opacity: 1.0,
                age: 0,
                lifetime: 1.25,
                kind: .heartOrText("嘭! \(snackType.emoji)\(snackType.displayName)")
            )
        )
        for _ in 0..<8 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 45...135)
            particles.append(
                EffectParticle(
                    position: screenPoint,
                    velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed + 20),
                    scale: CGFloat.random(in: 0.8...1.4),
                    opacity: 0.95,
                    age: 0,
                    lifetime: Double.random(in: 0.55...0.95),
                    kind: Bool.random() ? .burpBubble : .sparkle
                )
            )
        }

        scheduleReturnToIdle(after: 1.6)
    }

    // MARK: - 吞食、咀嚼与打嗝反馈 (Chomp & Snap)
    public func triggerChompAndSnap(
        fileName: String,
        snackType: SnackType = .freezeDried,
        chompScreenLocation: CGPoint
    ) {
        stateResetTask?.cancel()
        state = .chomping(fileName: fileName)
        jiggleAmplitude = 2.0
        CatSoundEngine.shared.playSnackChomp(for: snackType)

        // 1. 吞食瞬间的零食专属配色碎屑与星光粒子爆发
        spawnChompParticles(at: chompScreenLocation, primaryColor: snackType.crumbColor)

        // 2. 0.52 秒后在桶口冒出饱嗝气泡 ("嗝~")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            let burpOrigin = CGPoint(
                x: self.bucketScreenCenter.x + 22,
                y: self.bucketScreenCenter.y + self.restingHeadYOffset + 18
            )
            self.spawnBurpParticles(at: burpOrigin)
        }

        scheduleReturnToIdle(after: 1.85)
    }

    private func scheduleReturnToIdle(after seconds: TimeInterval) {
        stateResetTask?.cancel()
        stateResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if !self.isDraggingHead && !self.isExternalFileHovering {
                self.state = .idle
            }
        }
    }

    // MARK: - 生成桌面测试废纸团（同时生成真实桌面文件并点化为零食图标 + 屏幕悬浮可捕食零食气泡）
    public func spawnInteractiveTestSnack() {
        let createdURL = TrashService.shared.createSampleDesktopTrashFile()
        if let createdURL {
            _ = SnackIconManager.shared.turnToSnack(at: createdURL)
        }
        let emojis = ["🐟", "🥫", "🍣", "🌿", "🍱"]
        let angle = CGFloat.random(in: (CGFloat.pi * 0.58)...(CGFloat.pi * 0.92))
        let distance = CGFloat.random(in: 190...320)

        var targetX = bucketScreenCenter.x + cos(angle) * distance
        var targetY = bucketScreenCenter.y + sin(angle) * distance

        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let visible = screen.visibleFrame.insetBy(dx: 80, dy: 80)
            targetX = min(max(targetX, visible.minX), visible.maxX)
            targetY = min(max(targetY, visible.minY), visible.maxY)
        }

        let title = createdURL?.lastPathComponent ?? "小鱼干废纸团.txt"
        let snack = VirtualSnackItem(
            screenPosition: CGPoint(x: targetX, y: targetY),
            title: title,
            emoji: emojis.randomElement() ?? "🐟",
            linkedFileURL: createdURL
        )
        virtualSnacks.append(snack)
    }

    private func hitTestVirtualSnack(near point: CGPoint) -> VirtualSnackItem? {
        for snack in virtualSnacks {
            if hypot(point.x - snack.screenPosition.x, point.y - snack.screenPosition.y) < 54 {
                return snack
            }
        }
        return nil
    }

    // MARK: - 粒子生成器
    private func spawnChompParticles(at screenPoint: CGPoint, primaryColor: Color = Color(red: 1.0, green: 0.82, blue: 0.32)) {
        let colors: [Color] = [
            primaryColor,
            Color(red: 1.0, green: 0.82, blue: 0.32),
            Color(red: 1.0, green: 0.55, blue: 0.45),
            .white
        ]
        for _ in 0..<12 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...190)
            particles.append(
                EffectParticle(
                    position: screenPoint,
                    velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed + 40),
                    scale: CGFloat.random(in: 0.7...1.35),
                    opacity: 1.0,
                    age: 0,
                    lifetime: Double.random(in: 0.45...0.75),
                    kind: Bool.random() ? .crumb(colors.randomElement()!) : .sparkle
                )
            )
        }
    }

    private func spawnBurpParticles(at screenPoint: CGPoint) {
        particles.append(
            EffectParticle(
                position: screenPoint,
                velocity: CGVector(dx: 14, dy: 42),
                scale: 1.0,
                opacity: 1.0,
                age: 0,
                lifetime: 1.25,
                kind: .heartOrText("嗝~ 💨")
            )
        )
        for i in 0..<4 {
            particles.append(
                EffectParticle(
                    position: CGPoint(x: screenPoint.x + CGFloat(i * 8 - 12), y: screenPoint.y - 6),
                    velocity: CGVector(dx: CGFloat.random(in: -18...22), dy: CGFloat.random(in: 35...65)),
                    scale: CGFloat.random(in: 0.6...1.2),
                    opacity: 0.9,
                    age: 0,
                    lifetime: Double.random(in: 0.8...1.2),
                    kind: .burpBubble
                )
            )
        }
    }

    private func spawnHeartParticle(at screenPoint: CGPoint, text: String) {
        particles.append(
            EffectParticle(
                position: CGPoint(x: screenPoint.x, y: screenPoint.y + 34),
                velocity: CGVector(dx: 0, dy: 38),
                scale: 1.0,
                opacity: 1.0,
                age: 0,
                lifetime: 1.0,
                kind: .heartOrText(text)
            )
        )
    }
}
