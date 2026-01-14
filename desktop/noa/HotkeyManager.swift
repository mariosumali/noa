import Foundation
import AppKit
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventMonitor: Any?
    private var flagsMonitor: Any?
    private var isOptionPressed = false
    
    private init() {}
    
    func startListening() {
        // Monitor for modifier key changes (Option key)
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Also monitor local events
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        print("Hotkey listener started - Hold Option (⌥) to speak")
    }
    
    func stopListening() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)
        
        if optionPressed && !isOptionPressed {
            // Option key pressed down
            isOptionPressed = true
            onKeyDown()
        } else if !optionPressed && isOptionPressed {
            // Option key released
            isOptionPressed = false
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
}
