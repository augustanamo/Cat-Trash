import AppKit

/// 统一右键上下文菜单构建器：支持在桌面猫猫/废纸篓、以及菜单栏图标右键触发形态与垃圾桶样式切换
@MainActor
public final class CatContextMenuBuilder: NSObject {
    public static let shared = CatContextMenuBuilder()

    private override init() {
        super.init()
    }

    public func buildMenu() -> NSMenu {
        let menu = NSMenu(title: "Cat Trash Context Menu")
        let prefs = CatPreferences.shared

        // 1. 猫咪形态滑动切换进度条 (各档位猫猫头 + 左侧身体拉伸样式)
        let sliderHost = CatMorphSliderHostView()
        let sliderItem = NSMenuItem()
        sliderItem.view = sliderHost
        menu.addItem(sliderItem)

        menu.addItem(.separator())

        // 2. 垃圾桶样式子菜单
        let binMenuItem = NSMenuItem(title: "🗑️ 垃圾桶样式", action: nil, keyEquivalent: "")
        let binSubmenu = NSMenu(title: "垃圾桶样式")
        for style in TrashBinStyle.allCases {
            let emoji: String
            switch style {
            case .macOSFrosted: emoji = "🧊"
            case .greenWheelieBin: emoji = "🗑️"
            case .streetMetalBox: emoji = "📮"
            case .metalMesh: emoji = "🌐"
            }
            let item = NSMenuItem(
                title: "\(emoji) \(style.displayName)",
                action: #selector(handleBinStyleSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = style
            item.state = (prefs.selectedBinStyle == style) ? .on : .off
            binSubmenu.addItem(item)
        }
        binMenuItem.submenu = binSubmenu
        menu.addItem(binMenuItem)

        menu.addItem(.separator())

        // 3. 互动与桌面零食快捷功能 (精简文案)
        let feedItem = NSMenuItem(
            title: "🐟 投喂测试零食",
            action: #selector(handleSpawnSnack),
            keyEquivalent: "t"
        )
        feedItem.target = self
        menu.addItem(feedItem)

        let isStall = SnackIconManager.shared.isSnackStallActive
        let stallTitle = isStall ? "🍢 关闭桌面零食摊" : "✨ 开启桌面零食摊"
        let stallItem = NSMenuItem(
            title: stallTitle,
            action: #selector(handleToggleSnackStall),
            keyEquivalent: "s"
        )
        stallItem.target = self
        menu.addItem(stallItem)

        let resetIconsItem = NSMenuItem(
            title: "🔄 还原桌面图标",
            action: #selector(handleResetIcons),
            keyEquivalent: ""
        )
        resetIconsItem.target = self
        menu.addItem(resetIconsItem)

        let snapItem = NSMenuItem(
            title: "📍 复位到右下角",
            action: #selector(handleResetCorner),
            keyEquivalent: "r"
        )
        snapItem.target = self
        menu.addItem(snapItem)

        let trashItem = NSMenuItem(
            title: "🗑️ 打开废纸篓",
            action: #selector(handleOpenTrash),
            keyEquivalent: ""
        )
        trashItem.target = self
        menu.addItem(trashItem)

        menu.addItem(.separator())

        // 4. 打开偏好设置
        let settingsItem = NSMenuItem(
            title: "⚙️ 偏好设置...",
            action: #selector(handleOpenSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 5. 退出应用
        let quitItem = NSMenuItem(
            title: "🚪 退出",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func handleBinStyleSelected(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? TrashBinStyle else { return }
        CatPreferences.shared.selectedBinStyle = style
        CatSoundEngine.shared.playPurr()
    }

    @objc private func handleSpawnSnack() {
        CatPhysicsEngine.shared.spawnInteractiveTestSnack()
    }

    @objc private func handleToggleSnackStall() {
        SnackIconManager.shared.toggleSnackStall()
    }

    @objc private func handleResetIcons() {
        SnackIconManager.shared.resetAllDesktopIcons()
    }

    @objc private func handleResetCorner() {
        CatPreferences.shared.placementMode = .dockBottomRight
        CatPhysicsEngine.shared.snapBucketToBottomRightCorner()
    }

    @objc private func handleOpenTrash() {
        TrashService.shared.openSystemTrash()
    }

    @objc private func handleOpenSettings() {
        CatTrashAppDelegate.shared?.openSettingsWindow()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }
}
