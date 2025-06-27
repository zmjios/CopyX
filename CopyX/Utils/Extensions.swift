import Foundation
import SwiftUI

// MARK: - Array Extensions
extension Array {
    /// 将数组分割成指定大小的批次
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - String Extensions
extension String {
    /// 安全的本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 清理敏感信息的字符串
    func sanitized() -> String {
        // 移除可能的敏感信息标记
        var result = self
        
        // 简单的信用卡号遮蔽
        let creditCardPattern = "\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}"
        if let regex = try? NSRegularExpression(pattern: creditCardPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(location: 0, length: result.utf16.count),
                withTemplate: "****-****-****-****"
            )
        }
        
        // 身份证号遮蔽（中国）
        let idCardPattern = "\\d{17}[\\dXx]"
        if let regex = try? NSRegularExpression(pattern: idCardPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(location: 0, length: result.utf16.count),
                withTemplate: "***************"
            )
        }
        
        return result
    }
    
    /// 截断字符串到指定长度
    func truncated(to length: Int, withSuffix suffix: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + suffix
    }
}

// MARK: - Data Extensions
extension Data {
    /// 安全的字符串转换
    var safeString: String {
        return String(data: self, encoding: .utf8) ?? "<Invalid UTF-8>"
    }
    
    /// 格式化文件大小
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self.count))
    }
}

// MARK: - NSImage Extensions
extension NSImage {
    /// 安全的图像压缩
    func compressed(to maxSize: Int) -> NSImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        // 如果图像已经足够小，直接返回
        if tiffData.count <= maxSize {
            return self
        }
        
        // 计算压缩比例
        let compressionRatio = Double(maxSize) / Double(tiffData.count)
        let targetQuality = max(0.1, min(1.0, compressionRatio))
        
        // 压缩图像
        guard let compressedData = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: NSNumber(value: targetQuality)]
        ) else {
            return nil
        }
        
        return NSImage(data: compressedData)
    }
    
    /// 调整图像大小
    func resized(to newSize: NSSize) -> NSImage? {
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        defer { resizedImage.unlockFocus() }
        
        self.draw(in: NSRect(origin: .zero, size: newSize))
        return resizedImage
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    /// 安全设置对象
    func setObject<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            set(data, forKey: key)
        } catch {
            print("Failed to encode object for key \(key): \(error)")
        }
    }
    
    /// 安全获取对象
    func object<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object for key \(key): \(error)")
            return nil
        }
    }
}

// MARK: - Color Extensions
extension Color {
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// 获取十六进制字符串
    var hexString: String {
        let color = NSColor(self)
        let r = Int(color.redComponent * 255)
        let g = Int(color.greenComponent * 255)
        let b = Int(color.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - View Extensions
extension View {
    /// 条件性修饰符
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 条件性可见性
    @ViewBuilder func visible(_ visible: Bool) -> some View {
        if visible {
            self
        } else {
            self.hidden()
        }
    }
} 