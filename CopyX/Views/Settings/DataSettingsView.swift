import SwiftUI
import UniformTypeIdentifiers

// MARK: - 数据备份设置页面
struct ModernDataSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var showingClearAlert = false
    @State private var showingFullClearAlert = false
    @State private var exportProgress: Double = 0
    @State private var importProgress: Double = 0
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var selectedBackupPath = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 页面标题
                VStack(alignment: .leading, spacing: 6) {
                    LocalizedText("data_backup_title")
                        .font(.title2)
                        .fontWeight(.bold)
                    LocalizedText("data_backup_subtitle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 数据备份部分
                SettingsSection(
                    title: "data_backup".localized,
                    icon: "square.and.arrow.up"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        // 自动备份设置
                        SettingsToggle(
                            title: "auto_clear".localized,
                            subtitle: "auto_cleanup_subtitle".localized,
                            isOn: $clipboardManager.autoCleanup
                        )
                        
                        // 手动备份按钮
                        HStack {
                            SettingsButton(
                                title: "export_data".localized,
                                subtitle: isExporting ? "exporting_data".localized : nil,
                                icon: "square.and.arrow.up",
                                style: .secondary
                            ) {
                                exportData()
                            }
                            .disabled(isExporting)
                            
                            if isExporting {
                                ProgressView(value: exportProgress)
                                    .frame(maxWidth: 200)
                            }
                        }
                        
                        // 导入数据按钮
                        HStack {
                            SettingsButton(
                                title: "import_data".localized,
                                subtitle: isImporting ? "importing_data".localized : nil,
                                icon: "square.and.arrow.down",
                                style: .secondary
                            ) {
                                showingImportDialog = true
                            }
                            .disabled(isImporting)
                            
                            if isImporting {
                                ProgressView(value: importProgress)
                                    .frame(maxWidth: 200)
                            }
                        }
                        
                        // 备份路径设置
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("backup_path".localized)
                                        .font(.system(size: 15, weight: .medium))
                                    Text(selectedBackupPath.isEmpty ? "not_selected".localized : selectedBackupPath)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Spacer()
                                
                                Button("select".localized) {
                                    selectBackupPath()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                                .opacity(0.3)
                        )
                    }
                }
                
                // 数据管理部分
                SettingsSection(
                    title: "data_management".localized,
                    icon: "trash"
                ) {
                    HStack(spacing: 16) {
                        // 智能清空历史记录（保留收藏夹）
                        SettingsButton(
                            title: "smart_clear_history".localized,
                            subtitle: "smart_clear_subtitle".localized,
                            icon: "trash.slash",
                            style: .primary
                        ) {
                            showingClearAlert = true
                        }
                        .frame(maxWidth: .infinity)
                        .alert("confirm_smart_clear_title".localized, isPresented: $showingClearAlert) {
                            Button("cancel".localized, role: .cancel) { }
                            Button("smart_clear_history".localized, role: .destructive) {
                                smartClearHistory()
                            }
                        } message: {
                            Text("confirm_smart_clear_message".localized)
                        }
                        
                        // 完全清空历史记录
                        SettingsButton(
                            title: "full_clear_history".localized,
                            subtitle: "full_clear_subtitle".localized,
                            icon: "trash",
                            style: .destructive
                        ) {
                            showingFullClearAlert = true
                        }
                        .frame(maxWidth: .infinity)
                        .alert("confirm_full_clear_title".localized, isPresented: $showingFullClearAlert) {
                            Button("cancel".localized, role: .cancel) { }
                            Button("full_clear_history".localized, role: .destructive) {
                                clearAllHistory()
                            }
                        } message: {
                            Text("confirm_full_clear_message".localized)
                        }
                    }
                }
                
                // 数据统计部分
                SettingsSection(
                    title: "usage_statistics".localized,
                    icon: "chart.bar"
                ) {
                    DataStatsView(clipboardManager: clipboardManager)
                }
            }
            .padding(20)
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
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        let fileName = String(format: "export_default_filename".localized, DateFormatter.backupFormatter.string(from: Date()))
        panel.nameFieldStringValue = fileName
        
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
                    print("Export failed: \(error.localizedDescription)")
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
                    print("Import failed: \(error.localizedDescription)")
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
    
    private func smartClearHistory() {
        clipboardManager.clearHistoryKeepingFavorites()
    }
    
    private func clearAllHistory() {
        clipboardManager.clearHistory()
    }
}

// MARK: - 数据统计视图
struct DataStatsView: View {
    let clipboardManager: ClipboardManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 使用统一的设置信息卡片风格
            VStack(alignment: .leading, spacing: 8) {
                SettingsInfoCard(
                    title: "total_items_stat".localized,
                    description: "\(clipboardManager.clipboardHistory.count) 个项目",
                    icon: "doc.text",
                    color: .blue
                )
                
                SettingsInfoCard(
                    title: "favorite_items_stat".localized,
                    description: "\(clipboardManager.clipboardHistory.filter { $0.isFavorite }.count) 个收藏",
                    icon: "heart.fill",
                    color: .red
                )
                
                HStack(spacing: 12) {
                    SettingsInfoCard(
                        title: "text_items_stat".localized,
                        description: "\(clipboardManager.clipboardHistory.filter { $0.type == .text }.count)",
                        icon: "textformat",
                        color: .green
                    )
                    
                    SettingsInfoCard(
                        title: "image_items_stat".localized,
                        description: "\(clipboardManager.clipboardHistory.filter { $0.type == .image }.count)",
                        icon: "photo",
                        color: .orange
                    )
                }
            }
        }
    }
}

struct ModernDataSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ModernDataSettingsView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
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
