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
        guard !isRecording else { 
            print("AudioRecorder: Already recording")
            return 
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("noa_recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let url = recordingURL, let engine = audioEngine else { 
            print("AudioRecorder: Missing URL or engine")
            return 
        }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("AudioRecorder: Input format - \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")
        
        // Record in native format - Whisper API accepts m4a, mp3, wav, etc.
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: inputFormat.channelCount,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            print("AudioRecorder: Created audio file at \(url)")
        } catch {
            print("AudioRecorder: Failed to create audio file: \(error)")
            return
        }
        
        // Install tap on input node - record in native format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("AudioRecorder: Failed to write audio buffer: \(error)")
            }
        }
        
        // Start the audio engine
        do {
            try engine.start()
            isRecording = true
            print("AudioRecorder: Recording started")
        } catch {
            print("AudioRecorder: Failed to start audio engine: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (Data?) -> Void) {
        guard isRecording, let engine = audioEngine else {
            print("AudioRecorder: Not recording or no engine")
            completion(nil)
            return
        }
        
        // Stop recording
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        isRecording = false
        
        print("AudioRecorder: Recording stopped")
        
        // Read the recorded file
        guard let url = recordingURL else {
            print("AudioRecorder: No recording URL")
            completion(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("AudioRecorder: Read \(data.count) bytes from recording")
            // Clean up temp file
            try? FileManager.default.removeItem(at: url)
            completion(data)
        } catch {
            print("AudioRecorder: Failed to read audio file: \(error)")
            completion(nil)
        }
    }
}
