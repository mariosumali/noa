# Implementing Mac Native Transcription

## Web Dashboard
- [x] Create `VoiceInput` component using Web Speech API
- [x] Integrate `VoiceInput` into `Sidebar`
- [x] Connect to `api/process`
- [x] Verify
- [x] Add tool usage badges to Dashboard History

## Desktop App
- [x] Add Permissions to `Info.plist` (Mic & Speech)
- [x] Create `SpeechRecognizer.swift`
- [x] Add `TranscriptionMode` setting to `Settings.swift`
- [x] Add Transcription picker to `SettingsView.swift`
- [x] Refactor `AppState.swift` to use selected mode
- [x] Verify build
- [x] Add real-time transcription to Overlay
- [x] Add tool usage badges to Overlay

## Desktop UI Refinements
- [x] Fix auto-dismiss bug (handle .typing mode)
- [x] Implement "Prominent Header" style for all tools (Calendar, Email)
- [x] Add Close (X) button to Transcribe/Typing mode
- [x] Add tool icons to status Pill (Horizontal & Vertical)
- [x] Remove redundant tool badges from body content

## Improvements
- [x] Fix unread email count (use Labels API)
- [x] Support "last email from" queries (add getRecentEmails)
- [x] Fix "latest email" parsing bug
- [x] Improve context for general queries ("emails at 12")
- [x] Add advanced search parameters (Time, Subject, Sender)

## Transcription History & Auto-Paste
- [x] Add `autoPaste` toggle in Desktop Settings
- [x] Implement `pasteFromClipboard` (Cmd+V simulation)
- [x] Add `skip_ai` (transcription logging) to backend
- [x] Update Desktop App to log dictation to history
- [x] Add "Transcription" badge to Web History & Dashboard
- [x] Add "Transcription" badge to Desktop Overlay
