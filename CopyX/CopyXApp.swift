import SwiftUI
import AppKit

@main
struct CopyXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var hotKeyManager = HotKeyManager()
    
    var body: some Scene {
        // 由于我们是状态栏应用，不需要主窗口
        // 使用一个隐藏的窗口来保持应用运行
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .opacity(0)
                .onAppear {
                    // 将ClipboardManager和HotKeyManager实例传递给AppDelegate
                    appDelegate.clipboardManager = clipboardManager
                    appDelegate.hotKeyManager = hotKeyManager
                    
                    // 启动剪切板监控
                    clipboardManager.startMonitoring()
                    
                    // 设置HotKeyManager的clipboardManager引用
                    hotKeyManager.clipboardManager = clipboardManager
                    hotKeyManager.registerHotKeys()
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
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置状态栏图标
        setupStatusBar()
        
        // 隐藏Dock图标
        NSApp.setActivationPolicy(.accessory)
        
        // 确保ClipboardManager和HotKeyManager已经初始化
        // 由于.accessory模式下主窗口可能不会显示，我们需要手动初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let clipboardManager = self.clipboardManager,
               let hotKeyManager = self.hotKeyManager {
                print("开始启动剪切板监控...")
                clipboardManager.startMonitoring()
                
                hotKeyManager.clipboardManager = clipboardManager
                hotKeyManager.registerHotKeys()
                print("剪切板监控和快捷键已启动")
            }
        }
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyX")
            button.toolTip = "CopyX - 剪切板管理器"
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "显示剪切板历史", action: #selector(showClipboardHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "关于 CopyX", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc func showClipboardHistory() {
        hotKeyManager?.showClipboardHistory()
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            createSettingsWindow()
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createSettingsWindow() {
        let windowSize = NSSize(width: 900, height: 700)
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
        
        window.title = "CopyX - 设置"
        window.center()
        window.isReleasedWhenClosed = false
        
        // 创建设置视图
        let settingsView = SettingsView()
            .environmentObject(clipboardManager!)
            .environmentObject(hotKeyManager!)
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