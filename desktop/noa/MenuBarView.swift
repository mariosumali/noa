import SwiftUI

struct MenuBarView: View {
    weak var delegate: AppDelegate?
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("noa")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // User section
            if authManager.isLoggedIn {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.userEmail ?? "User")
                            .font(.system(size: 13, weight: .medium))
                        Text("Logged in")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.primary.opacity(0.03))
            } else {
                Button(action: { delegate?.showLoginWindow() }) {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.system(size: 20))
                        Text("Login to sync history")
                            .font(.system(size: 13))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.03))
            }
            
            Divider()
            
            // Menu items
            VStack(spacing: 0) {
                MenuButton(icon: "clock.arrow.circlepath", title: "History") {
                    delegate?.showHistoryWindow()
                }
                
                MenuButton(icon: "gear", title: "Settings") {
                    delegate?.showSettingsWindow()
                }
                
                MenuButton(icon: "questionmark.circle", title: "Help") {
                    if let url = URL(string: "https://github.com/mariosumali/noa") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            Divider()
            
            // Hotkey reminder
            HStack {
                Image(systemName: "option")
                    .font(.system(size: 12, weight: .medium))
                    .padding(4)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(4)
                
                Text("Hold Option to speak")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(16)
            
            Divider()
            
            // Quit
            HStack {
                if authManager.isLoggedIn {
                    Button("Logout") {
                        authManager.logout()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                }
                
                Spacer()
                
                Button("Quit noa") {
                    delegate?.quitApp()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 280)
    }
    
    private var statusColor: Color {
        switch appState.uiMode {
        case .idle: return .green
        case .listening: return .orange
        case .processing: return .yellow
        case .responding: return .blue
        case .typing: return .green
        }
    }
    
    private var statusText: String {
        switch appState.uiMode {
        case .idle: return "Ready"
        case .listening: return "Listening"
        case .processing: return "Processing"
        case .responding: return "Response"
        case .typing: return "Typing"
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
