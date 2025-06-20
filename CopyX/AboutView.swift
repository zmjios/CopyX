import SwiftUI
import AppKit

// MARK: - 关于页面
struct ModernAboutView: View {
    @State private var showingLicenses = false
    @State private var showingChangelog = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 应用图标和基本信息
                appInfoSection
                
                // 功能特色
                featuresSection
                
                // 系统信息
                systemInfoSection
                
                // 开发者信息
                developerSection
                
                // 法律信息
                legalSection
                
                // 版权信息
                copyrightSection
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingLicenses) {
            LicensesView()
        }
        .sheet(isPresented: $showingChangelog) {
            ChangelogView()
        }
    }
    
    // MARK: - 视图组件
    
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            // 应用图标
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("CopyX")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("强大的剪切板管理工具")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Text("版本 \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("构建 \(buildNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button("查看更新日志") {
                    showingChangelog = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("检查更新") {
                    checkForUpdates()
                }
                .buttonStyle(.bordered)
                
                Button("访问官网") {
                    openWebsite()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("主要功能")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                FeatureCard(
                    icon: "keyboard",
                    title: "全局快捷键",
                    description: "快速访问剪切板历史"
                )
                
                FeatureCard(
                    icon: "doc.text",
                    title: "智能识别",
                    description: "自动识别文本、图片、链接等类型"
                )
                
                FeatureCard(
                    icon: "magnifyingglass",
                    title: "快速搜索",
                    description: "实时搜索和类型筛选"
                )
                
                FeatureCard(
                    icon: "lock.shield",
                    title: "隐私保护",
                    description: "智能跳过密码等敏感内容"
                )
                
                FeatureCard(
                    icon: "externaldrive",
                    title: "数据备份",
                    description: "导入导出功能保护数据安全"
                )
                
                FeatureCard(
                    icon: "heart",
                    title: "收藏功能",
                    description: "收藏重要内容便于快速访问"
                )
            }
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("系统信息")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "操作系统", value: systemVersion)
                InfoRow(label: "设备型号", value: deviceModel)
                InfoRow(label: "处理器", value: processorInfo)
                InfoRow(label: "内存", value: memoryInfo)
                InfoRow(label: "安装路径", value: installPath)
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("开发者")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CopyX Team")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("专注于提升用户生产力的工具开发")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button("发送反馈") {
                    sendFeedback()
                }
                .buttonStyle(.borderedProminent)
                
                Button("GitHub") {
                    openGitHub()
                }
                .buttonStyle(.bordered)
                
                Button("支持我们") {
                    showSupport()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("法律信息")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Button("开源许可证") {
                    showingLicenses = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("隐私政策") {
                    openPrivacyPolicy()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("使用条款") {
                    openTermsOfService()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var copyrightSection: some View {
        VStack(spacing: 8) {
            Text("© 2025 CopyX. 保留所有权利。")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("基于 SwiftUI 和 AppKit 构建")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("感谢所有开源项目的贡献者")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 计算属性
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private var deviceModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
    
    private var processorInfo: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var cpu = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &cpu, &size, nil, 0)
        return String(cString: cpu)
    }
    
    private var memoryInfo: String {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(physicalMemory))
    }
    
    private var installPath: String {
        return Bundle.main.bundlePath
    }
    
    // MARK: - 私有方法
    
    private func checkForUpdates() {
        // 实现检查更新逻辑
        if let url = URL(string: "https://github.com/copyx/copyx/releases") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://copyx.app") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mailto:feedback@copyx.app?subject=CopyX Feedback") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com/copyx/copyx") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showSupport() {
        if let url = URL(string: "https://copyx.app/support") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://copyx.app/privacy") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://copyx.app/terms") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 功能卡片
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

// MARK: - 许可证视图
struct LicensesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("开源许可证")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("CopyX 使用了以下开源项目：")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 这里可以添加具体的开源许可证信息
                    LicenseItem(
                        name: "SwiftUI",
                        license: "Apple Inc.",
                        description: "用户界面框架"
                    )
                    
                    LicenseItem(
                        name: "AppKit",
                        license: "Apple Inc.",
                        description: "macOS 应用程序框架"
                    )
                }
                .padding(20)
            }
            .navigationTitle("许可证")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        // 关闭窗口
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - 许可证项目
struct LicenseItem: View {
    let name: String
    let license: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("许可证: \(license)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - 更新日志视图
struct ChangelogView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("更新日志")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    ChangelogEntry(
                        version: "1.0.0",
                        date: "2025-01-20",
                        changes: [
                            "首次发布",
                            "支持剪切板历史记录",
                            "全局快捷键支持",
                            "智能内容识别",
                            "数据备份功能"
                        ]
                    )
                }
                .padding(20)
            }
            .navigationTitle("更新日志")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        // 关闭窗口
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - 更新日志条目
struct ChangelogEntry: View {
    let version: String
    let date: String
    let changes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("版本 \(version)")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text(date)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.accentColor)
                        Text(change)
                            .font(.system(size: 14))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
} 