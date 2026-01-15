import Foundation
import AppKit
import ScreenCaptureKit

class ScreenCapture {
    
    /// Async screen capture using ScreenCaptureKit
    @available(macOS 14.0, *)
    static func captureWithScreenCaptureKit() async -> String? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else {
                print("ScreenCapture: No display found")
                return nil
            }
            
            let excludedWindows = content.windows.filter { window in
                window.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            
            let config = SCStreamConfiguration()
            config.width = min(1920, Int(display.width))
            config.height = min(1080, Int(display.height))
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = true
            
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            print("ScreenCapture: ✅ Captured \(config.width)x\(config.height)")
            
            let bitmapRep = NSBitmapImageRep(cgImage: image)
            guard let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else {
                print("ScreenCapture: Failed to convert to JPEG")
                return nil
            }
            
            print("ScreenCapture: Image size: \(imageData.count / 1024) KB")
            return imageData.base64EncodedString()
            
        } catch {
            print("ScreenCapture: ❌ \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fallback for older macOS versions using CGWindowListCreateImage
    static func captureWithCGWindowList() -> String? {
        guard let displayID = CGMainDisplayID() as CGDirectDisplayID?,
              let image = CGDisplayCreateImage(displayID) else {
            print("ScreenCapture: Failed to capture with CGDisplayCreateImage")
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else {
            print("ScreenCapture: Failed to convert to JPEG")
            return nil
        }
        
        print("ScreenCapture: ✅ Captured with fallback method (\(imageData.count / 1024) KB)")
        return imageData.base64EncodedString()
    }
    
    /// Main capture method - uses best available API
    static func captureMainScreenAsync() async -> String? {
        if #available(macOS 14.0, *) {
            return await captureWithScreenCaptureKit()
        } else {
            return captureWithCGWindowList()
        }
    }
    
    /// Check if query mentions screen/display
    static func shouldCaptureScreen(for query: String) -> Bool {
        let screenKeywords = [
            "screen", "display", "monitor", "showing", "see on",
            "looking at", "what's this", "what is this", "explain this",
            "read this", "what does this say", "summarize this",
            "on my screen", "on screen", "currently showing",
            "what am i looking at", "describe this", "help me with this"
        ]
        
        let lowercased = query.lowercased()
        return screenKeywords.contains { lowercased.contains($0) }
    }
}
