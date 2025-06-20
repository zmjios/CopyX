import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.on.clipboard")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("CopyX 正在后台运行")
                .font(.title2)
            Text("使用 ⌘⇧V 快捷键打开剪切板历史")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}