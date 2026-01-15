import SwiftUI
import AppKit
import Combine

class OverlayWindow: NSWindow {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = true
        
        let hostingView = NSHostingView(rootView: OverlayView())
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView
        
        positionWindow()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .overlaySettingsChanged,
            object: nil
        )
        
        AppState.shared.$uiMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.ignoresMouseEvents = (mode != .responding)
            }
            .store(in: &cancellables)
    }
    
    func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 16
        let position = NoaSettings.shared.overlayPosition
        
        var windowWidth: CGFloat
        var windowHeight: CGFloat
        var x: CGFloat
        var y: CGFloat
        
        switch position {
        case .bottom:
            windowWidth = 500
            windowHeight = 450
            x = screenFrame.midX - (windowWidth / 2)
            y = screenFrame.minY + margin
            
        case .top:
            windowWidth = 500
            windowHeight = 450
            x = screenFrame.midX - (windowWidth / 2)
            y = screenFrame.maxY - windowHeight - margin
            
        case .left:
            windowWidth = 500
            windowHeight = 400
            x = screenFrame.minX + margin
            y = screenFrame.midY - (windowHeight / 2)
            
        case .right:
            windowWidth = 500
            windowHeight = 400
            x = screenFrame.maxX - windowWidth - margin
            y = screenFrame.midY - (windowHeight / 2)
        }
        
        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    @objc private func screenDidChange() {
        positionWindow()
    }
    
    @objc private func settingsDidChange() {
        positionWindow()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
