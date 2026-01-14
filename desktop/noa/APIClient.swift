import Foundation

struct ProcessResponse: Codable {
    let transcribedText: String
    let response: String
    let promptId: String?
    
    enum CodingKeys: String, CodingKey {
        case transcribedText = "transcribed_text"
        case response
        case promptId = "prompt_id"
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}

class APIClient {
    static let shared = APIClient()
    
    private var baseURL: String { Config.shared.backendURL }
    private var openAIKey: String { Config.shared.openAIKey }
    
    private init() {}
    
    /// Process audio and optional screenshot through the backend
    func process(audioData: Data, screenshot: String?) async throws -> (transcribedText: String, response: String) {
        // Step 1: Transcribe audio using Whisper API directly
        let transcribedText = try await transcribeAudio(audioData)
        
        // Step 2: Send to backend for processing
        let response = try await sendToBackend(text: transcribedText, screenshot: screenshot)
        
        return (transcribedText, response)
    }
    
    /// Transcribe audio using OpenAI Whisper API
    private func transcribeAudio(_ audioData: Data) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.transcriptionFailed
        }
        
        let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcription.text
    }
    
    /// Send text and optional screenshot to backend
    private func sendToBackend(text: String, screenshot: String?) async throws -> String {
        let url = URL(string: "\(baseURL)/api/process")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["text": text]
        if let screenshot = screenshot {
            body["screenshot"] = screenshot
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.processingFailed
        }
        
        struct BackendResponse: Codable {
            let response: String
            let prompt_id: String?
        }
        
        let backendResponse = try JSONDecoder().decode(BackendResponse.self, from: data)
        return backendResponse.response
    }
}

enum APIError: LocalizedError {
    case transcriptionFailed
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .processingFailed:
            return "Failed to process request"
        }
    }
}
