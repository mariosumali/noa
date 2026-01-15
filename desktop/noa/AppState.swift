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
        print("AppState initialized")
    }
    
    func startListening() {
        guard mode == .idle else { 
            print("AppState: Can't start listening - mode is \(mode)")
            return 
        }
        
        print("AppState: Starting to listen...")
        mode = .listening
        transcribedText = ""
        responseText = ""
        errorMessage = nil
        
        audioRecorder?.startRecording()
    }
    
    func stopListening() {
        guard mode == .listening else { 
            print("AppState: Can't stop listening - mode is \(mode)")
            return 
        }
        
        print("AppState: Stopping listening, starting processing...")
        mode = .processing
        
        audioRecorder?.stopRecording { [weak self] audioData in
            guard let self = self else { return }
            
            if let audioData = audioData {
                print("AppState: Got audio data: \(audioData.count) bytes")
                self.processAudio(audioData)
            } else {
                print("AppState: No audio data received")
                DispatchQueue.main.async {
                    self.mode = .idle
                    self.errorMessage = "Failed to record audio"
                }
            }
        }
    }
    
    private func processAudio(_ audioData: Data) {
        Task {
            do {
                print("AppState: Calling API...")
                
                // Skip screenshot for now - it was causing deadlock
                let screenshot: String? = nil
                
                // Send to API
                let response = try await APIClient.shared.process(
                    audioData: audioData,
                    screenshot: screenshot
                )
                
                print("AppState: Got response!")
                await MainActor.run {
                    self.transcribedText = response.transcribedText
                    self.responseText = response.response
                    self.mode = .responding
                }
                
                // Auto-hide after 15 seconds
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                await MainActor.run {
                    if self.mode == .responding {
                        self.mode = .idle
                    }
                }
                
            } catch {
                print("AppState: Error - \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.mode = .idle
                }
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
