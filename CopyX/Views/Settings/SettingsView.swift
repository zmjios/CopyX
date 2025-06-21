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
        // 使用现代的 NavigationSplitView 替代旧的 NavigationView
        NavigationSplitView {
            List(selection: $selection) {
                // 使用新的 value-based NavigationLink
                NavigationLink(value: SettingsPage.general) {
                    Label { LocalizedText("general_settings") } icon: { Image(systemName: "gear") }
                }
                NavigationLink(value: SettingsPage.hotkeys) {
                    Label { LocalizedText("hotkey_settings") } icon: { Image(systemName: "keyboard") }
                }
                NavigationLink(value: SettingsPage.clipboard) {
                    Label { LocalizedText("clipboard_settings") } icon: { Image(systemName: "doc.on.clipboard") }
                }
                NavigationLink(value: SettingsPage.data) {
                    Label { LocalizedText("data_settings") } icon: { Image(systemName: "externaldrive") }
                }
                NavigationLink(value: SettingsPage.favorites) {
                    Label { LocalizedText("favorites_settings") } icon: { Image(systemName: "star") }
                }
                NavigationLink(value: SettingsPage.advanced) {
                    Label { LocalizedText("advanced_settings") } icon: { Image(systemName: "wrench.and.screwdriver") }
                }
                NavigationLink(value: SettingsPage.about) {
                    Label { LocalizedText("about") } icon: { Image(systemName: "info.circle") }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            // 使用 .navigationDestination 机制来显示详情视图
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
                Text("select_a_category".localized)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .id(localizationManager.revision)
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
