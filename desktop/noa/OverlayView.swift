import SwiftUI
import Combine
import AppKit

struct OverlayView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var settings = NoaSettings.shared
    @State private var waveformPhase: CGFloat = 0
    @State private var animationTimer: Timer?
    @State private var dismissTimer: Timer?
    @State private var showCopiedFeedback = false
    
    var body: some View {
        Group {
            switch settings.overlayPosition {
            case .bottom:
                bottomLayout
            case .top:
                topLayout
            case .left:
                leftLayout
            case .right:
                rightLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.uiMode)
        .onChange(of: appState.uiMode) { newValue in
            if newValue == .listening {
                startWaveformAnimation()
                cancelDismissTimer()
            } else if newValue == .responding {
                stopWaveformAnimation()
                startDismissTimer()
            } else {
                stopWaveformAnimation()
                cancelDismissTimer()
            }
        }
    }
    
    // MARK: - Layouts
    
    private var bottomLayout: some View {
        VStack(spacing: 10) {
            Spacer()
            if showResponsePanel {
                responsePanel
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            horizontalPillView
        }
        .padding(.bottom, 16)
    }
    
    private var topLayout: some View {
        VStack(spacing: 10) {
            horizontalPillView
            if showResponsePanel {
                responsePanel
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    private var leftLayout: some View {
        HStack(spacing: 10) {
            verticalPillView
            if showResponsePanel {
                responsePanel
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.leading, 16)
    }
    
    private var rightLayout: some View {
        HStack(spacing: 10) {
            Spacer()
            if showResponsePanel {
                responsePanel
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            verticalPillView
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.trailing, 16)
    }
    
    private var showResponsePanel: Bool {
        appState.uiMode == .responding || appState.uiMode == .processing || appState.uiMode == .typing || 
        (appState.uiMode == .listening && !appState.transcribedText.isEmpty)
    }
    
    // MARK: - Response Panel
    private var responsePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if appState.uiMode == .responding {
                HStack {
                    Spacer()
                    
                    Button(action: copyResponse) {
                        HStack(spacing: 4) {
                            Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                            Text(showCopiedFeedback ? "Copied!" : "Copy")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(showCopiedFeedback ? .green : .white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 20, height: 20)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
                .padding(.bottom, 4)
            }
            
            if appState.uiMode == .listening {
                // Real-time transcription while speaking
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Listening...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text(appState.transcribedText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if appState.uiMode == .processing {
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
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .foregroundColor(.green)
                    Text("Copied to clipboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
                
                Text(appState.aiResponse)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(5)
            } else if appState.uiMode == .responding {
                if !appState.transcribedText.isEmpty {
                    Text(appState.transcribedText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
                
                Text(appState.aiResponse)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(15)
                    .textSelection(.enabled)
            }
            
            if let error = appState.apiError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: settings.overlayPosition.isVertical ? 380 : 420, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(settings.overlayOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(appState.uiMode == .typing ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }
    
    // MARK: - Horizontal Pill (for top/bottom)
    private var horizontalPillView: some View {
        let pillColor = settings.pillColor.color
        let textColor = settings.pillColor.textColor
        
        return Group {
            if appState.uiMode == .listening {
                HStack(spacing: 2) {
                    ForEach(0..<14, id: \.self) { i in
                        WaveformBar(index: i, phase: waveformPhase, isVertical: false, color: textColor)
                    }
                }
                .frame(height: 18)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(pillColor.opacity(0.9)))
                .overlay(Capsule().stroke(textColor.opacity(0.1), lineWidth: 0.5))
            } else if appState.uiMode == .typing {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                .frame(height: 18)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(pillColor.opacity(0.9)))
                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.5))
            } else {
                Capsule()
                    .fill(pillColor.opacity(0.85))
                    .frame(width: 56, height: 20)
                    .overlay(Capsule().stroke(textColor.opacity(0.1), lineWidth: 0.5))
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }
    
    // MARK: - Vertical Pill (for left/right)
    private var verticalPillView: some View {
        let pillColor = settings.pillColor.color
        let textColor = settings.pillColor.textColor
        
        return Group {
            if appState.uiMode == .listening {
                VStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        WaveformBar(index: i, phase: waveformPhase, isVertical: true, color: textColor)
                    }
                }
                .frame(width: 18)
                .padding(.vertical, 14)
                .padding(.horizontal, 7)
                .background(Capsule().fill(pillColor.opacity(0.9)))
                .overlay(Capsule().stroke(textColor.opacity(0.1), lineWidth: 0.5))
            } else if appState.uiMode == .typing {
                VStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 18)
                .padding(.vertical, 14)
                .padding(.horizontal, 7)
                .background(Capsule().fill(pillColor.opacity(0.9)))
                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.5))
            } else {
                Capsule()
                    .fill(pillColor.opacity(0.85))
                    .frame(width: 20, height: 56)
                    .overlay(Capsule().stroke(textColor.opacity(0.1), lineWidth: 0.5))
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 8, x: 4)
    }
    
    // MARK: - Actions
    
    private func dismiss() {
        cancelDismissTimer()
        appState.reset()
    }
    
    private func copyResponse() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(appState.aiResponse, forType: .string)
        
        withAnimation {
            showCopiedFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
    
    private func startDismissTimer() {
        cancelDismissTimer()
        let seconds = settings.autoDismissSeconds
        guard seconds > 0 else { return }
        dismissTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            DispatchQueue.main.async {
                appState.reset()
            }
        }
    }
    
    private func cancelDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
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
    let isVertical: Bool
    var color: Color = .white
    
    private var barSize: CGFloat {
        let baseSize: CGFloat = 3
        let maxSize: CGFloat = 16
        let frequency = 0.7
        let phaseOffset = CGFloat(index) * 0.4
        
        let wave = sin(phase * frequency + phaseOffset)
        let normalizedWave = (wave + 1) / 2
        
        return baseSize + (maxSize - baseSize) * normalizedWave
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.9), color.opacity(0.4)],
                    startPoint: isVertical ? .leading : .top,
                    endPoint: isVertical ? .trailing : .bottom
                )
            )
            .frame(
                width: isVertical ? barSize : 2,
                height: isVertical ? 2 : barSize
            )
    }
}

#Preview {
    OverlayView()
        .frame(width: 500, height: 400)
        .background(Color.gray)
}
