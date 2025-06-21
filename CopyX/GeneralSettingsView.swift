import SwiftUI
import AppKit

// MARK: - 通用设置页面
struct ModernGeneralSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var localizationManager: LocalizationManager

    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("hideInDock") private var hideInDock: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 页面标题
                VStack(alignment: .leading, spacing: 8) {
                    LocalizedText("general_settings_title")
                        .font(.title)
                        .fontWeight(.bold)
                    LocalizedText("general_settings_subtitle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 启动设置
                SettingsSection(title: "startup_settings".localized, icon: "power") {
                    SettingsToggle(
                        title: "launch_at_startup".localized,
                        subtitle: "launch_at_startup_subtitle".localized,
                        isOn: $launchAtLogin
                    ) { value in
                        setLaunchAtLogin(value)
                    }
                    
                    SettingsToggle(
                        title: "show_in_menu_bar".localized,
                        subtitle: "show_in_menu_bar_subtitle".localized,
                        isOn: $showInMenuBar
                    ) { value in
                        updateMenuBarVisibility(value)
                    }
                    
                    SettingsToggle(
                        title: "hide_dock_icon".localized,
                        subtitle: "hide_dock_icon_subtitle".localized,
                        isOn: $hideInDock
                    ) { value in
                        NSApp.setActivationPolicy(value ? .accessory : .regular)
                    }
                }
                
                // 通知设置
                SettingsSection(title: "notification_settings".localized, icon: "bell") {
                    SettingsToggle(
                        title: "enable_notifications".localized,
                        subtitle: "enable_notifications_subtitle".localized,
                        isOn: $enableNotifications
                    )
                }
                
                // 语言设置
                SettingsSection(title: "language_settings".localized, icon: "globe") {
                    Picker("display_language".localized, selection: $localizationManager.language) {
                        ForEach(LocalizationManager.Language.allCases) { lang in
                            Text(lang.localizedName).tag(lang)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // 界面设置
                SettingsSection(title: "interface_settings".localized, icon: "paintbrush") {
                    SettingsToggle(
                        title: "enable_sound_effects".localized,
                        subtitle: "enable_sound_effects_subtitle".localized,
                        isOn: $clipboardManager.enableSound
                    )
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // 简化的登录时启动实现
        // 在实际项目中，建议使用ServiceManagement框架
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.copyx.app"
        
        if enabled {
            // 这里可以实现添加到登录项的逻辑
            print("Enable launch at login: \(bundleIdentifier)")
        } else {
            // 这里可以实现从登录项移除的逻辑
            print("Disable launch at login: \(bundleIdentifier)")
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

struct ModernGeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernGeneralSettingsView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
    }
} 
