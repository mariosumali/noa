import Foundation
import SwiftUI
import Combine

enum UIMode {
    case idle
    case listening
    case processing
    case responding
    case typing  // New mode for write/transcribe
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var uiMode: UIMode = .idle
    @Published var transcribedText: String = ""
    @Published var aiResponse: String = ""
    @Published var userId: String?
    @Published var deviceId: String = ""
    @Published var showLoginWindow: Bool = false
    @Published var showSettingsWindow: Bool = false
    @Published var showHistoryWindow: Bool = false
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 0.1, count: 16)
    @Published var isRecordingAudio: Bool = false
    @Published var isProcessingAPI: Bool = false
    @Published var apiError: String?
    @Published var toolsUsed: [String] = []

    private var audioRecorder = AudioRecorder()
    private var speechRecognizer = SpeechRecognizer()
    private var waveformTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load device ID from UserDefaults or generate new one
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            self.deviceId = APIClient.shared.getDeviceId()
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
        }
    }

    func startListening() {
        uiMode = .listening
        transcribedText = ""
        aiResponse = ""
        toolsUsed = []
        isRecordingAudio = true
        startWaveformAnimation()
        
        // Check which transcription mode to use
        if NoaSettings.shared.transcriptionMode == .appleDictation {
            // Subscribe to live transcript updates
            speechRecognizer.$transcript
                .receive(on: DispatchQueue.main)
                .sink { [weak self] text in
                    self?.transcribedText = text
                }
                .store(in: &cancellables)
            
            speechRecognizer.startTranscribing()
        } else {
            audioRecorder.startRecording()
        }
    }

    func stopListening() {
        uiMode = .processing
        isRecordingAudio = false
        stopWaveformAnimation()
        cancellables.removeAll()
        
        // Check which transcription mode was used
        if NoaSettings.shared.transcriptionMode == .appleDictation {
            // Apple Dictation mode - get transcript from SpeechRecognizer
            speechRecognizer.stopTranscribing { [weak self] transcription in
                guard let self = self else { return }
                
                if transcription.isEmpty {
                    DispatchQueue.main.async {
                        self.aiResponse = "Error: Could not transcribe audio."
                        self.uiMode = .responding
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                    self.isProcessingAPI = true
                    self.apiError = nil
                }
                
                // Process the transcription (skip cloud transcription)
                self.processTranscription(transcription)
            }
        } else {
            // Whisper mode - use AudioRecorder + API transcription
            audioRecorder.stopRecording { [weak self] audioData in
                guard let self = self else { return }
                
                guard let audioData = audioData else {
                    DispatchQueue.main.async {
                        self.aiResponse = "Error: Could not record audio."
                        self.uiMode = .responding
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.isProcessingAPI = true
                    self.apiError = nil
                }

                Task {
                    do {
                        let transcription = try await APIClient.shared.transcribeAudio(audioData)
                        await MainActor.run {
                            self.transcribedText = transcription
                        }
                        
                        // Process the transcription
                        self.processTranscription(transcription)
                    } catch {
                        await MainActor.run {
                            self.aiResponse = "Error: \(error.localizedDescription)"
                            self.uiMode = .responding
                            self.isProcessingAPI = false
                            self.apiError = error.localizedDescription
                            print("Transcription Error: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    /// Process the transcription text - handles write commands, screen capture, and API calls
    private func processTranscription(_ transcription: String) {
        Task {
            do {
                // Check if this is a write/transcribe command
                if KeyboardTyper.isWriteCommand(transcription) {
                    let textToType = KeyboardTyper.extractTextToType(transcription)
                    print("AppState: Write mode - copying: \(textToType)")
                    
                    // Copy to clipboard
                    KeyboardTyper.typeText(textToType)
                    
                    // Auto-paste if enabled
                    var currentFeedbackMessage = "Copied! Press ⌘V to paste"
                    if NoaSettings.shared.autoPaste {
                        // Small delay to ensure clipboard is ready
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                        KeyboardTyper.pasteFromClipboard()
                        currentFeedbackMessage = "Pasted!"
                    }
                    
                    let feedbackMessage = currentFeedbackMessage // Capture as immutable let

                    // Log to history without AI processing
                    let result = try await APIClient.shared.logTranscription(text: textToType)
                    
                    await MainActor.run {
                        self.aiResponse = "\(feedbackMessage)\n\"\(textToType)\""
                        self.toolsUsed = result.toolsUsed
                        self.uiMode = .typing
                        self.isProcessingAPI = false
                    }
                    return
                }

                // Check if screen capture needed
                var screenshotBase64: String? = nil
                if ScreenCapture.shouldCaptureScreen(for: transcription) {
                    print("AppState: Screen query detected, capturing...")
                    screenshotBase64 = await ScreenCapture.captureMainScreenAsync()
                    if screenshotBase64 != nil {
                        print("AppState: ✅ Screenshot ready")
                    } else {
                        print("AppState: ⚠️ Screenshot failed")
                    }
                }

                let result = try await APIClient.shared.processText(text: transcription, screenshot: screenshotBase64)
                
                await MainActor.run {
                    self.aiResponse = result.text
                    self.toolsUsed = result.toolsUsed
                    self.uiMode = .responding
                    self.isProcessingAPI = false
                    
                    // Speak the response if TTS is enabled
                    TextToSpeech.shared.speak(result.text)
                }
            } catch {
                await MainActor.run {
                    self.aiResponse = "Error: \(error.localizedDescription)"
                    self.uiMode = .responding
                    self.isProcessingAPI = false
                    self.apiError = error.localizedDescription
                    print("API Error: \(error)")
                }
            }
        }
    }
    
    func reset() {
        uiMode = .idle
        transcribedText = ""
        aiResponse = ""
        apiError = nil
        toolsUsed = []
    }

    private func startWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.waveformAmplitudes = (0..<16).map { _ in CGFloat.random(in: 0.1...1.0) }
            }
        }
    }

    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformAmplitudes = Array(repeating: 0.1, count: 16)
    }
}
