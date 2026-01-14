# noa Desktop App

A macOS desktop application that provides voice-activated AI assistance.

## Features

- 🎤 Voice input with Option key hold
- 🖥️ Screen capture and analysis
- 💬 Natural language responses
- 🔄 Floating overlay UI

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- OpenAI API key

## Setup

### 1. Create Xcode Project

1. Open Xcode
2. Create new project: **File → New → Project**
3. Choose: **macOS → App**
4. Settings:
   - Product Name: `noa`
   - Team: Your team
   - Organization Identifier: `com.mariosumali`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save to the `desktop` folder (replace if prompted)

### 2. Add Source Files

After creating the project:

1. Delete the auto-generated `ContentView.swift`
2. Right-click on the `noa` folder in Xcode
3. **Add Files to "noa"...**
4. Select all `.swift` files from `desktop/noa/`:
   - `NoaApp.swift`
   - `AppState.swift`
   - `OverlayWindow.swift`
   - `OverlayView.swift`
   - `HotkeyManager.swift`
   - `AudioRecorder.swift`
   - `ScreenCapture.swift`
   - `APIClient.swift`
   - `Config.swift`

### 3. Configure Info.plist

In Xcode, update your Info.plist with these keys (or copy from `noa/Info.plist`):

- `NSMicrophoneUsageDescription`: "noa needs microphone access to listen to your voice commands."
- `NSScreenCaptureUsageDescription`: "noa needs screen capture access to see and analyze what's on your screen when you ask."
- `LSUIElement`: `YES` (hides dock icon)

### 4. Configure Entitlements

Add these entitlements in Xcode:
- Audio Input: YES
- Network Client: YES

### 5. Set Up API Key

Create a config file at `~/.noa_config`:

```
OPENAI_API_KEY=your_openai_key_here
BACKEND_URL=http://localhost:3000
```

Or set environment variables in Xcode scheme.

### 6. Build & Run

1. Select your Mac as the run destination
2. Press **⌘R** to build and run

## Usage

1. The app runs in the menu bar (look for the waveform icon)
2. **Hold Option (⌥)** to start speaking
3. **Release Option** to process your request
4. The floating overlay shows your transcribed text and noa's response

## Permissions

On first run, macOS will ask for:
- **Microphone Access**: Required for voice input
- **Screen Recording**: Required for "what's on my screen" feature
- **Accessibility**: Required for global hotkey detection

Grant all permissions in **System Preferences → Privacy & Security**.

## Troubleshooting

### Hotkey not working
- Make sure noa has Accessibility permissions
- Try restarting the app after granting permissions

### Screen capture not working
- Grant Screen Recording permission in System Preferences
- Restart the app after granting permission

### Audio not recording
- Check Microphone permission
- Make sure your mic is working in other apps

## Architecture

```
NoaApp.swift          # App entry point, menu bar setup
AppState.swift        # Shared state management
OverlayWindow.swift   # Floating window configuration
OverlayView.swift     # SwiftUI overlay UI
HotkeyManager.swift   # Option key detection
AudioRecorder.swift   # Microphone recording
ScreenCapture.swift   # Screen capture utility
APIClient.swift       # Backend communication
Config.swift          # Configuration loading
```
