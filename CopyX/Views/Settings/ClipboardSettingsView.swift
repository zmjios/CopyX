import SwiftUI
import AppKit

// MARK: - 剪切板设置页面
struct ModernClipboardSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    title: "clipboard_title".localized,
                    subtitle: "clipboard_settings_subtitle".localized
                )
                
                // 历史记录设置
                SettingsSection(title: "history".localized, icon: "clock") {
                    RulerSlider(
                        title: "max_items".localized,
                        subtitle: "max_items_subtitle".localized,
                        value: Binding(
                            get: { Double(clipboardManager.maxHistoryCount) },
                            set: { clipboardManager.maxHistoryCount = Int($0) }
                        ),
                        range: 10...1000,
                        step: 10,
                        majorTickInterval: 100,
                        minorTickInterval: 50
                    )
                    
                    SettingsToggle(
                        title: "auto_clear".localized,
                        subtitle: "auto_clear_subtitle".localized,
                        isOn: $clipboardManager.autoCleanup
                    )
                }
                
                // 内容类型设置
                SettingsSection(title: "content_types".localized, icon: "doc.text") {
                    SettingsToggle(
                        title: "save_text_content".localized,
                        subtitle: "save_text_content_subtitle".localized,
                        isOn: $clipboardManager.enableTextHistory
                    )
                    
                    SettingsToggle(
                        title: "save_image_content".localized,
                        subtitle: "save_image_content_subtitle".localized,
                        isOn: $clipboardManager.enableImageHistory
                    )
                }
                
                // 隐私设置
                SettingsSection(title: "privacy_protection".localized, icon: "lock.shield") {
                    SettingsToggle(
                        title: "skip_password_fields".localized,
                        subtitle: "skip_password_fields_subtitle".localized,
                        isOn: $clipboardManager.excludePasswords
                    )
                }
                
                // 界面设置
                SettingsSection(title: "interface_settings".localized, icon: "eye") {
                    SettingsToggle(
                        title: "use_modal_share_view".localized,
                        subtitle: "use_modal_share_view_subtitle".localized,
                        isOn: $clipboardManager.useModalShareView
                    )
                }
                
                // 启动设置
                SettingsSection(title: "startup_settings".localized, icon: "power") {
                    SettingsToggle(
                        title: "auto_start_monitoring".localized,
                        subtitle: "auto_start_monitoring_subtitle".localized,
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
        case .never: return "autoclean_never".localized
        case .daily: return "autoclean_daily".localized
        case .weekly: return "autoclean_weekly".localized
        case .monthly: return "autoclean_monthly".localized
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
        case .low: return "imagequality_low".localized
        case .medium: return "imagequality_medium".localized
        case .high: return "imagequality_high".localized
        case .original: return "imagequality_original".localized
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
        case .short: return "notificationduration_short".localized
        case .medium: return "notificationduration_medium".localized
        case .long: return "notificationduration_long".localized
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

struct ModernClipboardSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernClipboardSettingsView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
    }
} 
