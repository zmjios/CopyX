import Foundation
import SwiftUI
import AppKit

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ClipboardItemType
    let sourceApp: String // 来源应用
    let sourceAppBundleIdentifier: String? // 应用Bundle ID
    let fileSize: String? // 文件大小（对于图片等）
    
    // 新增收藏夹相关属性
    var isFavorite: Bool = false
    var tags: [String] = []
    var customTitle: String?
    var usageCount: Int = 0
    var lastUsedDate: Date?
    
    init(content: String, timestamp: Date, type: ClipboardItemType, sourceApp: String, sourceAppBundleIdentifier: String?, fileSize: String?) {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.sourceApp = sourceApp
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.fileSize = fileSize
    }
    
    // 获取应用图标
    func getAppIcon() -> NSImage? {
        // 优先使用Bundle ID获取图标
        if let bundleId = sourceAppBundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        
        // 退回到使用应用名称搜索
        let appName = sourceApp.lowercased()
        if let foundApp = NSWorkspace.shared.runningApplications.first(where: { 
            $0.localizedName?.lowercased().contains(appName) == true 
        }) {
            return foundApp.icon
        }
        
        // 使用默认图标
        return NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil)
    }
    
    // 获取应用图标的主色调
    func getAppIconDominantColor() -> NSColor {
        guard let icon = getAppIcon() else {
            return getTypeColor()
        }
        
        // 将图标转换为较小尺寸以提高性能
        let size = NSSize(width: 32, height: 32)
        let resizedIcon = NSImage(size: size)
        resizedIcon.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: size))
        resizedIcon.unlockFocus()
        
        // 获取图像的bitmap表示
        guard let tiffData = resizedIcon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return getTypeColor()
        }
        
        // 分析主色调
        var redSum: CGFloat = 0
        var greenSum: CGFloat = 0
        var blueSum: CGFloat = 0
        var pixelCount: CGFloat = 0
        
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        
        for x in 0..<width {
            for y in 0..<height {
                if let color = bitmap.colorAt(x: x, y: y) {
                    // 跳过透明和接近白色的像素
                    if color.alphaComponent > 0.5 && 
                       (color.redComponent + color.greenComponent + color.blueComponent) < 2.4 {
                        redSum += color.redComponent
                        greenSum += color.greenComponent
                        blueSum += color.blueComponent
                        pixelCount += 1
                    }
                }
            }
        }
        
        if pixelCount > 0 {
            let avgRed = redSum / pixelCount
            let avgGreen = greenSum / pixelCount
            let avgBlue = blueSum / pixelCount
            return NSColor(red: avgRed, green: avgGreen, blue: avgBlue, alpha: 1.0)
        }
        
        return getTypeColor()
    }
    
    // 获取类型默认颜色
    private func getTypeColor() -> NSColor {
        switch type.backgroundColor {
        case "systemGreen": return NSColor.systemGreen
        case "systemOrange": return NSColor.systemOrange
        case "systemBlue": return NSColor.systemBlue
        case "systemPurple": return NSColor.systemPurple
        default: return NSColor.systemGray
        }
    }
    
    enum ClipboardItemType: String, CaseIterable, Codable {
        case text = "text"
        case image = "image"
        case url = "url"
        case file = "file"
        
        var iconName: String {
            switch self {
            case .text:
                return "doc.text"
            case .image:
                return "photo"
            case .url:
                return "link"
            case .file:
                return "doc"
            }
        }
        
        var localized: String {
            switch self {
            case .text:
                return "text_type".localized
            case .image:
                return "image_type".localized
            case .url:
                return "url_type".localized
            case .file:
                return "file_type".localized
            }
        }
        
        var displayName: String {
            switch self {
            case .text:
                return "富文本"
            case .image:
                return "图片"
            case .url:
                return "链接"
            case .file:
                return "文件"
            }
        }
        
        var backgroundColor: String {
            switch self {
            case .text:
                return "systemGreen"
            case .image:
                return "systemOrange"
            case .url:
                return "systemBlue"
            case .file:
                return "systemPurple"
            }
        }
    }
    
    var displayContent: String {
        switch type {
        case .text, .url:
            // 对于长文本，显示更多内容，但在卡片中通过ScrollView处理显示
            return content
        case .image:
            return "图片内容"
        case .file:
            return content
        }
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: timestamp)
        }
    }
    
    var relativeTime: String {
        let timeInterval = Date().timeIntervalSince(timestamp)
        
        // 1小时内显示相对时间
        if timeInterval < 3600 {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: timestamp, relativeTo: Date())
        } else {
            // 1小时之前显示具体时间
            let formatter = DateFormatter()
            let calendar = Calendar.current
            
            if calendar.isDateInToday(timestamp) {
                formatter.dateFormat = "HH:mm"
                return "今天 " + formatter.string(from: timestamp)
            } else if calendar.isDateInYesterday(timestamp) {
                formatter.dateFormat = "HH:mm"
                return "昨天 " + formatter.string(from: timestamp)
            } else {
                formatter.dateFormat = "MM-dd HH:mm"
                return formatter.string(from: timestamp)
            }
        }
    }
    
    mutating func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text, .url:
            pasteboard.setString(content, forType: .string)
        case .image:
            if let data = Data(base64Encoded: content) {
                pasteboard.setData(data, forType: .tiff)
            }
        case .file:
            pasteboard.setString(content, forType: .fileURL)
        }
        
        // 更新使用统计
        updateUsageStats()
    }
    
    // 更新使用统计
    mutating func updateUsageStats() {
        usageCount += 1
        lastUsedDate = Date()
    }
    
    // 切换收藏状态
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
    
    // 添加标签
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    // 移除标签
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    // 设置自定义标题
    mutating func setCustomTitle(_ title: String?) {
        customTitle = title?.isEmpty == true ? nil : title
    }
    
    // 获取显示标题
    var displayTitle: String {
        if let customTitle = customTitle, !customTitle.isEmpty {
            return customTitle
        }
        
        switch type {
        case .text, .url:
            return String(content.prefix(50))
        case .image:
            return "图片内容"
        case .file:
            return URL(string: content)?.lastPathComponent ?? "文件"
        }
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.content == rhs.content && lhs.type == rhs.type
    }
    
    // 自定义解码器，支持向后兼容
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(ClipboardItemType.self, forKey: .type)
        sourceApp = try container.decode(String.self, forKey: .sourceApp)
        fileSize = try container.decodeIfPresent(String.self, forKey: .fileSize)
        
        // 新字段，支持向后兼容
        sourceAppBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleIdentifier)
        
        // 新增收藏夹相关属性，支持向后兼容
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        customTitle = try container.decodeIfPresent(String.self, forKey: .customTitle)
        usageCount = try container.decodeIfPresent(Int.self, forKey: .usageCount) ?? 0
        lastUsedDate = try container.decodeIfPresent(Date.self, forKey: .lastUsedDate)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, content, timestamp, type, sourceApp, sourceAppBundleIdentifier, fileSize, isFavorite, tags, customTitle, usageCount, lastUsedDate
    }
} 