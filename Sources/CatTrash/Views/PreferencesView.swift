import SwiftUI

/// 原生毛玻璃设置面板 (Liquid Glass / Vibrant Preferences View)
public struct PreferencesView: View {
    @ObservedObject var prefs = CatPreferences.shared
    @ObservedObject var physics = CatPhysicsEngine.shared
    @ObservedObject var trashService = TrashService.shared
    @ObservedObject var detector = DesktopFileDetector.shared
    @ObservedObject var snackManager = SnackIconManager.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部标题栏与统计
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "cat.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cat Trash · 桌面宠物废纸篓")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text(physics.state.statusLabel)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("累计投喂")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text("\(prefs.totalTrashedCount) 份")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }

                    Divider()

                    // 当前猫猫与垃圾桶样式（提示右键切换）
                    HStack(spacing: 8) {
                        Label("品种与样式切换已移至「右键菜单」", systemImage: "cursorarrow.click.2")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(prefs.selectedMorph.displayName) · \(prefs.selectedBinStyle.displayName)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.12))
                            )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.04))
                    )

                    // 1. 外观尺寸缩放与橡皮筋物理调节
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("外观尺寸与物理手感", systemImage: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach([("0.8x", 0.8), ("1.0x", 1.0), ("1.5x", 1.5), ("2.2x 特写", 2.2)], id: \.0) { label, val in
                                    Button(label) {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                            prefs.widgetScale = val
                                            if prefs.placementMode == .dockBottomRight {
                                                physics.snapBucketToBottomRightCorner()
                                            }
                                        }
                                    }
                                    .controlSize(.mini)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        HStack {
                            Text("整体尺寸")
                                .font(.system(size: 12))
                                .frame(width: 64, alignment: .leading)
                            Slider(value: $prefs.widgetScale, in: 0.6...2.6)
                                .onChange(of: prefs.widgetScale) { _, _ in
                                    if prefs.placementMode == .dockBottomRight {
                                        physics.snapBucketToBottomRightCorner()
                                    }
                                }
                            Text(String(format: "%.0f%%", prefs.widgetScale * 100))
                                .font(.system(size: 11, design: .monospaced))
                                .frame(width: 40, alignment: .trailing)
                        }

                        HStack {
                            Text("拉拽阻力")
                                .font(.system(size: 12))
                                .frame(width: 64, alignment: .leading)
                            Slider(value: $prefs.stretchDamping, in: 0.2...1.0)
                            Text(String(format: "%.0f%%", prefs.stretchDamping * 100))
                                .font(.system(size: 11, design: .monospaced))
                                .frame(width: 40, alignment: .trailing)
                        }

                        HStack {
                            Text("回弹速度")
                                .font(.system(size: 12))
                                .frame(width: 64, alignment: .leading)
                            Slider(value: $prefs.snapSpeed, in: 0.5...1.8)
                            Text(String(format: "%.1fx", prefs.snapSpeed))
                                .font(.system(size: 11, design: .monospaced))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }

                    // 3. 音效开关与音量
                    VStack(alignment: .leading, spacing: 8) {
                        Label("音效反馈", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 16) {
                            Toggle("咀嚼与饱嗝声", isOn: $prefs.chompSoundEnabled)
                                .font(.system(size: 12))
                            Toggle("喵叫与呼噜声", isOn: $prefs.vocalSoundEnabled)
                                .font(.system(size: 12))
                        }

                        HStack {
                            Text("总音量")
                                .font(.system(size: 12))
                                .frame(width: 64, alignment: .leading)
                            Slider(value: $prefs.soundVolume, in: 0.0...1.0)
                            Button("试听嗷呜") {
                                CatSoundEngine.shared.playChompAndBurp()
                            }
                            .controlSize(.small)
                        }
                    }

                    // 4. 桌面零食模式 (Snack Mode · 方案 A)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("桌面零食摊模式 (Snack Mode)", systemImage: "wand.and.stars")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Toggle(
                                "开启桌面零食摊",
                                isOn: Binding(
                                    get: { snackManager.isSnackStallActive },
                                    set: { newValue in
                                        if newValue {
                                            snackManager.enableDesktopSnackStall()
                                            CatSoundEngine.shared.playEnchantPoof()
                                        } else {
                                            snackManager.resetAllDesktopIcons()
                                        }
                                    }
                                )
                            )
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .font(.system(size: 12, weight: .medium))
                        }

                        Text("🐟文档=小鱼干  🍣图片视频=冻干  🌿代码=猫草棒  🥫压缩包=罐头  🍱文件夹=拼盘\n提示：按住 Option(⌥) 拽猫头轻碰桌面文件，也可单独点化为猫零食（退出应用自动还原）")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)

                        HStack(spacing: 8) {
                            Button {
                                snackManager.resetAllDesktopIcons()
                            } label: {
                                Label("一键还原全部图标 (Reset Icons)", systemImage: "arrow.counterclockwise.circle")
                            }
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    // 5. 常驻位置与权限测试
                    VStack(alignment: .leading, spacing: 8) {
                        Label("桌面位置与快捷测试", systemImage: "macwindow.on.rectangle")
                            .font(.system(size: 13, weight: .semibold))

                        Picker("常驻位置", selection: $prefs.placementMode) {
                            ForEach(PlacementMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .font(.system(size: 12))
                        .onChange(of: prefs.placementMode) { _, newMode in
                            if newMode == .dockBottomRight {
                                physics.snapBucketToBottomRightCorner()
                            }
                        }

                        HStack(spacing: 8) {
                            Button {
                                physics.spawnInteractiveTestSnack()
                            } label: {
                                Label("生成测试废纸投喂", systemImage: "fish.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .controlSize(.small)

                            Button {
                                _ = trashService.undoLastTrash()
                            } label: {
                                Label("撤销上次吞食", systemImage: "arrow.uturn.backward")
                            }
                            .controlSize(.small)
                            .disabled(trashService.recentRecords.isEmpty)

                            Button {
                                detector.requestAccessibilityPermission()
                            } label: {
                                Label(
                                    detector.isAccessibilityTrusted ? "桌面识别已授权" : "授权识别桌面文件",
                                    systemImage: detector.isAccessibilityTrusted ? "checkmark.shield.fill" : "hand.raised.fill"
                                )
                            }
                            .controlSize(.small)
                        }

                        if let msg = trashService.lastStatusMessage {
                            Text(msg)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(18)
            }

            Divider()

            // 底部操作栏：打开废纸篓与退出
            HStack {
                Button {
                    TrashService.shared.openSystemTrash()
                } label: {
                    Label("打开系统废纸篓", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label("退出 Cat Trash", systemImage: "power")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.03))
        }
        .frame(width: 416, height: 560)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
