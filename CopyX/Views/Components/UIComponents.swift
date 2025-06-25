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

// MARK: - 启动动画组件
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var backgroundGradientOffset: CGFloat = -1.0
    @State private var loadingProgress: Double = 0.0
    @State private var showProgress: Bool = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // 动态渐变背景
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4),
                    Color.orange.opacity(0.3)
                ],
                startPoint: UnitPoint(x: backgroundGradientOffset, y: 0),
                endPoint: UnitPoint(x: backgroundGradientOffset + 1, y: 1)
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: backgroundGradientOffset)
            
            // 背景粒子效果
            ParticleSystem()
            
            VStack(spacing: 40) {
                // Logo区域
                VStack(spacing: 20) {
                    ZStack {
                        // 外圈光晕
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(logoScale * 1.2)
                            .opacity(logoOpacity * 0.6)
                        
                        // 主Logo背景
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        // Logo图标
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    // 应用标题
                    VStack(spacing: 8) {
                        Text("CopyX")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .opacity(titleOpacity)
                        
                        Text("强大的剪贴板管理工具")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(titleOpacity * 0.8)
                    }
                }
                
                // 加载进度
                if showProgress {
                    VStack(spacing: 16) {
                        // 进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 200, height: 6)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 200 * loadingProgress, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                        }
                        
                        Text("正在启动...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 背景渐变动画
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            backgroundGradientOffset = 1.0
        }
        
        // Logo缩放和透明度动画
        withAnimation(.interpolatingSpring(stiffness: 100, damping: 10, initialVelocity: 0).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // 标题淡入动画
        withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
            titleOpacity = 1.0
        }
        
        // 显示进度条
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showProgress = true
            }
            
            // 模拟加载进度
            simulateLoading()
        }
    }
    
    private func simulateLoading() {
        let steps = [0.2, 0.4, 0.6, 0.8, 1.0]
        let delays = [0.3, 0.5, 0.4, 0.6, 0.4]
        
        for (index, progress) in steps.enumerated() {
            let totalDelay = delays.prefix(index + 1).reduce(0, +)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingProgress = progress
                }
                
                // 完成加载
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onComplete()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 粒子系统组件
struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(particle.opacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(.linear(duration: particle.lifetime), value: particle.position)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let newParticle = Particle()
            particles.append(newParticle)
            
            // 动画粒子
            withAnimation(.linear(duration: newParticle.lifetime)) {
                particles[particles.count - 1].position = CGPoint(
                    x: newParticle.position.x + CGFloat.random(in: -100...100),
                    y: newParticle.position.y - 400
                )
                particles[particles.count - 1].opacity = 0
            }
            
            // 清理过期粒子
            DispatchQueue.main.asyncAfter(deadline: .now() + newParticle.lifetime) {
                particles.removeAll { $0.id == newParticle.id }
            }
        }
    }
}

// MARK: - 粒子数据结构
struct Particle {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    let lifetime: Double
    
    init() {
        self.position = CGPoint(
            x: CGFloat.random(in: 0...400),
            y: CGFloat.random(in: 400...600)
        )
        self.size = CGFloat.random(in: 2...8)
        self.opacity = Double.random(in: 0.3...0.8)
        self.lifetime = Double.random(in: 3...6)
    }
} 