import Foundation

class ScreenCapture {
    
    /// Screen capture is disabled during development
    /// Enable when you have an Apple Developer account for proper code signing
    static func captureMainScreenAsync() async -> String? {
        print("ScreenCapture: ⚠️ Disabled during development (requires Apple Developer Program)")
        print("ScreenCapture: Voice queries work normally, just without screen context")
        return nil
    }
    
    /// Check if query mentions screen/display
    /// Returns false to skip capture attempts during development
    static func shouldCaptureScreen(for query: String) -> Bool {
        // Disabled during development
        // When enabled, this detects keywords like "screen", "display", etc.
        return false
    }
}
