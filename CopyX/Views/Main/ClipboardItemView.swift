import SwiftUI
import AppKit

// MARK: - 可选择文本视图
struct SelectableTextView: NSViewRepresentable {
    let text: String
    let font: NSFont
    
    init(text: String, font: NSFont = NSFont.systemFont(ofSize: 13)) {
        self.text = text
        self.font = font
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 基本配置
        textView.string = text
        textView.font = font
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor.controlBackgroundColor
        textView.textColor = NSColor.textColor
        textView.textContainerInset = NSSize(width: 12, height: 12)
        
        // 文本属性
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isRichText = false
        textView.allowsUndo = false
        
        // 布局设置
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // 文本容器设置
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false
        }
        
        // 滚动视图设置
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
                textView.needsDisplay = true
            }
        }
    }
}

// MARK: - 自定义文本视图（支持增强右击菜单）
class CustomTextView: NSTextView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        
        // 获取选中的文本
        let selectedRange = self.selectedRange()
        let selectedText = selectedRange.length > 0 ? (self.string as NSString).substring(with: selectedRange) : ""
        let hasSelection = !selectedText.isEmpty
        
        // 复制选中内容
        if hasSelection {
            let copyItem = NSMenuItem(title: "复制选中内容", action: #selector(copy(_:)), keyEquivalent: "c")
            copyItem.target = self
            menu.addItem(copyItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // 全选
        let selectAllItem = NSMenuItem(title: "全选", action: #selector(selectAll(_:)), keyEquivalent: "a")
        selectAllItem.target = self
        menu.addItem(selectAllItem)
        
        // 复制全部内容
        let copyAllItem = NSMenuItem(title: "复制全部内容", action: #selector(copyAll), keyEquivalent: "")
        copyAllItem.target = self
        menu.addItem(copyAllItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 查找
        let findItem = NSMenuItem(title: "查找...", action: #selector(showFindPanel), keyEquivalent: "f")
        findItem.target = self
        menu.addItem(findItem)
        
        // 如果有选中文本，添加在网络中搜索选项
        if hasSelection && selectedText.count < 100 {
            menu.addItem(NSMenuItem.separator())
            
            let searchTitle = selectedText.count > 20 ? 
                "在网络中搜索 '\(selectedText.prefix(20))...'" : 
                "在网络中搜索 '\(selectedText)'"
            let searchItem = NSMenuItem(title: searchTitle, action: #selector(searchInWeb), keyEquivalent: "")
            searchItem.target = self
            menu.addItem(searchItem)
        }
        
        return menu
    }
    
    @objc func copyAll() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self.string, forType: .string)
        
        // 显示复制成功提示
        showNotification(message: "已复制全部内容到剪切板")
    }
    
    @objc func showFindPanel() {
        if let window = self.window {
            // 使用 window 的 firstResponder 来显示查找面板
            window.makeFirstResponder(self)
            // 使用 cmd+f 快捷键触发查找功能
            let event = NSEvent.keyEvent(with: .keyDown, 
                                       location: NSPoint.zero, 
                                       modifierFlags: .command, 
                                       timestamp: 0, 
                                       windowNumber: window.windowNumber, 
                                       context: nil, 
                                       characters: "f", 
                                       charactersIgnoringModifiers: "f", 
                                       isARepeat: false, 
                                       keyCode: 3)
            if let event = event {
                window.sendEvent(event)
            }
        }
    }
    
    @objc func searchInWeb() {
        // 获取当前选中的文本
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0 else { return }
        
        let selectedText = (self.string as NSString).substring(with: selectedRange)
        let searchText = selectedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://www.google.com/search?q=\(searchText)"
        
        if let url = URL(string: searchURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showNotification(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "操作成功"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            
            if let window = self.window {
                alert.beginSheetModal(for: window) { _ in }
            } else {
                alert.runModal()
            }
        }
    }
}

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
        .alert(LocalizedStringKey("confirm_delete"), isPresented: $showingDeleteConfirmation) {
            Button(LocalizedStringKey("cancel"), role: .cancel) { }
            Button(LocalizedStringKey("delete"), role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    clipboardManager.removeItem(item)
                    if selectedItem?.id == item.id {
                        selectedItem = nil
                    }
                }
            }
        } message: {
            Text(LocalizedStringKey("confirm_delete_message"))
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
                
                Image(systemName: item.type.iconName)
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
            // 增强的标题栏设计
            HStack(spacing: 8) {
                // 应用图标区域
                HStack(spacing: 6) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(item.sourceApp)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        // 毛玻璃背景
                        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        
                        // 渐变叠加
                        LinearGradient(
                            colors: [
                                item.getAppThemeColor().opacity(0.9),
                                item.getAppThemeColor().opacity(0.7),
                                item.getAppThemeColor().opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                
                Spacer()
                
                // 类型标签
                HStack(spacing: 4) {
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 9, weight: .medium))
                    Text(item.type.displayName)
                        .font(.system(size: 9, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.type.color.opacity(0.15))
                )
                .foregroundColor(item.type.color)
            }
            
            Text(item.displayContent)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(.top, 2)
            
            HStack {
                Text(formatTimestamp(item.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !item.content.isEmpty {
                    Text("\(item.content.count) \(NSLocalizedString("characters", comment: ""))")
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
                    tooltip: NSLocalizedString("delete", comment: "")
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



// MARK: - 原始精美卡片视图（完全恢复原设计）
struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetail: () -> Void
    let onShare: () -> Void
    
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
        .overlay(favoriteIndicator)
        .scaleEffect(cardScale)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: isHovered)
        .animation(.interpolatingSpring(stiffness: 400, damping: 20), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .animation(.bouncy(duration: 0.6), value: isCopied)
        .animation(.bouncy(duration: 0.8), value: item.isFavorite)
        .onHover { hovering in
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                // 单击选中卡片
            }
        }
        .onTapGesture(count: 2) {
            performCopyAnimation()
        }
        .contextMenu {
            cardContextMenu
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
                
                // 功能按钮
                cardActionButton(icon: "doc.on.doc.fill", tooltip: "copy_to_clipboard".localized, action: onCopy)
                cardActionButton(icon: "square.and.arrow.up.fill", tooltip: "share".localized, action: onShare)
                cardActionButton(
                    icon: item.isFavorite ? "heart.fill" : "heart", 
                    tooltip: item.isFavorite ? "unfavorite".localized : "favorite".localized, 
                    color: item.isFavorite ? .red : .secondary,
                    action: {
                        withAnimation(.bouncy(duration: 0.8)) {
                            onToggleFavorite()
                        }
                    }
                )
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
        } else if item.isFavorite {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.05),
                        Color.pink.opacity(0.03),
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
                LinearGradient(
                    colors: [
                        Color(item.getAppIconDominantColor()).opacity(0.6),
                        Color(item.getAppIconDominantColor()).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) : item.isFavorite ?
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.4),
                        Color.pink.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [
                        Color(NSColor.separatorColor).opacity(0.3),
                        Color(NSColor.separatorColor).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isSelected ? 3 : (item.isFavorite ? 2 : 1)
            )
    }
    
    // 复制反馈覆盖层
    private var copyFeedbackOverlay: some View {
        Group {
            if showCopyFeedback {
                ZStack {
                RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.2))
                    
                    VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.green)
                        
                            Text("已复制")
                                .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                        }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // 收藏标识
    private var favoriteIndicator: some View {
        Group {
            if item.isFavorite {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.red, Color.pink],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 12
                                    )
                                )
                                .frame(width: 24, height: 24)
                                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -8, y: 8)
                    }
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.bouncy(duration: 0.6), value: item.isFavorite)
            }
        }
    }
    
    // 计算属性
    private var cardScale: CGFloat {
        if isSelected {
            return 1.08
        } else if isPressed {
            return 0.98
        } else if isHovered {
            return 1.02
        } else {
        return 1.0
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return Color(item.getAppIconDominantColor()).opacity(0.4)
        } else if isHovered {
            return Color.black.opacity(0.15)
        } else {
            return Color.black.opacity(0.08)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isSelected {
            return 20
        } else if isHovered {
            return 12
        } else {
            return 6
        }
    }
    
    private var shadowOffset: CGFloat {
        if isSelected {
            return 8
        } else if isHovered {
            return 4
        } else {
        return 2
        }
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
        case .rtf:
            return .blue
        case .code:
            return .mint
        case .json:
            return .cyan
        case .xml:
            return .teal
        case .email:
            return .indigo
        case .phone:
            return .brown
        }
    }
    
    // 执行复制动画
    private func performCopyAnimation() {
        // 防止在按钮区域触发复制
        guard !isHovered else { return }
        
        withAnimation(.bouncy(duration: 0.6)) {
            isCopied = true
            showCopyFeedback = true
        }
        
        // 执行复制操作
        onCopy()
        
        // 重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                isCopied = false
                showCopyFeedback = false
            }
        }
    }
    
    // 右键菜单
    private var cardContextMenu: some View {
        VStack {
            Button(action: {
                performCopyAnimation()
            }) {
                Label("copy_to_clipboard".localized, systemImage: "doc.on.doc")
            }
            
            Button(action: onShare) {
                Label("share".localized, systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                withAnimation(.bouncy(duration: 0.8)) {
                    onToggleFavorite()
                }
            }) {
                Label(
                    item.isFavorite ? "unfavorite".localized : "favorite".localized,
                    systemImage: item.isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Divider()
            
            Button(action: onShowDetail) {
                Label("view_details".localized, systemImage: "info.circle")
            }
            
            Button(action: {
                // 删除功能 - 需要从外部传入
            }) {
                Label("delete_item".localized, systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
    
    // 功能按钮辅助方法
    private func cardActionButton(icon: String, tooltip: String, color: Color = .secondary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color == .red ? Color.red.opacity(0.1) : Color(NSColor.controlBackgroundColor).opacity(0.8))
                )
                .overlay(
                    Circle()
                        .stroke(color == .red ? Color.red.opacity(0.3) : Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
        .allowsHitTesting(true)
        .contentShape(Circle())
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - 剪切板详情视图
struct ClipboardDetailView: View {
    let item: ClipboardItem
    let onClose: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // 标题栏
            HStack {
                Text(LocalizedStringKey("clipboard_detail"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(LocalizedStringKey("close"), action: onClose)
                    .keyboardShortcut(.escape)
            }
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // 基本信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("basic_info"))
                            .font(.headline)
                        
                        HStack {
                            Text(LocalizedStringKey("type_label"))
                            Text(item.type.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(LocalizedStringKey("source_label"))
                            Text(item.sourceApp)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(LocalizedStringKey("time_label"))
                            Text(item.timestamp, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(LocalizedStringKey("size_label"))
                            Text(item.fileSize ?? NSLocalizedString("unknown_size", comment: "Unknown size"))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 内容预览
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("content_preview"))
                            .font(.headline)
                        
                        if item.type == .image, 
                           let data = Data(base64Encoded: item.content),
                           let image = NSImage(data: data) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .cornerRadius(8)
                        } else {
                            // 添加调试信息
                            if item.content.isEmpty {
                                Text(LocalizedStringKey("empty_content"))
                                    .foregroundColor(.secondary)
                                    .frame(minHeight: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                            } else {
                                ScrollView {
                                    Text(item.content)
                                        .font(.system(size: 13, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                }
                                .frame(minHeight: 300, maxHeight: 500)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // 底部按钮
            HStack {
                Spacer()
                
                Button(LocalizedStringKey("copy_to_clipboard"), action: onCopy)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - 简单文本视图（调试用）
struct SimpleTextView: NSViewRepresentable {
    let text: String
    let font: NSFont
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 基本配置
        textView.string = text
        textView.font = font
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor.controlBackgroundColor
        textView.textColor = NSColor.textColor
        textView.textContainerInset = NSSize(width: 12, height: 12)
        
        // 布局配置
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // 滚动视图配置
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }
}

// MARK: - 最简单的文本视图（用于调试）
struct BasicTextView: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.string = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = NSColor.controlBackgroundColor
        textView.textColor = NSColor.textColor
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
        }
    }
}

// MARK: - 带右击菜单的可选择文本视图
struct SelectableTextViewWithMenu: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CustomTextView()
        
        // 配置文本视图
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor.controlBackgroundColor
        textView.textColor = NSColor.textColor
        textView.textContainerInset = NSSize(width: 12, height: 12)
        
        // 配置滚动视图
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // 设置文本视图属性
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? CustomTextView {
            if textView.string != text {
                textView.string = text
                textView.needsDisplay = true
            }
        }
    }
}
