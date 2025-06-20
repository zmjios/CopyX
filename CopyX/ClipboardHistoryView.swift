import SwiftUI
import AppKit

// MARK: - 显示模式枚举
enum DisplayMode: String, CaseIterable {
    case bottom = "bottom"
    case center = "center"
    
    var displayName: String {
        switch self {
        case .bottom: return "底部显示"
        case .center: return "居中显示"
        }
    }
    
    var iconName: String {
        switch self {
        case .bottom: return "dock.rectangle"
        case .center: return "rectangle.center.inset.filled"
        }
    }
}

// MARK: - 剪切板历史视图
struct ClipboardHistoryView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @State private var searchText = ""
    @State private var selectedTypeFilter: ClipboardItem.ClipboardItemType? = nil
    @State private var selectedIndex = 0
    @State private var showingDetailView = false
    @State private var selectedItem: ClipboardItem? = nil
    @State private var displayMode: DisplayMode = .bottom
    @State private var showOnlyFavorites = false
    
    let onClose: (() -> Void)?
    
    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    var filteredItems: [ClipboardItem] {
        var items = clipboardManager.clipboardHistory
        
        // 收藏过滤
        if showOnlyFavorites {
            items = items.filter { $0.isFavorite }
        }
        
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
                // 从HotKeyManager获取当前显示模式
                updateDisplayModeFromHotKeyManager()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DisplayModeChanged"))) { notification in
                if let modeString = notification.userInfo?["mode"] as? String,
                   let mode = DisplayMode(rawValue: modeString) {
                    displayMode = mode
                }
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
        ZStack {
            VStack(spacing: 0) {
                topSearchBar
                divider
                contentArea
            }
            .background(.ultraThinMaterial)
            .id("mainContent") // 添加稳定的ID确保布局一致性
            
            // 只在居中模式显示拉伸指示符
            if displayMode == .center {
                resizeIndicator
            }
        }
    }
    
    private var topSearchBar: some View {
        HStack(spacing: 16) {
            // 左侧：搜索框
            searchField
            
            Spacer()
            
            // 中间：类型过滤按钮
            typeFilterButtons
            
            Spacer()
            
            // 右侧：收藏按钮 + 显示模式切换 + 设置按钮 + 关闭按钮
            HStack(spacing: 12) {
                favoritesButton
                displayModeToggle
                settingsButton
                closeButton
            }
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
                // 通知HotKeyManager关闭窗口
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloseClipboardHistory"),
                    object: nil
                )
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
    
    // 标题栏设置按钮
    private var settingsButton: some View {
        Button(action: {
            openSettingsWindow()
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
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
                .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .help("设置")
    }
    
    // 标题栏收藏按钮
    private var favoritesButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showOnlyFavorites.toggle()
            }
        }) {
            Image(systemName: showOnlyFavorites ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: showOnlyFavorites ? [
                            Color.red.opacity(0.9),
                            Color.pink.opacity(0.7)
                        ] : [
                            Color.gray.opacity(0.7),
                            Color.gray.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: showOnlyFavorites ? [
                                    Color.red.opacity(0.1),
                                    Color.pink.opacity(0.05)
                                ] : [
                                    Color.white.opacity(0.9),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                )
                .overlay(
                    Circle()
                        .stroke(
                            showOnlyFavorites ? 
                            Color.red.opacity(0.4) : 
                            Color.gray.opacity(0.3),
                            lineWidth: showOnlyFavorites ? 2 : 1
                        )
                )
                .shadow(
                    color: showOnlyFavorites ? Color.red.opacity(0.3) : Color.clear,
                    radius: showOnlyFavorites ? 3 : 0,
                    x: 0,
                    y: 1
                )
                .scaleEffect(showOnlyFavorites ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: showOnlyFavorites)
        }
        .buttonStyle(PlainButtonStyle())
        .help(showOnlyFavorites ? "显示全部" : "只显示收藏")
    }

    
    // 打开设置窗口
    private func openSettingsWindow() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.center()
        settingsWindow.title = "设置"
        settingsWindow.isReleasedWhenClosed = true
        settingsWindow.minSize = NSSize(width: 600, height: 450)
        
        // 使用现有的HotKeyManager实例，不要创建新的
        let settingsView = SettingsView()
            .environmentObject(clipboardManager)
            .environmentObject(hotKeyManager)
        
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.makeKeyAndOrderFront(nil)
    }
    
    // 标题栏显示模式切换（紧凑版）
    private var displayModeToggle: some View {
        HStack(spacing: 2) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayMode = mode
                        switchDisplayMode(to: mode)
                    }
                }) {
                    Image(systemName: mode.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(displayMode == mode ? .white : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(
                                    displayMode == mode ? 
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor,
                                            Color.accentColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.2),
                                            Color.gray.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    displayMode == mode ? 
                                    Color.accentColor.opacity(0.8) : 
                                    Color.gray.opacity(0.4),
                                    lineWidth: displayMode == mode ? 2 : 1
                                )
                        )
                        .shadow(
                            color: displayMode == mode ? Color.accentColor.opacity(0.4) : Color.clear,
                            radius: displayMode == mode ? 2 : 0,
                            x: 0,
                            y: 1
                        )
                        .scaleEffect(displayMode == mode ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: displayMode == mode)
                }
                .buttonStyle(PlainButtonStyle())
                .help(mode.displayName)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // 切换显示模式
    private func switchDisplayMode(to mode: DisplayMode) {
        // 通知HotKeyManager切换显示模式
        NotificationCenter.default.post(
            name: NSNotification.Name("SwitchDisplayMode"),
            object: nil,
            userInfo: ["mode": mode.rawValue]
        )
    }
    
    // 从HotKeyManager获取当前显示模式
    private func updateDisplayModeFromHotKeyManager() {
        // 从UserDefaults或HotKeyManager获取当前显示模式
        let currentMode = UserDefaults.standard.string(forKey: "displayMode") ?? "bottom"
        if let mode = DisplayMode(rawValue: currentMode) {
            displayMode = mode
        }
    }
    
    // 拉伸指示符
    private var resizeIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ResizeGripView()
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
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
                // 根据显示模式选择不同的布局
                if displayMode == .center {
                    clipboardItemsList  // 居中模式使用列表
                } else {
                    clipboardItemsGrid  // 底部模式使用卡片
                }
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
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
                            clipboardManager.copyToPasteboard(item)
                            if let onClose = onClose {
                                onClose()
                            } else {
                                NSApp.keyWindow?.close()
                            }
                        },
                        onToggleFavorite: {
                            clipboardManager.toggleFavorite(item)
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
    
    // 居中模式的列表视图
    private var clipboardItemsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardListItemView(
                        item: item,
                        index: index,
                        isSelected: index == selectedIndex,
                        onCopy: {
                            clipboardManager.copyToPasteboard(item)
                            if let onClose = onClose {
                                onClose()
                            } else {
                                NSApp.keyWindow?.close()
                            }
                        },
                        onToggleFavorite: {
                            clipboardManager.toggleFavorite(item)
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
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

// 列表项视图
struct ClipboardListItemView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetail: () -> Void
    
    @State private var isHovered = false
    @State private var showCopyFeedback = false
    @State private var isExpanded = false
    
    private var shouldTruncate: Bool {
        item.content.count > 80
    }
    
    private var displayContent: String {
        if isExpanded || !shouldTruncate {
            return item.content
        } else {
            return String(item.content.prefix(80)) + "..."
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // 左侧：应用图标
            VStack(spacing: 2) {
                if let appIcon = item.getAppIcon() {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(item.type.backgroundColor == "systemBlue" ? .blue : .gray)
                }
                
                Text(item.type.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 45)
            
            // 中间：内容预览
            VStack(alignment: .leading, spacing: 3) {
                // 内容预览
                Text(displayContent)
                    .font(.system(size: 13))
                    .lineLimit(isExpanded ? nil : 2)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 展开/收起按钮
                if shouldTruncate {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "收起" : "查看全部")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 来源信息
                HStack(spacing: 6) {
                    Text(item.sourceApp)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(item.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            // 右侧：操作按钮
            if isHovered || isSelected {
                HStack(spacing: 6) {
                    // 收藏按钮
                    Button(action: onToggleFavorite) {
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(item.isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(item.isFavorite ? "取消收藏" : "收藏")
                    
                    // 详情按钮
                    Button(action: onShowDetail) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("查看详情")
                    
                    // 复制按钮
                    Button(action: {
                        onCopy()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCopyFeedback = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCopyFeedback = false
                            }
                        }
                    }) {
                        Image(systemName: showCopyFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(showCopyFeedback ? .green : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("复制")
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    isSelected ? 
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.2),
                            Color.accentColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.8 : 0.6),
                            Color.white.opacity(isHovered ? 0.6 : 0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? 
                            Color.accentColor.opacity(0.5) : 
                            Color.gray.opacity(isHovered ? 0.4 : 0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// 拉伸指示符视图
struct ResizeGripView: View {
    var body: some View {
        ZStack {
            // 三条弯曲线条
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 2) {
                        ForEach(0..<(3-index), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.6),
                                            Color.gray.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 3, height: 3)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 12, height: 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.1))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
        )
        .opacity(0.7)
        .scaleEffect(1.2)
    }
}

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
        } else {
            return .primary
        }
    }
    
    private func getBackgroundColor() -> Color {
        switch backgroundColor {
        case "systemBlue": return .blue
        case "systemGreen": return .green
        case "systemOrange": return .orange
        case "systemRed": return .red
        case "systemPurple": return .purple
        case "systemYellow": return .yellow
        case "systemPink": return .pink
        case "systemTeal": return .teal
        case "systemIndigo": return .indigo
        case "systemCyan": return .cyan
        case "systemMint": return .mint
        default: return .gray
        }
    }
}

// MARK: - 预览
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
            .environmentObject(ClipboardManager())
            .frame(width: 800, height: 600)
    }
}
