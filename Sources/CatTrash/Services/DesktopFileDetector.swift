import Foundation
import AppKit
import ApplicationServices

/// 桌面与 Finder 文件探测器：直接向 Finder 进程查询光标坐标下的图标/文件行，并支持隐藏扩展名匹配
@MainActor
public final class DesktopFileDetector: ObservableObject {
    public static let shared = DesktopFileDetector()

    @Published public private(set) var isAccessibilityTrusted: Bool = false
    private var trustPollTimer: Timer?

    private init() {
        refreshTrustStatus()
        // 每 1.5 秒自动同步一次权限状态，用户在系统设置开启开关后界面立即变绿生效
        trustPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshTrustStatus()
            }
        }
    }

    @discardableResult
    public func refreshTrustStatus() -> Bool {
        let trusted = AXIsProcessTrusted()
        if self.isAccessibilityTrusted != trusted {
            self.isAccessibilityTrusted = trusted
        }
        return trusted
    }

    /// 请求或重置辅助功能权限（自动清理旧签名残留的失效 TCC 记录并重新弹窗授权）
    public func requestAccessibilityPermission() {
        if AXIsProcessTrusted() {
            self.isAccessibilityTrusted = true
            TrashService.shared.lastStatusMessage = "✅ 辅助功能权限已生效，可直接拽猫头去吃桌面文件！"
            return
        }

        // 先通过 tccutil 清除之前未签名旧版本残留的失效权限记录，避免开关开了也识别不到
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", "com.cattrash.desktoppet"]
        try? process.run()
        process.waitUntilExit()

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        self.isAccessibilityTrusted = trusted
        TrashService.shared.lastStatusMessage = "请在弹出的系统设置中勾选「Cat Trash」即可生效"
    }

    /// 根据当前鼠标屏幕坐标（AppKit 坐标系：主屏左下角为 0,0）探测下方是否有可安全删除的桌面/Finder 文件
    public func detectFileUnderCursor(appKitScreenPoint: CGPoint) -> URL? {
        let trusted = AXIsProcessTrusted()
        self.isAccessibilityTrusted = trusted
        guard trusted else { return nil }

        guard let primaryScreen = NSScreen.screens.first else { return nil }
        let primaryHeight = primaryScreen.frame.height
        let axX = Float(appKitScreenPoint.x)
        let axY = Float(primaryHeight - appKitScreenPoint.y)

        // 1. 优先直接向 Finder 进程查询该坐标下的 UI 元素（完全绕过 CatTrash 自身的全屏透明图层遮挡）
        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            let finderAX = AXUIElementCreateApplication(finderApp.processIdentifier)
            var finderHit: AXUIElement?
            if AXUIElementCopyElementAtPosition(finderAX, axX, axY, &finderHit) == .success,
               let hit = finderHit,
               let url = resolveFileURL(from: hit) {
                return url
            }
        }

        // 2. 备选：通过 SystemWide 查询
        let systemWide = AXUIElementCreateSystemWide()
        var sysHit: AXUIElement?
        if AXUIElementCopyElementAtPosition(systemWide, axX, axY, &sysHit) == .success,
           let hit = sysHit,
           let url = resolveFileURL(from: hit) {
            return url
        }

        return nil
    }

    // MARK: - 从 AXUIElement 树解析真实文件 URL
    private func resolveFileURL(from startElement: AXUIElement) -> URL? {
        // 先获取所在窗口的目录路径（若是打开的 Finder 窗口，可从窗口 AXDocument / AXProxy 获得当前文件夹路径）
        let windowDirectoryURL = findContainingFolderURL(from: startElement)

        var currentElement: AXUIElement? = startElement
        for _ in 0..<8 {
            guard let element = currentElement else { break }
            let role = copyStringAttribute(element, attribute: kAXRoleAttribute) ?? ""

            // 如果已经上溯到空白桌面滚动区或窗口本身，则停止，避免误匹配整个桌面目录
            if role == "AXScrollArea" || role == "AXWindow" || role == "AXApplication" || role == "AXSplitGroup" {
                break
            }

            // A. 检查元素自身属性
            if let url = extractURLFromSingleElement(element, folderURL: windowDirectoryURL) {
                return url
            }

            // B. 若是列表行 (AXRow / AXCell / AXGroup)，检查其直接子元素（Finder 列表模式的 URL 常挂在子 Cell/Text 上）
            if role == "AXRow" || role == "AXCell" || role == "AXGroup" || role == "AXOutlineRow" {
                for child in copyChildren(of: element).prefix(6) {
                    if let url = extractURLFromSingleElement(child, folderURL: windowDirectoryURL) {
                        return url
                    }
                }
            }

            currentElement = copyParentElement(element)
        }

        return nil
    }

    private func extractURLFromSingleElement(_ element: AXUIElement, folderURL: URL?) -> URL? {
        // 1. 直接读取 AXURL 属性
        if let url = copyURLAttribute(element, attribute: kAXURLAttribute),
           TrashService.shared.isSafeToTrash(url) {
            return url
        }

        // 2. 读取 AXFilename / AXTitle / AXValue 并结合目录匹配
        let candidateNames = [
            copyStringAttribute(element, attribute: kAXFilenameAttribute),
            copyStringAttribute(element, attribute: kAXTitleAttribute),
            copyStringAttribute(element, attribute: kAXValueAttribute)
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
         .filter { !$0.isEmpty }

        for name in candidateNames {
            if let resolved = resolveFileName(name, preferredFolder: folderURL),
               TrashService.shared.isSafeToTrash(resolved) {
                return resolved
            }
        }

        return nil
    }

    /// 根据文件名或隐藏扩展名后的显示名，在目标文件夹（或桌面）中匹配真实文件
    private func resolveFileName(_ name: String, preferredFolder: URL?) -> URL? {
        var searchFolders: [URL] = []
        if let preferredFolder {
            searchFolders.append(preferredFolder)
        }
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            if !searchFolders.contains(desktopURL) {
                searchFolders.append(desktopURL)
            }
        }

        for folder in searchFolders {
            // 1. 精确文件名匹配
            let exact = folder.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: exact.path) {
                return exact
            }

            // 2. 兼容 Finder 隐藏文件扩展名的情况（例如显示 "测试文件"，实际为 "测试文件.txt"）
            if let items = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                if let matched = items.first(where: {
                    $0.lastPathComponent == name ||
                    $0.deletingPathExtension().lastPathComponent == name
                }) {
                    return matched
                }
            }
        }

        return nil
    }

    /// 向上寻找所属 Finder 窗口当前打开的文件夹 URL
    private func findContainingFolderURL(from startElement: AXUIElement) -> URL? {
        var current: AXUIElement? = startElement
        for _ in 0..<12 {
            guard let el = current else { break }
            let role = copyStringAttribute(el, attribute: kAXRoleAttribute) ?? ""
            if role == "AXWindow" {
                if let docStr = copyStringAttribute(el, attribute: kAXDocumentAttribute),
                   let docURL = URL(string: docStr), docURL.isFileURL {
                    return docURL
                }
                if let proxy = copyElementAttribute(el, attribute: kAXProxyAttribute),
                   let proxyURL = copyURLAttribute(proxy, attribute: kAXURLAttribute) {
                    return proxyURL
                }
                break
            }
            current = copyParentElement(el)
        }
        return nil
    }

    // MARK: - AX Attributes Helpers

    private func copyURLAttribute(_ element: AXUIElement, attribute: String) -> URL? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard err == .success, let unwrapped = value else { return nil }

        if CFGetTypeID(unwrapped) == CFURLGetTypeID() {
            return (unwrapped as! CFURL) as URL
        }
        if let str = unwrapped as? String {
            if let url = URL(string: str), url.isFileURL {
                return url
            }
            if str.hasPrefix("/") {
                return URL(fileURLWithPath: str)
            }
        }
        return nil
    }

    private func copyStringAttribute(_ element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard err == .success, let str = value as? String else { return nil }
        return str
    }

    private func copyElementAttribute(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard err == .success, let unwrapped = value else { return nil }
        if CFGetTypeID(unwrapped) == AXUIElementGetTypeID() {
            return (unwrapped as! AXUIElement)
        }
        return nil
    }

    private func copyParentElement(_ element: AXUIElement) -> AXUIElement? {
        copyElementAttribute(element, attribute: kAXParentAttribute)
    }

    private func copyChildren(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard err == .success, let array = value as? [AXUIElement] else { return [] }
        return array
    }
}
