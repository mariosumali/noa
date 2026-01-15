import Foundation
import Speech
import AVFoundation

/// Handles on-device speech recognition using Apple's SFSpeechRecognizer
class SpeechRecognizer: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var transcript: String = ""
    @Published var isAvailable: Bool = false
    
    private var onComplete: ((String) -> Void)?
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        checkAuthorization()
    }
    
    private func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAvailable = (status == .authorized)
                if status != .authorized {
                    print("SpeechRecognizer: Not authorized - \(status.rawValue)")
                }
            }
        }
    }
    
    func startTranscribing() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("SpeechRecognizer: Could not create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Use on-device recognition if available (faster, private)
        if #available(macOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("SpeechRecognizer: Started transcribing")
        } catch {
            print("SpeechRecognizer: Could not start audio engine: \(error)")
        }
    }
    
    func stopTranscribing(completion: @escaping (String) -> Void) {
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Give a brief moment for final results
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let finalTranscript = self?.transcript ?? ""
            print("SpeechRecognizer: Stopped. Final transcript: \(finalTranscript)")
            completion(finalTranscript)
        }
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isAvailable = available
        }
    }
}
