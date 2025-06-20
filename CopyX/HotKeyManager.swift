import Foundation
import AppKit
import Carbon
import SwiftUI

// MARK: - 显示模式枚举
enum WindowDisplayMode: String, CaseIterable {
    case bottom = "bottom"
    case center = "center"
    
    var windowLevel: NSWindow.Level {
        switch self {
        case .bottom: return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        case .center: return .floating
        }
    }
}

class HotKeyManager: NSObject, ObservableObject {
    var clipboardManager: ClipboardManager?
    private var historyWindow: NSWindow?
    private var clickOutsideMonitor: Any?
    
    // 快捷键设置
    @AppStorage("hotKeyEnabled") var hotKeyEnabled: Bool = true
    @AppStorage("hotKeyModifiers") var hotKeyModifiers: Int = cmdKey | shiftKey
    @AppStorage("hotKeyCode") var hotKeyCode: Int = kVK_ANSI_V
    @AppStorage("displayMode") var displayMode: String = WindowDisplayMode.bottom.rawValue
    
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeySignature = FourCharCode("CpyX".fourCharCodeValue)
    private let hotKeyID: UInt32 = 1
    
    @Published var isHistoryWindowVisible: Bool = false
    
    override init() {
        super.init()
        // 从UserDefaults读取显示模式
        displayMode = UserDefaults.standard.string(forKey: "displayMode") ?? "bottom"
        registerHotKeys()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayModeChange(_:)),
            name: NSNotification.Name("SwitchDisplayMode"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloseRequest),
            name: NSNotification.Name("CloseClipboardHistory"),
            object: nil
        )
    }
    
    @objc private func handleDisplayModeChange(_ notification: Notification) {
        if let modeString = notification.userInfo?["mode"] as? String {
            displayMode = modeString
            // 保存到UserDefaults
            UserDefaults.standard.set(modeString, forKey: "displayMode")
            // 发送状态变化通知
            NotificationCenter.default.post(
                name: NSNotification.Name("DisplayModeChanged"),
                object: nil,
                userInfo: ["mode": modeString]
            )
            // 如果窗口正在显示，重新创建以应用新的显示模式
            if isHistoryWindowVisible {
                hideClipboardHistory()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showClipboardHistory()
                }
            }
        }
    }
    
    @objc private func handleCloseRequest() {
        hideClipboardHistory()
    }
    
    func registerHotKeys() {
        unregisterHotKeys()
        
        guard hotKeyEnabled else { return }
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let hotKeyPtr = UnsafeMutablePointer<EventHotKeyRef?>.allocate(capacity: 1)
        
        let status = RegisterEventHotKey(
            UInt32(hotKeyCode),
            UInt32(hotKeyModifiers),
            EventHotKeyID(signature: hotKeySignature, id: hotKeyID),
            GetApplicationEventTarget(),
            0,
            hotKeyPtr
        )
        
        if status == noErr {
            hotKeyRef = hotKeyPtr.pointee
            NSLog("热键注册成功")
        } else {
            NSLog("热键注册失败，错误代码: \(status)")
        }
        
        hotKeyPtr.deallocate()
        
        // 安装事件处理器
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
                return manager.handleHotKeyEvent(nextHandler, theEvent)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }
    
    func unregisterHotKeys() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    private func handleHotKeyEvent(_ nextHandler: EventHandlerCallRef?, _ theEvent: EventRef?) -> OSStatus {
        showClipboardHistory()
        return noErr
    }
    
    func showClipboardHistory() {
        if isHistoryWindowVisible {
            hideClipboardHistory()
            return
        }
        
        createHistoryWindow()
        isHistoryWindowVisible = true
    }
    
    func hideClipboardHistory() {
        guard let window = historyWindow else { return }
        
        let currentDisplayMode = WindowDisplayMode(rawValue: displayMode) ?? .bottom
        animateWindowDisappearance(window: window, mode: currentDisplayMode)
        
        // 移除点击外部监听器
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
    
    private func animateWindowDisappearance(window: NSWindow, mode: WindowDisplayMode) {
        let currentFrame = window.frame
        
        switch mode {
        case .bottom:
            // 底部模式：向下滑出
            let hiddenFrame = NSRect(
                x: currentFrame.minX,
                y: currentFrame.minY - currentFrame.height,
                width: currentFrame.width,
                height: currentFrame.height
            )
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.55, 0.06, 0.68, 0.19)
                window.animator().setFrame(hiddenFrame, display: true)
            }, completionHandler: {
                window.close()
                self.historyWindow = nil
                self.isHistoryWindowVisible = false
            })
            
        case .center:
            // 居中模式：缩放消失
            let hiddenFrame = NSRect(
                x: currentFrame.midX,
                y: currentFrame.midY,
                width: 0,
                height: 0
            )
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.55, 0.06, 0.68, 0.19)
                window.animator().setFrame(hiddenFrame, display: true)
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.close()
                self.historyWindow = nil
                self.isHistoryWindowVisible = false
            })
        }
    }
    
    private func createHistoryWindow() {
        guard let screen = NSScreen.main else { 
            NSLog("无法获取主屏幕信息")
            return 
        }
        
        let currentDisplayMode = WindowDisplayMode(rawValue: displayMode) ?? .bottom
        let (windowRect, hiddenRect) = calculateWindowFrames(for: currentDisplayMode, screen: screen)
        
        let window = NSWindow(
            contentRect: hiddenRect,
            styleMask: currentDisplayMode == .center ? [.titled, .closable, .resizable] : [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        setupWindowProperties(window, for: currentDisplayMode)
        
        // 创建内容视图
        let contentView = ClipboardHistoryView()
            .environmentObject(clipboardManager!)
            .environmentObject(self)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        
        historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 添加出现动画
        animateWindowAppearance(window: window, targetFrame: windowRect, mode: currentDisplayMode)
        
        // 添加点击外部区域关闭窗口的监听
        setupClickOutsideToClose()
    }
    
    private func calculateWindowFrames(for mode: WindowDisplayMode, screen: NSScreen) -> (target: NSRect, hidden: NSRect) {
        let screenFrame = screen.frame
        
        switch mode {
        case .bottom:
            let windowWidth = screenFrame.width
            let windowHeight: CGFloat = 380 // 增加高度以容纳底部工具栏
            
            let targetRect = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: windowWidth,
                height: windowHeight
            )
            
            let hiddenRect = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY - windowHeight,
                width: windowWidth,
                height: windowHeight
            )
            
            return (targetRect, hiddenRect)
            
        case .center:
            // 从UserDefaults读取保存的窗口大小，如果没有则使用默认值
            let windowWidth: CGFloat = UserDefaults.standard.object(forKey: "centerWindowWidth") as? CGFloat ?? 700
            let windowHeight: CGFloat = UserDefaults.standard.object(forKey: "centerWindowHeight") as? CGFloat ?? 600
            
            let targetRect = NSRect(
                x: screenFrame.midX - windowWidth / 2,
                y: screenFrame.midY - windowHeight / 2,
                width: windowWidth,
                height: windowHeight
            )
            
            // 居中模式的隐藏位置是缩放到0
            let hiddenRect = NSRect(
                x: screenFrame.midX,
                y: screenFrame.midY,
                width: 0,
                height: 0
            )
            
            return (targetRect, hiddenRect)
        }
    }
    
    private func setupWindowProperties(_ window: NSWindow, for mode: WindowDisplayMode) {
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        switch mode {
        case .bottom:
            // 底部模式：遮盖dock栏，使用更高的窗口级别
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
        case .center:
            // 居中模式：普通浮动窗口
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]
            window.title = "CopyX - 剪切板历史"
            // 设置窗口大小限制
            window.minSize = NSSize(width: 500, height: 400)
            window.maxSize = NSSize(width: 1200, height: 800)
        }
    }
    
    private func animateWindowAppearance(window: NSWindow, targetFrame: NSRect, mode: WindowDisplayMode) {
        switch mode {
        case .bottom:
            // 底部模式：从下方滑入
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.46, 0.45, 0.94)
                window.animator().setFrame(targetFrame, display: true)
            })
            
        case .center:
            // 居中模式：缩放出现
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
                window.animator().setFrame(targetFrame, display: true)
            })
        }
    }
    
    private func setupClickOutsideToClose() {
        // 移除之前的监听器
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // 使用全局事件监听器来检测点击
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let window = self.historyWindow,
                  self.isHistoryWindowVisible else { return }
            
            // 获取全局鼠标位置
            let globalLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            
            // 检查点击是否在窗口外部
            if !windowFrame.contains(globalLocation) {
                DispatchQueue.main.async {
                    self.hideClipboardHistory()
                }
            }
        }
    }
    
    func updateHotKey(modifiers: Int, keyCode: Int) {
        hotKeyModifiers = modifiers
        hotKeyCode = keyCode
        registerHotKeys()
    }
    
    func enableHotKey(_ enabled: Bool) {
        hotKeyEnabled = enabled
        if enabled {
            registerHotKeys()
        } else {
            unregisterHotKeys()
        }
    }
    
    deinit {
        unregisterHotKeys()
        NotificationCenter.default.removeObserver(self)
    }
}

