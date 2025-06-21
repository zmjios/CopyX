import Foundation
import AppKit
import CommonCrypto



class TextProcessor {
    
    // MARK: - 文本格式化
    
    /// 移除多余空白字符
    static func trimWhitespace(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 标准化换行符
    static func normalizeLineBreaks(_ text: String) -> String {
        return text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
    
    /// 移除多余的空行
    static func removeExtraBlankLines(_ text: String) -> String {
        return text.replacingOccurrences(of: "\n\n+", with: "\n\n", options: .regularExpression)
    }
    
    /// 格式化段落（合并换行）
    static func formatParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var currentParagraph = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                if !currentParagraph.isEmpty {
                    result.append(currentParagraph)
                    currentParagraph = ""
                }
                result.append("")
            } else {
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmedLine
            }
        }
        
        if !currentParagraph.isEmpty {
            result.append(currentParagraph)
        }
        
        return result.joined(separator: "\n")
    }
    
    static func removeExtraSpaces(_ text: String) -> String {
        return text.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
    }
    
    // MARK: - 大小写转换
    
    /// 转换为大写
    static func toUppercase(_ text: String) -> String {
        return text.uppercased()
    }
    
    /// 转换为小写
    static func toLowercase(_ text: String) -> String {
        return text.lowercased()
    }
    
    /// 转换为标题格式（每个单词首字母大写）
    static func toTitleCase(_ text: String) -> String {
        return text.capitalized
    }
    
    /// 转换为句子格式（首字母大写）
    static func toSentenceCase(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text.prefix(1).uppercased() + text.dropFirst().lowercased()
    }
    
    /// 驼峰命名法
    static func toCamelCase(_ text: String) -> String {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return text }
        
        let firstWord = words[0].lowercased()
        let remainingWords = words.dropFirst().map { $0.capitalized }
        
        return ([firstWord] + remainingWords).joined()
    }
    
    /// 蛇形命名法
    static func toSnakeCase(_ text: String) -> String {
        return text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: "_")
    }
    
    /// 短横线命名法
    static func toKebabCase(_ text: String) -> String {
        return text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .joined(separator: "-")
    }
    
    // MARK: - 文本反转
    static func reverseText(_ text: String) -> String {
        return String(text.reversed())
    }
    
    // MARK: - 编码解码
    
    /// URL编码
    static func urlEncode(_ text: String) -> String {
        return text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
    }
    
    /// URL解码
    static func urlDecode(_ text: String) -> String {
        return text.removingPercentEncoding ?? text
    }
    
    /// Base64编码
    static func base64Encode(_ text: String) -> String {
        return Data(text.utf8).base64EncodedString()
    }
    
    /// Base64解码
    static func base64Decode(_ text: String) -> String {
        guard let data = Data(base64Encoded: text),
              let decoded = String(data: data, encoding: .utf8) else {
            return text
        }
        return decoded
    }
    
    /// HTML转义
    static func htmlEscape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    /// HTML反转义
    static func htmlUnescape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
    
    // MARK: - 文本分析
    
    static func countCharacters(_ text: String) -> String {
        return String(text.count)
    }

    static func countWords(_ text: String) -> String {
        return String(text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
    }
    
    /// 获取文本统计信息
    static func getTextStats(_ text: String) -> TextStats {
        let characters = text.count
        let charactersNoSpaces = text.replacingOccurrences(of: " ", with: "").count
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let lines = text.components(separatedBy: .newlines).count
        let paragraphs = text.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        
        return TextStats(
            characters: characters,
            charactersNoSpaces: charactersNoSpaces,
            words: words,
            lines: lines,
            paragraphs: paragraphs
        )
    }
    
    /// 提取URL (简化版本，返回字符串)
    static func extractUrls(_ text: String) -> String {
        return extractURLs(text).joined(separator: "\n")
    }
    
    /// 提取URL
    static func extractURLs(_ text: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        } ?? []
    }
    
    /// 提取邮箱地址
    static func extractEmails(_ text: String) -> [String] {
        let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: [])
        let matches = emailRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        } ?? []
    }
    
    /// 提取电话号码
    static func extractPhoneNumbers(_ text: String) -> [String] {
        let phoneRegex = try? NSRegularExpression(pattern: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b|\\b\\d{3}[-.]?\\d{4}[-.]?\\d{4}\\b", options: [])
        let matches = phoneRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        return matches?.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        } ?? []
    }
    
    // MARK: - 文本转换
    
    /// 转换为JSON格式
    static func formatAsJSON(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let result = String(data: formatted, encoding: .utf8) else {
            return text
        }
        return result
    }
    
    /// 压缩JSON
    static func compactJSON(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let compact = try? JSONSerialization.data(withJSONObject: json, options: []),
              let result = String(data: compact, encoding: .utf8) else {
            return text
        }
        return result
    }
    
    /// 生成Markdown表格
    static func generateMarkdownTable(from text: String, delimiter: String = "\t") -> String {
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else { return text }
        
        let rows = lines.map { $0.components(separatedBy: delimiter) }
        let maxColumns = rows.map { $0.count }.max() ?? 0
        
        guard maxColumns > 0 else { return text }
        
        var result = ""
        
        // 表头
        if let firstRow = rows.first {
            result += "| " + firstRow.joined(separator: " | ") + " |\n"
            result += "|" + String(repeating: " --- |", count: maxColumns) + "\n"
        }
        
        // 数据行
        for row in rows.dropFirst() {
            let paddedRow = row + Array(repeating: "", count: max(0, maxColumns - row.count))
            result += "| " + paddedRow.joined(separator: " | ") + " |\n"
        }
        
        return result
    }

    static func generateMD5(_ text: String) -> String {
        let data = Data(text.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    static func generateSHA256(_ text: String) -> String {
        let data = Data(text.utf8)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - 哈希计算
    
    /// 计算字符串的SHA256哈希值
    static func sha256(_ text: String) -> String {
        guard let data = text.data(using: .utf8) else {
            return ""
        }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - 文本统计结构
struct TextStats {
    let characters: Int
    let charactersNoSpaces: Int
    let words: Int
    let lines: Int
    let paragraphs: Int
    
    var description: String {
        return """
        字符数: \(characters)
        字符数(不含空格): \(charactersNoSpaces)
        单词数: \(words)
        行数: \(lines)
        段落数: \(paragraphs)
        """
    }
}

enum AdvancedTextOperation: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case toUpperCase
    case toLowerCase
    case toTitleCase
    case toSentenceCase
    case trimWhitespace
    case removeExtraSpaces
    case reverseText
    case countCharacters
    case countWords
    case toBase64
    case fromBase64
    case urlEncode
    case urlDecode
    case generateMD5
    case generateSHA256

    var displayNameKey: String {
        switch self {
        case .toUpperCase: return "op_upper"
        case .toLowerCase: return "op_lower"
        case .toTitleCase: return "op_title"
        case .toSentenceCase: return "op_sentence"
        case .trimWhitespace: return "op_trim"
        case .removeExtraSpaces: return "op_remove_spaces"
        case .reverseText: return "op_reverse"
        case .countCharacters: return "op_count_chars"
        case .countWords: return "op_count_words"
        case .toBase64: return "op_base64_encode"
        case .fromBase64: return "op_base64_decode"
        case .urlEncode: return "op_url_encode"
        case .urlDecode: return "op_url_decode"
        case .generateMD5: return "op_md5"
        case .generateSHA256: return "op_sha256"
        }
    }
    
    var icon: String {
        switch self {
        case .trimWhitespace, .removeExtraSpaces:
            return "text.alignleft"
        case .toUpperCase, .toLowerCase, .toTitleCase, .toSentenceCase:
            return "textformat.abc"
        case .reverseText:
            return "arrow.2.squarepath"
        case .countCharacters, .countWords:
            return "number"
        case .toBase64, .fromBase64:
            return "lock.shield"
        case .urlEncode, .urlDecode:
            return "link"
        case .generateMD5, .generateSHA256:
            return "lock.shield"
        }
    }
    
    func apply(to text: String) -> String {
        switch self {
        case .toUpperCase:
            return TextProcessor.toUppercase(text)
        case .toLowerCase:
            return TextProcessor.toLowercase(text)
        case .toTitleCase:
            return TextProcessor.toTitleCase(text)
        case .toSentenceCase:
            return TextProcessor.toSentenceCase(text)
        case .trimWhitespace:
            return TextProcessor.trimWhitespace(text)
        case .removeExtraSpaces:
            return TextProcessor.removeExtraSpaces(text)
        case .reverseText:
            return TextProcessor.reverseText(text)
        case .countCharacters:
            return TextProcessor.countCharacters(text)
        case .countWords:
            return TextProcessor.countWords(text)
        case .toBase64:
            return TextProcessor.base64Encode(text)
        case .fromBase64:
            return TextProcessor.base64Decode(text)
        case .urlEncode:
            return TextProcessor.urlEncode(text)
        case .urlDecode:
            return TextProcessor.urlDecode(text)
        case .generateMD5:
            return TextProcessor.generateMD5(text)
        case .generateSHA256:
            return TextProcessor.generateSHA256(text)
        }
    }
}
