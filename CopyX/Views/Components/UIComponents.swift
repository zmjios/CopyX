import SwiftUI
import AppKit

// MARK: - 毛玻璃效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            TextField("search_clipboard_history_placeholder".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
}

// MARK: - 工具栏
struct ToolbarView: View {
    let itemCount: Int
    let onClearAll: () -> Void
    let onToggleAutoClean: () -> Void
    let isAutoCleanEnabled: Bool
    
    @State private var showingClearConfirmation = false
    
    var body: some View {
        HStack {
            // 左侧信息
            HStack(spacing: 12) {
                Text(String(format: "toolbar_item_count_format".localized, itemCount))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(action: onToggleAutoClean) {
                    HStack(spacing: 4) {
                        Image(systemName: isAutoCleanEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(isAutoCleanEnabled ? .green : .secondary)
                        
                        Text("toolbar_autoclean".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // 右侧操作
            Button("toolbar_clear_all".localized) {
                showingClearConfirmation = true
            }
            .font(.system(size: 12))
            .foregroundColor(.red)
            .buttonStyle(PlainButtonStyle())
            .disabled(itemCount == 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .alert("toolbar_clear_confirm_title".localized, isPresented: $showingClearConfirmation) {
            Button("cancel".localized, role: .cancel) { }
            Button("clear".localized, role: .destructive) {
                onClearAll()
            }
        } message: {
            Text("toolbar_clear_confirm_message".localized)
        }
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("empty_state_title".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("empty_state_subtitle".localized)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - 搜索空状态视图
struct SearchEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("search_empty_state_title".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(String(format: "search_empty_state_subtitle_format".localized, searchText))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - 操作按钮
struct ActionButton: View {
    let icon: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHovered ? .white : color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isHovered ? color : color.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(tooltip)
    }
} 