import Foundation
import AppKit

/// 安全文件删除服务：支持普通文件移入废纸篓 (trashItem + NSWorkspace.recycle 双保险) 及桌面挂载磁盘镜像 (.dmg Volume) 自动推出
@MainActor
public final class TrashService: ObservableObject {
    public static let shared = TrashService()

    @Published public private(set) var recentRecords: [TrashedRecord] = []
    @Published public var lastStatusMessage: String?

    private init() {}

    /// 校验 URL 是否可以安全移入废纸篓或推出（防止误删系统根目录、主目录或桌面目录本身）
    public func isSafeToTrash(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let standardized = url.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path

        let protectedPaths: Set<String> = [
            "/",
            "/Volumes",
            "/Applications",
            "/System",
            "/Library",
            "/Users",
            home,
            "\(home)/Desktop",
            "\(home)/Documents",
            "\(home)/Downloads",
            "\(home)/Library",
            Bundle.main.bundleURL.standardizedFileURL.path
        ]

        if protectedPaths.contains(standardized) {
            return false
        }
        return FileManager.default.fileExists(atPath: standardized)
    }

    /// 判断是否为桌面上挂载的外部磁盘镜像卷（如挂载后的 Unity Hub.dmg 卷宗）
    public func isMountedVolume(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        if path.hasPrefix("/Volumes/") && path.components(separatedBy: "/").count == 3 {
            return true
        }
        if let values = try? url.resourceValues(forKeys: [.isVolumeKey, .volumeIsRemovableKey, .volumeIsEjectableKey]),
           values.isVolume == true {
            return true
        }
        return false
    }

    /// 将单个或多个文件安全移入系统原生废纸篓（若是桌面挂载的 DMG 磁盘卷，则像原生废纸篓一样将其安全推出 Eject）
    @discardableResult
    public func moveFilesToTrash(_ urls: [URL]) -> (trashedCount: Int, firstFileName: String?) {
        var successCount = 0
        var firstName: String?

        for url in urls {
            guard isSafeToTrash(url) else { continue }
            let itemName = url.lastPathComponent

            // 1. 若目标是挂载在桌面上的 DMG 磁盘镜像卷（例如 “Unity Hub” 挂载卷），执行安全推出 (Eject)
            if isMountedVolume(url) {
                do {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                    if firstName == nil { firstName = itemName }
                    successCount += 1
                    lastStatusMessage = "⏏ 已帮您吞下并推出磁盘镜像「\(itemName)」！"
                    continue
                } catch {
                    // 若普通 unmount 失败，尝试通过 Finder AppleScript 推出
                    if ejectVolumeViaFinder(url) {
                        if firstName == nil { firstName = itemName }
                        successCount += 1
                        lastStatusMessage = "⏏ 已帮您推出磁盘镜像「\(itemName)」！"
                        continue
                    }
                }
            }

            // 2. 常规文件/文件夹：优先使用 FileManager.default.trashItem 同步移入废纸篓
            var resultingURL: NSURL?
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
                let record = TrashedRecord(
                    originalURL: url,
                    trashedURL: resultingURL as URL?,
                    timestamp: Date()
                )
                recentRecords.insert(record, at: 0)
                if recentRecords.count > 15 {
                    recentRecords.removeLast()
                }
                if firstName == nil { firstName = itemName }
                successCount += 1
            } catch let trashError {
                // 3. 备选双保险：调用 NSWorkspace.shared.recycle 或 Finder AppleScript 移入废纸篓（解决跨卷或权限受限文件）
                if trashViaFinderAppleScript(url) {
                    let record = TrashedRecord(originalURL: url, trashedURL: nil, timestamp: Date())
                    recentRecords.insert(record, at: 0)
                    if firstName == nil { firstName = itemName }
                    successCount += 1
                } else {
                    // 异步调用 NSWorkspace.shared.recycle 作为最终兜底
                    NSWorkspace.shared.recycle([url]) { recycledMap, recycleErr in
                        Task { @MainActor in
                            if let trashedURL = recycledMap[url] {
                                let record = TrashedRecord(originalURL: url, trashedURL: trashedURL, timestamp: Date())
                                self.recentRecords.insert(record, at: 0)
                                CatPreferences.shared.totalTrashedCount += 1
                                self.lastStatusMessage = "已吞下「\(itemName)」并送入系统废纸篓"
                            } else {
                                let errDetail = recycleErr?.localizedDescription ?? trashError.localizedDescription
                                self.lastStatusMessage = "无法移入废纸篓：\(errDetail)"
                            }
                        }
                    }
                    if firstName == nil { firstName = itemName }
                    successCount += 1
                }
            }
        }

