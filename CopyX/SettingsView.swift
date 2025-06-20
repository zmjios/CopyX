import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var hotKeyManager: HotKeyManager
    
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        NavigationView {
            // 侧边栏
            List(selection: $selectedTab) {
                Section("设置") {
                    SettingsNavItem(
                        tab: .general,
                        icon: "gearshape.fill",
                        title: "通用设置",
                        subtitle: "启动和界面配置"
                    )
                    
                    SettingsNavItem(
                        tab: .hotkeys,
                        icon: "keyboard.fill",
                        title: "快捷键",
                        subtitle: "自定义快捷键"
                    )
                    
                    SettingsNavItem(
                        tab: .clipboard,
                        icon: "doc.on.clipboard.fill",
                        title: "剪切板",
                        subtitle: "历史记录设置"
                    )
                    
                    SettingsNavItem(
                        tab: .data,
                        icon: "externaldrive.fill",
                        title: "数据备份",
                        subtitle: "导入导出数据"
                    )
                    
                    SettingsNavItem(
                        tab: .advanced,
                        icon: "gearshape.2.fill",
                        title: "高级功能",
                        subtitle: "文本处理和统计"
                    )
                    
                    SettingsNavItem(
                        tab: .favorites,
                        icon: "heart.fill",
                        title: "收藏夹",
                        subtitle: "管理收藏的项目"
                    )
                }
                
                Section("信息") {
                    SettingsNavItem(
                        tab: .about,
                        icon: "info.circle.fill",
                        title: "关于 CopyX",
                        subtitle: "版本信息"
                    )
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // 主内容区域
            Group {
                switch selectedTab {
                case .general:
                    ModernGeneralSettingsView()
                        .environmentObject(clipboardManager)
                case .hotkeys:
                    ModernHotKeySettingsView()
                        .environmentObject(hotKeyManager)
                case .clipboard:
                    ModernClipboardSettingsView()
                        .environmentObject(clipboardManager)
                case .data:
                    ModernDataSettingsView()
                        .environmentObject(clipboardManager)
                case .advanced:
                    ModernAdvancedSettingsView()
                        .environmentObject(clipboardManager)
                case .favorites:
                    ModernFavoritesSettingsView()
                        .environmentObject(clipboardManager)
                case .about:
                    ModernAboutView()
                }
            }
            .frame(minWidth: 400)
        }
    }
    
    enum SettingsTab: String, CaseIterable {
        case general = "general"
        case hotkeys = "hotkeys"
        case clipboard = "clipboard"
        case data = "data"
        case advanced = "advanced"
        case favorites = "favorites"
        case about = "about"
    }
}

struct SettingsNavItem: View {
    let tab: SettingsView.SettingsTab
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .tag(tab)
        .padding(.vertical, 4)
    }
}

// MARK: - 现代化通用设置
struct ModernGeneralSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = true
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("hideInDock") private var hideInDock: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 页面标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("通用设置")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("配置 CopyX 的启动和界面选项")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 启动设置
                SettingsSection(title: "启动设置", icon: "power") {
                    SettingsToggle(
                        title: "开机启动",
                        subtitle: "系统启动时自动运行 CopyX",
                        isOn: $launchAtLogin
                    ) { value in
                        setLaunchAtLogin(value)
                    }
                    
                    SettingsToggle(
                        title: "在菜单栏显示",
                        subtitle: "在系统菜单栏显示 CopyX 图标",
                        isOn: $showInMenuBar
                    )
                    
                    SettingsToggle(
                        title: "隐藏 Dock 图标",
                        subtitle: "在 Dock 中隐藏应用图标",
                        isOn: $hideInDock
                    ) { value in
                        NSApp.setActivationPolicy(value ? .accessory : .regular)
                    }
                }
                
                // 通知设置
                SettingsSection(title: "通知设置", icon: "bell") {
                    SettingsToggle(
                        title: "启用通知",
                        subtitle: "新的剪切板内容时显示桌面通知",
                        isOn: $enableNotifications
                    )
                }
                
                // 界面设置
                SettingsSection(title: "界面设置", icon: "paintbrush") {
                    SettingsToggle(
                        title: "启用剪切板音效",
                        subtitle: "复制内容时播放系统音效",
                        isOn: $clipboardManager.enableSound
                    )
                    
                    SettingsToggle(
                        title: "使用模态分享窗口",
                        subtitle: "使用居中弹框而非右下角菜单分享",
                        isOn: $clipboardManager.useModalShareView
                    )
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // 实现登录时启动的逻辑
    }
}

// MARK: - 设置页面辅助组件
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(.leading, 24)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    
    init(title: String, subtitle: String, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if #available(macOS 14.0, *) {
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: isOn) { _, newValue in
                        onChange?(newValue)
                    }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

