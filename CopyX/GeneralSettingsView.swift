import SwiftUI
import AppKit

// MARK: - 通用设置页面
struct ModernGeneralSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("hideInDock") private var hideInDock: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 页面标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("通用设置")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("配置 CopyX 的启动和界面选项")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 启动设置
                SettingsSection(title: "启动设置", icon: "power") {
                    SettingsToggle(
                        title: "开机启动",
                        subtitle: "系统启动时自动运行 CopyX",
                        isOn: $launchAtLogin
                    ) { value in
                        setLaunchAtLogin(value)
                    }
                    
                    SettingsToggle(
                        title: "在菜单栏显示",
                        subtitle: "在系统菜单栏显示 CopyX 图标",
                        isOn: $showInMenuBar
                    ) { value in
                        updateMenuBarVisibility(value)
                    }
                    
                    SettingsToggle(
                        title: "隐藏 Dock 图标",
                        subtitle: "在 Dock 中隐藏应用图标",
                        isOn: $hideInDock
                    ) { value in
                        NSApp.setActivationPolicy(value ? .accessory : .regular)
                    }
                }
                
                // 通知设置
                SettingsSection(title: "通知设置", icon: "bell") {
                    SettingsToggle(
                        title: "启用通知",
                        subtitle: "新的剪切板内容时显示桌面通知",
                        isOn: $enableNotifications
                    )
                }
                
                // 界面设置
                SettingsSection(title: "界面设置", icon: "paintbrush") {
                    SettingsToggle(
                        title: "启用剪切板音效",
                        subtitle: "复制内容时播放系统音效",
                        isOn: $clipboardManager.enableSound
                    )
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // 简化的登录时启动实现
        // 在实际项目中，建议使用ServiceManagement框架
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.copyx.app"
        
        if enabled {
            // 这里可以实现添加到登录项的逻辑
            print("启用开机启动: \(bundleIdentifier)")
        } else {
            // 这里可以实现从登录项移除的逻辑
            print("禁用开机启动: \(bundleIdentifier)")
        }
    }
    
    private func updateMenuBarVisibility(_ visible: Bool) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            if visible {
                if appDelegate.statusBarItem == nil {
                    appDelegate.setupStatusBar()
                }
            } else {
                if let statusBarItem = appDelegate.statusBarItem {
                    NSStatusBar.system.removeStatusItem(statusBarItem)
                    appDelegate.statusBarItem = nil
                }
            }
        }
    }
} 