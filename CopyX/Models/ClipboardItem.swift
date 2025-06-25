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
        case rtf = "rtf"           // 富文本
        case code = "code"         // 代码片段
        case json = "json"         // JSON 数据
        case xml = "xml"           // XML 数据
        case email = "email"       // 邮箱地址
        case phone = "phone"       // 电话号码
        
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
            case .rtf:
                return "doc.richtext"
            case .code:
                return "chevron.left.forwardslash.chevron.right"
            case .json:
                return "curlybraces"
            case .xml:
                return "chevron.left.forwardslash.chevron.right"
            case .email:
                return "envelope"
            case .phone:
                return "phone"
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
            case .rtf:
                return "rtf_type".localized
            case .code:
                return "code_type".localized
            case .json:
                return "json_type".localized
            case .xml:
                return "xml_type".localized
            case .email:
                return "email_type".localized
            case .phone:
                return "phone_type".localized
            }
        }
        
        var displayName: String {
            return localized
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
            case .rtf:
                return "systemGreen"
            case .code:
                return "systemIndigo"
            case .json:
                return "systemTeal"
            case .xml:
                return "systemCyan"
            case .email:
                return "systemPink"
            case .phone:
                return "systemBrown"
            }
        }
        
        var color: Color {
            switch self {
            case .text:
                return .green
            case .image:
                return .orange
            case .url:
                return .blue
            case .file:
                return .purple
            case .rtf:
                return Color(red: 0.2, green: 0.7, blue: 0.2)  // 深绿色
            case .code:
                return .indigo
            case .json:
                return .teal
            case .xml:
                return .cyan
            case .email:
                return .pink
            case .phone:
                return Color(red: 0.6, green: 0.4, blue: 0.2)  // 棕色
            }
        }
        
        /// 检测内容类型
        static func detectType(from content: String) -> ClipboardItemType {
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检测邮箱
            if isValidEmail(trimmedContent) {
                return .email
            }
            
            // 检测电话号码
            if isValidPhoneNumber(trimmedContent) {
                return .phone
            }
            
            // 检测 URL
            if isValidURL(trimmedContent) {
                return .url
            }
            
            // 检测 JSON
            if isValidJSON(trimmedContent) {
                return .json
            }
            
            // 检测 XML
            if isValidXML(trimmedContent) {
                return .xml
            }
            
            // 检测代码
            if isCodeContent(trimmedContent) {
                return .code
            }
            
            // 检测富文本标记
            if containsRichTextMarkers(trimmedContent) {
                return .rtf
            }
            
            // 默认为普通文本
            return .text
        }
        
        private static func isValidEmail(_ string: String) -> Bool {
            let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
            return string.range(of: emailRegex, options: .regularExpression) != nil
        }
        
        private static func isValidPhoneNumber(_ string: String) -> Bool {
            let phoneRegex = #"^[\+]?[1-9][\d]{3,14}$|^[\+]?[(]?[\d\s\-\(\)]{7,}$"#
            let cleanString = string.replacingOccurrences(of: "[\\s\\-\\(\\)]", with: "", options: .regularExpression)
            return cleanString.range(of: phoneRegex, options: .regularExpression) != nil
        }
        
        private static func isValidURL(_ string: String) -> Bool {
            guard let url = URL(string: string), 
                  let scheme = url.scheme,
                  ["http", "https", "ftp", "file"].contains(scheme.lowercased()) else {
                return false
            }
            return true
        }
        
        private static func isValidJSON(_ string: String) -> Bool {
            guard string.hasPrefix("{") || string.hasPrefix("[") else { return false }
            guard let data = string.data(using: .utf8) else { return false }
            
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
                return true
            } catch {
                return false
            }
        }
        
        private static func isValidXML(_ string: String) -> Bool {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasPrefix("<?xml") || 
                   (trimmed.hasPrefix("<") && trimmed.hasSuffix(">") && trimmed.contains("</"))
        }
        
        private static func isCodeContent(_ string: String) -> Bool {
            let codeIndicators = [
                "function ", "class ", "import ", "export ", "const ", "let ", "var ",
                "def ", "class ", "import ", "from ", "if __name__",
                "public class", "private ", "protected ", "static ",
                "#include", "#define", "int main", "void ",
                "SELECT ", "INSERT ", "UPDATE ", "DELETE ", "CREATE TABLE"
            ]
            
            let lowercased = string.lowercased()
            return codeIndicators.contains { lowercased.contains($0.lowercased()) } ||
                   string.contains("```") ||
                   string.filter({ $0 == "{" }).count > 2 ||
                   string.filter({ $0 == ";" }).count > 2
        }
        
        private static func containsRichTextMarkers(_ string: String) -> Bool {
            let rtfMarkers = ["\\rtf", "\\f0", "\\fs", "\\b0", "\\i0", "{\\rtf"]
            return rtfMarkers.contains { string.contains($0) }
        }
    }
    
    var displayContent: String {
        switch type {
        case .text, .url:
            // 对于长文本，显示更多内容，但在卡片中通过ScrollView处理显示
            return content
        case .image:
            return "image_content".localized
        case .file:
            return content
        case .rtf:
            return content
        case .code:
            return content
        case .json:
            return content
        case .xml:
            return content
        case .email:
            return content
        case .phone:
            return content
        }
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            return "yesterday".localized
        } else {
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: timestamp)
        }
    }
    
    var relativeTime: String {
        let timeInterval = Date().timeIntervalSince(timestamp)
        
        // 小于1分钟
        if timeInterval < 60 {
            return "just_now".localized
        }
        // 小于1小时
        else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            if minutes == 1 {
                return "minute_ago".localized
            } else {
                return String(format: "minutes_ago".localized, minutes)
            }
        }
        // 小于24小时
        else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            if hours == 1 {
                return "hour_ago".localized
            } else {
                return String(format: "hours_ago".localized, hours)
            }
        }
        // 小于7天
        else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            if days == 1 {
                return "day_ago".localized
            } else {
                return String(format: "days_ago".localized, days)
            }
        }
        // 超过7天显示日期
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: timestamp)
        }
    }
    
    mutating func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch type {
        case .text, .url, .rtf, .code, .json, .xml, .email, .phone:
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
        case .text, .url, .rtf, .code, .json, .xml, .email, .phone:
            return String(content.prefix(50))
        case .image:
            return "image_content".localized
        case .file:
            return URL(string: content)?.lastPathComponent ?? "file_type".localized
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
    
    // MARK: - UI Enhancement Methods
    
    /// 获取应用特定的主题色
    func getAppThemeColor() -> Color {
        let appName = sourceApp.lowercased()
        let bundleId = sourceAppBundleIdentifier?.lowercased() ?? ""
        
        // 首先尝试通过 Bundle ID 精确匹配
        switch bundleId {
        case "com.apple.safari":
            return Color.blue
        case "com.google.chrome", "com.google.chrome.canary":
            return Color(red: 66/255, green: 133/255, blue: 244/255) // Google Blue
        case "org.mozilla.firefox":
            return Color(red: 255/255, green: 95/255, blue: 21/255) // Firefox Orange
        case "com.apple.dt.xcode":
            return Color(red: 20/255, green: 122/255, blue: 255/255) // Xcode Blue
        case "com.microsoft.vscode":
            return Color(red: 0/255, green: 122/255, blue: 204/255) // VS Code Blue
        case "com.apple.finder":
            return Color(red: 62/255, green: 125/255, blue: 219/255) // Finder Blue
        case "com.apple.terminal":
            return Color(red: 40/255, green: 40/255, blue: 40/255) // Terminal Dark
        case "com.apple.notes":
            return Color(red: 255/255, green: 207/255, blue: 74/255) // Notes Yellow
        case "com.apple.mail":
            return Color(red: 26/255, green: 115/255, blue: 232/255) // Mail Blue
        case "com.apple.ichat", "com.apple.messages":
            return Color(red: 52/255, green: 199/255, blue: 89/255) // Messages Green
        case "com.tinyspeck.slackmacgap":
            return Color(red: 74/255, green: 21/255, blue: 75/255) // Slack Purple
        case "com.hnc.discord":
            return Color(red: 88/255, green: 101/255, blue: 242/255) // Discord Blurple
        case "ru.keepcoder.telegram":
            return Color(red: 40/255, green: 159/255, blue: 217/255) // Telegram Blue
        case "com.tencent.xinwechat":
            return Color(red: 7/255, green: 193/255, blue: 96/255) // WeChat Green
        case "com.tencent.qq":
            return Color(red: 18/255, green: 183/255, blue: 245/255) // QQ Blue
        case "com.figma.desktop":
            return Color(red: 162/255, green: 89/255, blue: 255/255) // Figma Purple
        case "com.bohemiancoding.sketch3":
            return Color(red: 253/255, green: 197/255, blue: 0/255) // Sketch Orange
        case "com.adobe.photoshop":
            return Color(red: 0/255, green: 104/255, blue: 183/255) // Photoshop Blue
        case "com.adobe.illustrator":
            return Color(red: 255/255, green: 127/255, blue: 0/255) // Illustrator Orange
        case "notion.id":
            return Color(red: 55/255, green: 53/255, blue: 47/255) // Notion Dark
        case "md.obsidian":
            return Color(red: 106/255, green: 57/255, blue: 175/255) // Obsidian Purple
        case "com.typora.typora":
            return Color(red: 51/255, green: 126/255, blue: 169/255) // Typora Blue
        case "com.sublimetext.4":
            return Color(red: 255/255, green: 152/255, blue: 0/255) // Sublime Orange
        case "com.jetbrains.intellij":
            return Color(red: 0/255, green: 112/255, blue: 204/255) // IntelliJ Blue
        case "com.postmanlabs.mac":
            return Color(red: 255/255, green: 109/255, blue: 56/255) // Postman Orange
        case "com.docker.docker":
            return Color(red: 33/255, green: 150/255, blue: 243/255) // Docker Blue
        case "com.spotify.client":
            return Color(red: 30/255, green: 215/255, blue: 96/255) // Spotify Green
        case "com.apple.music":
            return Color(red: 250/255, green: 60/255, blue: 78/255) // Apple Music Red
        case "com.apple.podcasts":
            return Color(red: 146/255, green: 86/255, blue: 243/255) // Podcasts Purple
        case "com.apple.calculator":
            return Color(red: 127/255, green: 127/255, blue: 127/255) // Calculator Gray
        case "com.apple.systempreferences":
            return Color(red: 127/255, green: 127/255, blue: 127/255) // System Preferences Gray
        default:
            // 如果 Bundle ID 匹配失败，尝试应用名称匹配
            return getAppThemeColorByName(appName)
        }
    }
    
    /// 通过应用名称获取主题色（作为 Bundle ID 匹配的后备方案）
    private func getAppThemeColorByName(_ appName: String) -> Color {
        switch appName {
        case let name where name.contains("safari"):
            return Color.blue
        case let name where name.contains("chrome"):
            return Color(red: 66/255, green: 133/255, blue: 244/255)
        case let name where name.contains("firefox"):
            return Color(red: 255/255, green: 95/255, blue: 21/255)
        case let name where name.contains("xcode"):
            return Color(red: 20/255, green: 122/255, blue: 255/255)
        case let name where name.contains("vscode"), let name where name.contains("code"):
            return Color(red: 0/255, green: 122/255, blue: 204/255)
        case let name where name.contains("finder"):
            return Color(red: 62/255, green: 125/255, blue: 219/255)
        case let name where name.contains("terminal"):
            return Color(red: 40/255, green: 40/255, blue: 40/255)
        case let name where name.contains("notes"), let name where name.contains("备忘录"):
            return Color(red: 255/255, green: 207/255, blue: 74/255)
        case let name where name.contains("mail"), let name where name.contains("邮件"):
            return Color(red: 26/255, green: 115/255, blue: 232/255)
        case let name where name.contains("messages"), let name where name.contains("信息"):
            return Color(red: 52/255, green: 199/255, blue: 89/255)
        case let name where name.contains("slack"):
            return Color(red: 74/255, green: 21/255, blue: 75/255)
        case let name where name.contains("discord"):
            return Color(red: 88/255, green: 101/255, blue: 242/255)
        case let name where name.contains("telegram"):
            return Color(red: 40/255, green: 159/255, blue: 217/255)
        case let name where name.contains("wechat"), let name where name.contains("微信"):
            return Color(red: 7/255, green: 193/255, blue: 96/255)
        case let name where name.contains("qq"):
            return Color(red: 18/255, green: 183/255, blue: 245/255)
        case let name where name.contains("figma"):
            return Color(red: 162/255, green: 89/255, blue: 255/255)
        case let name where name.contains("sketch"):
            return Color(red: 253/255, green: 197/255, blue: 0/255)
        case let name where name.contains("photoshop"):
            return Color(red: 0/255, green: 104/255, blue: 183/255)
        case let name where name.contains("illustrator"):
            return Color(red: 255/255, green: 127/255, blue: 0/255)
        case let name where name.contains("notion"):
            return Color(red: 55/255, green: 53/255, blue: 47/255)
        case let name where name.contains("obsidian"):
            return Color(red: 106/255, green: 57/255, blue: 175/255)
        case let name where name.contains("typora"):
            return Color(red: 51/255, green: 126/255, blue: 169/255)
        case let name where name.contains("sublime"):
            return Color(red: 255/255, green: 152/255, blue: 0/255)
        case let name where name.contains("intellij"), let name where name.contains("idea"):
            return Color(red: 0/255, green: 112/255, blue: 204/255)
        case let name where name.contains("postman"):
            return Color(red: 255/255, green: 109/255, blue: 56/255)
        case let name where name.contains("docker"):
            return Color(red: 33/255, green: 150/255, blue: 243/255)
        case let name where name.contains("spotify"):
            return Color(red: 30/255, green: 215/255, blue: 96/255)
        case let name where name.contains("music"), let name where name.contains("音乐"):
            return Color(red: 250/255, green: 60/255, blue: 78/255)
        case let name where name.contains("podcast"):
            return Color(red: 146/255, green: 86/255, blue: 243/255)
        default:
            // 为其他应用生成基于名称的一致颜色
            return generateConsistentColor(from: appName)
        }
    }
    
    /// 为未知应用生成一致的颜色
    private func generateConsistentColor(from appName: String) -> Color {
        let hash = abs(appName.hash)
        
        // 使用更协调的颜色调色板
        let colorPalette: [(red: Double, green: Double, blue: Double)] = [
            (red: 74/255, green: 144/255, blue: 226/255),   // 蓝色
            (red: 52/255, green: 199/255, blue: 89/255),    // 绿色
            (red: 255/255, green: 149/255, blue: 0/255),    // 橙色
            (red: 255/255, green: 59/255, blue: 48/255),    // 红色
            (red: 175/255, green: 82/255, blue: 222/255),   // 紫色
            (red: 255/255, green: 204/255, blue: 0/255),    // 黄色
            (red: 90/255, green: 200/255, blue: 250/255),   // 青色
            (red: 255/255, green: 45/255, blue: 85/255),    // 粉色
            (red: 48/255, green: 176/255, blue: 199/255),   // 蓝绿色
            (red: 162/255, green: 132/255, blue: 94/255)    // 棕色
        ]
        
        let selectedColor = colorPalette[hash % colorPalette.count]
        return Color(red: selectedColor.red, green: selectedColor.green, blue: selectedColor.blue)
    }
    
    /// 获取内容预览的智能截取
    var smartPreview: String {
        switch type {
        case .text, .rtf, .code, .json, .xml, .email, .phone:
            // 移除多余的空白字符
            let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            // 智能截取，保持单词完整性
            if cleanContent.count <= 100 {
                return cleanContent
            } else {
                let truncated = String(cleanContent.prefix(100))
                if let lastSpace = truncated.lastIndex(of: " ") {
                    return String(truncated[..<lastSpace]) + "..."
                } else {
                    return truncated + "..."
                }
            }
            
        case .url:
            // URL 显示域名和路径
            if let url = URL(string: content) {
                let host = url.host ?? ""
                let path = url.path
                if path.isEmpty || path == "/" {
                    return host
                } else {
                    return "\(host)\(path)"
                }
            }
            return content
            
        case .image:
            return "image_content".localized
            
        case .file:
            // 文件显示文件名
            if let url = URL(string: content) {
                return url.lastPathComponent
            }
            return content
        }
    }
    
    /// 获取内容的详细信息
    var contentInfo: String {
        switch type {
        case .text, .rtf, .code, .json, .xml:
            let wordCount = content.split(separator: " ").count
            let charCount = content.count
            return "\(charCount) 字符, \(wordCount) 单词"
            
        case .url:
            if let url = URL(string: content) {
                return url.absoluteString
            }
            return content
            
        case .email:
            return content
            
        case .phone:
            return content
            
        case .image:
            return fileSize ?? "图片"
            
        case .file:
            return fileSize ?? "文件"
        }
    }
    
    /// 获取优先级分数（用于排序）
    var priorityScore: Double {
        var score: Double = 0
        
        // 收藏项目优先级更高
        if isFavorite {
            score += 1000
        }
        
        // 使用频率影响优先级
        score += Double(usageCount) * 10
        
        // 时间越近优先级越高
        let timeScore = max(0, 100 - Date().timeIntervalSince(timestamp) / 86400) // 天数
        score += timeScore
        
        // 内容长度适中的优先级更高
        let contentLength = Double(content.count)
        if contentLength > 10 && contentLength < 1000 {
            score += 50
        }
        
        return score
    }
} 