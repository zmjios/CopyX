import SwiftUI
import AppKit

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            TextField("搜索剪切板历史...", text: $searchText)
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
                Text("共 \(itemCount) 个项目")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(action: onToggleAutoClean) {
                    HStack(spacing: 4) {
                        Image(systemName: isAutoCleanEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(isAutoCleanEnabled ? .green : .secondary)
                        
                        Text("自动清理")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // 右侧操作
            Button("清空全部") {
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
        .alert("确认清空", isPresented: $showingClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                onClearAll()
            }
        } message: {
            Text("确定要清空所有剪切板历史吗？此操作无法撤销。")
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
                Text("剪切板历史为空")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("复制一些内容开始使用 CopyX")
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
                Text("未找到相关内容")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("没有找到包含 \"\(searchText)\" 的剪切板项目")
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