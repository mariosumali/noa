import Foundation
import SwiftUI
import Combine

enum UIMode {
    case idle
    case listening
    case processing
    case responding
}

class AppState: ObservableObject {
    @Published var uiMode: UIMode = .idle
    @Published var transcribedText: String = ""
    @Published var aiResponse: String = ""
    @Published var userId: String?
    @Published var deviceId: String
    @Published var showLoginWindow: Bool = false
    @Published var showSettingsWindow: Bool = false
    @Published var showHistoryWindow: Bool = false
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 0.1, count: 16)
    @Published var isRecordingAudio: Bool = false
    @Published var isProcessingAPI: Bool = false
    @Published var apiError: String?

    private var audioRecorder = AudioRecorder()
    private var apiClient: APIClient { APIClient.shared }
    private var waveformTimer: Timer?

    init() {
        // Use APIClient's device ID
        self.deviceId = apiClient.getDeviceId()
        
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
        }
    }

    func startListening() {
        uiMode = .listening
        transcribedText = ""
        aiResponse = ""
        isRecordingAudio = true
        startWaveformAnimation()
        audioRecorder.startRecording()
    }

    func stopListening() {
        uiMode = .processing
        isRecordingAudio = false
        stopWaveformAnimation()
        
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
                    let transcription = try await self.apiClient.transcribeAudio( audioData)
                    await MainActor.run {
                        self.transcribedText = transcription
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

                    let response = try await self.apiClient.processPrompt(
                        userId: self.userId,
                        deviceId: self.deviceId,
                        text: transcription,
                        screenshot: screenshotBase64
                    )
                    
                    await MainActor.run {
                        self.aiResponse = response
                        self.uiMode = .responding
                        self.isProcessingAPI = false
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
    }
    
    func reset() {
        uiMode = .idle
        transcribedText = ""
        aiResponse = ""
        apiError = nil
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
