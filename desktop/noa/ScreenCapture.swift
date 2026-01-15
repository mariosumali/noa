import Foundation

class ScreenCapture {
    /// Disabled for development - returns nil
    static func captureMainScreen() -> String? {
        // Screen capture disabled to avoid permission prompts during development
        // Re-enable when ready for production with proper code signing
        return nil
    }
}
