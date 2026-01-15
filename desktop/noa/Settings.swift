import Foundation
import SwiftUI

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
    
    private init() {
        self.overlayOpacity = UserDefaults.standard.object(forKey: "overlayOpacity") as? Double ?? 0.88
        
        if let positionString = UserDefaults.standard.string(forKey: "overlayPosition"),
           let position = OverlayPosition(rawValue: positionString) {
            self.overlayPosition = position
        } else {
            self.overlayPosition = .bottom
        }
        
        self.autoDismissSeconds = UserDefaults.standard.object(forKey: "autoDismissSeconds") as? Double ?? 15
    }
}

extension Notification.Name {
    static let overlaySettingsChanged = Notification.Name("overlaySettingsChanged")
}
