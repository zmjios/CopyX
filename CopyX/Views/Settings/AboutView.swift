import SwiftUI
import AppKit

// MARK: - 关于页面
struct ModernAboutView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
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
        .id(localizationManager.revision) // Force view refresh
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
                
                LocalizedText("about_subtitle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Text("\("version".localized) \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\("build".localized) \(buildNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button("about_view_changelog_button".localized) {
                    showingChangelog = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("about_check_updates_button".localized) {
                    checkForUpdates()
                }
                .buttonStyle(.bordered)
                
                Button("about_visit_website_button".localized) {
                    openWebsite()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            LocalizedText("about_main_features_title")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                FeatureCard(
                    icon: "keyboard",
                    title: "about_feature_hotkey_title".localized,
                    description: "about_feature_hotkey_desc".localized
                )
                
                FeatureCard(
                    icon: "doc.text",
                    title: "about_feature_smart_recognition_title".localized,
                    description: "about_feature_smart_recognition_desc".localized
                )
                
                FeatureCard(
                    icon: "magnifyingglass",
                    title: "about_feature_quick_search_title".localized,
                    description: "about_feature_quick_search_desc".localized
                )
                
                FeatureCard(
                    icon: "lock.shield",
                    title: "about_feature_privacy_title".localized,
                    description: "about_feature_privacy_desc".localized
                )
                
                FeatureCard(
                    icon: "externaldrive",
                    title: "about_feature_backup_title".localized,
                    description: "about_feature_backup_desc".localized
                )
                
                FeatureCard(
                    icon: "heart",
                    title: "about_feature_favorites_title".localized,
                    description: "about_feature_favorites_desc".localized
                )
            }
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocalizedText("about_system_info_title")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "about_info_os".localized, value: systemVersion)
                InfoRow(label: "about_info_model".localized, value: deviceModel)
                InfoRow(label: "about_info_processor".localized, value: processorInfo)
                InfoRow(label: "about_info_memory".localized, value: memoryInfo)
                InfoRow(label: "about_info_path".localized, value: installPath)
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocalizedText("about_developer_title")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CopyX Team")
                        .font(.system(size: 16, weight: .medium))
                    
                    LocalizedText("about_developer_desc")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button("about_send_feedback_button".localized) {
                    sendFeedback()
                }
                .buttonStyle(.borderedProminent)
                
                Button("GitHub") {
                    openGitHub()
                }
                .buttonStyle(.bordered)
                
                Button("about_support_us_button".localized) {
                    showSupport()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocalizedText("about_legal_title")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Button("about_licenses_button".localized) {
                    showingLicenses = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("about_privacy_policy_button".localized) {
                    openPrivacyPolicy()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("about_terms_of_service_button".localized) {
                    openTermsOfService()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var copyrightSection: some View {
        VStack(spacing: 8) {
            LocalizedText("about_copyright_notice")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LocalizedText("about_built_with")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LocalizedText("about_open_source_thanks")
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