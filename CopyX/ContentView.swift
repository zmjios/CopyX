import SwiftUI

struct ContentView: View {
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack {
            Image(systemName: "doc.on.clipboard")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            LocalizedText("copyx_running_in_background")
                .font(.title2)
            LocalizedText("use_hotkey_to_open")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ClipboardManager())
            .environmentObject(LocalizationManager.shared)
    }
}