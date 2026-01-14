# Project Plan: noa

## Overview

noa is a personal AI assistant created by Mario Sumali. It combines a desktop application (voice-activated overlay) with a web application (settings & dashboard) to help users interact with their digital services through natural language.

---

## Decisions Made

| Decision | Choice | Future |
|----------|--------|--------|
| **Actions** | Read-only (answer questions) | Will add actions later |
| **Voice Response** | Text display only | Will add TTS later |
| **Platform** | macOS only | Windows support later |
| **Processing** | Cloud-based | — |
| **Screen Capture** | On-demand only | — |

---

## MVP Scope (v0.1)

**Goal**: Build the skeleton infrastructure with voice input and screen reading capability.

### What's IN the MVP
1. **Web App - Landing Page**
   - Professional, minimalistic design
   - Sign up / Log in functionality
   - Product overview

2. **Web App - Dashboard**
   - Prompt history (stored commands and responses)
   - Basic account settings

3. **Desktop App - macOS**
   - Overlay widget (small oval at bottom)
   - Function key hold to activate
   - Voice transcription (speech-to-text)
   - Display transcribed request
   - Display AI response
   - On-demand screen capture

4. **Backend**
   - User authentication
   - Store prompts/responses
   - AI/LLM integration for responses
   - Screen analysis via vision model

5. **One Integration: Screen Reading**
   - Capture current screen on demand
   - Send to vision model for analysis
   - "What's on my screen?" functionality

### What's NOT in the MVP
- ❌ Email integrations (Gmail, Outlook)
- ❌ Calendar integrations
- ❌ Slack integration
- ❌ Google Drive integration
- ❌ Taking actions (sending emails, scheduling)
- ❌ Text-to-speech responses
- ❌ Windows support
- ❌ Mobile app

---

## Architecture (MVP)

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER                                     │
└─────────────────────────────────────────────────────────────────┘
                    │                           │
        [Hold Fn + Speak]              [Browser]
                    │                           │
                    ▼                           ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│  Desktop App (macOS/Swift)  │   │    Web App (Next.js)        │
│  ─────────────────────────  │   │    ─────────────────────    │
│  • Overlay UI (oval)        │   │    • Landing page           │
│  • Fn key listener          │   │    • Auth (login/signup)    │
│  • Microphone capture       │   │    • Dashboard              │
│  • Screen capture           │   │    • Prompt history         │
│  • Display responses        │   │    • Settings               │
└─────────────────────────────┘   └─────────────────────────────┘
                    │                           │
                    └───────────┬───────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (Node/Python)                    │
│  ───────────────────────────────────────────────────────────    │
│  • POST /auth/signup                                             │
│  • POST /auth/login                                              │
│  • POST /prompts          (save prompt + response)               │
│  • GET  /prompts          (get prompt history)                   │
│  • POST /process          (send voice text + optional screenshot)│
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        External Services                         │
│  ───────────────────────────────────────────────────────────    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Whisper API   │  │  OpenAI GPT-4   │  │  GPT-4 Vision   │ │
│  │   (Speech→Text) │  │  (Responses)    │  │  (Screen Read)  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Database                                │
│  ───────────────────────────────────────────────────────────    │
│  • Users (id, email, password_hash, created_at)                  │
│  • Prompts (id, user_id, text, response, screenshot_url, ts)     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack (MVP)

### Chosen for MVP

| Component | Technology | Reason |
|-----------|------------|--------|
| **Desktop App** | Swift (native macOS) | Best macOS integration, lightweight, can do Windows later with different tech |
| **Web App** | Next.js 14 | Full-stack React, great DX, easy deployment |
| **Backend** | Next.js API Routes | Keep it simple, one codebase for web + API |
| **Database** | Supabase (Postgres) | Auth built-in, easy setup, real-time capable |
| **Speech-to-Text** | Whisper API (OpenAI) | Accurate, easy integration |
| **LLM** | OpenAI GPT-4 | Best quality, vision capabilities included |
| **Hosting** | Vercel (web) | Easy Next.js deployment |

### Data Flow

1. User holds Fn key → Desktop app starts recording
2. User speaks → Audio captured
3. User releases Fn → Audio sent to Whisper API → Text returned
4. If "screen" mentioned → Capture screenshot
5. Text (+ screenshot if applicable) sent to backend `/process`
6. Backend sends to GPT-4 (with vision if screenshot)
7. Response returned → Displayed in overlay
8. Prompt + response saved to database

---

## Database Schema (MVP)

```sql
-- Users table (handled by Supabase Auth)
-- Supabase provides: id, email, encrypted_password, created_at, etc.

-- Prompts table
CREATE TABLE prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  response TEXT,
  screenshot_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX prompts_user_id_idx ON prompts(user_id);
CREATE INDEX prompts_created_at_idx ON prompts(created_at DESC);
```

---

## File Structure (MVP)