// MARK: - 现代化快捷键设置
struct ModernHotKeySettingsView: View {
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @State private var isRecording: Bool = false
    @State private var recordedKeyCode: Int = 0
    @State private var recordedModifiers: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 页面标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("快捷键设置")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("自定义全局快捷键来快速访问剪切板历史")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 快捷键配置
                SettingsSection(title: "快捷键配置", icon: "keyboard") {
                    SettingsToggle(
                        title: "启用快捷键",
                        subtitle: "使用全局快捷键打开剪切板历史窗口",
                        isOn: $hotKeyManager.hotKeyEnabled
                    ) { enabled in
                        hotKeyManager.enableHotKey(enabled)
                    }
                    
                    if hotKeyManager.hotKeyEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("当前快捷键")
                                .font(.system(size: 14, weight: .medium))
                            
                            HStack {
                                Text(currentHotKeyString)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.textBackgroundColor))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                
                                Spacer()
                                
                                Button(isRecording ? "按键录制中..." : "重新设置") {
                                    if isRecording {
                                        stopRecording()
                                    } else {
                                        startRecording()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isRecording)
                            }
                            
                            if isRecording {
                                HStack {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                        .foregroundColor(.orange)
                                    Text("请按下新的快捷键组合")
                                        .font(.system(size: 13))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                // 快捷键说明
                SettingsSection(title: "快捷键说明", icon: "questionmark.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("⌘")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("Command 键")
                                .font(.system(size: 14))
                        }
                        
                        HStack(spacing: 12) {
                            Text("⌥")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("Option 键")
                                .font(.system(size: 14))
                        }
                        
                        HStack(spacing: 12) {
                            Text("⌃")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("Control 键")
                                .font(.system(size: 14))
                        }
                        
                        HStack(spacing: 12) {
                            Text("⇧")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("Shift 键")
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if isRecording {
                    recordedKeyCode = Int(event.keyCode)
                    recordedModifiers = Int(event.modifierFlags.rawValue)
                    stopRecording()
                    return nil
                }
                return event
            }
        }
    }
    
    private var currentHotKeyString: String {
        let modifierString = KeyCodeUtils.modifierString(for: hotKeyManager.hotKeyModifiers)
        let keyString = KeyCodeUtils.keyName(for: hotKeyManager.hotKeyCode)
        return "\(modifierString)\(keyString)"
    }
    
    private func startRecording() {
        isRecording = true
    }
    
    private func stopRecording() {
        isRecording = false
        if recordedModifiers != 0 && recordedKeyCode != 0 {
            hotKeyManager.updateHotKey(modifiers: recordedModifiers, keyCode: recordedKeyCode)
        }
    }
}

// MARK: - 现代化剪切板设置
struct ModernClipboardSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var tempMaxCount: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("剪切板设置")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("配置剪切板历史记录的保存和管理选项")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                SettingsSection(title: "历史记录", icon: "clock.arrow.circlepath") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("最大保存数量")
                                    .font(.system(size: 15, weight: .medium))
                                Text("限制保存的剪切板历史项目数量")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            TextField("", value: $clipboardManager.maxHistoryCount, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                        
                        SettingsToggle(
                            title: "自动清理过期项目",
                            subtitle: "超过30天的项目将被自动删除",
                            isOn: $clipboardManager.autoCleanup
                        )
                    }
                }
                
                SettingsSection(title: "隐私设置", icon: "lock.shield") {
                    SettingsToggle(
                        title: "跳过密码内容",
                        subtitle: "不保存可能包含密码的敏感内容",
                        isOn: $clipboardManager.skipPasswords
                    )
                    
                    SettingsToggle(
                        title: "启用文本内容",
                        subtitle: "保存复制的文本内容",
                        isOn: $clipboardManager.enableTextHistory
                    )
                    
                    SettingsToggle(
                        title: "启用图片内容",
                        subtitle: "保存复制的图片内容",
                        isOn: $clipboardManager.enableImageHistory
                    )
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 现代化数据设置
struct ModernDataSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("数据备份")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("导入导出剪切板历史数据，保护你的数据安全")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                SettingsSection(title: "数据导出", icon: "square.and.arrow.up") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("将剪切板历史导出为 JSON 文件，便于备份和迁移")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button("导出数据") {
                            exportData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                SettingsSection(title: "数据导入", icon: "square.and.arrow.down") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("从备份的 JSON 文件中恢复剪切板历史")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button("导入数据") {
                            importData()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                SettingsSection(title: "数据清理", icon: "trash") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚠️ 此操作将永久删除所有剪切板历史记录")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Button("清空所有数据") {
                            clipboardManager.clearHistory()
                        }
                        .buttonStyle(.borderedProminent)
                        .accentColor(.red)
                    }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func exportData() {
        clipboardManager.exportData()
    }
    
    private func importData() {
        clipboardManager.importData()
    }
}

