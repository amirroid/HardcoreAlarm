import AppKit
import SwiftUI
import HardcoreAlarmCore

@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()
    
    public weak var mainWindow: NSWindow?
    public var overlayWindow: NSWindow?
    private var verificationWindow: NSWindow?
    
    public init() {}
    
    public func setMainWindow(_ window: NSWindow) {
        self.mainWindow = window
        window.delegate = WindowCloseInterceptor.shared
        window.isReleasedWhenClosed = false
    }
    
    // MARK: - Alarm Full-Screen Overlay Window
    public func presentAlarmOverlay(alarm: Alarm, onDismiss: @escaping @MainActor () -> Void, onSnooze: @escaping @MainActor () -> Void) {
        // Bring application to front
        NSApp.activate(ignoringOtherApps: true)
        
        if self.overlayWindow != nil {
            self.overlayWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
        guard let screen = NSScreen.main else { return }
        
        // Enable Kiosk-grade lockdown presentation options
        NSApp.presentationOptions = [
            .hideDock,
            .hideMenuBar,
            .disableAppleMenu,
            .disableProcessSwitching,
            .disableForceQuit,
            .disableSessionTermination,
            .disableHideApplication
        ]
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isReleasedWhenClosed = false
        window.level = .screenSaver // High system priority above ordinary windows
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.canHide = false
        window.hidesOnDeactivate = false
        
        let overlayView = AlarmOverlayView(
            alarm: alarm,
            onDismissCompleted: { [weak self] in
                self?.closeOverlay()
                onDismiss()
            },
            onSnooze: { [weak self] in
                self?.closeOverlay()
                onSnooze()
            }
        )
        
        window.contentView = NSHostingView(rootView: overlayView)
        window.makeKeyAndOrderFront(nil)
        self.overlayWindow = window
    }
    
    public func closeOverlay() {
        NSApp.presentationOptions = []
        self.overlayWindow?.orderOut(nil)
        self.overlayWindow = nil
    }
    
    // MARK: - Verification Modal Window
    public func presentVerificationPrompt(onConfirm: @escaping @MainActor () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        
        if self.verificationWindow != nil {
            self.verificationWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.level = .floating
        window.title = "Wake-Up Verification"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        let modalView = WakeUpVerificationModal()
        window.contentView = NSHostingView(rootView: modalView)
        window.makeKeyAndOrderFront(nil)
        self.verificationWindow = window
    }
    
    public func closeVerification() {
        self.verificationWindow?.orderOut(nil)
        self.verificationWindow = nil
    }
}

// MARK: - Window Close Interceptor
public final class WindowCloseInterceptor: NSObject, NSWindowDelegate, @unchecked Sendable {
    public static let shared = WindowCloseInterceptor()
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false // Do not destroy window; hide it so it can be instantly reopened!
    }
}

// MARK: - Window Accessor for SwiftUI
public struct WindowAccessor: NSViewRepresentable {
    public let callback: (NSWindow) -> Void
    
    public init(callback: @escaping (NSWindow) -> Void) {
        self.callback = callback
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                callback(window)
            }
        }
    }
}
