import Foundation
import AppKit
import ScreenCaptureKit

class ScreenCapture {
    
    /// Captures the main screen and returns base64 encoded PNG
    static func captureMainScreen() -> String? {
        guard let screen = NSScreen.main else {
            print("No main screen found")
            return nil
        }
        
        // Use CGWindowListCreateImage for screen capture
        let screenRect = CGRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y,
            width: screen.frame.width,
            height: screen.frame.height
        )
        
        guard let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            print("Failed to capture screen")
            return nil
        }
        
        // Convert to PNG data
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("Failed to convert to PNG")
            return nil
        }
        
        // Compress if too large (max ~4MB for API)
        var finalData = pngData
        if pngData.count > 4_000_000 {
            // Convert to JPEG with compression
            if let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
                finalData = jpegData
            }
        }
        
        // Return base64 encoded
        return finalData.base64EncodedString()
    }
    
    /// Captures a specific window
    static func captureWindow(windowID: CGWindowID) -> String? {
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData.base64EncodedString()
    }
}
