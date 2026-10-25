import AppKit
import SwiftUI

/// 透明无边框悬浮面板：负责全屏渲染拉伸动画 + 仅在猫猫与网格桶区域拦截鼠标与文件拖放事件
@MainActor
public final class CatOverlayWindowController: NSObject {
    public static let shared = CatOverlayWindowController()

    private var overlayPanel: NSPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    private override init() {
        super.init()
    }

    public func showOverlay() {
        guard overlayPanel == nil else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = true

        let containerView = CatDropAndHitTestView(frame: screen.frame)
        let hostingView = NSHostingView(rootView: CatTrashSceneView(canvasSize: screen.frame.size))
        hostingView.frame = containerView.bounds
        hostingView.autoresizingMask = [.width, .height]
        containerView.addSubview(hostingView)

        panel.contentView = containerView
        panel.orderFrontRegardless()
        self.overlayPanel = panel

        startMousePassThroughMonitors()
    }

    /// 动态切换鼠标穿透，并在模式 A 拖拽猫头开启穿透时依然能全局追踪鼠标移动与松手
    private func startMousePassThroughMonitors() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .flagsChanged]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handleMonitoredMouseEvent(event)
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .flagsChanged]
        ) { [weak self] event in
            Task { @MainActor in
                self?.handleMonitoredMouseEvent(event)
            }
            return event
        }
    }

    private func handleMonitoredMouseEvent(_ event: NSEvent) {
        let physics = CatPhysicsEngine.shared
        let mouse = NSEvent.mouseLocation
        let isOption = event.modifierFlags.contains(.option)

        // 若正在进行模式 A（拉拽猫头），保持窗口穿透以便底层桌面文件可被无遮挡探测，同时实时更新猫头坐标与 Option 点化状态
        if physics.isDraggingHead {
            overlayPanel?.ignoresMouseEvents = true
            if event.type == .leftMouseDragged || event.type == .flagsChanged {
                physics.updateHeadDrag(toScreenPoint: mouse, isOptionPressed: isOption)
            } else if event.type == .leftMouseUp {
                physics.endHeadDrag(atScreenPoint: mouse, isOptionPressed: isOption)
                updateMouseEventInterception()
            }
            return
        }

        // 若悬浮菜单正打开，用户在空白区域或外部点击鼠标，则自动收起悬浮菜单
        if physics.isFloatingMenuVisible && (event.type == .leftMouseDown || event.type == .rightMouseDown) {
            let bucket = physics.bucketScreenCenter
            let s = max(physics.scale, 0.85)
            let dx = mouse.x - bucket.x
            let dy = mouse.y - bucket.y
            let style = CatPreferences.shared.selectedBinStyle
            let sideClearance = style.sideClearance * s
            let topY = -style.topSliderOffsetY * s

            let inTopSlider = abs(dx) <= 95 * s && dy >= topY - 14 * s && dy <= topY + 14 * s
            let inRightBins = dx >= sideClearance - 16 * s && dx <= sideClearance + 16 * s && abs(dy) <= 72 * s
            let inLeftControls = dx >= -sideClearance - 16 * s && dx <= -sideClearance + 16 * s && abs(dy) <= 36 * s
            let nearBucket = hypot(dx, dy) < (style == .greenWheelieBin ? 145 : 105) * s

            if !inTopSlider && !inRightBins && !inLeftControls && !nearBucket {
                physics.isFloatingMenuVisible = false
            }
        }

        updateMouseEventInterception()
    }

    private func updateMouseEventInterception() {
        guard let panel = overlayPanel else { return }
        let physics = CatPhysicsEngine.shared

        if physics.isDraggingHead {
            // 模式 A 拽猫头时必须开启穿透，防止全屏窗口挡住底层桌面图标探测
            panel.ignoresMouseEvents = true
            return
        }

        if physics.isDraggingBucket || physics.isExternalFileHovering {
            panel.ignoresMouseEvents = false
            return
        }

        let mouse = NSEvent.mouseLocation
        let bucket = physics.bucketScreenCenter
        let head = physics.currentHeadScreenPoint
        let s = max(physics.scale, 0.85)

        // 给桶和猫头留出充足的接收范围，同时包含桌面虚拟测试废纸团的点击/悬停
        let dx = mouse.x - bucket.x
        let dy = mouse.y - bucket.y
        let style = CatPreferences.shared.selectedBinStyle
        let sideClearance = style.sideClearance * s
        let topY = -style.topSliderOffsetY * s

        var nearFloatingControls = false
        if physics.isFloatingMenuVisible {
            let inTopSlider = abs(dx) <= 95 * s && dy >= topY - 14 * s && dy <= topY + 14 * s
            let inRightBins = dx >= sideClearance - 16 * s && dx <= sideClearance + 16 * s && abs(dy) <= 72 * s
            let inLeftControls = dx >= -sideClearance - 16 * s && dx <= -sideClearance + 16 * s && abs(dy) <= 36 * s

            nearFloatingControls = inTopSlider || inRightBins || inLeftControls
        }

        let nearBucket = hypot(dx, dy) < (style == .greenWheelieBin ? 145 : 105) * s
        let nearHead = hypot(mouse.x - head.x, mouse.y - head.y) < 72 * s

        panel.ignoresMouseEvents = !(nearBucket || nearHead || nearFloatingControls)
    }
}

// MARK: - 支持模式 A 拽猫头 + 模式 B 拖放文件投喂的交互容器视图
@MainActor
final class CatDropAndHitTestView: NSView {
    private var dragMode: DragMode = .none

