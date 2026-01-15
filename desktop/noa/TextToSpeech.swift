import Foundation
import AVFoundation

@MainActor
class TextToSpeech: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TextToSpeech()
    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking = false
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// Speak the given text if TTS is enabled
    func speak(_ text: String) {
        guard NoaSettings.shared.textToSpeechEnabled else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Clean up the text for speech
        let cleanedText = cleanTextForSpeech(text)
        
        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.rate = NoaSettings.shared.speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Add a small pause at the beginning to prevent cutoff
        utterance.preUtteranceDelay = 0.3
        
        // Use a nice voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        isSpeaking = true
        synthesizer.speak(utterance)
        print("TTS: Speaking response...")
    }
    
    /// Stop any current speech
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    /// Clean up text for better speech output
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text
        
        // Remove markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        
        // Remove URLs
        let urlPattern = "https?://[\\S]+"
        if let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "link")
        }
        
        // Limit length for very long responses
        if cleaned.count > 1000 {
            cleaned = String(cleaned.prefix(1000)) + "... and more."
        }
        
        return cleaned
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("TTS: Finished speaking")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        print("TTS: Cancelled")
    }
}
