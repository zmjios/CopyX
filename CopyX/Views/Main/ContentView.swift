import SwiftUI
import AppKit

struct FirstLaunchWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyNotice = false
    @State private var showUserAgreement = false
    @State private var hasAgreed = false
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("first_launch_welcome".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("first_launch_subtitle".localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Privacy Notice
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("privacy_notice_title".localized)
                        .font(.headline)
                    Spacer()
                }
                
                Text("privacy_notice_message".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            // User Agreement
            VStack(spacing: 12) {
                HStack {
                    Toggle(isOn: $hasAgreed) {
                        Text("user_agreement_message".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
                
                Button("view_full_agreement".localized) {
                    showUserAgreement = true
                }
                .buttonStyle(.link)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("skip_for_now".localized) {
                    onComplete()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Button("get_started".localized) {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasAgreed)
            }
        }
        .padding(32)
        .frame(width: 500, height: 600)
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showPrivacyNotice) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showUserAgreement) {
            UserAgreementView()
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("privacy_policy".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(privacyPolicyContent)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("privacy_policy".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var privacyPolicyContent: String {
        """
        隐私政策

        最后更新：2024年

        1. 信息收集
        CopyX 仅在您的本地设备上存储剪贴板历史记录。我们不会收集、传输或存储您的个人数据到远程服务器。

        2. 数据使用
        - 剪贴板内容仅用于提供历史记录功能
        - 敏感信息（如密码、身份证号、银行卡号）会被自动识别并跳过
        - 所有数据仅存储在您的本地设备上

        3. 数据安全
        - 所有数据都加密存储在您的设备上
        - 没有网络传输，确保数据安全
        - 您可以随时清除所有历史记录

        4. 权限使用
        - 剪贴板访问：用于监控和管理剪贴板内容
        - 辅助功能权限：用于检测应用上下文以提供更好的体验

        5. 联系我们
        如有隐私相关问题，请联系：support@copyx.app
        """
    }
}

struct UserAgreementView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("terms_of_service".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(userAgreementContent)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("terms_of_service".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var userAgreementContent: String {
        """
        用户协议

        最后更新：2024年

        1. 接受条款
        使用 CopyX 即表示您同意遵守本协议的所有条款和条件。

        2. 软件许可
        - CopyX 授予您有限的、非独占的、不可转让的许可
        - 您可以在您拥有的设备上安装和使用本软件
        - 禁止逆向工程、反编译或反汇编

        3. 用户责任
        - 您需负责保护您的设备和数据安全
        - 不得将软件用于非法用途
        - 遵守所有适用的法律法规

        4. 免责声明
        - 软件按"现状"提供，不提供任何明示或暗示的保证
        - 我们不对因使用软件而造成的任何损失承担责任

        5. 终止
        我们保留在违反本协议时终止您使用许可的权利。

        6. 联系方式
        如有问题，请联系：support@copyx.app
        """
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

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