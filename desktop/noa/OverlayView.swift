import SwiftUI
import Combine

struct OverlayView: View {
    @ObservedObject var appState = AppState.shared
    @State private var waveformPhase: CGFloat = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            // Response panel (above the pill)
            if appState.mode == .responding || appState.mode == .processing {
                responsePanel
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Small pill at the bottom
            pillView
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.mode)
        .onChange(of: appState.mode) { oldValue, newValue in
            if newValue == .listening {
                startWaveformAnimation()
            } else {
                stopWaveformAnimation()
            }
        }
    }
    
    // MARK: - Response Panel
    private var responsePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appState.mode == .processing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                    Text("Thinking...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            } else if appState.mode == .responding {
                // User's question
                if !appState.transcribedText.isEmpty {
                    Text(appState.transcribedText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
                
                // AI Response
                Text(appState.responseText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(12)
            }
            
            // Error message
            if let error = appState.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(16)
        .frame(maxWidth: 360, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    // MARK: - Small Pill
    private var pillView: some View {
        Group {
            if appState.mode == .listening {
                // Expanded pill with waveform
                HStack(spacing: 2) {
                    ForEach(0..<12, id: \.self) { i in
                        WaveformBar(index: i, phase: waveformPhase)
                    }
                }
                .frame(height: 16)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.9))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            } else {
                // Tiny idle pill
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 48, height: 16)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
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
        let baseHeight: CGFloat = 2
        let maxHeight: CGFloat = 14
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
        .frame(width: 400, height: 300)
        .background(Color.gray)
}
