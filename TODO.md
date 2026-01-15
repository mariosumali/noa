# TODO

## ✅ Completed

### Phase 1: Project Setup
- [x] Initialize Next.js project with TypeScript
- [x] Set up Tailwind CSS
- [x] Create Supabase project
- [x] Set up environment variables
- [x] Create basic file structure

### Phase 2: Landing Page
- [x] Design landing page layout
- [x] Build hero section
- [x] Build features section
- [x] Build CTA section
- [x] Add navigation

### Phase 3: Authentication
- [x] Set up Supabase Auth
- [x] Build login page
- [x] Build signup page
- [x] Google OAuth integration
- [x] Implement auth middleware
- [x] Protected routes for dashboard

### Phase 4: Dashboard
- [x] Dashboard layout with sidebar
- [x] Prompt history page (grouped by date)
- [x] Settings page
- [x] Wispr Flow-inspired UI design
- [x] Connect to Supabase

### Phase 5: API Routes
- [x] POST /api/process - AI processing with vision
- [x] GET /api/prompts - Get history
- [x] POST /api/auth/login - Desktop login
- [x] POST /api/auth/signup - Desktop signup
- [x] OpenAI GPT-4o integration
- [x] Whisper API integration
- [x] GPT-4 Vision for screenshots

### Phase 6: Desktop App (macOS)
- [x] Create Xcode project
- [x] Build overlay UI (tiny pill + response panel)
- [x] Option key detection (hotkey)
- [x] Microphone recording (m4a format)
- [x] Whisper API transcription
- [x] Backend connection
- [x] Response display
- [x] Menu bar app integration
- [x] Login/signup window
- [x] Settings window
- [x] History view
- [x] Device ID tracking for prompts
- [x] AppState singleton pattern
- [x] Symlink setup for development

### Phase 7: Screen Capture
- [x] ScreenCaptureKit implementation
- [x] Keyword detection for screen queries
- [x] GPT-4 Vision integration
- [x] Base64 image encoding

### Phase 8: Integration & Polish
- [x] End-to-end testing
- [x] Error handling
- [x] Loading states
- [x] Prompt persistence to Supabase

### Phase 9: Desktop Enhancements
- [x] X button to dismiss response
- [x] Copy button for responses
- [x] Auto-dismiss timer
- [x] Configurable overlay position (bottom/top/left/right)
- [x] Configurable overlay opacity
- [x] Configurable hotkey (Option/Control/Command/Shift)
- [x] Text-to-speech toggle
- [x] "Write" command (transcribe → clipboard)
- [x] Pill color customization
- [x] Dark mode toggle on web

### Phase 10: Gmail Integration
- [x] Google OAuth credentials setup
- [x] user_integrations database table
- [x] Gmail API wrapper (lib/gmail.ts)
- [x] OAuth connect/callback routes
- [x] Gmail status API (connect/disconnect)
- [x] Gmail query detection in /api/process
- [x] Email context for AI responses
- [x] Integrations UI in settings

---

## 🔄 In Progress

- [ ] Screen capture permissions (requires Apple Developer Program for stable signing)

---

## 📋 Upcoming

### Polish
- [x] Better error messages
- [x] Set Password for Google accounts
- [ ] Keyboard shortcuts in web app
- [ ] Dark mode toggle
- [ ] Notification sounds

### Features
- [ ] Search prompts
- [ ] Delete prompts
- [ ] Export history
- [ ] Usage analytics

### Desktop
- [ ] Launch at login
- [ ] Custom hotkey configuration
- [ ] Auto-update mechanism
- [ ] Proper code signing (Apple Developer Program)

---

## 🐛 Known Issues

See [BUGS.md](./BUGS.md)
