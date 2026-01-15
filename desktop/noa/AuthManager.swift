import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn = false
    @Published var userEmail: String?
    @Published var userId: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var message: String?
    
    private var backendURL: String { Config.shared.backendURL }
    
    private init() {
        // Check if already logged in
        if let token = UserDefaults.standard.string(forKey: "noa_user_token"),
           !token.isEmpty {
            isLoggedIn = true
            userEmail = UserDefaults.standard.string(forKey: "noa_user_email")
            userId = UserDefaults.standard.string(forKey: "noa_user_id")
        }
    }
    
    func login(email: String, password: String) async {
        await MainActor.run { 
            isLoading = true
            error = nil
            message = nil
        }
        
        do {
            guard let url = URL(string: "\(backendURL)/api/auth/login") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
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
                    self.userEmail = result.email ?? email
                    self.userId = result.user_id
                    
                    // Store credentials
                    UserDefaults.standard.set(result.access_token, forKey: "noa_user_token")
                    UserDefaults.standard.set(result.email ?? email, forKey: "noa_user_email")
                    UserDefaults.standard.set(result.user_id, forKey: "noa_user_id")
                    
                    self.isLoading = false
                }
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.serverError(errorResponse?.error ?? "Login failed")
            }
        } catch let authError as AuthError {
            await MainActor.run {
                self.error = authError.localizedDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Network error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func signup(email: String, password: String) async {
        await MainActor.run { 
            isLoading = true
            error = nil
            message = nil
        }
        
        do {
            guard let url = URL(string: "\(backendURL)/api/auth/signup") else {
                throw AuthError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "email": email,
                "password": password
            ])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // Check if email confirmation is required
                if let signupResponse = try? JSONDecoder().decode(SignupResponse.self, from: data),
                   signupResponse.requires_confirmation == true {
                    await MainActor.run {
                        self.message = signupResponse.message ?? "Check your email to confirm your account"
                        self.isLoading = false
                    }
                } else if let result = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                    await MainActor.run {
                        self.isLoggedIn = true
                        self.userEmail = result.email ?? email
                        self.userId = result.user_id
                        
                        UserDefaults.standard.set(result.access_token, forKey: "noa_user_token")
                        UserDefaults.standard.set(result.email ?? email, forKey: "noa_user_email")
                        UserDefaults.standard.set(result.user_id, forKey: "noa_user_id")
                        
                        self.isLoading = false
                    }
                }
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw AuthError.serverError(errorResponse?.error ?? "Signup failed")
            }
        } catch let authError as AuthError {
            await MainActor.run {
                self.error = authError.localizedDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Network error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        isLoggedIn = false
        userEmail = nil
        userId = nil
        error = nil
        message = nil
        
        UserDefaults.standard.removeObject(forKey: "noa_user_token")
        UserDefaults.standard.removeObject(forKey: "noa_user_email")
        UserDefaults.standard.removeObject(forKey: "noa_user_id")
    }
    
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: "noa_user_id")
    }
}

struct AuthResponse: Codable {
    let access_token: String?
    let user_id: String?
    let email: String?
}

struct SignupResponse: Codable {
    let message: String?
    let requires_confirmation: Bool?
}

struct ErrorResponse: Codable {
    let error: String
}

enum AuthError: LocalizedError {
    case invalidURL
    case networkError
    case invalidCredentials
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .networkError: return "Network error - is the backend running?"
        case .invalidCredentials: return "Invalid email or password"
        case .serverError(let message): return message
        }
    }
}
