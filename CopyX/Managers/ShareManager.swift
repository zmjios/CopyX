import SwiftUI
import AppKit
import UserNotifications

// MARK: - 分享管理器
class ShareManager: ObservableObject {
    static let shared = ShareManager()
    
    private init() {}
    
    // MARK: - 系统分享
    func shareToSystem(_ item: ClipboardItem) {
        let shareText = prepareShareContent(item)
        let finalText = shareText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !finalText.isEmpty else {
            NSLog("分享文本为空")
            return
        }
        
        // 直接使用系统原生分享选择器
        DispatchQueue.main.async {
            let sharingServicePicker = NSSharingServicePicker(items: [finalText])
            
            if let window = NSApp.keyWindow {
                let rect = NSRect(x: window.frame.midX, y: window.frame.midY, width: 1, height: 1)
                sharingServicePicker.show(relativeTo: rect, of: window.contentView!, preferredEdge: .minY)
            }
        }
    }
    
    // MARK: - 微信分享
    func shareToWeChat(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        // 首先检查微信是否安装
        if isWeChatInstalled() {
            shareToWeChatDirectly(content: content, item: item)
        } else {
            showWeChatNotInstalledAlert(content: content)
        }
    }
    
    // MARK: - 其他平台分享
    func shareToTwitter(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let twitterURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedContent)") {
            NSWorkspace.shared.open(twitterURL)
            showShareNotification(platform: "X (Twitter)", message: "正在打开 X...")
        }
    }
    
    func shareToWeibo(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let weiboURL = URL(string: "https://service.weibo.com/share/share.php?title=\(encodedContent)") {
            NSWorkspace.shared.open(weiboURL)
            showShareNotification(platform: "微博", message: "正在打开微博...")
        }
    }
    
    func shareToQQ(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        if let qqURL = URL(string: "mqq://") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            
            NSWorkspace.shared.open(qqURL, configuration: NSWorkspace.OpenConfiguration()) { app, error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.showShareNotification(platform: "QQ", message: "内容已复制到剪切板，请在QQ中粘贴")
                    } else {
                        self.shareToSystem(item)
                    }
                }
            }
        }
    }
    
    // MARK: - 复制到剪切板
    func copyToClipboard(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        NSPasteboard.general.clearContents()
        
        switch item.type {
        case .text, .url, .file, .rtf, .code, .json, .xml, .email, .phone:
            NSPasteboard.general.setString(content, forType: .string)
        case .image:
            if let imageData = Data(base64Encoded: item.content),
               let nsImage = NSImage(data: imageData) {
                NSPasteboard.general.writeObjects([nsImage])
                NSPasteboard.general.setString(content, forType: .string)
            } else {
                NSPasteboard.general.setString(content, forType: .string)
            }
        }
        
        showShareNotification(platform: "剪切板", message: "内容已复制到剪切板")
    }
    
    // MARK: - 私有方法
    private func prepareShareContent(_ item: ClipboardItem) -> String {
        switch item.type {
        case .text, .rtf, .code, .json, .xml, .email, .phone:
            return item.content
        case .url:
            return item.content
        case .image:
            return "分享了一张图片"
        case .file:
            return "分享了文件: \(item.displayTitle)"
        }
    }
    
    private func isWeChatInstalled() -> Bool {
        if let wechatURL = URL(string: "weixin://") {
            return NSWorkspace.shared.urlForApplication(toOpen: wechatURL) != nil
        }
        return false
    }
    
    private func shareToWeChatDirectly(content: String, item: ClipboardItem) {
        // 创建临时文件用于分享
        let tempURL = createTempFileForSharing(content: content, item: item)
        
        // 使用系统分享服务直接分享到微信
        if let tempURL = tempURL {
            let sharingItems: [Any]
            
            switch item.type {
            case .text, .url, .rtf, .code, .json, .xml, .email, .phone:
                sharingItems = [content]
            case .image:
                if let imageData = Data(base64Encoded: item.content),
                   let nsImage = NSImage(data: imageData) {
                    sharingItems = [nsImage, content]
                } else {
                    sharingItems = [content]
                }
            case .file:
                sharingItems = [tempURL, "文件: \(item.displayTitle)"]
            }
            
            DispatchQueue.main.async {
                // 查找微信分享服务
                if let wechatService = NSSharingService.sharingServices(forItems: sharingItems)
                    .first(where: { $0.title.contains("微信") || $0.title.contains("WeChat") }) {
                    
                    if wechatService.canPerform(withItems: sharingItems) {
                        wechatService.perform(withItems: sharingItems)
                        self.showShareNotification(platform: "微信", message: "正在分享到微信...")
                    } else {
                        self.fallbackToWeChatURLScheme(content: content, item: item)
                    }
                } else {
                    self.fallbackToWeChatURLScheme(content: content, item: item)
                }
            }
        } else {
            fallbackToWeChatURLScheme(content: content, item: item)
        }
    }
    
    private func createTempFileForSharing(content: String, item: ClipboardItem) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName: String
        
        switch item.type {
        case .text, .rtf, .code, .json, .xml, .email, .phone:
            fileName = "shared_text.txt"
        case .url:
            fileName = "shared_url.txt"
        case .image:
            fileName = "shared_image.txt"
        case .file:
            fileName = "shared_file_info.txt"
        }
        
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            NSLog("创建临时文件失败: \(error)")
            return nil
        }
    }
    
    private func fallbackToWeChatURLScheme(content: String, item: ClipboardItem) {
        // 原有的URL Scheme方式作为备选
        shareToWeChatWithURLScheme(content: content, item: item)
    }
    
    private func shareToWeChatWithURLScheme(content: String, item: ClipboardItem) {
        var shareURL: URL?
        
        switch item.type {
        case .text, .url, .rtf, .code, .json, .xml, .email, .phone:
            shareURL = URL(string: "weixin://dl/stickers")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
        case .image:
            shareURL = URL(string: "weixin://dl/moments")
            if let imageData = Data(base64Encoded: item.content),
               let nsImage = NSImage(data: imageData) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([nsImage])
            }
        case .file:
            shareURL = URL(string: "weixin://dl/chat")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("文件: \(item.displayTitle)", forType: .string)
        }
        
        if let url = shareURL {
            NSWorkspace.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWeChatShareGuidance(for: item.type)
            }
        }
    }
    
    private func showWeChatShareGuidance(for type: ClipboardItem.ClipboardItemType) {
        let message: String
        switch type {
        case .text, .url, .rtf, .code, .json, .xml, .email, .phone:
            message = "内容已复制到剪切板，在微信中长按输入框粘贴分享"
        case .image:
            message = "图片已复制到剪切板，在微信中点击相册选择或粘贴分享"
        case .file:
            message = "文件信息已复制，可在微信文件传输助手中分享"
        }
        
        showShareNotification(platform: "微信", message: message)
    }
    
    private func showWeChatNotInstalledAlert(content: String) {
        let alert = NSAlert()
        alert.messageText = "微信未安装"
        alert.informativeText = "您的设备上没有安装微信应用。是否要打开微信网页版？"
        alert.addButton(withTitle: "打开网页版")
        alert.addButton(withTitle: "复制内容")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            if let webURL = URL(string: "https://wx.qq.com/") {
                NSWorkspace.shared.open(webURL)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
                showShareNotification(platform: "微信网页版", message: "内容已复制到剪切板")
            }
        case .alertSecondButtonReturn:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            showShareNotification(platform: "剪切板", message: "内容已复制到剪切板")
        default:
            break
        }
    }
    
    private func showShareNotification(platform: String, message: String) {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    let content = UNMutableNotificationContent()
                    content.title = "分享到\(platform)"
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
        }
    }
} 