import SwiftUI
import AppKit

// MARK: - View扩展：支持键盘事件
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Bool) -> some View {
        background(KeyEventView(onKeyDown: action))
    }
}

struct KeyEventView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyEventNSView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyEventNSView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let onKeyDown = onKeyDown, onKeyDown(event) {
            return
        }
        super.keyDown(with: event)
    }
}

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
    @State private var selectedIndex = -1
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
            .onKeyDown { event in
                if event.keyCode == 53 { // ESC键的keyCode
                    onClose?()
                    return true
                }
                return false
            }
            .onAppear {
                selectedIndex = -1
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
                    .padding(.bottom, displayMode == .bottom ? 20 : 0) // 底部模式添加额外间距
            }
            .background(.ultraThinMaterial)
            .id(localizationManager.revision)
            
            // 只在居中模式显示拉伸指示符
            if displayMode == .center {
                resizeIndicator
            }
        }
        .clipped() // 确保内容不会溢出边界
    }
    
    private var topSearchBar: some View {
        VStack(spacing: 0) {
            // 全屏标题栏
            HStack(spacing: 20) {
                // 左侧：应用标题和状态
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("CopyX")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if !filteredItems.isEmpty {
                                Text("Pro")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, .red],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(filteredItems.count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.accentColor)
                            Text("items".localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if showOnlyFavorites {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                                    .scaleEffect(1.2)
                                    .animation(.bouncy(duration: 0.6).repeatForever(autoreverses: true), value: showOnlyFavorites)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 中间：搜索框
            searchField
            
            Spacer()
            
                // 右侧：过滤和操作按钮
                HStack(spacing: 12) {
            typeFilterButtons
            
                    Divider()
                        .frame(height: 20)
            
                favoritesButton
                settingsButton
                closeButton
            }
        }
        .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5),
            alignment: .bottom
        )
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? .secondary : .accentColor)
                .font(.system(size: 14, weight: .medium))
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
            TextField("search_placeholder".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .allowsHitTesting(true)
                .focusable(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: searchText.isEmpty ? 
                                    [Color.gray.opacity(0.3), Color.gray.opacity(0.1)] :
                                    [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: searchText.isEmpty ? 1 : 2
                        )
                        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
    
    private var typeFilterButtons: some View {
        HStack(spacing: 6) {
            Button(action: { 
                withAnimation(.bouncy(duration: 0.5)) {
                    selectedTypeFilter = nil 
                }
            }) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedTypeFilter == nil ? .white : .secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                selectedTypeFilter == nil ? 
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedTypeFilter == nil ? 
                                Color.blue.opacity(0.3) : 
                                Color.secondary.opacity(0.3), 
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: selectedTypeFilter == nil ? .blue.opacity(0.3) : .clear,
                        radius: selectedTypeFilter == nil ? 4 : 0,
                        x: 0,
                        y: 2
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help("all_types".localized)
            .scaleEffect(selectedTypeFilter == nil ? 1.1 : 1.0)
            .animation(.bouncy(duration: 0.5), value: selectedTypeFilter)

            ForEach(ClipboardItem.ClipboardItemType.allCases, id: \.self) { type in
                Button(action: { 
                    withAnimation(.bouncy(duration: 0.5)) {
                        selectedTypeFilter = type 
                    }
                }) {
                    Image(systemName: type.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTypeFilter == type ? .white : type.color)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedTypeFilter == type ? 
                                    LinearGradient(
                                        colors: [type.color, type.color.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [type.color.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    type.color.opacity(selectedTypeFilter == type ? 0.5 : 0.3), 
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedTypeFilter == type ? type.color.opacity(0.3) : .clear,
                            radius: selectedTypeFilter == type ? 4 : 0,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help(type.displayName)
                .scaleEffect(selectedTypeFilter == type ? 1.1 : 1.0)
                .animation(.bouncy(duration: 0.5), value: selectedTypeFilter)
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                if let onClose = onClose {
                    onClose()
                } else {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CloseClipboardHistory"),
                        object: nil
                    )
                }
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .help("close".localized)
        .scaleEffect(1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                // 可以添加悬停缩放效果
            }
        }
    }
    
    // 标题栏设置按钮
    private var settingsButton: some View {
        Button(action: {
            hotKeyManager.openSettings()
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.15), Color.secondary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help("settings".localized)
        .scaleEffect(1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                // 悬停效果可以在这里添加
            }
        }
    }
    
    // 标题栏收藏按钮
    private var favoritesButton: some View {
        Button(action: {
            withAnimation(.bouncy(duration: 0.6)) {
                showOnlyFavorites.toggle()
            }
        }) {
            Image(systemName: showOnlyFavorites ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(showOnlyFavorites ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            showOnlyFavorites ? 
                            LinearGradient(
                                colors: [Color.red, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            showOnlyFavorites ? Color.red.opacity(0.3) : Color.secondary.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: showOnlyFavorites ? Color.red.opacity(0.3) : Color.clear,
                    radius: showOnlyFavorites ? 6 : 0,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(showOnlyFavorites ? "show_all".localized : "show_favorites_only".localized)
        .scaleEffect(showOnlyFavorites ? 1.1 : 1.0)
        .animation(.bouncy(duration: 0.6), value: showOnlyFavorites)
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
                switch displayMode {
                case .center:
                    clipboardItemsList  // 居中模式使用列表
                case .bottom:
                    clipboardItemsGrid  // 底部模式使用水平卡片
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
                            // 不关闭窗口，保持历史视图开启，添加复制成功反馈
                            withAnimation(.bouncy(duration: 0.6)) {
                                // 可以添加复制成功的视觉反馈
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
                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
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
                            // 不关闭窗口，保持历史视图开启
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
            
            if item.isFavorite {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.1), Color.pink.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
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
                        item.isFavorite ?
                        [Color.red.opacity(0.6), Color.pink.opacity(0.3)] :
                        [Color.white.opacity(isHovered ? 0.6 : 0.3), Color.white.opacity(isHovered ? 0.3 : 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isSelected ? 2 : 1
            )
    }


    
    // 复制反馈覆盖层
    private var copyFeedbackOverlay: some View {
        Group {
            if showCopyFeedback {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                    
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("已复制")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    

    
    // 现代化操作按钮
    private func modernActionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color == .secondary ? color : .white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: color == .secondary ? 
                                    [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)] :
                                    [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                // 可以添加悬停效果
            }
        }
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
        .onTapGesture(count: 2) {
            onCopy()
            withAnimation { showCopyFeedback = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showCopyFeedback = false }
            }
        }
        .contextMenu {
            listItemContextMenu
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
            
            // 应用名称使用主题色
            Text(item.sourceApp)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.getAppThemeColor().opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(item.getAppThemeColor().opacity(0.3), lineWidth: 0.5)
                        )
                )
                .foregroundColor(item.getAppThemeColor())
            
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            }

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
            actionButton(icon: item.isFavorite ? "heart.fill" : "heart", color: item.isFavorite ? .red : .pink, tooltip: item.isFavorite ? "unfavorite" : "favorite", action: onToggleFavorite)
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

    // 列表项右键菜单
    private var listItemContextMenu: some View {
        VStack {
            Button(action: {
                onCopy()
                withAnimation { showCopyFeedback = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCopyFeedback = false }
                }
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
        }
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

// MARK: - 预览
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
            .frame(width: 800, height: 600)
    }
}
