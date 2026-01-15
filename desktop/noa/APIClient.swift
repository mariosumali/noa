import Foundation
import IOKit

struct TranscriptionResponse: Codable {
    let text: String
}

class APIClient {
    static let shared = APIClient()
    
    private var baseURL: String { Config.shared.backendURL }
    private var openAIKey: String { Config.shared.openAIKey }
    private let deviceId: String
    
    private init() {
        // Generate a persistent device ID
        deviceId = APIClient.getDeviceId()
        print("APIClient initialized with device: \(deviceId)")
    }
    
    /// Get a unique device identifier
    private static func getDeviceId() -> String {
        // Try to get hardware UUID
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        defer { IOObjectRelease(platformExpert) }
        
        if let uuid = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String {
            return "mac_\(uuid.prefix(16))"
        }
        
        // Fallback to a generated ID stored in UserDefaults
        let key = "noa_device_id"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        
        let newId = "mac_\(UUID().uuidString.prefix(16))"
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    /// Process audio and optional screenshot through the backend
    func process(audioData: Data, screenshot: String?) async throws -> (transcribedText: String, response: String) {
        print("APIClient: Starting process...")
        print("APIClient: Audio data size: \(audioData.count) bytes")
        
        // Step 1: Transcribe audio using Whisper API directly
        let transcribedText = try await transcribeAudio(audioData)
        print("APIClient: Transcribed text: \(transcribedText)")
        
        // Step 2: Send to backend for processing
        let response = try await sendToBackend(text: transcribedText, screenshot: screenshot)
        print("APIClient: Got response: \(response.prefix(100))...")
        
        return (transcribedText, response)
    }
    
    /// Transcribe audio using OpenAI Whisper API
    private func transcribeAudio(_ audioData: Data) async throws -> String {
        print("APIClient: Transcribing audio with Whisper...")
        
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            print("APIClient: Invalid URL")
            throw APIError.transcriptionFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file field - using m4a format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("APIClient: Sending \(body.count) bytes to Whisper API...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("APIClient: No HTTP response")
                throw APIError.transcriptionFailed
            }
            
            print("APIClient: Whisper response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("APIClient: Whisper error: \(errorBody)")
                throw APIError.transcriptionFailed
            }
            
            let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            return transcription.text
        } catch let error as URLError {
            print("APIClient: Network error: \(error.localizedDescription)")
            print("APIClient: Error code: \(error.code.rawValue)")
            throw APIError.networkError(error.localizedDescription)
        } catch {
            print("APIClient: Error: \(error)")
            throw error
        }
    }
    
    /// Send text and optional screenshot to backend
    private func sendToBackend(text: String, screenshot: String?) async throws -> String {
        print("APIClient: Sending to backend at \(baseURL)...")
        
        guard let url = URL(string: "\(baseURL)/api/process") else {
            throw APIError.processingFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        var body: [String: Any] = [
            "text": text,
            "device_id": deviceId
        ]
        if let screenshot = screenshot {
            body["screenshot"] = screenshot
            print("APIClient: Including screenshot")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.processingFailed
        }
        
        print("APIClient: Backend response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("APIClient: Backend error: \(errorBody)")
            throw APIError.processingFailed
        }
        
        struct BackendResponse: Codable {
            let response: String
            let prompt_id: String?
        }
        
        let backendResponse = try JSONDecoder().decode(BackendResponse.self, from: data)
        print("APIClient: Saved prompt with ID: \(backendResponse.prompt_id ?? "none")")
        return backendResponse.response
    }
}

enum APIError: LocalizedError {
    case transcriptionFailed
    case processingFailed
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .processingFailed:
            return "Failed to process request"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
