import SwiftUI
import AppKit

class OverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        
        // Position at bottom center of screen
        positionAtBottomCenter()
        
        // Set SwiftUI content
        self.contentView = NSHostingView(rootView: OverlayView())
    }
    
    func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 200
        let bottomMargin: CGFloat = 40
        
        let x = screenFrame.midX - (windowWidth / 2)
        let y = screenFrame.minY + bottomMargin
        
        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