extension HotKeyManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isHistoryWindowVisible = false
    }
    
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == historyWindow,
              displayMode == "center" else { return }
        
        // 保存居中模式的窗口大小
        let frame = window.frame
        UserDefaults.standard.set(frame.width, forKey: "centerWindowWidth")
        UserDefaults.standard.set(frame.height, forKey: "centerWindowHeight")
    }
}

// MARK: - Helper Extensions
extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = result << 8 + FourCharCode(char)
        }
        return result
    }
}

// MARK: - Key Code Utilities
struct KeyCodeUtils {
    static let keyCodeMap: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
        kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8",
        kVK_ANSI_9: "9", kVK_ANSI_0: "0",
        kVK_Space: "空格", kVK_Return: "回车", kVK_Tab: "Tab", kVK_Escape: "Esc"
    ]
    
    static func keyName(for keyCode: Int) -> String {
        return keyCodeMap[keyCode] ?? "未知键"
    }
    
    static func modifierString(for modifiers: Int) -> String {
        var components: [String] = []
        
        if modifiers & cmdKey != 0 {
            components.append("⌘")
        }
        if modifiers & optionKey != 0 {
            components.append("⌥")
        }
        if modifiers & controlKey != 0 {
            components.append("⌃")
        }
        if modifiers & shiftKey != 0 {
            components.append("⇧")
        }
        
        return components.joined()
    }
} 