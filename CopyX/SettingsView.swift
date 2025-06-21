import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @EnvironmentObject var hotKeyManager: HotKeyManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selection: String? = "general"

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ModernGeneralSettingsView(), tag: "general", selection: $selection) {
                    Label { LocalizedText("general_settings") } icon: { Image(systemName: "gear") }
                }
                NavigationLink(destination: ModernHotKeySettingsView(), tag: "hotkeys", selection: $selection) {
                    Label { LocalizedText("hotkey_settings") } icon: { Image(systemName: "keyboard") }
                }
                NavigationLink(destination: ModernClipboardSettingsView(), tag: "clipboard", selection: $selection) {
                    Label { LocalizedText("clipboard_settings") } icon: { Image(systemName: "doc.on.clipboard") }
                }
                NavigationLink(destination: ModernDataSettingsView(), tag: "data", selection: $selection) {
                    Label { LocalizedText("data_settings") } icon: { Image(systemName: "externaldrive") }
                }
                NavigationLink(destination: ModernFavoritesSettingsView(), tag: "favorites", selection: $selection) {
                    Label { LocalizedText("favorites_settings") } icon: { Image(systemName: "star") }
                }
                NavigationLink(destination: ModernAdvancedSettingsView(), tag: "advanced", selection: $selection) {
                    Label { LocalizedText("advanced_settings") } icon: { Image(systemName: "wrench.and.screwdriver") }
                }
                NavigationLink(destination: ModernAboutView(), tag: "about", selection: $selection) {
                    Label { LocalizedText("about") } icon: { Image(systemName: "info.circle") }
                }
            }
            .listStyle(SidebarListStyle())
            
            // 默认视图
            Text("select_a_category".localized)
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
