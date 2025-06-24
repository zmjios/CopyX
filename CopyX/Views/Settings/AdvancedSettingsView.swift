import SwiftUI
import AppKit

// MARK: - 高级功能设置页面
struct ModernAdvancedSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedText = ""
    @State private var processedText = ""
    @State private var selectedOperation: AdvancedTextOperation = .trimWhitespace
    @State private var showingStats = false
    @State private var usageStats: UsageStats?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsPageHeader(
                    title: "advanced_settings_title".localized,
                    subtitle: "advanced_settings_subtitle".localized
                )
                
                // 文本处理工具
                SettingsSection(title: "text_processing_tool".localized, icon: "textformat") {
                    VStack(alignment: .leading, spacing: 16) {
                        LocalizedText("select_text_operation")
                            .font(.system(size: 14, weight: .medium))
                        
                        Picker("operation".localized, selection: $selectedOperation) {
                            ForEach(AdvancedTextOperation.allCases, id: \.self) { operation in
                                HStack {
                                    Image(systemName: operation.icon)
                                    Text(operation.displayNameKey.localized)
                                }
                                .tag(operation)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            LocalizedText("input_text")
                                .font(.system(size: 13, weight: .medium))
                            TextEditor(text: $selectedText)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Button("process_text".localized) {
                            processedText = selectedOperation.apply(to: selectedText)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedText.isEmpty)
                        
                        if !processedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                LocalizedText("processing_result")
                                    .font(.system(size: 13, weight: .medium))
                                TextEditor(text: .constant(processedText))
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.05))
                                    .cornerRadius(6)
                                
                                Button("copy_result".localized) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(processedText, forType: .string)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                // 快速操作
                SettingsSection(title: "quick_actions".localized, icon: "bolt") {
                    VStack(alignment: .leading, spacing: 12) {
                        LocalizedText("quick_process_from_clipboard")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(AdvancedTextOperation.allCases.prefix(9), id: \.self) { operation in
                                QuickActionButton(operation: operation)
                            }
                        }
                    }
                }
                
                // 使用统计
                SettingsSection(title: "usage_statistics".localized, icon: "chart.bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("refresh_stats".localized) {
                            usageStats = clipboardManager.getUsageStats()
                            showingStats = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let stats = usageStats, showingStats {
                            UsageStatsView(stats: stats)
                        }
                    }
                }
                
                // 性能设置
                SettingsSection(title: "performance_settings".localized, icon: "speedometer") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsToggle(
                            title: "enable_sound_effects".localized,
                            subtitle: "play_sound_on_copy".localized,
                            isOn: $clipboardManager.enableSound
                        )
                        
                        SettingsToggle(
                            title: "auto_clear_history".localized,
                            subtitle: "auto_clear_history_subtitle".localized,
                            isOn: $clipboardManager.autoCleanup
                        )
                        
                        SettingsSlider(
                            title: "history_limit".localized,
                            subtitle: "history_limit_subtitle".localized,
                            value: Binding(
                                get: { Double(clipboardManager.maxHistoryCount) },
                                set: { clipboardManager.updateMaxHistoryCount(Int($0)) }
                            ),
                            range: 10...1000,
                            step: 10
                        )
                    }
                }
                
                // 实验性功能
                SettingsSection(title: "experimental_features".localized, icon: "flask") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsInfoCard(
                            title: "experimental_warning_title".localized,
                            description: "experimental_warning_desc".localized,
                            icon: "exclamationmark.triangle",
                            color: .orange
                        )
                        
                        SettingsToggle(
                            title: "enable_text_history".localized,
                            subtitle: "enable_text_history_subtitle".localized,
                            isOn: $clipboardManager.enableTextHistory
                        )
                        
                        SettingsToggle(
                            title: "enable_image_history".localized,
                            subtitle: "enable_image_history_subtitle".localized,
                            isOn: $clipboardManager.enableImageHistory
                        )
                        
                        SettingsToggle(
                            title: "enable_sound".localized,
                            subtitle: "enable_sound_subtitle".localized,
                            isOn: $clipboardManager.enableSound
                        )
                    }
                }
            }
            .padding(12)
        }
        .id(localizationManager.revision)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 快速操作按钮
struct QuickActionButton: View {
    let operation: AdvancedTextOperation
    @State private var isProcessing = false
    
    var body: some View {
        Button(action: {
            performQuickAction()
        }) {
            VStack(spacing: 4) {
                Image(systemName: operation.icon)
                    .font(.system(size: 16))
                Text(operation.displayNameKey.localized)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isProcessing)
        .overlay(
            Group {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
        )
    }
    
    private func performQuickAction() {
        guard let currentText = NSPasteboard.general.string(forType: .string) else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let processed = operation.apply(to: currentText)
            
            DispatchQueue.main.async {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(processed, forType: .string)
                isProcessing = false
            }
        }
    }
}

// MARK: - 使用统计视图
struct UsageStatsView: View {
    let stats: UsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LocalizedText("usage_stats_title")
                .font(.system(size: 15, weight: .medium))
            
            VStack(alignment: .leading, spacing: 8) {
                StatRow(label: "total_items_stat".localized, value: "\(stats.totalItems)")
                StatRow(label: "favorite_items_stat".localized, value: "\(stats.favoriteItems)")
                StatRow(label: "total_usage_stat".localized, value: "\(stats.totalUsage)")
                
                if let mostUsed = stats.mostUsedItem {
                    StatRow(label: "most_used_item_stat".localized, value: mostUsed.displayTitle)
                }
                
                ForEach(stats.itemsByType.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                    StatRow(label: type.displayName.localized, value: "\(count)")
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

// MARK: - 统计行
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// The following enum has been moved to TextProcessor.swift to consolidate definitions.
// enum AdvancedTextOperation: String, CaseIterable { ... }
// All related code that was here has been removed.

 