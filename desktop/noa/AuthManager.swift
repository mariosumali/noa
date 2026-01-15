import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var userEmail: String?
    @Published var userId: String?
    @Published var isLoading = false
    @Published var error: String?
    
    private var backendURL: String { Config.shared.backendURL }
    
    private init() {}
    
    func login(email: String, password: String) async {
        await MainActor.run { isLoading = true; error = nil }
        
        do {
            guard let url = URL(string: "\(backendURL)/api/auth/login") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password
            ])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                await MainActor.run {
                    self.isLoggedIn = true
                    self.userEmail = email
                    self.userId = result.user_id
                    
                    // Store credentials
                    UserDefaults.standard.set(result.access_token, forKey: "noa_user_token")
                    UserDefaults.standard.set(email, forKey: "noa_user_email")
                    UserDefaults.standard.set(result.user_id, forKey: "noa_user_id")
                    
                    self.isLoading = false
                }
            } else {
                throw AuthError.invalidCredentials
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        isLoggedIn = false
        userEmail = nil
        userId = nil
        
        UserDefaults.standard.removeObject(forKey: "noa_user_token")
        UserDefaults.standard.removeObject(forKey: "noa_user_email")
        UserDefaults.standard.removeObject(forKey: "noa_user_id")
    }
    
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "noa_user_id")
    }
}

struct AuthResponse: Codable {
    let access_token: String
    let user_id: String
}

enum AuthError: LocalizedError {
    case invalidURL
    case networkError
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .networkError: return "Network error"
        case .invalidCredentials: return "Invalid email or password"
        }
    }
}
