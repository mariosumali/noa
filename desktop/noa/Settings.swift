import Foundation
import SwiftUI
import Carbon

enum OverlayPosition: String, CaseIterable {
    case bottom = "bottom"
    case top = "top"
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .bottom: return "Bottom"
        case .top: return "Top"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
    
    var isVertical: Bool {
        return self == .left || self == .right
    }
}

enum HotkeyOption: String, CaseIterable {
    case option = "option"
    case control = "control"
    case command = "command"
    case shift = "shift"
    case fn = "fn"
    case rightOption = "rightOption"
    
    var displayName: String {
        switch self {
        case .option: return "⌥ Option"
        case .control: return "⌃ Control"
        case .command: return "⌘ Command"
        case .shift: return "⇧ Shift"
        case .fn: return "fn Function"
        case .rightOption: return "⌥ Right Option"
        }
    }
    
    var modifierFlag: NSEvent.ModifierFlags {
        switch self {
        case .option, .rightOption: return .option
        case .control: return .control
        case .command: return .command
        case .shift: return .shift
        case .fn: return .function
        }
    }
}

class NoaSettings: ObservableObject {
    static let shared = NoaSettings()
    
    @Published var overlayOpacity: Double {
        didSet {
            UserDefaults.standard.set(overlayOpacity, forKey: "overlayOpacity")
            NotificationCenter.default.post(name: .overlaySettingsChanged, object: nil)
        }
    }
    
    @Published var overlayPosition: OverlayPosition {
        didSet {
            UserDefaults.standard.set(overlayPosition.rawValue, forKey: "overlayPosition")
            NotificationCenter.default.post(name: .overlaySettingsChanged, object: nil)
        }
    }
    
    @Published var autoDismissSeconds: Double {
        didSet {
            UserDefaults.standard.set(autoDismissSeconds, forKey: "autoDismissSeconds")
        }
    }
    
    @Published var hotkey: HotkeyOption {
        didSet {
            UserDefaults.standard.set(hotkey.rawValue, forKey: "hotkey")
            NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
        }
    }
    
    @Published var textToSpeechEnabled: Bool {
        didSet {
            UserDefaults.standard.set(textToSpeechEnabled, forKey: "textToSpeechEnabled")
        }
    }
    
    @Published var speechRate: Float {
        didSet {
            UserDefaults.standard.set(speechRate, forKey: "speechRate")
        }
    }
    
    private init() {
        self.overlayOpacity = UserDefaults.standard.object(forKey: "overlayOpacity") as? Double ?? 0.88
        
        if let positionString = UserDefaults.standard.string(forKey: "overlayPosition"),
           let position = OverlayPosition(rawValue: positionString) {
            self.overlayPosition = position
        } else {
            self.overlayPosition = .bottom
        }
        
        self.autoDismissSeconds = UserDefaults.standard.object(forKey: "autoDismissSeconds") as? Double ?? 15
        
        if let hotkeyString = UserDefaults.standard.string(forKey: "hotkey"),
           let hk = HotkeyOption(rawValue: hotkeyString) {
            self.hotkey = hk
        } else {
            self.hotkey = .option
        }
        
        self.textToSpeechEnabled = UserDefaults.standard.bool(forKey: "textToSpeechEnabled")
        self.speechRate = UserDefaults.standard.object(forKey: "speechRate") as? Float ?? 0.5
    }
}

extension Notification.Name {
    static let overlaySettingsChanged = Notification.Name("overlaySettingsChanged")
    static let hotkeyChanged = Notification.Name("hotkeyChanged")
}
