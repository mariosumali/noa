import SwiftUI
import AppKit

@main
struct NoaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var statusItem: NSStatusItem?
    let appState = AppState.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create menu bar icon
        setupMenuBar()
        
        // Create overlay window
        setupOverlayWindow()
        
        // Start hotkey listener
        HotkeyManager.shared.startListening()
        
        // Request permissions
        requestPermissions()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "noa")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show noa", action: #selector(showOverlay), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func setupOverlayWindow() {
        overlayWindow = OverlayWindow()
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    func requestPermissions() {
        // Request microphone access
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("Microphone access granted")
            } else {
                print("Microphone access denied")
            }
        }
        
        // Request screen recording access (will prompt user)
        CGRequestScreenCaptureAccess()
    }
    
    @objc func showOverlay() {
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

import AVFoundation
