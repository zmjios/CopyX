import Foundation
import AppKit
import SwiftUI
import UserNotifications

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

class ClipboardManager: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published var maxHistoryCount: Int = 100
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    
    // 用户设置
    @AppStorage("maxHistoryCount") var storedMaxHistoryCount: Int = 100
    @AppStorage("enabledTypes") var enabledTypesData: Data = Data()
    @AppStorage("excludePasswords") var excludePasswords: Bool = true
    @AppStorage("enableSound") var enableSound: Bool = false
    @AppStorage("autoStart") var autoStart: Bool = true
    @AppStorage("autoCleanup") var autoCleanup: Bool = false
    @AppStorage("enableTextHistory") var enableTextHistory: Bool = true
    @AppStorage("enableImageHistory") var enableImageHistory: Bool = true
    
    // 方便访问的别名
    var skipPasswords: Bool {
        get { excludePasswords }
        set { excludePasswords = newValue }
    }
    
    var enabledTypes: Set<ClipboardItem.ClipboardItemType> {
        get {
            if let types = try? JSONDecoder().decode(Set<ClipboardItem.ClipboardItemType>.self, from: enabledTypesData) {
                return types
            }
            return Set(ClipboardItem.ClipboardItemType.allCases)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                enabledTypesData = data
            }
        }
    }
    
    init() {
        NSLog("ClipboardManager初始化")
        loadClipboardHistory()
        maxHistoryCount = storedMaxHistoryCount
        NSLog("加载的历史记录数量: \(clipboardHistory.count)")
    }
    
    func startMonitoring() {
        NSLog("=== startMonitoring被调用 ===")
        guard !isMonitoring else { 
            NSLog("已经在监控中，跳过")
            return 
        }
        
        NSLog("开始启动剪切板监控")
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        NSLog("初始changeCount: \(lastChangeCount)")
        
        // 立即检查一次当前剪切板内容
        NSLog("立即检查当前剪切板内容...")
        checkForClipboardChanges()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }
        NSLog("=== 定时器已启动，剪切板监控正在运行 ===")
        
        // 测试通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSLog("测试: 剪切板监控服务正在运行... 当前历史记录数量: \(self.clipboardHistory.count)")
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            NSLog("检测到剪切板变化: \(lastChangeCount) -> \(currentChangeCount)")
            lastChangeCount = currentChangeCount
            handleClipboardChange()
        }
    }
    
    private func handleClipboardChange() {
        NSLog("handleClipboardChange被调用")
        guard let newItem = createClipboardItem() else { 
            NSLog("无法创建剪切板项目")
            return 
        }
        
        NSLog("创建了新的剪切板项目: \(newItem.type.displayName) - \(newItem.content.prefix(50))")
        
        // 检查是否与最近的项目重复
        if let lastItem = clipboardHistory.first, lastItem == newItem {
            NSLog("项目重复，跳过")
            return
        }
        
        // 检查是否为密码（简单检测）
        if excludePasswords && isPotentialPassword(newItem.content) {
            NSLog("检测到潜在密码，跳过")
            return
        }
        
        // 检查类型是否启用
        if !enabledTypes.contains(newItem.type) {
            NSLog("类型未启用，跳过: \(newItem.type)")
            return
        }
        
        NSLog("添加到历史记录")
        DispatchQueue.main.async {
            self.addToHistory(newItem)
        }
        
        if enableSound {
            playClipboardSound()
        }
    }
    
    private func createClipboardItem() -> ClipboardItem? {
        // 获取当前前台应用作为来源
        let (sourceApp, bundleId) = getCurrentFrontmostAppInfo()
        
        // 首先尝试获取文本
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let type: ClipboardItem.ClipboardItemType
            
            // 检测URL
            if isValidURL(string) {
                type = .url
            } else {
                type = .text
            }
            
            return ClipboardItem(
                content: string,
                timestamp: Date(),
                type: type,
                sourceApp: sourceApp,
                sourceAppBundleIdentifier: bundleId,
                fileSize: nil
            )
        }
        
        // 尝试获取图片
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let base64String = imageData.base64EncodedString()
            let fileSize = formatFileSize(imageData.count)
            
            return ClipboardItem(
                content: base64String,
                timestamp: Date(),
                type: .image,
                sourceApp: sourceApp,
                sourceAppBundleIdentifier: bundleId,
                fileSize: fileSize
            )
        }
        
        // 尝试获取文件URL
        if let fileURL = pasteboard.string(forType: .fileURL) {
            var fileSize: String?
            if let url = URL(string: fileURL) {
                fileSize = getFileSize(url: url)
            }
            
            return ClipboardItem(
                content: fileURL,
                timestamp: Date(),
                type: .file,
                sourceApp: sourceApp,
                sourceAppBundleIdentifier: bundleId,
                fileSize: fileSize
            )
        }
        
        return nil
    }
    
    private func addToHistory(_ item: ClipboardItem) {
        NSLog("addToHistory被调用，当前历史记录数量: \(clipboardHistory.count)")
        
        // 移除重复项
        clipboardHistory.removeAll { $0 == item }
        
        // 添加到开头
        clipboardHistory.insert(item, at: 0)
        
        NSLog("添加后历史记录数量: \(clipboardHistory.count)")
        
        // 限制历史记录数量
        if clipboardHistory.count > maxHistoryCount {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
        }
        
        saveClipboardHistory()
    }
    
    func removeItem(_ item: ClipboardItem) {
        clipboardHistory.removeAll { $0.id == item.id }
        saveClipboardHistory()
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        saveClipboardHistory()
    }
    
    func updateMaxHistoryCount(_ count: Int) {
        maxHistoryCount = count
        storedMaxHistoryCount = count
        
        if clipboardHistory.count > maxHistoryCount {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
            saveClipboardHistory()
        }
    }
    
    private func saveClipboardHistory() {
        do {
            // 使用文件系统存储而不是UserDefaults
            let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appSupportPath = documentsPath.appendingPathComponent("CopyX", isDirectory: true)
            
            // 创建目录（如果不存在）
            try FileManager.default.createDirectory(at: appSupportPath, withIntermediateDirectories: true, attributes: nil)
            
            let filePath = appSupportPath.appendingPathComponent("clipboardHistory.json")
            let data = try JSONEncoder().encode(clipboardHistory)
            try data.write(to: filePath)
            
            NSLog("剪切板历史已保存到: \(filePath.path)")
        } catch {
            NSLog("保存剪切板历史失败: \(error)")
        }
    }
    
    private func loadClipboardHistory() {
        do {
            let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appSupportPath = documentsPath.appendingPathComponent("CopyX", isDirectory: true)
            let filePath = appSupportPath.appendingPathComponent("clipboardHistory.json")
            
            guard FileManager.default.fileExists(atPath: filePath.path) else {
                print("历史记录文件不存在，使用空数组")
                clipboardHistory = []
                return
            }
            
            let data = try Data(contentsOf: filePath)
            clipboardHistory = try JSONDecoder().decode([ClipboardItem].self, from: data)
            print("成功加载剪切板历史，共 \(clipboardHistory.count) 项")
        } catch {
            print("加载剪切板历史失败: \(error)")
            clipboardHistory = []
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string), url.scheme != nil {
            return true
        }
        return false
    }
    
    private func isPotentialPassword(_ string: String) -> Bool {
        // 简单的密码检测逻辑
        let passwordPatterns = [
            "password", "密码", "passwd", "pwd"
        ]
        
        let lowercased = string.lowercased()
        return passwordPatterns.contains { lowercased.contains($0) }
    }
    
    private func playClipboardSound() {
        NSSound(named: NSSound.Name("Ping"))?.play()
    }
    
    // MARK: - 辅助方法
    private func getCurrentFrontmostApp() -> String {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            return frontmostApp.localizedName ?? "未知应用"
        }
        return "系统"
    }
    
    private func getCurrentFrontmostAppInfo() -> (name: String, bundleId: String?) {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            let name = frontmostApp.localizedName ?? "未知应用"
            let bundleId = frontmostApp.bundleIdentifier
            return (name, bundleId)
        }
        return ("系统", nil)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func getFileSize(url: URL) -> String? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                return formatFileSize(fileSize)
            }
        } catch {
            print("获取文件大小失败: \(error)")
        }
        return nil
    }
    
    // MARK: - 数据导入导出
    func exportData() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "CopyX_Backup_\(DateFormatter.backupFormatter.string(from: Date()))"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                let data = try JSONEncoder().encode(self.clipboardHistory)
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    self.showNotification(title: "导出成功", message: "剪切板历史已成功导出到 \(url.lastPathComponent)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNotification(title: "导出失败", message: "导出时发生错误：\(error.localizedDescription)")
                }
            }
        }
    }
    
    func importData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            guard response == .OK, let url = openPanel.urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let importedItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
                
                DispatchQueue.main.async {
                    // 合并导入的数据，避免重复
                    let existingIds = Set(self.clipboardHistory.map { $0.id })
                    let newItems = importedItems.filter { !existingIds.contains($0.id) }
                    
                    self.clipboardHistory.append(contentsOf: newItems)
                    self.clipboardHistory.sort { $0.timestamp > $1.timestamp }
                    
                    // 限制数量
                    if self.clipboardHistory.count > self.maxHistoryCount {
                        self.clipboardHistory = Array(self.clipboardHistory.prefix(self.maxHistoryCount))
                    }
                    
                    self.saveClipboardHistory()
                    
                    self.showNotification(title: "导入成功", message: "成功导入 \(newItems.count) 个剪切板项目")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showNotification(title: "导入失败", message: "导入时发生错误：\(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        // 使用现代化的 UserNotifications 框架
        if #available(macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            
            // 请求通知权限
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = message
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil
                    )
                    
                    center.add(request) { error in
                        if let error = error {
                            NSLog("通知发送失败: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // 为旧版本系统保留兼容性
            #if swift(>=5.0)
            #warning("使用已废弃的 NSUserNotification API 以支持旧版本系统")
            #endif
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    deinit {
        stopMonitoring()
    }
} 