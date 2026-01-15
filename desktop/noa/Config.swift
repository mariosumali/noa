import Foundation

struct Config {
    static let shared = Config()
    
    let openAIKey: String
    let backendURL: String
    
    private init() {
        // Load from ~/.noa_config file
        if let key = Config.loadFromFile(key: "OPENAI_API_KEY") {
            openAIKey = key
        } else {
            openAIKey = ""
            print("Warning: OPENAI_API_KEY not found in ~/.noa_config")
        }
        
        if let url = Config.loadFromFile(key: "BACKEND_URL") {
            backendURL = url
        } else {
            backendURL = "http://localhost:3000"
        }
        
        print("Config loaded - API Key: \(openAIKey.prefix(20))...")
        print("Config loaded - Backend URL: \(backendURL)")
    }
    
    private static func loadFromFile(key: String) -> String? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configPath = homeDir.appendingPathComponent(".noa_config")
        
        guard let contents = try? String(contentsOf: configPath, encoding: .utf8) else {
            print("Warning: Could not read ~/.noa_config")
            return nil
        }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count >= 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                // Join remaining parts in case value contains "="
                let value = parts.dropFirst().joined(separator: "=")
                return value.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return nil
    }
}
