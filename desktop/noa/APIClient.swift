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
        deviceId = APIClient.generateDeviceId()
        print("APIClient initialized with device: \(deviceId)")
    }
    
    /// Public accessor for device ID
    func getDeviceId() -> String {
        return deviceId
    }
    
    /// Get a unique device identifier
    private static func generateDeviceId() -> String {
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
        
        let key = "noa_device_id"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        
        let newId = "mac_\(UUID().uuidString.prefix(16))"
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    /// Transcribe audio using OpenAI Whisper API
    func transcribeAudio(_ audioData: Data) async throws -> String {
        print("APIClient: Transcribing audio with Whisper...")
        
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            throw APIError.transcriptionFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.transcriptionFailed
        }
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("APIClient: Whisper error: \(errorBody)")
            throw APIError.transcriptionFailed
        }
        
        let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcription.text
    }
    
    /// Send text (and optional screenshot) to backend for AI processing
    func processText(text: String, screenshot: String?) async throws -> String {
        print("APIClient: Sending to backend...")
        
        guard let url = URL(string: "\(baseURL)/api/process") else {
            throw APIError.processingFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90 // Longer timeout for vision processing
        
        var body: [String: Any] = [
            "text": text,
            "device_id": deviceId
        ]
        
        if let userId = AuthManager.shared.getUserId() {
            body["user_id"] = userId
        }
        
        if let screenshot = screenshot {
            body["screenshot"] = screenshot
            print("APIClient: Including screenshot (\(screenshot.count / 1024) KB)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.processingFailed
        }
        
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
