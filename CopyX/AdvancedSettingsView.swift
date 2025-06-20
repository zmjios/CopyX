import SwiftUI
import AppKit

// MARK: - 高级功能设置页面
struct ModernAdvancedSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedText = ""
    @State private var processedText = ""
    @State private var selectedOperation: AdvancedTextOperation = .trimWhitespace
    @State private var showingStats = false
    @State private var usageStats: UsageStats?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    title: "高级功能",
                    subtitle: "文本处理工具和使用统计"
                )
                
                // 文本处理工具
                SettingsSection(title: "文本处理工具", icon: "textformat") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择文本处理操作")
                            .font(.system(size: 14, weight: .medium))
                        
                        Picker("操作", selection: $selectedOperation) {
                            ForEach(AdvancedTextOperation.allCases, id: \.self) { operation in
                                HStack {
                                    Image(systemName: operation.icon)
                                    Text(operation.displayName)
                                }
                                .tag(operation)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("输入文本")
                                .font(.system(size: 13, weight: .medium))
                            TextEditor(text: $selectedText)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Button("处理文本") {
                            processedText = selectedOperation.apply(to: selectedText)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedText.isEmpty)
                        
                        if !processedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("处理结果")
                                    .font(.system(size: 13, weight: .medium))
                                TextEditor(text: .constant(processedText))
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.05))
                                    .cornerRadius(6)
                                
                                Button("复制结果") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(processedText, forType: .string)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                // 快速操作
                SettingsSection(title: "快速操作", icon: "bolt") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("从剪切板快速处理文本")
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
                SettingsSection(title: "使用统计", icon: "chart.bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("刷新统计") {
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
                SettingsSection(title: "性能设置", icon: "speedometer") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsToggle(
                            title: "启用声音提示",
                            subtitle: "复制内容时播放提示音",
                            isOn: $clipboardManager.enableSound
                        )
                        
                        SettingsToggle(
                            title: "自动清理历史",
                            subtitle: "定期清理旧的剪切板历史",
                            isOn: $clipboardManager.autoCleanup
                        )
                        
                        SettingsSlider(
                            title: "历史记录限制",
                            subtitle: "设置最大历史记录数量",
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
                SettingsSection(title: "实验性功能", icon: "flask") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsInfoCard(
                            title: "⚠️ 实验性功能",
                            description: "这些功能仍在开发中，可能不稳定或导致意外行为",
                            icon: "exclamationmark.triangle",
                            color: .orange
                        )
                        
                        SettingsToggle(
                            title: "启用文本历史",
                            subtitle: "记录文本类型的剪切板内容",
                            isOn: $clipboardManager.enableTextHistory
                        )
                        
                        SettingsToggle(
                            title: "启用图片历史",
                            subtitle: "记录图片类型的剪切板内容",
                            isOn: $clipboardManager.enableImageHistory
                        )
                        
                        SettingsToggle(
                            title: "启用声音",
                            subtitle: "剪切板变化时播放提示音",
                            isOn: $clipboardManager.enableSound
                        )
                    }
                }
            }
            .padding(30)
        }
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
                Text(operation.displayName)
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
            Text("统计信息")
                .font(.system(size: 15, weight: .medium))
            
            VStack(alignment: .leading, spacing: 8) {
                StatRow(label: "总项目数", value: "\(stats.totalItems)")
                StatRow(label: "收藏项目数", value: "\(stats.favoriteItems)")
                StatRow(label: "总使用次数", value: "\(stats.totalUsage)")
                
                if let mostUsed = stats.mostUsedItem {
                    StatRow(label: "最常用项目", value: mostUsed.displayTitle)
                }
                
                ForEach(stats.itemsByType.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                    StatRow(label: type.displayName, value: "\(count)")
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
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 文本操作枚举
enum AdvancedTextOperation: String, CaseIterable {
    case trimWhitespace = "去除空格"
    case uppercase = "转大写"
    case lowercase = "转小写"
    case capitalizeWords = "首字母大写"
    case removeLineBreaks = "移除换行"
    case addLineBreaks = "添加换行"
    case removeNumbers = "移除数字"
    case removeSpecialChars = "移除特殊字符"
    case urlEncode = "URL编码"
    case urlDecode = "URL解码"
    case base64Encode = "Base64编码"
    case base64Decode = "Base64解码"
    case reverseText = "反转文本"
    case sortLines = "排序行"
    case removeDuplicateLines = "去重行"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .trimWhitespace: return "scissors"
        case .uppercase: return "textformat.abc"
        case .lowercase: return "textformat.abc.dottedunderline"
        case .capitalizeWords: return "textformat.alt"
        case .removeLineBreaks: return "arrow.left.and.right"
        case .addLineBreaks: return "arrow.up.and.down"
        case .removeNumbers: return "number.circle.fill"
        case .removeSpecialChars: return "character.cursor.ibeam"
        case .urlEncode: return "link"
        case .urlDecode: return "link.badge.plus"
        case .base64Encode: return "lock.fill"
        case .base64Decode: return "lock.open.fill"
        case .reverseText: return "arrow.left.arrow.right"
        case .sortLines: return "arrow.up.arrow.down"
        case .removeDuplicateLines: return "doc.on.doc"
        }
    }
    
    func apply(to text: String) -> String {
        switch self {
        case .trimWhitespace:
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .capitalizeWords:
            return text.capitalized
        case .removeLineBreaks:
            return text.replacingOccurrences(of: "\n", with: " ")
        case .addLineBreaks:
            return text.replacingOccurrences(of: " ", with: "\n")
        case .removeNumbers:
            return text.replacingOccurrences(of: "\\d", with: "", options: .regularExpression)
        case .removeSpecialChars:
            return text.replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
        case .urlEncode:
            return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        case .urlDecode:
            return text.removingPercentEncoding ?? text
        case .base64Encode:
            return Data(text.utf8).base64EncodedString()
        case .base64Decode:
            guard let data = Data(base64Encoded: text) else { return text }
            return String(data: data, encoding: .utf8) ?? text
        case .reverseText:
            return String(text.reversed())
        case .sortLines:
            return text.components(separatedBy: .newlines).sorted().joined(separator: "\n")
        case .removeDuplicateLines:
            let lines = text.components(separatedBy: .newlines)
            return Array(Set(lines)).joined(separator: "\n")
        }
    }
}

 