```
noa/
├── README.md
├── PLAN.md
├── TODO.md
├── FUTURE.md
├── BUGS.md
│
├── web/                          # Next.js web application
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   ├── .env.local
│   │
│   ├── app/
│   │   ├── layout.tsx            # Root layout
│   │   ├── page.tsx              # Landing page
│   │   ├── globals.css
│   │   │
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx
│   │   │   └── signup/page.tsx
│   │   │
│   │   ├── dashboard/
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx          # Main dashboard
│   │   │   ├── history/page.tsx  # Prompt history
│   │   │   └── settings/page.tsx
│   │   │
│   │   └── api/
│   │       ├── auth/
│   │       │   └── [...supabase]/route.ts
│   │       ├── prompts/
│   │       │   └── route.ts      # GET & POST prompts
│   │       └── process/
│   │           └── route.ts      # Process voice + screen
│   │
│   ├── components/
│   │   ├── ui/                   # Reusable UI components
│   │   ├── landing/              # Landing page components
│   │   └── dashboard/            # Dashboard components
│   │
│   └── lib/
│       ├── supabase.ts           # Supabase client
│       ├── openai.ts             # OpenAI client
│       └── utils.ts
│
└── desktop/                      # Swift macOS application
    ├── noa.xcodeproj
    └── noa/
        ├── NoaApp.swift          # App entry point
        ├── ContentView.swift     # Main overlay view
        ├── AudioRecorder.swift   # Microphone handling
        ├── ScreenCapture.swift   # Screenshot functionality
        ├── HotkeyManager.swift   # Fn key detection
        ├── APIClient.swift       # Backend communication
        └── Assets.xcassets
```

---

## MVP Development Phases

### Phase 1: Project Setup
- [ ] Initialize Next.js project with TypeScript
- [ ] Set up Tailwind CSS
- [ ] Create Supabase project
- [ ] Set up environment variables
- [ ] Create basic file structure

### Phase 2: Web - Landing Page
- [ ] Design landing page layout
- [ ] Build hero section
- [ ] Build features section
- [ ] Build CTA section
- [ ] Add navigation

### Phase 3: Web - Authentication
- [ ] Set up Supabase Auth
- [ ] Build login page
- [ ] Build signup page
- [ ] Implement auth middleware
- [ ] Protected routes for dashboard

### Phase 4: Web - Dashboard
- [ ] Dashboard layout with sidebar
- [ ] Prompt history page (list view)
- [ ] Settings page (basic)
- [ ] Connect to Supabase for data

### Phase 5: Backend - API Routes
- [ ] POST /api/prompts - Save prompt
- [ ] GET /api/prompts - Get history
- [ ] POST /api/process - Process request
- [ ] OpenAI integration (GPT-4)
- [ ] Whisper API integration (if needed server-side)

### Phase 6: Desktop - macOS App
- [ ] Create Xcode project
- [ ] Build overlay UI (oval shape)
- [ ] Implement Fn key detection
- [ ] Implement microphone recording
- [ ] Implement screen capture
- [ ] Send audio to Whisper API
- [ ] Send text to backend
- [ ] Display response in overlay

### Phase 7: Integration & Polish
- [ ] Connect desktop app to backend
- [ ] Test full flow end-to-end
- [ ] Error handling
- [ ] Loading states
- [ ] Polish UI/UX

---

## API Endpoints (MVP)

### Authentication (Supabase handles)
- `POST /auth/signup` - Create account
- `POST /auth/login` - Sign in
- `POST /auth/logout` - Sign out

### Prompts
```
POST /api/prompts
Body: { text: string, response: string, screenshot_url?: string }
Returns: { id, text, response, screenshot_url, created_at }

GET /api/prompts
Query: ?limit=50&offset=0
Returns: { prompts: [...], total: number }
```

### Process (Main endpoint for desktop app)
```
POST /api/process
Body: { 
  text: string,           // Transcribed voice input
  screenshot?: string     // Base64 encoded image (optional)
}
Returns: { 
  response: string,       // AI response
  prompt_id: string       // Saved prompt ID
}
```

---

## Future Integrations (Post-MVP)

Once the skeleton is working, we'll add these one by one:

1. **Google Calendar** - "What's on my calendar?"
2. **Gmail** - "Do I have important emails?"
3. **Outlook** - Email and calendar
4. **Slack** - "Who should I respond to?"
5. **Google Drive** - "What did I last edit?"
6. **Actions** - Actually send emails, schedule meetings
7. **Text-to-Speech** - Voice responses
8. **Windows App** - Cross-platform support

---

## Notes

- Using Supabase for auth simplifies a lot of the backend complexity
- Swift for macOS gives us the best integration for hotkeys, screen capture, and system-level access
- Keeping web and API in the same Next.js project reduces complexity for MVP
- GPT-4 Vision handles both text responses and screen analysis
