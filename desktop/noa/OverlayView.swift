import SwiftUI

struct OverlayView: View {
    @ObservedObject var appState = AppState.shared
    @State private var waveformPhase: CGFloat = 0
    @State private var animationTimer: Timer?
    
    private var isExpanded: Bool {
        appState.mode != .idle
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Group {
                if isExpanded {
                    expandedView
                } else {
                    collapsedView
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: appState.mode) { oldValue, newValue in
            if newValue == .listening {
                startWaveformAnimation()
            } else {
                stopWaveformAnimation()
            }
        }
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
    
    // MARK: - Collapsed State (tiny pill)
    private var collapsedView: some View {
        Capsule()
            .fill(Color.black.opacity(0.85))
            .frame(width: 80, height: 24)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
    
    // MARK: - Expanded State
    private var expandedView: some View {
        VStack(spacing: 10) {
            Group {
                if appState.mode == .listening {
                    listeningView
                } else if appState.mode == .processing {
                    processingView
                } else if appState.mode == .responding {
                    respondingView
                }
            }
            
            if let error = appState.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: expandedWidth)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 6)
    }
    
    private var expandedWidth: CGFloat {
        switch appState.mode {
        case .idle: return 80
        case .listening: return 200
        case .processing: return 160
        case .responding: return 320
        }
    }
    
    // MARK: - Listening View with Waveform
    private var listeningView: some View {
        HStack(spacing: 2) {
            ForEach(0..<16, id: \.self) { i in
                WaveformBar(index: i, phase: waveformPhase)
            }
        }
        .frame(height: 24)
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .tint(.white)
            
            Text("Processing...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 24)
    }
    
    // MARK: - Responding View
    private var respondingView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !appState.transcribedText.isEmpty {
                Text(appState.transcribedText)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Text(appState.responseText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(5)
        }
    }
}

// MARK: - Waveform Bar
struct WaveformBar: View {
    let index: Int
    let phase: CGFloat
    
    private var barHeight: CGFloat {
        let baseHeight: CGFloat = 3
        let maxHeight: CGFloat = 20
        let frequency = 0.7
        let phaseOffset = CGFloat(index) * 0.4
        
        let wave = sin(phase * frequency + phaseOffset)
        let normalizedWave = (wave + 1) / 2
        
        return baseHeight + (maxHeight - baseHeight) * normalizedWave
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
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
        .frame(width: 400, height: 100)
        .background(Color.gray)
}
