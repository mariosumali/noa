import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
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
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    SecureField(isSignUp ? "Min 6 characters" : "••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Error message
                if let error = authManager.error {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
                
                // Success message
                if let message = authManager.message {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }
                
                // Submit button
                Button(action: submit) {
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
                    .background(canSubmit ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
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
                        Text("Login via Web Browser")
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
            
            // Footer - toggle between login/signup
            HStack {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Button(isSignUp ? "Login" : "Sign Up") {
                    withAnimation {
                        isSignUp.toggle()
                        authManager.error = nil
                        authManager.message = nil
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 400, height: 520)
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                NSApp.keyWindow?.close()
            }
        }
    }
    
    private var canSubmit: Bool {
        !authManager.isLoading && 
        !email.isEmpty && 
        !password.isEmpty &&
        (isSignUp ? password.count >= 6 : true)
    }
    
    private func submit() {
        Task {
            if isSignUp {
                await authManager.signup(email: email, password: password)
            } else {
                await authManager.login(email: email, password: password)
            }
        }
    }
    
    private func openWebLogin() {
        if let url = URL(string: "\(Config.shared.backendURL)/login") {
            NSWorkspace.shared.open(url)
        }
    }
}
