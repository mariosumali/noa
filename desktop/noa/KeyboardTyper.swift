import Foundation
import AppKit

/// Copies text to clipboard for easy pasting
class KeyboardTyper {
    
    /// Copies the text to clipboard (user presses Cmd+V to paste)
    static func typeText(_ text: String) {
        print("KeyboardTyper: Copying '\(text)' to clipboard")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("KeyboardTyper: ✅ Copied to clipboard - press Cmd+V to paste")
    }
    
    /// Checks if the transcription is a "write/transcribe" command
    static func isWriteCommand(_ text: String) -> Bool {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let writeKeywords = [
            "transcribe",
            "write",
            "type",
            "dictate",
            "write this",
            "type this",
            "transcribe this"
        ]
        
        for keyword in writeKeywords {
            if lowercased.hasPrefix(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Extracts the text to type from a write command
    static func extractTextToType(_ text: String) -> String {
        let lowercased = text.lowercased()
        var result = text
        
        let prefixes = [
            "transcribe this:",
            "transcribe this",
            "transcribe:",
            "transcribe",
            "write this:",
            "write this",
            "write:",
            "write",
            "type this:",
            "type this",
            "type:",
            "type",
            "dictate this:",
            "dictate this",
            "dictate:",
            "dictate"
        ]
        
        for prefix in prefixes {
            if lowercased.hasPrefix(prefix) {
                result = String(text.dropFirst(prefix.count))
                break
            }
        }
        
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.hasPrefix(":") || result.hasPrefix(",") {
            result = String(result.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        
        return result
    }
}
