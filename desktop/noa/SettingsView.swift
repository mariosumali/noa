import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var hotkeyOption = true
    @State private var showOverlay = true
    @State private var backendURL = Config.shared.backendURL
    @State private var apiKeySet = !Config.shared.openAIKey.isEmpty
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // General
                SettingsSection(title: "General") {
                    SettingsToggle(
                        title: "Launch at Login",
                        description: "Start noa when you log in to your Mac",
                        isOn: $launchAtLogin
                    )
                    
                    SettingsToggle(
                        title: "Show Overlay",
                        description: "Show the floating pill at the bottom of the screen",
                        isOn: $showOverlay
                    )
                }
                
                // Hotkey
                SettingsSection(title: "Hotkey") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Activation Key")
                                .font(.system(size: 13, weight: .medium))
                            Text("Hold this key to start speaking")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("⌥")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text("Option")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // API Configuration
                SettingsSection(title: "Configuration") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenAI API Key")
                                .font(.system(size: 13, weight: .medium))
                            Text(apiKeySet ? "API key is configured" : "Not configured")
                                .font(.system(size: 11))
                                .foregroundColor(apiKeySet ? .green : .red)
                        }
                        
                        Spacer()
                        
                        Button("Edit Config") {
                            openConfigFile()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Backend URL")
                                .font(.system(size: 13, weight: .medium))
                            Text(backendURL)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // About
                SettingsSection(title: "About") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("noa")
                                .font(.system(size: 13, weight: .medium))
                            Text("Version 1.0.0")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("GitHub") {
                            if let url = URL(string: "https://github.com/mariosumali/noa") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(24)
        }
        .frame(width: 450, height: 400)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        showOverlay = UserDefaults.standard.bool(forKey: "showOverlay")
    }
    
    private func openConfigFile() {
        let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".noa_config")
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: configPath.path) {
            let template = "OPENAI_API_KEY=your_key_here\nBACKEND_URL=http://localhost:3000\n"
            try? template.write(to: configPath, atomically: true, encoding: .utf8)
        }
        
        NSWorkspace.shared.open(configPath)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 0) {
                content
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 4)
    }
}
