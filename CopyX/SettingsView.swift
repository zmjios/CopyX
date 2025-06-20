import SwiftUI
import AppKit

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
