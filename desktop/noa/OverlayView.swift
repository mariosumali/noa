import SwiftUI
import Combine

struct OverlayView: View {
    @ObservedObject var appState = AppState.shared
    @State private var waveformPhase: CGFloat = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Response panel (above the pill)
            if appState.uiMode == .responding || appState.uiMode == .processing || appState.uiMode == .typing {
                responsePanel
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Small pill - always at the bottom, fixed position
            pillView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.uiMode)
        .onChange(of: appState.uiMode) { newValue in
            if newValue == .listening {
                startWaveformAnimation()
            } else {
                stopWaveformAnimation()
            }
        }
    }
    
    // MARK: - Response Panel
    private var responsePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if appState.uiMode == .processing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                    Text("Thinking...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            } else if appState.uiMode == .typing {
                // Typing mode indicator
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .foregroundColor(.green)
                    Text("Typing...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                
                // Show what's being typed
                Text(appState.aiResponse)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(5)
            } else if appState.uiMode == .responding {
                // User's question
                if !appState.transcribedText.isEmpty {
                    Text(appState.transcribedText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
                
                // AI Response
                Text(appState.aiResponse)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(15)
            }
            
            // Error message
            if let error = appState.apiError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 420, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(appState.uiMode == .typing ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
    
    // MARK: - Small Pill (fixed position)
    private var pillView: some View {
        Group {
            if appState.uiMode == .listening {
                // Expanded pill with waveform
                HStack(spacing: 2) {
                    ForEach(0..<14, id: \.self) { i in
                        WaveformBar(index: i, phase: waveformPhase)
                    }
                }
                .frame(height: 18)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.9))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            } else if appState.uiMode == .typing {
                // Typing pill (green accent)
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                .frame(height: 18)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.9))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                )
            } else {
                // Tiny idle pill
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 56, height: 20)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
    
    private func startWaveformAnimation() {
        waveformPhase = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            waveformPhase += 0.15
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        waveformPhase = 0
    }
}

// MARK: - Waveform Bar
struct WaveformBar: View {
    let index: Int
    let phase: CGFloat
    
    private var barHeight: CGFloat {
        let baseHeight: CGFloat = 3
        let maxHeight: CGFloat = 16
        let frequency = 0.7
        let phaseOffset = CGFloat(index) * 0.4
        
        let wave = sin(phase * frequency + phaseOffset)
        let normalizedWave = (wave + 1) / 2
        
        return baseHeight + (maxHeight - baseHeight) * normalizedWave
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.9), .white.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: barHeight)
    }
}

#Preview {
    OverlayView()
        .frame(width: 500, height: 400)
        .background(Color.gray)
}
