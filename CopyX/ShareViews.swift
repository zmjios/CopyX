import SwiftUI
import AppKit

// MARK: - 分享模态框
struct ShareModal: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
            
            // 分享选项
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("share_to_title".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 分享选项网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    // 系统分享
                    ShareModalOption(
                        title: "share_system".localized,
                        icon: "square.and.arrow.up.circle.fill",
                        color: .blue
                    ) {
                        ShareManager.shared.shareToSystem(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    // 微信分享
                    ShareModalOption(
                        title: "share_wechat".localized,
                        icon: "message.fill",
                        color: .green
                    ) {
                        ShareManager.shared.shareToWeChat(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    // X (Twitter) 分享
                    ShareModalOption(
                        title: "share_twitter".localized,
                        icon: "bubble.left.and.bubble.right.fill",
                        color: .cyan
                    ) {
                        ShareManager.shared.shareToTwitter(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    // 微博分享
                    ShareModalOption(
                        title: "share_weibo".localized,
                        icon: "globe.asia.australia.fill",
                        color: .orange
                    ) {
                        ShareManager.shared.shareToWeibo(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    // QQ分享
                    ShareModalOption(
                        title: "share_qq".localized,
                        icon: "person.2.fill",
                        color: .purple
                    ) {
                        ShareManager.shared.shareToQQ(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                    
                    // 复制内容
                    ShareModalOption(
                        title: "share_copy_content".localized,
                        icon: "doc.on.doc.fill",
                        color: .gray
                    ) {
                        ShareManager.shared.copyToClipboard(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                            isPresented = false
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .frame(width: 300, height: 240)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
            )
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
    }
}

// MARK: - 分享模态选项
struct ShareModalOption: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 分享菜单覆盖层
struct ShareMenuOverlay: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
            
            // 分享菜单
            VStack(spacing: 8) {
                // 系统分享
                ShareOptionButton(
                    title: "share_system".localized,
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    ShareManager.shared.shareToSystem(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                
                // 微信分享
                ShareOptionButton(
                    title: "share_wechat".localized,
                    icon: "message",
                    color: .green
                ) {
                    ShareManager.shared.shareToWeChat(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                
                // X (Twitter) 分享
                ShareOptionButton(
                    title: "share_twitter".localized,
                    icon: "bubble.left.and.bubble.right",
                    color: .cyan
                ) {
                    ShareManager.shared.shareToTwitter(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                
                // 微博分享
                ShareOptionButton(
                    title: "share_weibo".localized,
                    icon: "globe.asia.australia",
                    color: .orange
                ) {
                    ShareManager.shared.shareToWeibo(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                
                // QQ分享
                ShareOptionButton(
                    title: "share_qq".localized,
                    icon: "person.2",
                    color: .purple
                ) {
                    ShareManager.shared.shareToQQ(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
                
                // 复制内容
                ShareOptionButton(
                    title: "share_copy_content".localized,
                    icon: "doc.on.doc",
                    color: .gray
                ) {
                    ShareManager.shared.copyToClipboard(item)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        isPresented = false
                    }
                }
            }
            .padding(10)
            .frame(width: 180, height: 240)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            .allowsHitTesting(true)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - 分享选项按钮
struct ShareOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
    }
} 