import SwiftUI
import AppKit

class OverlayWindow: NSWindow {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window configuration
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = true
        
        // Set up the SwiftUI content
        let hostingView = NSHostingView(rootView: OverlayView())
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView
        
        // Position at bottom center of screen
        positionWindow()
        
        // Listen for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 350
        let windowHeight: CGFloat = 80
        let bottomMargin: CGFloat = 24
        
        let x = screenFrame.midX - (windowWidth / 2)
        let y = screenFrame.minY + bottomMargin
        
        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    @objc private func screenDidChange() {
        positionWindow()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
