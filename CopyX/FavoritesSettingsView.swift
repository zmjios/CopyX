import SwiftUI
import AppKit

// MARK: - 收藏夹设置页面
struct ModernFavoritesSettingsView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedItems: Set<String> = []
    @State private var sortOption: FavoriteSortOption = .dateAdded
    @State private var showingExportDialog = false
    
    var filteredFavorites: [ClipboardItem] {
        let favorites = clipboardManager.favoriteItems
        let filtered = searchText.isEmpty ? favorites : favorites.filter { item in
            item.displayTitle.localizedCaseInsensitiveContains(searchText) ||
            item.content.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted(by: { first, second in
            switch sortOption {
            case .dateAdded:
                return first.timestamp > second.timestamp
            case .dateModified:
                return (first.lastUsedDate ?? first.timestamp) > (second.lastUsedDate ?? second.timestamp)
            case .alphabetical:
                return first.displayTitle.localizedCompare(second.displayTitle) == .orderedAscending
            case .type:
                return first.type.rawValue < second.type.rawValue
            case .usageCount:
                return first.usageCount > second.usageCount
            }
        })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题和工具栏
            headerView
            
            // 主内容区域
            if filteredFavorites.isEmpty {
                emptyStateView
            } else {
                favoritesListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 视图组件
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPageHeader(
                title: "收藏夹管理",
                subtitle: "管理和组织你的收藏项目"
            )
            
            // 搜索和筛选工具栏
            HStack(spacing: 12) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索收藏项目...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // 排序选择器
                Picker("排序", selection: $sortOption) {
                    ForEach(FavoriteSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(minWidth: 100)
            }
            
            // 操作工具栏
            HStack {
                Text("共 \(filteredFavorites.count) 个收藏项目")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(selectedItems.isEmpty ? "全选" : "取消全选") {
                        if selectedItems.isEmpty {
                            selectedItems = Set(filteredFavorites.map { $0.id.uuidString })
                        } else {
                            selectedItems.removeAll()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(filteredFavorites.isEmpty)
                    
                    Button("导出选中") {
                        exportSelectedFavorites()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedItems.isEmpty)
                    
                    Button("删除选中") {
                        deleteSelectedFavorites()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "还没有收藏项目" : "没有找到匹配的收藏项目")
                    .font(.system(size: 18, weight: .medium))
                
                Text(searchText.isEmpty ? 
                     "在剪切板历史中点击心形图标来收藏项目" : 
                     "尝试使用不同的搜索关键词")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !searchText.isEmpty {
                Button("清除搜索") {
                    searchText = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var favoritesListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredFavorites.enumerated()), id: \.element.id) { index, item in
                    FavoriteItemRow(
                        item: item,
                        index: index,
                        isSelected: selectedItems.contains(item.id.uuidString),
                        onToggleSelection: {
                            if selectedItems.contains(item.id.uuidString) {
                                selectedItems.remove(item.id.uuidString)
                            } else {
                                selectedItems.insert(item.id.uuidString)
                            }
                        },
                        onRemoveFromFavorites: {
                            clipboardManager.toggleFavorite(item)
                        },
                        onCopy: {
                            clipboardManager.copyToPasteboard(item)
                        }
                    )
                    
                    if index < filteredFavorites.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - 私有方法
    
    private func exportSelectedFavorites() {
        let selectedFavorites = filteredFavorites.filter { selectedItems.contains($0.id.uuidString) }
        // 简单的导出实现 - 复制到剪切板
        let exportText = selectedFavorites.map { item in
            "\(item.displayTitle): \(item.content)"
        }.joined(separator: "\n\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(exportText, forType: .string)
        
        // 显示通知
        let alert = NSAlert()
        alert.messageText = "导出完成"
        alert.informativeText = "已将 \(selectedFavorites.count) 个收藏项目复制到剪切板"
        alert.runModal()
    }
    
    private func deleteSelectedFavorites() {
        let alert = NSAlert()
        alert.messageText = "确认删除选中的收藏项目"
        alert.informativeText = "将从收藏夹中移除 \(selectedItems.count) 个项目，但不会删除历史记录中的原始项目。"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertFirstButtonReturn {
            let itemsToRemove = filteredFavorites.filter { selectedItems.contains($0.id.uuidString) }
            for item in itemsToRemove {
                clipboardManager.toggleFavorite(item)
            }
            selectedItems.removeAll()
        }
    }
}

// MARK: - 收藏项目行
struct FavoriteItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onRemoveFromFavorites: () -> Void
    let onCopy: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 选择框
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 类型图标
            ZStack {
                Circle()
                    .fill(item.type.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.type.color)
            }
            
            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
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
                
                Text(String(item.content.prefix(100)))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("收藏于 \(formatDate(item.timestamp))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !item.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 9))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(3)
                            }
                        }
                    }
                }
            }
            
            // 操作按钮
            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .help("复制")
                    
                    Button(action: onRemoveFromFavorites) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .help("取消收藏")
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 排序选项枚举
enum FavoriteSortOption: String, CaseIterable {
    case dateAdded = "dateAdded"
    case dateModified = "dateModified"
    case alphabetical = "alphabetical"
    case type = "type"
    case usageCount = "usageCount"
    
    var displayName: String {
        switch self {
        case .dateAdded: return "收藏时间"
        case .dateModified: return "修改时间"
        case .alphabetical: return "字母顺序"
        case .type: return "类型"
        case .usageCount: return "使用次数"
        }
    }
} 