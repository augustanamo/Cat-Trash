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

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        setupStatusBarItem()
        setupSettingsWindow()
        CatOverlayWindowController.shared.showOverlay()
    }

    func applicationWillTerminate(_ notification: Notification) {
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

    /// 使用独立毛玻璃悬浮窗代替容易被全屏层挤出屏幕顶部的 NSPopover，确保位置 100% 居中于菜单栏图标正下方
    private func setupSettingsWindow() {
        let panelWidth: CGFloat = 424
        let panelHeight: CGFloat = 480

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
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
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showQuickContextMenu()
        } else {
            toggleSettingsWindow(relativeTo: sender)
        }
    }

    private func toggleSettingsWindow(relativeTo button: NSStatusBarButton) {
        guard let panel = settingsWindow else { return }

        if panel.isVisible {
            panel.orderOut(nil)
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
        let targetY = visibleFrame.maxY - panelSize.height - 8

        panel.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func showQuickContextMenu() {
        let menu = CatContextMenuBuilder.shared.buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    public func openSettingsWindow() {
        if let button = statusItem.button {
            if settingsWindow?.isVisible == true {
                settingsWindow?.orderOut(nil)
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
