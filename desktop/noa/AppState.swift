import Foundation
import Combine

enum AppMode {
    case idle
    case listening
    case processing
    case responding
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var mode: AppMode = .idle
    @Published var transcribedText: String = ""
    @Published var responseText: String = ""
    @Published var isVisible: Bool = true
    @Published var errorMessage: String?
    
    private var audioRecorder: AudioRecorder?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        audioRecorder = AudioRecorder()
    }
    
    func startListening() {
        guard mode == .idle else { return }
        
        mode = .listening
        transcribedText = ""
        responseText = ""
        errorMessage = nil
        
        audioRecorder?.startRecording()
    }
    
    func stopListening() {
        guard mode == .listening else { return }
        
        mode = .processing
        
        audioRecorder?.stopRecording { [weak self] audioData in
            guard let self = self, let audioData = audioData else {
                self?.mode = .idle
                self?.errorMessage = "Failed to record audio"
                return
            }
            
            self.processAudio(audioData)
        }
    }
    
    private func processAudio(_ audioData: Data) {
        Task { @MainActor in
            do {
                // Check if user mentioned "screen"
                let includeScreen = true // For MVP, always include screen
                
                var screenshot: String? = nil
                if includeScreen {
                    screenshot = ScreenCapture.captureMainScreen()
                }
                
                // Send to backend
                let response = try await APIClient.shared.process(
                    audioData: audioData,
                    screenshot: screenshot
                )
                
                self.transcribedText = response.transcribedText
                self.responseText = response.response
                self.mode = .responding
                
                // Auto-hide after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if self.mode == .responding {
                        self.mode = .idle
                    }
                }
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.mode = .idle
            }
        }
    }
    
    func reset() {
        mode = .idle
        transcribedText = ""
        responseText = ""
        errorMessage = nil
    }
}
