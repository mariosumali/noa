import Foundation

struct Config {
    static let shared = Config()
    
    let openAIKey: String
    let backendURL: String
    
    private init() {
        // Try to load from environment or config file
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            openAIKey = key
        } else if let key = Config.loadFromFile(key: "OPENAI_API_KEY") {
            openAIKey = key
        } else {
            openAIKey = ""
            print("Warning: OPENAI_API_KEY not found")
        }
        
        if let url = ProcessInfo.processInfo.environment["BACKEND_URL"] {
            backendURL = url
        } else if let url = Config.loadFromFile(key: "BACKEND_URL") {
            backendURL = url
        } else {
            backendURL = "http://localhost:3000"
        }
    }
    
    private static func loadFromFile(key: String) -> String? {
        // Look for .env file in app bundle or home directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let envPath = homeDir.appendingPathComponent(".noa_config")
        
        guard let contents = try? String(contentsOf: envPath, encoding: .utf8) else {
            return nil
        }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
}
