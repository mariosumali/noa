import Foundation
import AppKit
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isKeyPressed = false
    
    private init() {
        // Listen for hotkey changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyDidChange),
            name: .hotkeyChanged,
            object: nil
        )
    }
    
    func startListening() {
        stopListening() // Clear any existing monitors
        
        let hotkey = NoaSettings.shared.hotkey
        print("Hotkey listener started - Hold \(hotkey.displayName) to speak")
        
        // Monitor for modifier key changes
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Also monitor local events
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }
    
    func stopListening() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        isKeyPressed = false
    }
    
    @objc private func hotkeyDidChange() {
        // Restart listening with new hotkey
        if flagsMonitor != nil {
            startListening()
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let hotkey = NoaSettings.shared.hotkey
        let keyPressed = event.modifierFlags.contains(hotkey.modifierFlag)
        
        if keyPressed && !isKeyPressed {
            // Key pressed down
            isKeyPressed = true
            onKeyDown()
        } else if !keyPressed && isKeyPressed {
            // Key released
            isKeyPressed = false
            onKeyUp()
        }
    }
    
    private func onKeyDown() {
        DispatchQueue.main.async {
            AppState.shared.startListening()
        }
    }
    
    private func onKeyUp() {
        DispatchQueue.main.async {
            AppState.shared.stopListening()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopListening()
    }
}
