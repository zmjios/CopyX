import SwiftUI
import AppKit
import UserNotifications

struct ClipboardHistoryView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedTypeFilter: ClipboardItem.ClipboardItemType? = nil
    @State private var showingFavoritesOnly = false
    @State private var selectedIndex = 0
    @State private var showingDetailView = false
    @State private var selectedItem: ClipboardItem? = nil
    
    let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    var filteredItems: [ClipboardItem] {
        var items = clipboardManager.clipboardHistory
        
        // 收藏过滤
        if showingFavoritesOnly {
            items = items.filter { $0.isFavorite }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.sourceApp.localizedCaseInsensitiveContains(searchText) ||
                item.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
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
                clipboardManager.copyToPasteboard(item)
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
                    isSelected: selectedTypeFilter == type && !showingFavoritesOnly,
                    backgroundColor: type?.backgroundColor ?? "systemGray"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTypeFilter = type
                        // 如果选择了类型筛选，清除收藏筛选
                        showingFavoritesOnly = false
                    }
                }
            }
            
            // 收藏夹筛选按钮
            FilterButton(
                title: "收藏",
                icon: "heart.fill",
                isSelected: showingFavoritesOnly,
                backgroundColor: "systemPink"
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingFavoritesOnly.toggle()
                    // 如果开启收藏筛选，清除类型筛选
                    if showingFavoritesOnly {
                        selectedTypeFilter = nil
                    }
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
                        clipboardManager: clipboardManager,
                        onCopy: {
                            clipboardManager.copyToPasteboard(item)
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
    let clipboardManager: ClipboardManager
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
            // 只在非操作按钮区域响应点击
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
        .allowsHitTesting(true)
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
            
            // 收藏按钮
            Button(action: {
                toggleFavorite()
            }) {
                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isFavorite ? .pink : .secondary)
                    .scaleEffect(item.isFavorite ? 1.1 : 1.0)
                    .animation(.bouncy(duration: 0.5), value: item.isFavorite)
            }
            .buttonStyle(PlainButtonStyle())
            .help(item.isFavorite ? "取消收藏" : "添加收藏")
            
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
                
                // 操作图标 - 参考图片中右下角的图标
                if isHovered || isSelected {
                    HStack(spacing: 6) {
                        // 分享按钮
                        ShareButton(item: item)
                            .allowsHitTesting(true) // 确保可以点击
                        
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
                    .allowsHitTesting(true) // 确保操作按钮区域可以点击
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
    
    // 切换收藏状态
    private func toggleFavorite() {
        withAnimation(.bouncy(duration: 0.5)) {
            clipboardManager.toggleFavorite(item)
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

// MARK: - 分享按钮组件
struct ShareButton: View {
    let item: ClipboardItem
    @State private var showingShareMenu = false
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        ZStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingShareMenu.toggle()
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(Color(item.getAppIconDominantColor()))
            }
            .buttonStyle(PlainButtonStyle())
            .help("分享")
            .onTapGesture {
                // 阻止事件冒泡到父视图
            }
            
            if showingShareMenu {
                if clipboardManager.useModalShareView {
                    ShareModalView(item: item, isPresented: $showingShareMenu)
                } else {
                    ShareMenuOverlay(item: item, isPresented: $showingShareMenu)
                }
            }
        }
    }
}

// MARK: - 分享模态弹框
struct ShareModalView: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 半透明背景遮罩
            Color.black.opacity(0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
            
            // 中心弹框
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("分享到")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("关闭")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // 分享选项网格 - 改为3列布局以容纳更多选项
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ShareModalOption(
                        title: "微信",
                        icon: "message.fill",
                        color: .green
                    ) {
                        ShareManager.shared.shareToWeChat(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    ShareModalOption(
                        title: "系统分享",
                        icon: "square.and.arrow.up.circle.fill",
                        color: .blue
                    ) {
                        ShareManager.shared.shareToSystem(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    ShareModalOption(
                        title: "X (Twitter)",
                        icon: "bubble.left.and.bubble.right.fill",
                        color: .cyan
                    ) {
                        ShareManager.shared.shareToTwitter(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    ShareModalOption(
                        title: "微博",
                        icon: "globe.asia.australia.fill",
                        color: .orange
                    ) {
                        ShareManager.shared.shareToWeibo(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    ShareModalOption(
                        title: "QQ",
                        icon: "person.2.fill",
                        color: .purple
                    ) {
                        ShareManager.shared.shareToQQ(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    ShareModalOption(
                        title: "复制链接",
                        icon: "link.circle.fill",
                        color: .gray
                    ) {
                        ShareManager.shared.copyToClipboard(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(width: 300, height: 240)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .drawingGroup() // 优化跨屏幕渲染性能
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
        .background(
            // 隐藏的键盘事件处理器
            KeyboardEventHandler { event in
                if event.keyCode == 53 { // ESC键的keyCode是53
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                    return true
                }
                return false
            }
        )
    }
}

// MARK: - 分享模态选项
struct ShareModalOption: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 分享菜单覆盖层
struct ShareMenuOverlay: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    
    var body: some View {
        GeometryReader { geometry in
            // 透明背景，点击关闭菜单
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                .overlay(
                    ShareMenuContent(item: item, isPresented: $isPresented)
                        .position(
                            x: max(100, min(geometry.size.width - 100, geometry.size.width - 50)),
                            y: max(120, min(geometry.size.height - 120, geometry.size.height - 50))
                        )
                        .scaleEffect(isPresented ? 1.0 : 0.8)
                        .opacity(isPresented ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isPresented)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .drawingGroup() // 优化跨屏幕渲染性能
        .allowsHitTesting(true)
        .background(
            // 隐藏的键盘事件处理器
            KeyboardEventHandler { event in
                if event.keyCode == 53 { // ESC键的keyCode是53
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                    return true
                }
                return false
            }
        )
    }
}

// MARK: - 分享菜单内容
struct ShareMenuContent: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("分享到")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 2)
            
            VStack(spacing: 4) {
                // 系统分享
                ShareOptionButton(
                    title: "系统分享",
                    icon: "square.and.arrow.up.circle.fill",
                    color: .blue,
                    action: {
                        ShareManager.shared.shareToSystem(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                
                // 微信分享
                ShareOptionButton(
                    title: "微信",
                    icon: "message.fill",
                    color: .green,
                    action: {
                        ShareManager.shared.shareToWeChat(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                
                // X (Twitter) 分享
                ShareOptionButton(
                    title: "X (Twitter)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .cyan,
                    action: {
                        ShareManager.shared.shareToTwitter(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                
                // 微博分享
                ShareOptionButton(
                    title: "微博",
                    icon: "globe.asia.australia.fill",
                    color: .orange,
                    action: {
                        ShareManager.shared.shareToWeibo(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                
                // QQ分享
                ShareOptionButton(
                    title: "QQ",
                    icon: "person.2.fill",
                    color: .purple,
                    action: {
                        ShareManager.shared.shareToQQ(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
                
                // 复制内容
                ShareOptionButton(
                    title: "复制内容",
                    icon: "doc.on.doc.fill",
                    color: .gray,
                    action: {
                        ShareManager.shared.copyToClipboard(item)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                )
            }
        }
        .padding(10)
        .frame(width: 180, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .allowsHitTesting(true)
        .contentShape(Rectangle())
    }
}

// MARK: - 分享选项按钮
struct ShareOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1.0 : 0.0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}





// MARK: - 分享管理器
class ShareManager {
    static let shared = ShareManager()
    
    private init() {}
    
    // 分享到微信
    func shareToWeChat(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        // 首先检查微信是否安装
        if isWeChatInstalled() {
            // 使用微信分享URL Scheme
            shareToWeChatWithURLScheme(content: content, item: item)
        } else {
            // 微信未安装，提供备用方案
            showWeChatNotInstalledAlert(content: content)
        }
    }
    
    // 检查微信是否安装
    private func isWeChatInstalled() -> Bool {
        if let wechatURL = URL(string: "weixin://") {
            return NSWorkspace.shared.urlForApplication(toOpen: wechatURL) != nil
        }
        return false
    }
    
    // 使用微信URL Scheme分享
    private func shareToWeChatWithURLScheme(content: String, item: ClipboardItem) {
        // 根据内容类型构建不同的分享URL
        var shareURL: URL?
        
        switch item.type {
        case .text, .url:
            // 文本分享：使用微信的文本分享接口
            shareURL = URL(string: "weixin://dl/stickers")
            
            // 先复制内容到剪切板
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            
        case .image:
            // 图片分享：打开微信让用户手动分享
            shareURL = URL(string: "weixin://dl/moments")
            
            // 如果是图片，尝试复制图片到剪切板
            if let imageData = Data(base64Encoded: item.content),
               let nsImage = NSImage(data: imageData) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([nsImage])
            }
            
        case .file:
            // 文件分享：打开微信文件传输助手
            shareURL = URL(string: "weixin://dl/chat")
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("文件: \(item.displayTitle)", forType: .string)
        }
        
        // 打开微信
        if let url = shareURL {
            NSWorkspace.shared.open(url)
            
            // 延迟显示分享指导
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWeChatShareGuidance(for: item.type)
            }
        }
    }
    
    // 显示微信分享指导
    private func showWeChatShareGuidance(for type: ClipboardItem.ClipboardItemType) {
        let message: String
        switch type {
        case .text, .url:
            message = "内容已复制到剪切板，在微信中长按输入框粘贴分享"
        case .image:
            message = "图片已复制到剪切板，在微信中点击相册选择或粘贴分享"
        case .file:
            message = "文件信息已复制，可在微信文件传输助手中分享"
        }
        
        showShareNotification(platform: "微信", message: message)
    }
    
    // 微信未安装时的处理
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
            // 打开微信网页版
            if let webURL = URL(string: "https://wx.qq.com/") {
                NSWorkspace.shared.open(webURL)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
                showShareNotification(platform: "微信网页版", message: "内容已复制到剪切板")
            }
        case .alertSecondButtonReturn:
            // 仅复制内容
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            showShareNotification(platform: "剪切板", message: "内容已复制到剪切板")
        default:
            break
        }
    }
    
    // 分享到 X (Twitter)
    func shareToTwitter(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let twitterURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedContent)") {
            NSWorkspace.shared.open(twitterURL)
            showShareNotification(platform: "X (Twitter)", message: "正在打开 X...")
        }
    }
    
    // 分享到微博
    func shareToWeibo(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let weiboURL = URL(string: "https://service.weibo.com/share/share.php?title=\(encodedContent)") {
            NSWorkspace.shared.open(weiboURL)
            showShareNotification(platform: "微博", message: "正在打开微博...")
        }
    }
    
    // 分享到QQ
    func shareToQQ(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        // 尝试打开QQ
        if let qqURL = URL(string: "mqq://") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            
            NSWorkspace.shared.open(qqURL, configuration: NSWorkspace.OpenConfiguration()) { app, error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.showShareNotification(platform: "QQ", message: "内容已复制到剪切板，请在QQ中粘贴")
                    } else {
                        // QQ未安装，使用系统分享
                        self.shareToSystem(item)
                    }
                }
            }
        }
    }
    
    // 系统分享
    func shareToSystem(_ item: ClipboardItem) {
        // 使用最简单的分享方式 - 纯文本
        let shareText: String
        
        switch item.type {
        case .text:
            shareText = item.content
        case .url:
            shareText = item.content
        case .image:
            shareText = "图片分享"
        case .file:
            shareText = "文件: \(item.displayTitle)"
        }
        
        // 确保文本不为空
        let finalText = shareText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else {
            NSLog("分享文本为空")
            self.fallbackShare(content: "无内容可分享")
            return
        }
        
        let itemsToShare = [finalText]
        
        // 调试信息
        NSLog("准备分享文本: \(finalText)")
        
        // 使用系统分享面板
        DispatchQueue.main.async {
            // 尝试使用不同的分享方式
            self.trySystemShare(items: itemsToShare, content: finalText, originalItem: item)
        }
    }
    
    // 尝试多种系统分享方式
    private func trySystemShare(items: [Any], content: String, originalItem: ClipboardItem) {
        NSLog("开始尝试系统分享，项目数量: \(items.count)")
        
        // 只尝试一种方式：直接使用分享服务
        if self.tryDirectSharingService(items: items, content: content) {
            return
        }
        
        // 备用方案 - 复制到剪切板并提示用户
        self.fallbackShare(content: content)
    }
    

    
    // 直接使用分享服务
    private func tryDirectSharingService(items: [Any], content: String) -> Bool {
        NSLog("尝试直接分享服务")
        
        // 方法1：尝试使用特定的分享服务而不是选择器
        let availableServices = NSSharingService.sharingServices(forItems: items)
        NSLog("系统可用的分享服务: \(availableServices.map { $0.title })")
        
        if !availableServices.isEmpty {
            // 创建一个简单的选择对话框
            let alert = NSAlert()
            alert.messageText = "选择分享方式"
            alert.informativeText = "请选择要使用的分享服务："
            
            // 添加主要的分享服务选项
            let mainServices = ["Mail", "Messages", "Notes", "Reminders"]
            for serviceName in mainServices {
                if availableServices.contains(where: { $0.title == serviceName }) {
                    alert.addButton(withTitle: serviceName)
                }
            }
            
            // 如果有其他服务，添加一个"其他"选项
            if availableServices.count > mainServices.count {
                alert.addButton(withTitle: "其他...")
            }
            
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // 用户选择了第一个按钮，尝试使用对应的服务
                if let selectedService = availableServices.first(where: { $0.title == mainServices[0] }) {
                    return self.performDirectShare(service: selectedService, items: items)
                }
            } else if response == .alertSecondButtonReturn {
                // 用户选择了第二个按钮
                if availableServices.count > 1,
                   let selectedService = availableServices.first(where: { $0.title == mainServices[1] }) {
                    return self.performDirectShare(service: selectedService, items: items)
                }
            }
            // 可以继续处理其他按钮...
        }
        
        // 方法2：如果上述方法失败，尝试使用系统的分享扩展
        return self.trySystemShareExtension(content: content)
    }
    
    // 执行直接分享
    private func performDirectShare(service: NSSharingService, items: [Any]) -> Bool {
        NSLog("使用服务进行分享: \(service.title)")
        
        if service.canPerform(withItems: items) {
            service.perform(withItems: items)
            self.showShareNotification(platform: service.title, message: "正在通过 \(service.title) 分享...")
            return true
        } else {
            NSLog("服务 \(service.title) 无法处理这些项目")
            return false
        }
    }
    
    // 尝试使用系统分享扩展
    private func trySystemShareExtension(content: String) -> Bool {
        NSLog("尝试使用系统分享扩展")
        
        // 使用 NSWorkspace 打开系统分享
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        // 尝试打开系统的分享菜单（如果可能）
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sharing") {
            NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { app, error in
                DispatchQueue.main.async {
                    if error != nil {
                        // 如果无法打开系统偏好设置，显示手动分享提示
                        self.showManualShareDialog(content: content)
                    }
                }
            }
            return true
        }
        
        return false
    }
    
    // 显示手动分享对话框
    private func showManualShareDialog(content: String) {
        let alert = NSAlert()
        alert.messageText = "内容已复制到剪切板"
        alert.informativeText = "由于系统限制，无法直接打开分享面板。内容已复制到剪切板，您可以：\n\n1. 打开邮件应用并粘贴内容\n2. 打开信息应用并粘贴内容\n3. 使用 Command+V 在任何应用中粘贴\n\n内容：\(content.prefix(100))..."
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "打开邮件")
        alert.addButton(withTitle: "打开信息")
        
        let response = alert.runModal()
        
        switch response {
        case .alertSecondButtonReturn:
            // 打开邮件应用
            if let mailURL = URL(string: "mailto:") {
                NSWorkspace.shared.open(mailURL)
            }
        case .alertThirdButtonReturn:
            // 打开信息应用
            if let messagesURL = URL(string: "sms:") {
                NSWorkspace.shared.open(messagesURL)
            }
        default:
            break
        }
        
        self.showShareNotification(platform: "手动分享", message: "内容已复制到剪切板，可手动分享")
    }
    
    // 方式3：备用方案
    private func fallbackShare(content: String) {
        NSLog("使用备用分享方案")
        
        // 复制内容到剪切板
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        
        // 显示提示
        let alert = NSAlert()
        alert.messageText = "系统分享不可用"
        alert.informativeText = "内容已复制到剪切板。您可以手动粘贴到其他应用中进行分享。"
        alert.addButton(withTitle: "确定")
        alert.runModal()
        
        self.showShareNotification(platform: "剪切板", message: "内容已复制到剪切板，可手动分享")
    }
    
    // 复制到剪切板
    func copyToClipboard(_ item: ClipboardItem) {
        let content = prepareShareContent(item)
        
        NSPasteboard.general.clearContents()
        
        switch item.type {
        case .text, .url, .file:
            NSPasteboard.general.setString(content, forType: .string)
        case .image:
            // 如果是图片，同时复制图片和文本
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
    
    // 准备分享内容
    private func prepareShareContent(_ item: ClipboardItem) -> String {
        var content = ""
        
        switch item.type {
        case .text:
            content = item.content
        case .url:
            content = item.content
        case .image:
            content = "分享了一张图片"
        case .file:
            content = "分享了文件: \(item.displayTitle)"
        }
        
        // 添加来源信息
        content += "\n\n📎 来自 CopyX 剪切板"
        
        return content
    }
    
    // 显示分享通知
    private func showShareNotification(platform: String, message: String) {
        DispatchQueue.main.async {
            // 使用现代化的 UserNotifications 框架
            if #available(macOS 10.14, *) {
                let center = UNUserNotificationCenter.current()
                
                // 请求通知权限
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
            } else {
                // 为旧版本系统保留兼容性（虽然已废弃）
                let notification = NSUserNotification()
                notification.title = "分享到\(platform)"
                notification.informativeText = message
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
        }
    }
}

// MARK: - 动画配置
struct AnimationConfig {
    static let multiScreenOptimized = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    static let quickTransition = Animation.spring(
        response: 0.3,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    // 检测是否为多屏幕环境
    static var isMultiScreen: Bool {
        return NSScreen.screens.count > 1
    }
    
    // 根据环境选择最佳动画
    static var optimal: Animation {
        return isMultiScreen ? multiScreenOptimized : quickTransition
    }
}

// MARK: - 键盘事件处理器
struct KeyboardEventHandler: NSViewRepresentable {
    let onKeyEvent: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyEventView()
        view.onKeyEvent = onKeyEvent
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? KeyEventView {
            keyView.onKeyEvent = onKeyEvent
        }
    }
}

class KeyEventView: NSView {
    var onKeyEvent: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyEvent, handler(event) {
            return // 事件已处理
        }
        super.keyDown(with: event)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
} 
