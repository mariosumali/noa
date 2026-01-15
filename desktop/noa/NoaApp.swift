import SwiftUI
import AppKit

@main
struct NoaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we manage windows manually
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var loginWindow: NSWindow?
    var settingsWindow: NSWindow?
    var historyWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menu bar app only
        NSApp.setActivationPolicy(.accessory)
        
        // Set up menu bar
        setupMenuBar()
        
        // Set up overlay window
        overlayWindow = OverlayWindow()
        overlayWindow?.orderFront(nil)
        
        // Set up hotkey listener
        HotkeyManager.shared.startListening()
        
        // Check if logged in
        checkAuthStatus()
        
        print("noa started - Menu bar app ready")
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "noa")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover for menu
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 360)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView(delegate: self))
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func checkAuthStatus() {
        // Check if user is logged in via stored token
        if let _ = UserDefaults.standard.string(forKey: "noa_user_token") {
            AuthManager.shared.isLoggedIn = true
            AuthManager.shared.userEmail = UserDefaults.standard.string(forKey: "noa_user_email")
        }
    }
    
    func showLoginWindow() {
        popover?.performClose(nil)
        
        if loginWindow == nil {
            loginWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            loginWindow?.title = "Login to noa"
            loginWindow?.center()
            loginWindow?.contentView = NSHostingView(rootView: LoginView())
            loginWindow?.isReleasedWhenClosed = false
        }
        
        loginWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showSettingsWindow() {
        popover?.performClose(nil)
        
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "noa Settings"
            settingsWindow?.center()
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showHistoryWindow() {
        popover?.performClose(nil)
        
        if historyWindow == nil {
            historyWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            historyWindow?.title = "noa History"
            historyWindow?.center()
            historyWindow?.contentView = NSHostingView(rootView: HistoryView())
            historyWindow?.isReleasedWhenClosed = false
        }
        
        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func quitApp() {
        NSApp.terminate(nil)
    }
}