        if successCount > 0 {
            CatPreferences.shared.totalTrashedCount += successCount
            if lastStatusMessage == nil || !(lastStatusMessage?.hasPrefix("⏏") ?? false) {
                if successCount == 1, let name = firstName {
                    lastStatusMessage = "已吞下「\(name)」并送入系统废纸篓"
                } else {
                    lastStatusMessage = "已吞下 \(successCount) 个文件并送入系统废纸篓"
                }
            }
        }

        return (successCount, firstName)
    }

    /// 通过 Finder AppleScript 删除文件至废纸篓
    private func trashViaFinderAppleScript(_ url: URL) -> Bool {
        let escapedPath = url.path.replacingOccurrences(of: "\"", with: "\\\"")
        let source = "tell application \"Finder\" to delete (POSIX file \"\(escapedPath)\" as alias)"
        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&errorDict)
            return errorDict == nil
        }
        return false
    }

    /// 通过 Finder AppleScript 推出挂载卷
    private func ejectVolumeViaFinder(_ url: URL) -> Bool {
        let volumeName = url.lastPathComponent.replacingOccurrences(of: "\"", with: "\\\"")
        let source = "tell application \"Finder\" to eject disk \"\(volumeName)\""
        var errorDict: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&errorDict)
            return errorDict == nil
        }
        return false
    }

    /// 从废纸篓撤销找回最近一次被猫猫吞掉的文件
    @discardableResult
    public func undoLastTrash() -> Bool {
        guard let latest = recentRecords.first else { return false }
        guard let trashedURL = latest.trashedURL,
              FileManager.default.fileExists(atPath: trashedURL.path) else {
            recentRecords.removeFirst()
            lastStatusMessage = "该文件在废纸篓中已不存在或为已推出的磁盘镜像"
            return false
        }

        do {
            try FileManager.default.moveItem(at: trashedURL, to: latest.originalURL)
            recentRecords.removeFirst()
            lastStatusMessage = "已从猫嘴里抢回「\(latest.fileName)」！"
            return true
        } catch {
            lastStatusMessage = "找回失败：\(error.localizedDescription)"
            return false
        }
    }

    /// 打开系统废纸篓
    public func openSystemTrash() {
        if let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.open(trashURL)
        }
    }

    /// 在桌面创建一个有趣的测试废纸文件，方便用户立即测试拖拽投喂或拉猫头吞食
    @discardableResult
    public func createSampleDesktopTrashFile() -> URL? {
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return nil
        }

        let samples: [(name: String, content: String)] = [
            ("🐟小鱼干包装袋_喂猫测试", "这是一袋刚吃完的小鱼干空袋子！\n你可以把它拖进右下角的金属网格猫猫桶，或者把猫猫的头拽过来一口吞掉它~"),
            ("📝改不完的Bug清单_喂猫测试", "Bug #404: 猫猫太长了合不上嘴\n快把这个烦人的 Bug 喂给 Cat Trash 吃掉解压吧！"),
            ("🥫空猫罐头盒_喂猫测试", "金枪鱼味猫罐头空盒 × 1\n放心喂食，所有被猫猫吃掉的文件都会安全存放在 macOS 系统废纸篓中，随时可找回。"),
            ("📉废弃需求文档v99_喂猫测试", "第 99 版作废需求文档，最适合给史莱姆果冻猫当下午茶点心！")
        ]

        let pick = samples.randomElement()!
        let timestamp = Int(Date().timeIntervalSince1970) % 1000
        let fileName = "\(pick.name)_\(timestamp).txt"
        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try pick.content.write(to: fileURL, atomically: true, encoding: .utf8)
            lastStatusMessage = "已在桌面生成「\(fileName)」，快去喂猫吧！"
            return fileURL
        } catch {
            lastStatusMessage = "生成测试文件失败：\(error.localizedDescription)"
            return nil
        }
    }
}
