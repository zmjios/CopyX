import SwiftUI
import AppKit

struct ClipboardHistoryView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedTypeFilter: ClipboardItem.ClipboardItemType? = nil
    @State private var selectedIndex = 0
    @State private var showingDetailView = false
    @State private var selectedItem: ClipboardItem? = nil
    
    let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    var filteredItems: [ClipboardItem] {
        var items = clipboardManager.clipboardHistory
        
        // 搜索过滤
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.sourceApp.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 类型过滤
        if let typeFilter = selectedTypeFilter {
            items = items.filter { $0.type == typeFilter }
        }
        
        return items
    }
    
    var body: some View {
        mainContentView
            .onAppear {
                selectedIndex = 0
            }
    }
    
    // 统一的关闭详情视图方法
    private func closeDetailView() {
        showingDetailView = false
        selectedItem = nil
    }
    
    // 打开详情视图窗口
    private func openDetailWindow(for item: ClipboardItem) {
        selectedItem = item
        showingDetailView = true
        
        let detailWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        detailWindow.center()
        detailWindow.title = "剪切板详情"
        detailWindow.isReleasedWhenClosed = true
        
        let detailView = ClipboardDetailView(
            item: item,
            isShowing: $showingDetailView,
            onClose: {
                detailWindow.close()
                closeDetailView()
            },
            onCopy: {
                item.copyToPasteboard()
                detailWindow.close()
                closeDetailView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.keyWindow?.close()
                }
            }
        )
        
        detailWindow.contentView = NSHostingView(rootView: detailView)
        detailWindow.makeKeyAndOrderFront(nil)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            topSearchBar
            divider
            contentArea
        }
        .background(.ultraThinMaterial)
        .id("mainContent") // 添加稳定的ID确保布局一致性
    }
    
    private var topSearchBar: some View {
        HStack(spacing: 16) {
            searchField
            Spacer()
            typeFilterButtons
            Spacer()
            closeButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.15),
                    Color.blue.opacity(0.12),
                    Color.cyan.opacity(0.08),
                    Color.mint.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.clear,
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(
            // 添加微妙的彩虹边框
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.3),
                            Color.cyan.opacity(0.3),
                            Color.mint.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                ),
            alignment: .bottom
        )
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? .secondary : .purple)
                .font(.system(size: 14))
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
            TextField("搜索", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.purple.opacity(0.05),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: searchText.isEmpty ? 
                                    [Color.gray.opacity(0.3)] :
                                    [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: searchText.isEmpty ? 1 : 2
                        )
                        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                )
        )
        .frame(width: 220)
    }
    
    private var typeFilterButtons: some View {
        HStack(spacing: 8) {
            ForEach([nil] + ClipboardItem.ClipboardItemType.allCases, id: \.self) { type in
                FilterButton(
                    title: type?.displayName ?? "全部",
                    icon: type?.iconName ?? "square.grid.2x2",
                    isSelected: selectedTypeFilter == type,
                    backgroundColor: type?.backgroundColor ?? "systemGray"
                ) {
                    selectedTypeFilter = type
                }
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            if let onClose = onClose {
                onClose()
            } else {
                NSApp.keyWindow?.close()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.8),
                            Color.orange.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                )
                .shadow(color: Color.red.opacity(0.3), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(CloseButtonStyle())
    }
}

struct CloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ClipboardHistoryView {
    private var divider: some View {
        Rectangle()
            .frame(height: 2)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.cyan.opacity(0.15),
                        Color.mint.opacity(0.1),
                        Color.clear,
                        Color.mint.opacity(0.1),
                        Color.cyan.opacity(0.15),
                        Color.blue.opacity(0.2),
                        Color.purple.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    private var contentArea: some View {
        Group {
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                clipboardItemsGrid
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无剪切板记录")
                .font(.title2)
                .foregroundColor(.secondary)
            if !searchText.isEmpty {
                Text("尝试修改搜索条件")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var clipboardItemsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardCardView(
                        item: item,
                        index: index,
                        isSelected: index == selectedIndex,
                        onCopy: {
                            item.copyToPasteboard()
                            if let onClose = onClose {
                                onClose()
                            } else {
                                NSApp.keyWindow?.close()
                            }
                        },
                        onShowDetail: {
                            openDetailWindow(for: item)
                        }
                    )
                    .onTapGesture {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                            selectedIndex = index
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top))
                    ))
                    .onAppear {
                        // 错峰出现动画
                        withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.1)) {
                            // 卡片出现动画
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 4)
            .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: filteredItems.count)
        }
    }
}

