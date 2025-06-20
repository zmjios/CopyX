import SwiftUI
import AppKit

// MARK: - 剪切板项目视图
struct ClipboardItemView: View {
    let item: ClipboardItem
    let index: Int
    @Binding var selectedItem: ClipboardItem?
    @Binding var showShareModal: Bool
    @Binding var showShareMenu: Bool
    @Binding var shareMenuItem: ClipboardItem?
    @ObservedObject var clipboardManager: ClipboardManager
    
    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            mainContentView
            dividerView
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    clipboardManager.removeItem(item)
                    if selectedItem?.id == item.id {
                        selectedItem = nil
                    }
                }
            }
        } message: {
            Text("确定要删除这个剪切板项目吗？此操作无法撤销。")
        }
    }
    
    private var mainContentView: some View {
        HStack(spacing: 12) {
            leftIconView
            contentAreaView
            Spacer()
            actionButtonsView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundView)
        .overlay(borderView)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedItem = selectedItem?.id == item.id ? nil : item
            }
        }
        .contentShape(Rectangle())
    }
    
    private var leftIconView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(item.type.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.type.color)
            }
            
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var contentAreaView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.displayTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
            
            Text(item.displayContent)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
            
            HStack {
                Text(formatTimestamp(item.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !item.content.isEmpty {
                    Text("\(item.content.count) 字符")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        if isHovered || selectedItem?.id == item.id {
            HStack(spacing: 8) {
                ActionButton(
                    icon: "doc.on.doc",
                    color: .blue,
                    tooltip: "复制到剪切板"
                ) {
                    clipboardManager.copyToPasteboard(item)
                }
                
                ActionButton(
                    icon: "square.and.arrow.up",
                    color: .green,
                    tooltip: "分享"
                ) {
                    shareMenuItem = item
                    showShareModal = true
                }
                
                ActionButton(
                    icon: "trash",
                    color: .red,
                    tooltip: "删除"
                ) {
                    showingDeleteConfirmation = true
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(selectedItem?.id == item.id ? 
                  Color(NSColor.controlAccentColor).opacity(0.1) : 
                  (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(selectedItem?.id == item.id ? 
                   Color(NSColor.controlAccentColor).opacity(0.3) : 
                   Color.clear, lineWidth: 1)
    }
    
    @ViewBuilder
    private var dividerView: some View {
        if index < clipboardManager.clipboardHistory.count - 1 {
            Divider()
                .padding(.horizontal, 16)
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDate(timestamp, inSameDayAs: now) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: timestamp))"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(timestamp, inSameDayAs: yesterday) {
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: timestamp))"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(timestamp) == true {
            formatter.dateFormat = "E HH:mm"
            return formatter.string(from: timestamp)
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: timestamp)
        }
    }
}

// MARK: - 扩展：剪切板项目类型
extension ClipboardItem.ClipboardItemType {
    var icon: String {
        switch self {
        case .text:
            return "doc.text"
        case .url:
            return "link"
        case .image:
            return "photo"
        case .file:
            return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .text:
            return .blue
        case .url:
            return .purple
        case .image:
            return .orange
        case .file:
            return .green
        }
    }
}

// MARK: - 原始精美卡片视图（完全恢复原设计）
struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetail: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var isCopied: Bool = false
    @State private var showCopyFeedback: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部类型标签区域
            cardTypeHeader
            
            // 主要内容区域
            cardMainContent
            
            // 底部信息栏
            cardBottomInfo
        }
        .frame(width: 320, height: 260)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .overlay(copyFeedbackOverlay)
        .scaleEffect(cardScale)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: isHovered)
        .animation(.interpolatingSpring(stiffness: 400, damping: 20), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .animation(.bouncy(duration: 0.6), value: isCopied)
        .onHover { hovering in
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            performCopyAnimation()
        }
        .onTapGesture(count: 2) {
            onShowDetail()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    // 顶部类型标签
    private var cardTypeHeader: some View {
        HStack {
            // 应用图标和来源信息
            HStack(spacing: 8) {
                // 应用图标
                Group {
                    if let appIcon = item.getAppIcon() {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "app.badge")
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 18, height: 18)
                .cornerRadius(4)
                
                // 应用名称
                Text(item.sourceApp)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(item.getAppIconDominantColor()),
                                Color(item.getAppIconDominantColor()).opacity(0.8),
                                Color(item.getAppIconDominantColor()).opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(item.getAppIconDominantColor()).opacity(0.3), radius: 4, x: 0, y: 2)
            )
            
            Spacer()
            
            // 类型标签
            HStack(spacing: 4) {
                Image(systemName: item.type.iconName)
                    .font(.system(size: 10, weight: .medium))
                Text(item.type.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                getTypeGradientColor().opacity(0.3),
                                getTypeGradientColor().opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(getTypeGradientColor())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // 主要内容区域
    private var cardMainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if item.type == .image {
                imageContentView
            } else {
                textContentView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // 图片内容视图
    private var imageContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = Data(base64Encoded: item.content),
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 90)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.systemGray))
                    .frame(height: 90)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("图片预览")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            if let fileSize = item.fileSize {
                Text(fileSize)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
            }
        }
    }
    
    // 文本内容视图
    private var textContentView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 文本内容 - 使用更大的字体和更好的行距
            Text(item.displayContent)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(2)
                .foregroundColor(.primary)
                .lineLimit(7)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .multilineTextAlignment(.leading)
            
            // 如果文本太长，显示"查看全部"按钮
            if item.content.count > 100 {
                Spacer()
                    .frame(height: 8)
                
                HStack {
                    Spacer()
                    Button("查看全部") {
                        onShowDetail()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 4)
            }
        }
    }
    
    // 底部信息栏
    private var cardBottomInfo: some View {
        HStack {
            // 左侧：序号和文件大小信息
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(item.getAppIconDominantColor()))
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color(item.getAppIconDominantColor()).opacity(0.1))
                    )
                
                if let fileSize = item.fileSize {
                    Text(fileSize)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
            }
            
            Spacer()
            
            // 右侧：时间和操作图标
            HStack(spacing: 8) {
                Text(item.relativeTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 操作图标
                if isHovered || isSelected {
                    HStack(spacing: 6) {
                        Button(action: onToggleFavorite) {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 14))
                                .foregroundColor(item.isFavorite ? .red : Color(item.getAppIconDominantColor()))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onShowDetail) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(Color(item.getAppIconDominantColor()))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: performCopyAnimation) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(Color(item.getAppIconDominantColor()))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(item.getAppIconDominantColor()).opacity(0.08),
                            Color(item.getAppIconDominantColor()).opacity(0.05),
                            Color(NSColor.controlBackgroundColor).opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 36)
        )
    }
    
    // 卡片背景
    private var cardBackground: some View {
        Rectangle()
            .fill(backgroundFill)
    }
    
    private var backgroundFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(item.getAppIconDominantColor()).opacity(0.15),
                        Color(item.getAppIconDominantColor()).opacity(0.08),
                        Color(NSColor.controlBackgroundColor)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(NSColor.controlBackgroundColor),
                        Color(NSColor.controlBackgroundColor).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    // 卡片边框
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isSelected ? 
                Color(item.getAppIconDominantColor()).opacity(0.4) :
                (isHovered ? Color.secondary.opacity(0.2) : Color.clear),
                lineWidth: isSelected ? 2 : 1
            )
    }
    
    // 复制反馈覆盖层
    private var copyFeedbackOverlay: some View {
        Group {
            if showCopyFeedback {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.8))
                    .overlay(
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            Text("已复制")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // 计算属性
    private var cardScale: CGFloat {
        if isPressed { return 0.95 }
        if isSelected { return 1.02 }
        if isHovered { return 1.01 }
        return 1.0
    }
    
    private var shadowColor: Color {
        if isSelected { return Color(item.getAppIconDominantColor()).opacity(0.3) }
        if isHovered { return .black.opacity(0.15) }
        return .black.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        if isSelected { return 12 }
        if isHovered { return 8 }
        return 4
    }
    
    private var shadowOffset: CGFloat {
        if isSelected { return 4 }
        if isHovered { return 3 }
        return 2
    }
    
    // 获取类型渐变颜色
    private func getTypeGradientColor() -> Color {
        switch item.type {
        case .text:
            return .blue
        case .url:
            return .purple
        case .image:
            return .orange
        case .file:
            return .green
        }
    }
    
    // 执行复制动画
    private func performCopyAnimation() {
        withAnimation(.bouncy(duration: 0.6)) {
            isCopied = true
            showCopyFeedback = true
        }
        
        onCopy()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCopyFeedback = false
                isCopied = false
            }
        }
    }
}

// MARK: - 剪切板详情视图
struct ClipboardDetailView: View {
    let item: ClipboardItem
    let onClose: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题栏
            HStack {
                Text("剪切板详情")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("关闭", action: onClose)
                    .keyboardShortcut(.escape)
            }
            .padding()
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("基本信息")
                            .font(.headline)
                        
                        HStack {
                            Text("类型:")
                            Text(item.type.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("来源:")
                            Text(item.sourceApp)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("时间:")
                            Text(item.timestamp, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("大小:")
                            Text(item.fileSize ?? "未知")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 内容预览
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容预览")
                            .font(.headline)
                        
                        if item.type == .image, 
                           let data = Data(base64Encoded: item.content),
                           let image = NSImage(data: data) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .cornerRadius(8)
                        } else {
                            Text(item.content)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            
            // 底部按钮
            HStack {
                Spacer()
                
                Button("复制到剪切板", action: onCopy)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
} 