    private enum DragMode {
        case none
        case pullingCatHead
        case movingBucket(startOffset: CGVector)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let screenPt = window?.convertToScreen(NSRect(origin: point, size: .zero)).origin ?? NSEvent.mouseLocation
        let physics = CatPhysicsEngine.shared
        let headPt = physics.currentHeadScreenPoint
        let bucketPt = physics.bucketScreenCenter
        let s = max(physics.scale, 0.85)

        let dx = screenPt.x - bucketPt.x
        let dy = screenPt.y - bucketPt.y
        let style = CatPreferences.shared.selectedBinStyle
        let sideClearance = style.sideClearance * s
        let topY = -style.topSliderOffsetY * s

        // 如果周围悬浮按钮处于打开状态，点击命中三大群组时派发给 SwiftUI 宿主视图
        if physics.isFloatingMenuVisible {
            let inTopSlider = abs(dx) <= 95 * s && dy >= topY - 14 * s && dy <= topY + 14 * s
            let inRightBins = dx >= sideClearance - 16 * s && dx <= sideClearance + 16 * s && abs(dy) <= 72 * s
            let inLeftControls = dx >= -sideClearance - 16 * s && dx <= -sideClearance + 16 * s && abs(dy) <= 36 * s

            if inTopSlider || inRightBins || inLeftControls {
                if let hosting = subviews.first {
                    return hosting.hitTest(point) ?? hosting
                }
            }
        }

        let nearBucket = hypot(dx, dy) < (style == .greenWheelieBin ? 145 : 105) * s
        let nearHead = hypot(screenPt.x - headPt.x, screenPt.y - headPt.y) < 72 * s

        if nearBucket || nearHead {
            return self
        }
        return nil
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        nil
    }

    override func rightMouseDown(with event: NSEvent) {
        CatSoundEngine.shared.playPurr()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        CatPhysicsEngine.shared.isFloatingMenuVisible.toggle()
    }

    // MARK: - 模式 A：按下并向外拖拽猫头（支持按住 Option 点化零食） / 拖动桶身位置
    override func mouseDown(with event: NSEvent) {
        let screenPt = NSEvent.mouseLocation
        let physics = CatPhysicsEngine.shared
        let headPt = physics.currentHeadScreenPoint
        let bucketPt = physics.bucketScreenCenter

        let s = max(physics.scale, 0.85)
        let isCommandPressed = event.modifierFlags.contains(.command)
        let isBottomBucketClick = screenPt.y < bucketPt.y - 6 * s && hypot(screenPt.x - bucketPt.x, screenPt.y - bucketPt.y) < 52 * s

        // 如果悬浮菜单处于显示状态，点击猫头或桶身时自然收起
        if physics.isFloatingMenuVisible {
            physics.isFloatingMenuVisible = false
        }

        if isCommandPressed || (CatPreferences.shared.placementMode == .freeFloating && isBottomBucketClick) {
            CatPreferences.shared.placementMode = .freeFloating
            physics.isDraggingBucket = true
            dragMode = .movingBucket(
                startOffset: CGVector(dx: bucketPt.x - screenPt.x, dy: bucketPt.y - screenPt.y)
            )
            return
        }

        // 点击猫头或桶口上方区域 -> 启动模式 A 橡皮筋拽猫头（若按住 Option 则进入“轻碰点化零食”模式）
        if hypot(screenPt.x - headPt.x, screenPt.y - headPt.y) < 62 * s ||
           hypot(screenPt.x - bucketPt.x, screenPt.y - bucketPt.y) < 68 * s {
            dragMode = .pullingCatHead
            window?.ignoresMouseEvents = true
            physics.beginHeadDrag()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let screenPt = NSEvent.mouseLocation
        let physics = CatPhysicsEngine.shared
        let isOption = event.modifierFlags.contains(.option)

        switch dragMode {
        case .pullingCatHead:
            physics.updateHeadDrag(toScreenPoint: screenPt, isOptionPressed: isOption)
        case .movingBucket(let offset):
            let newCenter = CGPoint(x: screenPt.x + offset.dx, y: screenPt.y + offset.dy)
            physics.bucketScreenCenter = newCenter
            CatPreferences.shared.customBucketOriginX = newCenter.x
            CatPreferences.shared.customBucketOriginY = newCenter.y
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        let screenPt = NSEvent.mouseLocation
        let physics = CatPhysicsEngine.shared
        let isOption = event.modifierFlags.contains(.option)

        switch dragMode {
        case .pullingCatHead:
            physics.endHeadDrag(atScreenPoint: screenPt, isOptionPressed: isOption)
        case .movingBucket:
            physics.isDraggingBucket = false
        case .none:
            break
        }
        dragMode = .none
    }

    // MARK: - 模式 B：Finder 文件直接拖放投喂 (NSDraggingDestination)
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = extractFileURLs(from: sender)
        guard !urls.isEmpty else { return [] }
        CatPhysicsEngine.shared.onExternalFilesEntered(fileNames: urls.map(\.lastPathComponent))
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = extractFileURLs(from: sender)
        guard !urls.isEmpty else { return [] }
        CatPhysicsEngine.shared.onExternalFilesUpdated(
            cursorScreenPoint: NSEvent.mouseLocation,
            fileNames: urls.map(\.lastPathComponent)
        )
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        CatPhysicsEngine.shared.onExternalFilesExited()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = extractFileURLs(from: sender)
        guard !urls.isEmpty else { return false }
        return CatPhysicsEngine.shared.onExternalFilesDropped(urls: urls)
    }

    private func extractFileURLs(from sender: NSDraggingInfo) -> [URL] {
        let pasteboard = sender.draggingPasteboard
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] else {
            return []
        }
        return urls
    }
}
