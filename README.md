# CopyX - 强大的 macOS 剪切板管理工具

<div align="center">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue.svg" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/SwiftUI-✓-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT License">
</div>

## 📋 功能特色

- **📚 剪切板历史管理** - 自动保存和管理剪切板历史记录
- **⌨️ 全局快捷键** - 支持自定义快捷键快速访问
- **🎨 多种显示样式** - 支持横向和纵向布局切换
- **🔍 智能搜索** - 快速搜索和过滤剪切板内容
- **📱 多种内容类型** - 支持文本、图片、文件、链接等多种格式
- **🔐 隐私保护** - 支持密码检测和过滤
- **💾 数据备份** - 支持数据导入导出功能
- **🎯 状态栏常驻** - 方便快速访问和管理

## 🚀 快速开始

### 系统要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本

### 安装步骤

1. 克隆项目到本地

```bash
git clone https://github.com/your-username/CopyX.git
cd CopyX
```

2. 使用 Xcode 打开项目

```bash
open CopyX.xcodeproj
```

3. 在 Xcode 中编译并运行

### 首次使用

1. 启动应用后，CopyX 会自动在状态栏显示图标
2. 使用默认快捷键 `⌘⇧V` 打开剪切板历史窗口
3. 通过状态栏菜单访问设置页面进行个性化配置

## 📖 使用指南

### 基本操作

- **查看历史**: 使用快捷键 `⌘⇧V` 或点击状态栏图标
- **复制内容**: 点击历史记录项目或按回车键
- **删除记录**: 悬停在项目上点击删除按钮
- **搜索内容**: 在历史窗口顶部使用搜索框
- **清空历史**: 在历史窗口点击"清空历史"按钮

### 高级功能

#### 快捷键设置

- 在设置页面的"快捷键"标签页中
- 可以自定义全局快捷键组合
- 支持 Command、Option、Control、Shift 等修饰键

#### 显示样式

- **纵向布局**: 传统列表显示，适合查看详细信息
- **横向布局**: 网格显示，适合快速浏览

#### 内容类型管理

- 支持启用/禁用特定内容类型的监控
- 包括纯文本、图片、文件、链接等

#### 数据管理

- **导出数据**: 将剪切板历史导出为 JSON 文件
- **导入数据**: 从备份文件恢复剪切板历史
- **存储限制**: 可设置历史记录数量和存储空间限制

## ⚙️ 配置选项

### 通用设置

- 开机启动
- 菜单栏显示
- Dock 图标隐藏
- 通知开关

### 剪切板设置

- 最大历史记录数量
- 内容类型过滤
- 密码检测和过滤
- 音效提示

### 快捷键配置

- 全局快捷键启用/禁用
- 自定义快捷键组合
- 快捷键冲突检测

## 🛠️ 技术实现

### 架构设计

- **SwiftUI**: 现代化的用户界面框架
- **Combine**: 响应式编程处理数据流
- **AppKit**: 系统级功能和窗口管理
- **Carbon**: 全局快捷键注册

### 核心组件

- `ClipboardManager`: 剪切板监控和历史管理
- `HotKeyManager`: 全局快捷键处理
- `ClipboardItem`: 剪切板项目数据模型
- `ClipboardHistoryView`: 历史记录显示界面
- `SettingsView`: 设置页面

### 数据存储

- 使用 `UserDefaults` 存储用户设置
- 使用 `JSON` 格式存储剪切板历史
- 支持数据压缩和加密（可选）

## 🔧 开发说明

### 项目结构

```
CopyX/
├── CopyXApp.swift              # 应用程序入口
├── ContentView.swift           # 主界面视图
├── ClipboardManager.swift      # 剪切板管理器
├── HotKeyManager.swift         # 快捷键管理器
├── ClipboardItem.swift         # 数据模型
├── ClipboardHistoryView.swift  # 历史记录视图
├── SettingsView.swift          # 设置界面
├── Assets.xcassets/            # 资源文件
└── CopyX.entitlements         # 应用权限配置
```

### 构建配置

- 最低部署目标: macOS 14.0
- Swift 版本: 5.0
- 应用分类: 生产力工具

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献

欢迎提交 Pull Request 和 Issue！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📞 联系我们

- 项目主页: [https://github.com/your-username/CopyX](https://github.com/your-username/CopyX)
- 问题反馈: [https://github.com/your-username/CopyX/issues](https://github.com/your-username/CopyX/issues)

## 🙏 致谢

感谢所有为这个项目贡献代码和想法的开发者们！

---

<div align="center">
  Made with ❤️ by CopyX Team
</div>
