import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("noa")
                    .font(.system(size: 28, weight: .bold))
                
                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                if let error = authManager.error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
                
                Button(action: login) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.trailing, 4)
                        }
                        Text(isSignUp ? "Create Account" : "Login")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                .padding(.top, 8)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                }
                .padding(.vertical, 8)
                
                // Web login
                Button(action: openWebLogin) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Login via Web")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Footer
            HStack {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(isSignUp ? "Login" : "Sign Up") {
                    isSignUp.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 400, height: 500)
        .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
            if newValue {
                // Close window on successful login
                NSApp.keyWindow?.close()
            }
        }
    }
    
    private func login() {
        Task {
            await authManager.login(email: email, password: password)
        }
    }
    
    private func openWebLogin() {
        if let url = URL(string: "\(Config.shared.backendURL)/login") {
            NSWorkspace.shared.open(url)
        }
    }
}