// MARK: - 高级功能设置页面
struct ModernAdvancedSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var selectedText = ""
    @State private var processedText = ""
    @State private var selectedOperation: TextOperation = .trimWhitespace
    @State private var showingStats = false
    @State private var usageStats: UsageStats?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("高级功能")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("文本处理工具和使用统计")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 文本处理工具
                SettingsSection(title: "文本处理工具", icon: "textformat") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择文本处理操作")
                            .font(.system(size: 14, weight: .medium))
                        
                        Picker("操作", selection: $selectedOperation) {
                            ForEach(TextOperation.allCases, id: \.self) { operation in
                                HStack {
                                    Image(systemName: operation.icon)
                                    Text(operation.rawValue)
                                }
                                .tag(operation)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("输入文本")
                                .font(.system(size: 13, weight: .medium))
                            TextEditor(text: $selectedText)
                                .font(.system(size: 12, design: .monospaced))
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Button("处理文本") {
                            processedText = clipboardManager.processText(selectedText, operation: selectedOperation)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedText.isEmpty)
                        
                        if !processedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("处理结果")
                                    .font(.system(size: 13, weight: .medium))
                                TextEditor(text: .constant(processedText))
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.05))
                                    .cornerRadius(6)
                                
                                Button("复制结果") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(processedText, forType: .string)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                // 使用统计
                SettingsSection(title: "使用统计", icon: "chart.bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("刷新统计") {
                            usageStats = clipboardManager.getUsageStats()
                            showingStats = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let stats = usageStats, showingStats {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("统计信息")
                                    .font(.system(size: 13, weight: .medium))
                                
                                Text(stats.description)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(12)
                                    .background(Color.secondary.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // 快速操作
                SettingsSection(title: "快速操作", icon: "bolt") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("从剪切板快速处理文本")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(TextOperation.allCases.prefix(9), id: \.self) { operation in
                                Button(action: {
                                    if let currentText = NSPasteboard.general.string(forType: .string) {
                                        let processed = operation.apply(to: currentText)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(processed, forType: .string)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: operation.icon)
                                            .font(.system(size: 16))
                                        Text(operation.rawValue)
                                            .font(.system(size: 10))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 收藏夹设置页面
struct ModernFavoritesSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedTag = ""
    
    var filteredFavorites: [ClipboardItem] {
        var items = clipboardManager.favoriteItems
        
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if !selectedTag.isEmpty {
            items = items.filter { $0.tags.contains(selectedTag) }
        }
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("收藏夹管理")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("管理你收藏的剪切板项目")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 搜索和筛选
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索收藏项目...", text: $searchText)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    if !clipboardManager.allTags.isEmpty {
                        Picker("标签", selection: $selectedTag) {
                            Text("所有标签").tag("")
                            ForEach(clipboardManager.allTags, id: \.self) { tag in
                                Text(tag).tag(tag)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 16)
            
            Divider()
            
            // 收藏项目列表
            if filteredFavorites.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "还没有收藏的项目" : "没有找到匹配的收藏项目")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("在剪切板历史中点击心形图标来收藏项目")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFavorites) { item in
                            FavoriteItemCard(item: item)
                                .environmentObject(clipboardManager)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct FavoriteItemCard: View {
    let item: ClipboardItem
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            VStack {
                Image(systemName: item.type.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(getTypeColor())
                    .cornerRadius(8)
                
                Spacer()
            }
            
            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if item.usageCount > 0 {
                        Text("使用 \(item.usageCount) 次")
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if !item.tags.isEmpty {
                    HStack {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                }
                
                HStack {
                    Text(item.sourceApp)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.relativeTime)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            VStack(spacing: 8) {
                Button(action: {
                    clipboardManager.copyToPasteboard(item)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .help("复制")
                
                Button(action: {
                    clipboardManager.toggleFavorite(item)
                }) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .help("取消收藏")
            }
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(12)
        .background(Color.secondary.opacity(isHovered ? 0.08 : 0.04))
        .cornerRadius(10)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovered
            }
        }
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

// MARK: - 现代化关于页面
struct ModernAboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 应用图标和信息
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 8) {
                        Text("CopyX")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("强大的剪切板管理工具")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("版本 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 功能特色
                VStack(alignment: .leading, spacing: 20) {
                    Text("主要功能")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "keyboard", title: "全局快捷键", description: "快速访问剪切板历史")
                        FeatureRow(icon: "doc.text", title: "智能识别", description: "自动识别文本、图片、链接等类型")
                        FeatureRow(icon: "magnifyingglass", title: "快速搜索", description: "实时搜索和类型筛选")
                        FeatureRow(icon: "lock.shield", title: "隐私保护", description: "智能跳过密码等敏感内容")
                        FeatureRow(icon: "externaldrive", title: "数据备份", description: "导入导出功能保护数据安全")
                    }
                }
                
                // 版权信息
                VStack(spacing: 8) {
                    Text("© 2025 CopyX. 保留所有权利。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("基于 SwiftUI 构建")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Helper Types
struct ClipboardExportDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    
    let items: [ClipboardItem]
    
    init(items: [ClipboardItem]) {
        self.items = items
    }
    
    init(configuration: ReadConfiguration) throws {
        items = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(items)
        return FileWrapper(regularFileWithContents: data)
    }
}

 
