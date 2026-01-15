import Foundation
import AppKit
import ScreenCaptureKit

class ScreenCapture {
    
    /// Async screen capture - returns base64 encoded PNG
    static func captureMainScreenAsync() async -> String? {
        do {
            // Get available content
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else {
                print("ScreenCapture: No display found")
                return nil
            }
            
            // Create filter for the display (exclude our own app windows)
            let excludedWindows = content.windows.filter { window in
                window.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            
            // Configure capture
            let config = SCStreamConfiguration()
            config.width = Int(display.width)
            config.height = Int(display.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = true
            
            // Capture the image
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            print("ScreenCapture: Captured \(display.width)x\(display.height) image")
            
            // Convert CGImage to JPEG data (smaller than PNG)
            let bitmapRep = NSBitmapImageRep(cgImage: image)
            
            // Use JPEG with 70% quality for smaller size
            guard let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
                print("ScreenCapture: Failed to convert to JPEG")
                return nil
            }
            
            print("ScreenCapture: Image size: \(imageData.count / 1024) KB")
            
            // Return base64 encoded
            return imageData.base64EncodedString()
            
        } catch {
            print("ScreenCapture: Error - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Check if query mentions screen/display
    static func shouldCaptureScreen(for query: String) -> Bool {
        let screenKeywords = [
            "screen", "display", "monitor", "showing", "see on",
            "looking at", "what's this", "what is this", "explain this",
            "read this", "what does this say", "summarize this",
            "on my screen", "on screen", "currently showing"
        ]
        
        let lowercased = query.lowercased()
        return screenKeywords.contains { lowercased.contains($0) }
    }
}
