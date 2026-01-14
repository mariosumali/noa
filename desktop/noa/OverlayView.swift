import SwiftUI

struct OverlayView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 12) {
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: appState.mode)
                    
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Logo
                    Text("noa")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Content area
                VStack(alignment: .leading, spacing: 8) {
                    if !appState.transcribedText.isEmpty {
                        Text(appState.transcribedText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if !appState.responseText.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text(appState.responseText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(6)
                    }
                    
                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    
                    if appState.mode == .idle && appState.transcribedText.isEmpty {
                        Text("Hold ⌥ Option to speak")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                    
                    if appState.mode == .listening {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.orange)
                                    .frame(width: 4, height: CGFloat.random(in: 8...24))
                                    .animation(
                                        .easeInOut(duration: 0.3)
                                        .repeatForever()
                                        .delay(Double(i) * 0.1),
                                        value: appState.mode
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                    }
                    
                    if appState.mode == .processing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 380, minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    var statusColor: Color {
        switch appState.mode {
        case .idle:
            return .gray
        case .listening:
            return .orange
        case .processing:
            return .blue
        case .responding:
            return .green
        }
    }
    
    var statusText: String {
        switch appState.mode {
        case .idle:
            return "Ready"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        case .responding:
            return "Done"
        }
    }
}

#Preview {
    OverlayView()
        .frame(width: 400, height: 200)
        .background(Color.black)
}
