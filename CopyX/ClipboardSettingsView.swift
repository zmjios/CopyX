import SwiftUI
import AppKit

// MARK: - 剪切板设置页面
struct ModernClipboardSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    title: "剪切板设置",
                    subtitle: "配置剪切板历史记录的行为和限制"
                )
                
                // 历史记录设置
                SettingsSection(title: "历史记录", icon: "clock") {
                    SettingsSlider(
                        title: "最大保存数量",
                        subtitle: "超过此数量时会自动删除最旧的记录",
                        value: Binding(
                            get: { Double(clipboardManager.maxHistoryCount) },
                            set: { clipboardManager.maxHistoryCount = Int($0) }
                        ),
                        range: 10...1000,
                        step: 10
                    )
                    
                    SettingsToggle(
                        title: "自动清理",
                        subtitle: "定期清理过期的剪切板项目",
                        isOn: $clipboardManager.autoCleanup
                    )
                }
                
                // 内容类型设置
                SettingsSection(title: "内容类型", icon: "doc.text") {
                    SettingsToggle(
                        title: "保存文本内容",
                        subtitle: "自动保存复制的文本内容",
                        isOn: $clipboardManager.enableTextHistory
                    )
                    
                    SettingsToggle(
                        title: "保存图片内容",
                        subtitle: "自动保存复制的图片内容",
                        isOn: $clipboardManager.enableImageHistory
                    )
                }
                
                // 隐私设置
                SettingsSection(title: "隐私保护", icon: "lock.shield") {
                    SettingsToggle(
                        title: "跳过密码字段",
                        subtitle: "自动跳过密码输入框的内容",
                        isOn: $clipboardManager.excludePasswords
                    )
                }
                
                // 界面设置
                SettingsSection(title: "界面设置", icon: "eye") {
                    SettingsToggle(
                        title: "使用模态分享视图",
                        subtitle: "使用弹窗模式显示分享选项",
                        isOn: $clipboardManager.useModalShareView
                    )
                }
                
                // 音效设置
                SettingsSection(title: "音效提示", icon: "speaker") {
                    SettingsToggle(
                        title: "启用音效",
                        subtitle: "复制内容时播放系统音效",
                        isOn: $clipboardManager.enableSound
                    )
                }
                
                // 启动设置
                SettingsSection(title: "启动设置", icon: "power") {
                    SettingsToggle(
                        title: "自动启动监控",
                        subtitle: "应用启动时自动开始监控剪切板",
                        isOn: $clipboardManager.autoStart
                    )
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 辅助枚举类型

enum AutoCleanInterval: String, CaseIterable, Codable {
    case never = "never"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .never: return "从不"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}

enum ImageQuality: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case original = "original"
    
    var displayName: String {
        switch self {
        case .low: return "低质量"
        case .medium: return "中等质量"
        case .high: return "高质量"
        case .original: return "原始质量"
        }
    }
    
    var compressionQuality: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.8
        case .original: return 1.0
        }
    }
}

enum NotificationDuration: String, CaseIterable, Codable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    
    var displayName: String {
        switch self {
        case .short: return "短 (2秒)"
        case .medium: return "中等 (5秒)"
        case .long: return "长 (10秒)"
        }
    }
    
    var seconds: Double {
        switch self {
        case .short: return 2.0
        case .medium: return 5.0
        case .long: return 10.0
        }
    }
} 