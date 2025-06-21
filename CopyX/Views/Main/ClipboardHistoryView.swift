import SwiftUI
import AppKit

// MARK: - 显示模式枚举
enum DisplayMode: String, CaseIterable {
    case bottom = "bottom"
    case center = "center"
    
    var displayName: String {
        switch self {
        case .bottom: return "bottom_mode".localized
        case .center: return "center_mode".localized
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
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    @State private var selectedTypeFilter: ClipboardItem.ClipboardItemType? = nil
    @State private var selectedIndex = 0
    @State private var showingDetailView = false
    @State private var selectedItem: ClipboardItem? = nil
    @State private var displayMode: DisplayMode = .bottom
    @State private var showOnlyFavorites = false
    
    // 分享功能所需的状态
    @State private var showShareModal = false
    @State private var itemToShare: ClipboardItem? = nil
    @State private var showShareMenu = false
    //@State private var shareMenuItem: ShareMenuItem? = nil
    
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
            .keyboardShortcut(.cancelAction)
            .onAppear {
                selectedIndex = 0
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DisplayModeChanged"))) { notification in
                if let modeString = notification.userInfo?["mode"] as? String,
                   let mode = DisplayMode(rawValue: modeString) {
                    displayMode = mode
                }
            }
            .overlay(
                // 分享模态框
                ZStack {
                    if showShareModal, let item = itemToShare {
                        ShareModal(item: item, isPresented: $showShareModal)
                    }
                }
            )
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
        detailWindow.title = "clipboard_details_title".localized
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
        .environmentObject(clipboardManager)
        .environmentObject(localizationManager)
        
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
            .id(localizationManager.revision)
            
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
            
            // 右侧：收藏按钮 + 设置按钮 + 关闭按钮
            HStack(spacing: 12) {
                favoritesButton
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
            
            TextField("search_placeholder".localized, text: $searchText)
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
        HStack {
            // "所有类型" 按钮
            TypeFilterButton(
                label: "all_types".localized,
                icon: "square.grid.2x2.fill",
                isSelected: selectedTypeFilter == nil,
                action: { selectedTypeFilter = nil }
            )

            // 动态生成其他类型的按钮
            ForEach(ClipboardItem.ClipboardItemType.allCases, id: \.self) { type in
                TypeFilterButton(
                    label: type.localized,
                    icon: type.iconName,
                    isSelected: selectedTypeFilter == type,
                    action: { selectedTypeFilter = type }
                )
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
            hotKeyManager.openSettings()
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
                        },
                        onShare: {
                            itemToShare = item
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                                showShareModal = true
                            }
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
            LazyVStack(spacing: 12) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    ModernClipboardListItemView(
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
                        },
                        onShare: {
                            itemToShare = item
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                                showShareModal = true
                            }
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
            .padding(.vertical, 12)
        }
    }
}

// MARK: - 全新设计的现代化列表项视图 (Modern List Item View)
struct ModernClipboardListItemView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetail: () -> Void
    let onShare: () -> Void

    @State private var isHovered = false
    @State private var showCopyFeedback = false

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
            
            LinearGradient(
                colors: [
                    Color(nsColor: item.getAppIconDominantColor()).opacity(0.25),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).blur(radius: 20)
            
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.2))
            }
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: isSelected ?
                        [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)] :
                        [Color.white.opacity(isHovered ? 0.6 : 0.3), Color.white.opacity(isHovered ? 0.3 : 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isSelected ? 2.5 : 1.5
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            content
            footer
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(cardBorder)
        .shadow(color: .black.opacity(isHovered ? 0.25 : 0.15), radius: isHovered ? 8 : 4, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: isHovered)
        .animation(.interpolatingSpring(stiffness: 200, damping: 25), value: isSelected)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }

    private var header: some View {
        HStack {
            if let appIcon = item.getAppIcon() {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(radius: 2)
            }
            Text(item.sourceApp)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.9))

            Spacer()

            Text(item.type.displayName)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(item.type.color.opacity(0.2))
                .foregroundColor(item.type.color)
                .clipShape(Capsule())
        }
    }

    private var content: some View {
        Text(item.content)
            .font(.system(size: 14))
            .foregroundColor(.primary.opacity(0.85))
            .lineLimit(3)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Text(item.relativeTime)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()

            if isHovered || isSelected {
                actionButtons
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 0) {
            actionButton(icon: "square.and.arrow.up", color: .blue, tooltip: "share", action: onShare)
            actionButton(icon: item.isFavorite ? "heart.fill" : "heart", color: .pink, tooltip: "favorite", action: onToggleFavorite)
            actionButton(icon: "info.circle", color: .cyan, tooltip: "details", action: onShowDetail)
            actionButton(icon: showCopyFeedback ? "checkmark" : "doc.on.doc", color: .green, tooltip: "copy", action: {
                onCopy()
                withAnimation { showCopyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCopyFeedback = false }
                }
            })
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func actionButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(tooltip.localized)
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

// MARK: - 过滤按钮 (Filter Button)
struct TypeFilterButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
            .frame(width: 800, height: 600)
    }
}
