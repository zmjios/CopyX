import SwiftUI
import UniformTypeIdentifiers

// MARK: - 数据备份设置页面
struct ModernDataSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var showingClearAlert = false
    @State private var exportProgress: Double = 0
    @State private var importProgress: Double = 0
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var selectedBackupPath = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 数据备份部分
                SettingsSection(
                    title: "数据备份",
                    icon: "square.and.arrow.up"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 自动备份设置
                        SettingsToggle(
                            title: "自动清理",
                            subtitle: "定期清理旧的剪切板项目",
                            isOn: $clipboardManager.autoCleanup
                        )
                        
                        // 手动备份按钮
                        HStack {
                            Button("导出数据") {
                                exportData()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isExporting)
                            
                            if isExporting {
                                ProgressView(value: exportProgress)
                                    .frame(maxWidth: 200)
                            }
                        }
                        
                        // 导入数据按钮
                        HStack {
                            Button("导入数据") {
                                showingImportDialog = true
                            }
                            .buttonStyle(.bordered)
                            .disabled(isImporting)
                            
                            if isImporting {
                                ProgressView(value: importProgress)
                                    .frame(maxWidth: 200)
                            }
                        }
                        
                        // 备份路径设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备份路径")
                                .font(.system(size: 13, weight: .medium))
                            
                            HStack {
                                Text(selectedBackupPath.isEmpty ? "未选择" : selectedBackupPath)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button("选择") {
                                    selectBackupPath()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
                
                // 数据管理部分
                SettingsSection(
                    title: "数据管理",
                    icon: "trash"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 清空历史记录
                        Button("清空所有历史记录") {
                            showingClearAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .alert("确认清空", isPresented: $showingClearAlert) {
                            Button("取消", role: .cancel) { }
                            Button("清空", role: .destructive) {
                                clearAllHistory()
                            }
                        } message: {
                            Text("此操作将清空所有剪切板历史记录，且无法撤销。")
                        }
                    }
                }
                
                // 数据统计部分
                SettingsSection(
                    title: "数据统计",
                    icon: "chart.bar"
                ) {
                    DataStatsView(clipboardManager: clipboardManager)
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importData(from: url)
                }
            case .failure(let error):
                print("导入失败: \(error)")
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clipboard_backup_\(DateFormatter.backupFormatter.string(from: Date())).json"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                performExport(to: url)
            }
        }
    }
    
    private func performExport(to url: URL) {
        isExporting = true
        exportProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 模拟导出进度
            for i in 1...10 {
                Thread.sleep(forTimeInterval: 0.1)
                DispatchQueue.main.async {
                    exportProgress = Double(i) / 10.0
                }
            }
            
            // 执行实际导出
            do {
                let data = try JSONEncoder().encode(clipboardManager.clipboardHistory)
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    isExporting = false
                    exportProgress = 0
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    exportProgress = 0
                    print("导出失败: \(error)")
                }
            }
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        importProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 模拟导入进度
            for i in 1...10 {
                Thread.sleep(forTimeInterval: 0.1)
                DispatchQueue.main.async {
                    importProgress = Double(i) / 10.0
                }
            }
            
            // 执行实际导入
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([ClipboardItem].self, from: data)
                
                DispatchQueue.main.async {
                    // 合并导入的数据
                    for item in items {
                        if !clipboardManager.clipboardHistory.contains(item) {
                            clipboardManager.clipboardHistory.append(item)
                        }
                    }
                    
                    isImporting = false
                    importProgress = 0
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    importProgress = 0
                    print("导入失败: \(error)")
                }
            }
        }
    }
    
    private func selectBackupPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.urls.first {
                selectedBackupPath = url.path
            }
        }
    }
    
    private func clearAllHistory() {
        clipboardManager.clipboardHistory.removeAll()
    }
}

// MARK: - 数据统计视图
struct DataStatsView: View {
    let clipboardManager: ClipboardManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(
                label: "总项目数",
                value: "\(clipboardManager.clipboardHistory.count)"
            )
            
            StatRow(
                label: "文本项目",
                value: "\(textItemsCount)"
            )
            
            StatRow(
                label: "图片项目",
                value: "\(imageItemsCount)"
            )
            
            StatRow(
                label: "文件项目",
                value: "\(fileItemsCount)"
            )
            
            StatRow(
                label: "URL项目",
                value: "\(urlItemsCount)"
            )
            
            StatRow(
                label: "最大历史数量",
                value: "\(clipboardManager.maxHistoryCount)"
            )
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var textItemsCount: Int {
        clipboardManager.clipboardHistory.filter { $0.type == .text }.count
    }
    
    private var imageItemsCount: Int {
        clipboardManager.clipboardHistory.filter { $0.type == .image }.count
    }
    
    private var fileItemsCount: Int {
        clipboardManager.clipboardHistory.filter { $0.type == .file }.count
    }
    
    private var urlItemsCount: Int {
        clipboardManager.clipboardHistory.filter { $0.type == .url }.count
    }
}



// MARK: - 备份间隔枚举
enum BackupInterval: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
} 