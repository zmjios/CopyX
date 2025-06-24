import SwiftUI
import AppKit
import Carbon

// MARK: - 快捷键设置页面
struct ModernHotKeySettingsView: View {
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isRecording: Bool = false
    @State private var recordedKeyCode: Int = 0
    @State private var recordedModifiers: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 页面标题
                VStack(alignment: .leading, spacing: 6) {
                    LocalizedText("hotkeys_title")
                        .font(.title2)
                        .fontWeight(.bold)
                    LocalizedText("hotkey_settings_subtitle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 主快捷键设置
                SettingsSection(title: "main_hotkey".localized, icon: "keyboard") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            LocalizedText("show_clipboard_history")
                                .font(.system(size: 15, weight: .medium))
                            
                            Spacer()
                            
                            HotKeyRecorderView(
                                keyCode: $hotKeyManager.hotKeyCode,
                                modifiers: $hotKeyManager.hotKeyModifiers,
                                isRecording: $isRecording
                            )
                        }
                        
                        Toggle("enable_hotkey".localized, isOn: $hotKeyManager.hotKeyEnabled)
                            .onChange(of: hotKeyManager.hotKeyEnabled) { enabled in
                                hotKeyManager.enableHotKey(enabled)
                            }
                        
                        LocalizedText("hotkey_show_hide_description")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 快捷键提示
                SettingsSection(title: "usage_tips".localized, icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 8) {
                        HelpTip(
                            icon: "1.circle",
                            title: "set_hotkey".localized,
                            description: "set_hotkey_desc".localized
                        )
                        
                        HelpTip(
                            icon: "2.circle",
                            title: "global_hotkey".localized,
                            description: "global_hotkey_desc".localized
                        )
                        
                        HelpTip(
                            icon: "3.circle",
                            title: "avoid_conflicts".localized,
                            description: "avoid_conflicts_desc".localized
                        )
                        
                        HelpTip(
                            icon: "4.circle",
                            title: "recommended_combinations".localized,
                            description: "recommended_combinations_desc".localized
                        )
                    }
                }
                
                // 当前快捷键信息
                SettingsSection(title: "current_settings".localized, icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\("hotkey".localized):")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(currentHotKeyString())
                                .font(.system(size: 14, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Text("\("status".localized):")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(hotKeyManager.hotKeyEnabled ? "enabled".localized : "disabled".localized)
                                .font(.system(size: 14))
                                .foregroundColor(hotKeyManager.hotKeyEnabled ? .green : .red)
                        }
                    }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func currentHotKeyString() -> String {
        var result = ""
        
        // 修饰键
        if hotKeyManager.hotKeyModifiers & cmdKey != 0 {
            result += "⌘"
        }
        if hotKeyManager.hotKeyModifiers & optionKey != 0 {
            result += "⌥"
        }
        if hotKeyManager.hotKeyModifiers & controlKey != 0 {
            result += "⌃"
        }
        if hotKeyManager.hotKeyModifiers & shiftKey != 0 {
            result += "⇧"
        }
        
        // 主键
        result += KeyCodeUtils.keyName(for: hotKeyManager.hotKeyCode)
        
        return result.isEmpty ? "hotkey_not_set".localized : result
    }
}

// MARK: - 快捷键录制器
struct HotKeyRecorderView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @Binding var isRecording: Bool
    @State private var eventMonitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 8))
                        LocalizedText("press_hotkey_prompt")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(displayString())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !isRecording {
                    Button("reset".localized) {
                        startRecording()
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 150)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopRecording()
        }
    }
    
    private func displayString() -> String {
        var result = ""
        
        // 修饰键
        if modifiers & cmdKey != 0 {
            result += "⌘"
        }
        if modifiers & optionKey != 0 {
            result += "⌥"
        }
        if modifiers & controlKey != 0 {
            result += "⌃"
        }
        if modifiers & shiftKey != 0 {
            result += "⇧"
        }
        
        // 主键
        result += KeyCodeUtils.keyName(for: keyCode)
        
        return result.isEmpty ? "click_to_set".localized : result
    }
    
    private func startRecording() {
        isRecording = true
        
        // 添加全局事件监听器
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            let newKeyCode = Int(event.keyCode)
            let newModifiers = Int(event.modifierFlags.rawValue) & (cmdKey | optionKey | controlKey | shiftKey)
            
            // 确保有修饰键
            if newModifiers != 0 {
                keyCode = newKeyCode
                modifiers = newModifiers
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - 帮助提示组件
struct HelpTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ModernHotKeySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernHotKeySettingsView()
            .environmentObject(HotKeyManager())
            .environmentObject(LocalizationManager.shared)
    }
} 