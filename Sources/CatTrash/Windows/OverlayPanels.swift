import AppKit
import SwiftUI

/// 透明无边框悬浮面板：跨多显示器独立渲染 + 全局鼠标穿透与文件拖拽投喂
@MainActor
public final class CatOverlayWindowController: NSObject {
    public static let shared = CatOverlayWindowController()

    private var overlayPanels: [NSPanel] = []
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var screenChangeObserver: Any?
    private var lastMouseMoveCheckTime: TimeInterval = 0

    private override init() {
        super.init()
    }

    public func showOverlay() {
        guard overlayPanels.isEmpty else { return }
        buildPanelsForConnectedScreens()
        startMousePassThroughMonitors()
        startScreenChangeObservation()
    }

    /// 为所有已连接的显示器（主屏、副屏、外接竖屏等）分别构建独立的透明悬浮层
    private func buildPanelsForConnectedScreens() {
        for panel in overlayPanels {
            panel.orderOut(nil)
            panel.close()
        }
        overlayPanels.removeAll()

        for screen in NSScreen.screens {
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
            // 解决跨显示器核心问题 1：在其他屏幕或应用获得焦点时不自动隐藏
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.ignoresMouseEvents = true

            let containerView = CatDropAndHitTestView(
                frame: NSRect(origin: .zero, size: screen.frame.size),
                screenFrame: screen.frame
            )
            let hostingView = NSHostingView(rootView: CatTrashSceneView(screenFrame: screen.frame))
            hostingView.frame = containerView.bounds
            hostingView.autoresizingMask = [.width, .height]
            containerView.addSubview(hostingView)

            panel.contentView = containerView
            panel.orderFrontRegardless()
            overlayPanels.append(panel)
        }
    }

    private func startScreenChangeObservation() {
        guard screenChangeObserver == nil else { return }
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreensChanged()
            }
        }
    }

    private func handleScreensChanged() {
        buildPanelsForConnectedScreens()
        // 若当前垃圾桶坐标不再位于任何屏幕可视区域内，自动吸附回最适合的屏幕右下角
        let currentCenter = CatPhysicsEngine.shared.bucketScreenCenter
        let isOnScreen = NSScreen.screens.contains { $0.frame.contains(currentCenter) }
        if !isOnScreen {
            CatPhysicsEngine.shared.snapBucketToBottomRightCorner()
        }
        updateMouseEventInterception()
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

    private func setIgnoresMouseEvents(_ panel: NSPanel, _ ignore: Bool) {
        if panel.ignoresMouseEvents != ignore {
            panel.ignoresMouseEvents = ignore
        }
    }

    private func handleMonitoredMouseEvent(_ event: NSEvent) {
        let physics = CatPhysicsEngine.shared
        let mouse = NSEvent.mouseLocation
        let isOption = event.modifierFlags.contains(.option)

        // 若正在进行模式 A（拉拽猫头），保持全屏窗口穿透以便底层桌面文件可被无遮挡探测，同时实时更新猫头坐标与 Option 点化状态
        if physics.isDraggingHead {
            for panel in overlayPanels {
                setIgnoresMouseEvents(panel, true)
            }
            if event.type == .leftMouseDragged || event.type == .flagsChanged {
                physics.updateHeadDrag(toScreenPoint: mouse, isOptionPressed: isOption)
            } else if event.type == .leftMouseUp {
                physics.endHeadDrag(atScreenPoint: mouse, isOptionPressed: isOption)
                updateMouseEventInterception()
            }
            return
        }

        // 高回报率鼠标节流：非点击/非拖拽的普通 mouseMoved 事件限制在约 40Hz，避免 1000Hz 鼠标高频触发主线程与 WindowServer IPC
        if event.type == .mouseMoved {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastMouseMoveCheckTime >= 0.024 else { return }
            lastMouseMoveCheckTime = now
        }

        // 若悬浮菜单正打开，用户在空白区域或外部点击鼠标，则自动收起悬浮菜单
        if physics.isFloatingMenuVisible && (event.type == .leftMouseDown || event.type == .rightMouseDown) {
            let bucket = physics.bucketScreenCenter
            let s = max(physics.scale, 0.85)
            let dx = mouse.x - bucket.x
            let dy = mouse.y - bucket.y
            let style = CatPreferences.shared.selectedBinStyle
            let inControls = FloatingControlsLayout(style: style).contains(
                screenPoint: mouse, bucketCenter: bucket, scale: physics.scale)
            let nearBucket = hypot(dx, dy) < (style == .greenWheelieBin ? 145 : 105) * s

            if !inControls && !nearBucket {
                physics.isFloatingMenuVisible = false
            }
        }

        updateMouseEventInterception()
    }

    private func updateMouseEventInterception() {
        let physics = CatPhysicsEngine.shared
        let mouse = NSEvent.mouseLocation
        let bucket = physics.bucketScreenCenter
        let head = physics.currentHeadScreenPoint
        let s = max(physics.scale, 0.85)

        // 当鼠标进入猫桶警戒半径（如准备盯梢或点击拖拽）时，立即从 12Hz 节能待机唤醒至 60Hz 满帧响应
        let distToBucket = hypot(mouse.x - bucket.x, mouse.y - bucket.y)
        if distToBucket < 230 * s {
            physics.wakeUpSimulationIfNeeded()
        }

        for panel in overlayPanels {
            guard let screen = panel.screen ?? NSScreen.screens.first(where: { $0.frame == panel.frame }) else {
                setIgnoresMouseEvents(panel, true)
                continue
            }

            let isMouseOnThisScreen = screen.frame.contains(mouse)

            if physics.isDraggingHead {
                setIgnoresMouseEvents(panel, true)
                continue
            }

            if (physics.isDraggingBucket || physics.isExternalFileHovering) && isMouseOnThisScreen {
                setIgnoresMouseEvents(panel, false)
                continue
            }

            if isMouseOnThisScreen {
                let dx = mouse.x - bucket.x
                let dy = mouse.y - bucket.y
                let style = CatPreferences.shared.selectedBinStyle

                var nearFloatingControls = false
                if physics.isFloatingMenuVisible {
                    nearFloatingControls = FloatingControlsLayout(style: style).contains(
                        screenPoint: mouse, bucketCenter: bucket, scale: physics.scale)
                }

                let nearBucket = hypot(dx, dy) < (style == .greenWheelieBin ? 145 : 105) * s
                let nearHead = hypot(mouse.x - head.x, mouse.y - head.y) < 72 * s

                setIgnoresMouseEvents(panel, !(nearBucket || nearHead || nearFloatingControls))
            } else {
                setIgnoresMouseEvents(panel, true)
            }
        }
    }
}

// MARK: - 支持模式 A 拽猫头 + 模式 B 拖放文件投喂的交互容器视图
@MainActor
final class CatDropAndHitTestView: NSView {
    private var dragMode: DragMode = .none
    let screenFrame: CGRect

    private enum DragMode {
        case none
        case pullingCatHead
        case movingBucket(startOffset: CGVector)
    }

    init(frame frameRect: NSRect, screenFrame: CGRect) {
        self.screenFrame = screenFrame
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

        // 如果周围悬浮按钮处于打开状态，点击命中三大群组时派发给 SwiftUI 宿主视图
        if physics.isFloatingMenuVisible && FloatingControlsLayout(style: style).contains(
            screenPoint: screenPt, bucketCenter: bucketPt, scale: physics.scale) {
            if let hosting = subviews.first {
                return hosting.hitTest(point) ?? hosting
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
