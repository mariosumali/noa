import Foundation
import AVFoundation

class AudioRecorder: NSObject {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var isRecording = false
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioEngine = AVAudioEngine()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("noa_recording_\(Date().timeIntervalSince1970).wav")
        
        guard let url = recordingURL, let engine = audioEngine else { return }
        
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Create audio file for recording
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ])
        } catch {
            print("Failed to create audio file: \(error)")
            return
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("Failed to write audio buffer: \(error)")
            }
        }
        
        // Start the audio engine
        do {
            try engine.start()
            isRecording = true
            print("Recording started")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (Data?) -> Void) {
        guard isRecording, let engine = audioEngine else {
            completion(nil)
            return
        }
        
        // Stop recording
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        isRecording = false
        
        print("Recording stopped")
        
        // Read the recorded file
        guard let url = recordingURL else {
            completion(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            // Clean up temp file
            try? FileManager.default.removeItem(at: url)
            completion(data)
        } catch {
            print("Failed to read audio file: \(error)")
            completion(nil)
        }
    }
}
