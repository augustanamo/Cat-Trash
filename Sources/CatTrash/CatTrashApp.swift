import AppKit
import SwiftUI

@main
@MainActor
struct CatTrashMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = CatTrashAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class CatTrashAppDelegate: NSObject, NSApplicationDelegate {
    public static weak var shared: CatTrashAppDelegate?
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSPanel?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        setupStatusBarItem()
        setupSettingsWindow()
        CatOverlayWindowController.shared.showOverlay()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopOutsideClickMonitor()
        // 应用退出即自动还原桌面所有自定义零食图标，确保桌面整洁受控
        SnackIconManager.shared.resetAllDesktopIcons()
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Cat Trash")
            button.title = " CatTrash"
            button.action = #selector(handleStatusBarClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    /// 使用固定位置的毛玻璃 HUD 菜单栏面板，左右键点击统一呼出，不可被随意拖拽，点击外部自动收起
    private func setupSettingsWindow() {
        let panelWidth: CGFloat = 416
        let panelHeight: CGFloat = 560

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingController = NSHostingController(rootView: PreferencesView())
        panel.contentViewController = hostingController
        self.settingsWindow = panel
    }

    @objc private func handleStatusBarClick(_ sender: NSStatusBarButton) {
        // 左右键点击统一呼出/收起偏好设置大面板，彻底消除多面板重叠困扰
        toggleSettingsWindow(relativeTo: sender)
    }

    private func toggleSettingsWindow(relativeTo button: NSStatusBarButton) {
        guard let panel = settingsWindow else { return }

        if panel.isVisible {
            closeSettingsWindow()
            return
        }

        DesktopFileDetector.shared.refreshTrustStatus()

        let screen = button.window?.screen ?? NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = panel.frame.size

        // 计算菜单栏按钮正下方的屏幕坐标，并严格限制在 visibleFrame 内部，绝不超出屏幕顶部或右侧
        var targetX = visibleFrame.maxX - panelSize.width - 16
        if let btnWindow = button.window {
            let btnFrame = btnWindow.frame
            targetX = btnFrame.midX - panelSize.width * 0.5
        }
        targetX = min(max(targetX, visibleFrame.minX + 12), visibleFrame.maxX - panelSize.width - 12)
        let targetY = visibleFrame.maxY - panelSize.height - 6

        panel.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        panel.invalidateShadow()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        startOutsideClickMonitor()
    }

    public func closeSettingsWindow() {
        stopOutsideClickMonitor()
        settingsWindow?.orderOut(nil)
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()

        // 全局监听：当用户在其他窗口或桌面点击时，自动收起设置面板
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self = self, let panel = self.settingsWindow, panel.isVisible else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                if let button = self.statusItem.button, let btnWindow = button.window {
                    let btnFrame = btnWindow.convertToScreen(button.bounds)
                    if btnFrame.contains(mouseLocation) {
                        return
                    }
                }
                self.closeSettingsWindow()
            }
        }

        // 本地监听：当用户在本应用内部（如桌面交互层）点击时，自动收起设置面板
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, let panel = self.settingsWindow, panel.isVisible else { return event }
            let mouseLocation = NSEvent.mouseLocation
            if !panel.frame.contains(mouseLocation) {
                if let button = self.statusItem.button, let btnWindow = button.window {
                    let btnFrame = btnWindow.convertToScreen(button.bounds)
                    if btnFrame.contains(mouseLocation) {
                        return event
                    }
                }
                self.closeSettingsWindow()
            }
            return event
        }
    }

    private func stopOutsideClickMonitor() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    public func openSettingsWindow() {
        if let button = statusItem.button {
            if settingsWindow?.isVisible == true {
                closeSettingsWindow()
                return
            }
            toggleSettingsWindow(relativeTo: button)
        }
    }

    @objc private func toggleSnackStallFromMenu() {
        SnackIconManager.shared.toggleSnackStall()
    }

    @objc private func resetAllIconsFromMenu() {
        SnackIconManager.shared.resetAllDesktopIcons()
    }

    @objc private func openSettingsFromMenu() {
        if let button = statusItem.button {
            if settingsWindow?.isVisible == true { return }
            toggleSettingsWindow(relativeTo: button)
        }
    }

    @objc private func spawnTestSnack() {
        CatPhysicsEngine.shared.spawnInteractiveTestSnack()
    }

    @objc private func resetBucketCorner() {
        CatPreferences.shared.placementMode = .dockBottomRight
        CatPhysicsEngine.shared.snapBucketToBottomRightCorner()
    }

    @objc private func openSystemTrash() {
        TrashService.shared.openSystemTrash()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
