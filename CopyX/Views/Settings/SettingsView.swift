import SwiftUI
import AppKit

// 为设置页面定义一个清晰的导航目标枚举
enum SettingsPage: String, Hashable {
    case general, hotkeys, clipboard, data, favorites, advanced, about
}

struct SettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // 使用新的导航目标枚举作为选择状态
    @State private var selection: SettingsPage? = .general

    var body: some View {
        NavigationSplitView {
            // 左侧边栏 - 美化的系统设置风格
            List(selection: $selection) {
                // 美化的系统设置风格导航项
                EnhancedSystemSettingsNavigationItem(
                    page: .general,
                    icon: "gear",
                    title: "general_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .hotkeys,
                    icon: "keyboard",
                    title: "hotkey_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .clipboard,
                    icon: "doc.on.clipboard",
                    title: "clipboard_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .data,
                    icon: "externaldrive",
                    title: "data_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .favorites,
                    icon: "heart.fill",
                    title: "favorites_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .advanced,
                    icon: "gearshape.2",
                    title: "advanced_settings"
                )
                
                EnhancedSystemSettingsNavigationItem(
                    page: .about,
                    icon: "info.circle",
                    title: "about"
                )
            }
            .listStyle(.sidebar)
            .navigationTitle("CopyX")
            .frame(minWidth: 214, idealWidth: 214, maxWidth: 214)
        } detail: {
            // 右侧详情区 - 固定宽度
            Group {
                if let selection {
                    switch selection {
                    case .general:
                        ModernGeneralSettingsView()
                    case .hotkeys:
                        ModernHotKeySettingsView()
                    case .clipboard:
                        ModernClipboardSettingsView()
                    case .data:
                        ModernDataSettingsView()
                    case .favorites:
                        ModernFavoritesSettingsView()
                    case .advanced:
                        ModernAdvancedSettingsView()
                    case .about:
                        ModernAboutView()
                    }
                } else {
                    SystemSettingsEmptyView()
                }
            }
            .frame(minWidth: 500, idealWidth: 500, maxWidth: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 714, idealWidth: 714, maxWidth: 714, minHeight: 520, idealHeight: 520, maxHeight: 800)
        .toolbar {
            // 隐藏侧边栏切换按钮
            ToolbarItem(placement: .navigation) {
                EmptyView()
            }
        }
        .id(localizationManager.revision)
    }
}

// MARK: - 美化的系统设置风格导航项组件
struct EnhancedSystemSettingsNavigationItem: View {
    let page: SettingsPage
    let icon: String
    let title: String
    
    var body: some View {
        NavigationLink(value: page) {
            HStack(spacing: 10) {
                // 美化的图标
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 18, height: 18)
                
                // 文本
                LocalizedText(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 系统设置风格的空状态视图
struct SystemSettingsEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("选择设置项")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("从侧边栏选择一个设置类别")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(LocalizationManager.shared)
            .environmentObject(ClipboardManager())
            .environmentObject(HotKeyManager())
    }
}
