import SwiftUI
import AppKit
import Carbon

// MARK: - 快捷键设置页面
struct ModernHotKeySettingsView: View {
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @State private var isRecording: Bool = false
    @State private var recordedKeyCode: Int = 0
    @State private var recordedModifiers: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 页面标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("快捷键设置")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("自定义全局快捷键来快速访问剪切板历史")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 主快捷键设置
                SettingsSection(title: "主快捷键", icon: "keyboard") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("显示剪切板历史")
                                .font(.system(size: 15, weight: .medium))
                            
                            Spacer()
                            
                            HotKeyRecorderView(
                                keyCode: $hotKeyManager.hotKeyCode,
                                modifiers: $hotKeyManager.hotKeyModifiers,
                                isRecording: $isRecording
                            )
                        }
                        
                        Toggle("启用快捷键", isOn: $hotKeyManager.hotKeyEnabled)
                            .onChange(of: hotKeyManager.hotKeyEnabled) { enabled in
                                hotKeyManager.enableHotKey(enabled)
                            }
                        
                        Text("按下快捷键来显示或隐藏剪切板历史窗口")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 快捷键提示
                SettingsSection(title: "使用提示", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 8) {
                        HelpTip(
                            icon: "1.circle",
                            title: "设置快捷键",
                            description: "点击快捷键输入框，然后按下你想要的组合键"
                        )
                        
                        HelpTip(
                            icon: "2.circle",
                            title: "全局快捷键",
                            description: "设置的快捷键在任何应用中都可以使用"
                        )
                        
                        HelpTip(
                            icon: "3.circle",
                            title: "避免冲突",
                            description: "请确保不与系统或其他应用的快捷键冲突"
                        )
                        
                        HelpTip(
                            icon: "4.circle",
                            title: "推荐组合",
                            description: "推荐使用 Cmd+Shift+V 或 Cmd+Option+V 等组合"
                        )
                    }
                }
                
                // 当前快捷键信息
                SettingsSection(title: "当前设置", icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("快捷键:")
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
                            Text("状态:")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(hotKeyManager.hotKeyEnabled ? "已启用" : "已禁用")
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
        
        return result.isEmpty ? "未设置" : result
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
                        Text("按下快捷键...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(displayString())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !isRecording {
                    Button("重设") {
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
        
        return result.isEmpty ? "点击设置" : result
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