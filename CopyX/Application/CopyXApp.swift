import SwiftUI
import AppKit

@main
struct CopyXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var hotKeyManager = HotKeyManager()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        // 由于我们是状态栏应用，不需要主窗口
        // 使用一个隐藏的窗口来保持应用运行
            WindowGroup {
                EmptyView()
                    .environmentObject(clipboardManager)
                    .environmentObject(hotKeyManager)
                    .environmentObject(localizationManager)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onAppear {
                        // 请求通知权限
                        ClipboardManager.requestNotificationPermission()

                        // 将 managers 传递给需要它们的 AppKit 部分
                        appDelegate.clipboardManager = clipboardManager
                        appDelegate.hotKeyManager = hotKeyManager
                        appDelegate.localizationManager = localizationManager
                        
                        hotKeyManager.clipboardManager = clipboardManager
                        hotKeyManager.localizationManager = localizationManager
                        hotKeyManager.appDelegate = appDelegate
                        
                        // 启动服务
                        clipboardManager.startMonitoring()
                        hotKeyManager.registerHotKeys()

                        // 设置UI
                        DispatchQueue.main.async {
                            appDelegate.setupStatusBar()
                        }
                    }
            }
            .windowStyle(HiddenTitleBarWindowStyle())
            .windowResizability(.contentSize)
        
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var clipboardManager: ClipboardManager?
    var hotKeyManager: HotKeyManager?
    var localizationManager: LocalizationManager?
    var settingsWindow: NSWindow?
    private var menu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 应用启动完成，正在设置状态栏图标...")
        
        // 检查是否隐藏Dock图标（默认为true）
        let hideInDock = UserDefaults.standard.object(forKey: "hideInDock") as? Bool ?? true
        NSApp.setActivationPolicy(hideInDock ? .accessory : .regular)
        
        // 立即设置状态栏图标
        setupStatusBar()
        
        // 延迟再次确认状态栏设置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.statusBarItem == nil || self.statusBarItem?.button == nil {
                print("🔄 状态栏图标未正确设置，重新设置...")
                self.setupStatusBar()
            } else {
                print("✅ 状态栏图标设置确认成功")
            }
        }
        
        // 确保ClipboardManager和HotKeyManager已经初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let clipboardManager = self.clipboardManager,
               let hotKeyManager = self.hotKeyManager {
                print("📋 开始启动剪切板监控...")
                clipboardManager.startMonitoring()
                
                hotKeyManager.clipboardManager = clipboardManager
                hotKeyManager.registerHotKeys()
                print("✅ 剪切板监控和快捷键已启动")
            }
        }
        
        // 不设置默认菜单，通过按钮点击事件来控制
        // statusBarItem?.menu = nil
        
        // 创建状态栏菜单
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "settings".localized, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "about".localized, action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        self.menu = menu
        print("✅ 状态栏菜单创建完成")
    }
    
    func setupStatusBar() {
        print("🔧 setupStatusBar() 被调用")
        
        // 如果已经存在，先移除
        if statusBarItem != nil {
            NSStatusBar.system.removeStatusItem(statusBarItem!)
            statusBarItem = nil
            print("🗑️ 移除了旧的状态栏项目")
        }
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("✅ 创建了statusBarItem: \(statusBarItem != nil)")
        
        if let button = statusBarItem?.button {
            // 设置图标
            if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyX") {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
                print("✅ 使用系统符号图标成功")
            } else {
                // 如果系统符号不可用，使用文本作为后备
                button.title = "📋"
                print("📋 使用文本图标作为后备")
            }
            
            button.toolTip = "app_name".localized
            button.target = self
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            print("✅ 设置了按钮图标、工具提示和点击事件")
        } else {
            print("❌ 无法获取statusBarItem的button")
        }
        
        // 不设置默认菜单，通过按钮点击事件来控制
        // statusBarItem?.menu = nil
        print("✅ 状态栏菜单设置完成")
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // 右键点击显示菜单
            menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        } else {
            // 左键点击显示剪切板历史
            showClipboardHistory()
        }
    }
    
    @objc func showClipboardHistory() {
        hotKeyManager?.showClipboardHistory()
    }
    
    @objc func openSettings() {
        print("✅ [AppDelegate] openSettings() 被调用")
        if settingsWindow == nil {
            print("   -> settingsWindow 为 nil，正在创建新窗口...")
            createSettingsWindow()
        }
        
        // 确保窗口显示在前面，但不持续浮动
        print("   -> 正在显示设置窗口...")
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createSettingsWindow() {
        let windowSize = NSSize(width: 714, height: 650)  // 缩小窗口大小
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: windowSize.width,
                height: windowSize.height
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "settings".localized
        window.center()
        window.minSize = NSSize(width: 714, height: 550)  // 缩小最小尺寸
        window.maxSize = NSSize(width: 1400, height: 1000) // 适当调整最大尺寸
        
        window.isReleasedWhenClosed = false
        
        // 创建设置视图
        let settingsView = SettingsView()
            .environmentObject(clipboardManager!)
            .environmentObject(hotKeyManager!)
            .environmentObject(localizationManager!)
            .frame(width: windowSize.width, height: windowSize.height)
        
        window.contentView = NSHostingView(rootView: settingsView)
        window.delegate = self
        
        settingsWindow = window
    }
    
    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == settingsWindow {
            settingsWindow?.orderOut(nil)
            return false // 不销毁窗口，只是隐藏
        }
        return true
    }
}




