# Transcription History & UI Refinement

Implemented native transcription logging, auto-paste, and a refined UI for tool feedback.

## Key Changes

### 1. UI Refinements (Desktop)
- **Prominent Headers**: Tool usage (Calendar, Email, Transcription) is now displayed in a centered header with distinct colors and icons.
- **Pill Icons**: The collapsed "Pill" view now shows the icon of the active tool (e.g., specific calendar or email icon) instead of a generic capsule when responding.
- **Transcribe Mode**: Added a "Close" (X) button to the transcription feedback window.
- **Clean Layout**: Removed redundant tool badges from the content area, relying on the header for context.

### 2. Backend Logging
Modified `POST /api/process` to accept a `skip_ai` flag. When true, it logs the prompt to Supabase with tool `transcription_log` and returns immediately.

### 3. Auto-Paste & Desktop Integration
Updated `AppState.swift` and `APIClient.swift` to:
- Detect "Write/Transcribe" commands locally.
- Perform the copy/paste action (simulating Cmd+V if `autoPaste` is enabled).
- Send the text to the backend for history logging.

## Verification
- Built desktop app successfully and verified UI element logic.