// MARK: - 剪切板详情视图
struct ClipboardDetailView: View {
    let item: ClipboardItem
    @Binding var isShowing: Bool
    let onClose: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        detailContent
    }
    
    private var detailContent: some View {
        VStack(spacing: 0) {
            detailHeader
            detailDivider
            detailScrollContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("剪切板详情")
    }
    
    private var detailHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text(item.type.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getTypeColor())
                )
                
                Text("来源：\(item.sourceApp)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("复制") {
                    onCopy()
                }
                .buttonStyle(.borderedProminent)
                
                Button("关闭") {
                    onClose()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: []) // 添加ESC键支持
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 70)
        .background(.ultraThinMaterial)
    }
    
    private var detailDivider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color.secondary.opacity(0.2))
    }
    
    private var detailScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if item.type == .image {
                    imageDetailView
                } else {
                    textDetailView
                }
                metaInfoView
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var imageDetailView: some View {
        Group {
            if let imageData = Data(base64Encoded: item.content),
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("无法显示图片")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
    
    private var textDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("内容")
                    .font(.headline)
                Spacer()
                Text("\(item.content.count) 字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            
            // 文本内容显示区域
            ScrollView {
                Text(item.content)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(minHeight: 200, maxHeight: 350)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var metaInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("详细信息")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "创建时间", value: item.timestamp.formatted(date: .abbreviated, time: .shortened))
                InfoRow(label: "来源应用", value: item.sourceApp)
                InfoRow(label: "内容类型", value: item.type.displayName)
                if let fileSize = item.fileSize {
                    InfoRow(label: "文件大小", value: fileSize)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.05))
            )
        }
        .padding(.top, 8)
    }
    
    private func getTypeColor() -> Color {
        switch item.type.backgroundColor {
        case "systemGreen": return .green
        case "systemOrange": return .orange
        case "systemBlue": return .blue
        case "systemPurple": return .purple
        default: return .gray
        }
    }
}

