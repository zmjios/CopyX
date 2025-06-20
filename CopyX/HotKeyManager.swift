import Foundation
import AppKit
import Carbon
import SwiftUI

class HotKeyManager: NSObject, ObservableObject {
    var clipboardManager: ClipboardManager?
    private var historyWindow: NSWindow?
    private var clickOutsideMonitor: Any?
    
    // 快捷键设置
    @AppStorage("hotKeyEnabled") var hotKeyEnabled: Bool = true
    @AppStorage("hotKeyModifiers") var hotKeyModifiers: Int = cmdKey | shiftKey
    @AppStorage("hotKeyCode") var hotKeyCode: Int = kVK_ANSI_V
    
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeySignature = FourCharCode("CpyX".fourCharCodeValue)
    private let hotKeyID: UInt32 = 1
    
    @Published var isHistoryWindowVisible: Bool = false
    
    override init() {
        super.init()
        registerHotKeys()
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
        
        let currentFrame = window.frame
        let hiddenFrame = NSRect(
            x: currentFrame.minX,
            y: currentFrame.minY - currentFrame.height,
            width: currentFrame.width,
            height: currentFrame.height
        )
        
        // 添加消失动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.55, 0.06, 0.68, 0.19)
            window.animator().setFrame(hiddenFrame, display: true)
        }, completionHandler: {
            window.close()
            self.historyWindow = nil
            self.isHistoryWindowVisible = false
        })
        
        // 移除点击外部监听器
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
    
    private func createHistoryWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowWidth = screenFrame.width
        let windowHeight: CGFloat = 350 // 增加高度，给更多展示空间
        
        // 窗口占满全屏宽度，显示在底部
        let windowRect = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: windowWidth,
            height: windowHeight
        )
        
        // 创建窗口，初始位置在屏幕下方（隐藏）
        let hiddenRect = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY - windowHeight,
            width: windowWidth,
            height: windowHeight
        )
        
        let window = NSWindow(
            contentRect: hiddenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = true  // 重新启用阴影
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 创建内容视图，包含动画状态
        let contentView = ClipboardHistoryView(onClose: { [weak self] in
            self?.hideClipboardHistory()
        })
        .environmentObject(clipboardManager!)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        
        historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 添加弹出动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.46, 0.45, 0.94)
            window.animator().setFrame(windowRect, display: true)
        })
        
        // 添加点击外部区域关闭窗口的监听
        setupClickOutsideToClose()
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
    }
}

extension HotKeyManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isHistoryWindowVisible = false
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