// MARK: - 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let backgroundColor: String
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getBackgroundGradient())
                    .shadow(
                        color: isSelected ? getBackgroundColor().opacity(0.4) : Color.clear,
                        radius: isSelected ? 4 : 0,
                        x: 0,
                        y: 2
                    )
            )
            .foregroundColor(getForegroundColor())
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(getBorderGradient(), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func getBackgroundGradient() -> some ShapeStyle {
        if isSelected {
            return LinearGradient(
                colors: [
                    getBackgroundColor(),
                    getBackgroundColor().opacity(0.8),
                    getBackgroundColor()
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    getBackgroundColor().opacity(0.15),
                    getBackgroundColor().opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func getBorderGradient() -> some ShapeStyle {
        if isSelected {
            return LinearGradient(
                colors: [
                    getBackgroundColor(),
                    getBackgroundColor().opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    getBackgroundColor().opacity(0.5),
                    getBackgroundColor().opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.secondary.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func getForegroundColor() -> Color {
        if isSelected {
            return .white
        } else if isHovered {
            return getBackgroundColor()
        } else {
            return .primary
        }
    }
    
    private func getBackgroundColor() -> Color {
        switch backgroundColor {
        case "systemGreen": return .green
        case "systemOrange": return .orange
        case "systemBlue": return .blue
        case "systemPurple": return .purple
        default: return .purple // 默认使用紫色给"全部"按钮
        }
    }
}

// MARK: - 剪切板卡片视图
struct ClipboardCardView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onCopy: () -> Void
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
                                .fill(Color(NSColor.tertiarySystemFill))
                        )
            }
        }
    }
    
    // 文本内容视图 - 参考图片中的文本显示方式
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
                // 添加一些垂直间距，让按钮靠下一点
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
                .padding(.bottom, 4) // 在按钮下方添加一点底部间距
            }
        }
    }
    
    // 底部信息栏 - 参考图片中的底部设计
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
                                .fill(Color(NSColor.tertiarySystemFill))
                        )
                }
            }
            
            Spacer()
            
            // 右侧：时间和操作图标
            HStack(spacing: 8) {
                Text(item.relativeTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 操作图标 - 参考图片中右下角的图标
                if isHovered || isSelected {
                    HStack(spacing: 6) {
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
                            Color(NSColor.tertiarySystemFill).opacity(0.15)
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
        if isCopied {
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.15),
                    Color.mint.opacity(0.1),
                    Color.green.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isSelected {
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.cyan.opacity(0.1),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    Color(item.getAppIconDominantColor()).opacity(0.08),
                    Color(item.getAppIconDominantColor()).opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 卡片边框 - 参考图片中选中状态的蓝色边框
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(borderGradient, lineWidth: borderWidth)
    }
    
    private var borderGradient: some ShapeStyle {
        if isCopied {
            return LinearGradient(
                colors: [Color.green, Color.mint, Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isSelected {
            return LinearGradient(
                colors: [Color.blue, Color.cyan, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    Color(item.getAppIconDominantColor()),
                    Color(item.getAppIconDominantColor()).opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(NSColor.separatorColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var borderWidth: CGFloat {
        if isCopied || isSelected {
            return 3 // 更粗的边框，参考图片
        } else if isHovered {
            return 1
        } else {
            return 0.5
        }
    }
    
    // 缩放效果
    private var cardScale: CGFloat {
        if isPressed {
            return 0.95
        } else if isSelected {
            return 1.02 // 轻微放大
        } else if isHovered {
            return 1.01
        } else {
            return 1.0
        }
    }
    
    // 阴影效果
    private var shadowColor: Color {
        if isCopied {
            return .green.opacity(0.4)
        } else if isSelected {
            return .blue.opacity(0.4)
        } else if isHovered {
            return Color(item.getAppIconDominantColor()).opacity(0.2)
        } else {
            return .black.opacity(0.08)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isCopied || isSelected {
            return 12
        } else if isHovered {
            return 8
        } else {
            return 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isCopied || isSelected {
            return 6
        } else if isHovered {
            return 4
        } else {
            return 2
        }
    }
    
    // 复制反馈覆盖层
    private var copyFeedbackOverlay: some View {
        Group {
            if showCopyFeedback {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 40, height: 40)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    
                    Text("已复制")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        )
                }
                .scaleEffect(showCopyFeedback ? 1.0 : 0.3)
                .opacity(showCopyFeedback ? 1.0 : 0.0)
            }
        }
    }
    
    // 获取类型渐变颜色
    private func getTypeGradientColor() -> Color {
        switch item.type {
        case .text:
            return .purple
        case .image:
            return .orange
        case .file:
            return .blue
        case .url:
            return .green
        }
    }
    
    // 执行复制动画
    private func performCopyAnimation() {
        withAnimation(.bouncy(duration: 0.6)) {
            isCopied = true
            showCopyFeedback = true
        }
        
        // 触觉反馈
        let impactFeedback = NSHapticFeedbackManager.defaultPerformer
        impactFeedback.perform(.alignment, performanceTime: .default)
        
        onCopy()
        
        // 重置动画状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                isCopied = false
                showCopyFeedback = false
            }
        }
    }
    

}

// MARK: - 可选择文本组件
struct SelectableText: NSViewRepresentable {
    let text: String
    let font: Font
    let maxLines: Int
    let onTextSelected: ((String) -> Void)?
    
    init(text: String, font: Font = .body, maxLines: Int = 0, onTextSelected: ((String) -> Void)? = nil) {
        self.text = text
        self.font = font
        self.maxLines = maxLines
        self.onTextSelected = onTextSelected
    }
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        let textView = NSTextView()
        
        // 配置文本视图
        textView.string = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = false
        textView.backgroundColor = NSColor.clear
        textView.textColor = NSColor.labelColor
        textView.font = NSFont.systemFont(ofSize: 13)
        
        // 关键配置：确保文本容器正确设置
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        
        // 设置布局约束
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width, .height]
        
        // 设置最大行数
        if maxLines > 0 {
            textView.textContainer?.maximumNumberOfLines = maxLines
        }
        
        // 设置换行模式
        textView.textContainer?.lineBreakMode = .byWordWrapping
        
        // 设置代理
        textView.delegate = context.coordinator
        
        // 添加到容器视图
        containerView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 强制布局更新
        DispatchQueue.main.async {
            textView.needsLayout = true
            textView.needsDisplay = true
            containerView.needsLayout = true
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let textView = nsView.subviews.first as? NSTextView {
            if textView.string != text {
                textView.string = text
                DispatchQueue.main.async {
                    textView.needsLayout = true
                    textView.needsDisplay = true
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SelectableText
        
        init(_ parent: SelectableText) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                let selectedText = (textView.string as NSString).substring(with: selectedRange)
                if !selectedText.isEmpty {
                    parent.onTextSelected?(selectedText)
                }
            }
        }
    }
}

extension NSApplication {
    static let keyboardShortcutNotification = Notification.Name("KeyboardShortcut")
} 
