# Project Plan: noa

## Overview

**noa** is a personal AI voice assistant for macOS, created by Mario Sumali. It combines a native desktop application (voice-activated overlay) with a web dashboard (settings & history) to help users interact with AI through natural language.

---

## Current Status: ✅ Beta

The MVP is complete and functional:
- Desktop app with voice input and AI responses
- Web dashboard with Wispr Flow-inspired UI
- Full authentication flow
- Prompt history persistence

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           USER                                   │
└─────────────────────────────────────────────────────────────────┘
                    │                           │
        [Hold ⌥ + Speak]                [Browser]
                    │                           │
                    ▼                           ▼
┌─────────────────────────────┐   ┌─────────────────────────────┐
│  Desktop App (macOS/Swift)  │   │    Web App (Next.js)        │
│  ─────────────────────────  │   │    ─────────────────────    │
│  • Menu bar app             │   │    • Landing page           │
│  • Tiny pill overlay        │   │    • Auth (login/signup)    │
│  • Option key activation    │   │    • Dashboard              │
│  • Whisper transcription    │   │    • Prompt history         │
│  • Response panel           │   │    • Settings               │
│  • Login/Settings/History   │   │                             │
└─────────────────────────────┘   └─────────────────────────────┘
                    │                           │
                    └───────────┬───────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend (Next.js API Routes)                 │
│  ───────────────────────────────────────────────────────────    │
│  • POST /api/auth/login      (authenticate user)                 │
│  • POST /api/auth/signup     (create account)                    │
│  • POST /api/process         (AI processing)                     │
│  • GET  /api/prompts         (get history)                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
        │   Whisper   │ │   GPT-4     │ │  Supabase   │
        │   (STT)     │ │   (LLM)     │ │   (DB)      │
        └─────────────┘ └─────────────┘ └─────────────┘
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Desktop App** | Swift / SwiftUI (native macOS) |
| **Web App** | Next.js 14, React 18, Tailwind CSS |
| **Backend** | Next.js API Routes |
| **Database** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth (email + Google OAuth) |
| **Speech-to-Text** | OpenAI Whisper API |
| **LLM** | OpenAI GPT-4 |
| **Hosting** | Vercel |

---

## Database Schema

```sql
-- Prompts table
CREATE TABLE prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT,                    -- For anonymous/device tracking
  text TEXT NOT NULL,                -- User's spoken text
  response TEXT,                     -- AI response
  screenshot_url TEXT,               -- Screen capture (if used)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX prompts_user_id_idx ON prompts(user_id);
CREATE INDEX prompts_device_id_idx ON prompts(device_id);
CREATE INDEX prompts_created_at_idx ON prompts(created_at DESC);
```

---

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with email/password |
| POST | `/api/auth/signup` | Create new account |
| POST | `/api/auth/set-password` | Set password for Google OAuth users |

### Processing
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/process` | Process voice text, return AI response |

**Request:**
```json
{
  "text": "What is the meaning of life?",
  "device_id": "mac_ABC123",
  "user_id": "optional-uuid",
  "screenshot": "optional-base64"
}
```

**Response:**
```json
{
  "response": "The meaning of life is...",
  "prompt_id": "uuid"
}
```

### Prompts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/prompts?device_id=X` | Get prompt history |
| POST | `/api/prompts` | Save a prompt (internal) |

---

## File Structure

```
noa/
├── README.md              # Project overview
├── PLAN.md               # This file
├── TODO.md               # Task tracking
├── FUTURE.md             # Future features
├── BUGS.md               # Bug tracking
│
├── web/                  # Next.js web application
│   ├── app/
│   │   ├── page.tsx                 # Landing page
│   │   ├── layout.tsx               # Root layout
│   │   ├── globals.css              # Global styles
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx
│   │   │   ├── signup/page.tsx
│   │   │   └── actions.ts
│   │   ├── dashboard/
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx             # Home (history)
│   │   │   ├── history/page.tsx
│   │   │   └── settings/page.tsx
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   │   ├── login/route.ts
│   │   │   │   └── signup/route.ts
│   │   │   ├── process/route.ts
│   │   │   ├── prompts/route.ts
│   │   │   ├── auth/
│   │   │   │   ├── login/route.ts
│   │   │   │   ├── signup/route.ts
│   │   │   │   └── set-password/route.ts
│   │   │   └── integrations/
│   │   │       └── gmail/
│   │   └── auth/callback/route.ts
│   │
│   ├── components/
│   │   ├── landing/                 # Landing page sections
│   │   └── dashboard/
│   │       └── Sidebar.tsx
│   │
│   ├── lib/
│   │   ├── supabase.ts              # Supabase clients
│   │   ├── supabase-server.ts
│   │   ├── supabase-browser.ts
│   │   ├── openai.ts                # OpenAI functions
│   │   └── utils.ts
│   │
│   └── hooks/
│       └── useAuth.ts
│
└── desktop/              # Swift macOS application
    └── noa/
        ├── NoaApp.swift             # App entry, menu bar
        ├── AppState.swift           # State management
        ├── OverlayWindow.swift      # Window positioning
        ├── OverlayView.swift        # Pill + response UI
        ├── HotkeyManager.swift      # Option key detection
        ├── AudioRecorder.swift      # Microphone recording
        ├── ScreenCapture.swift      # Screen capture (disabled)
        ├── APIClient.swift          # Backend + Whisper API
        ├── Config.swift             # Load ~/.noa_config
        ├── AuthManager.swift        # User authentication
        ├── MenuBarView.swift        # Menu bar popover
        ├── LoginView.swift          # Login window
        ├── SettingsView.swift       # Settings window
        ├── HistoryView.swift        # History window
        ├── Info.plist
        └── noa.entitlements
```

---

## Data Flow

1. **User holds Option key** → Desktop app starts recording
2. **User speaks** → Audio captured as m4a
3. **User releases key** → Audio sent to Whisper API → Text returned
4. **Text sent to backend** `/api/process` with device_id
5. **Backend calls GPT-4** → Response generated
6. **Response saved** to Supabase with device/user tracking
7. **Response returned** → Displayed in overlay panel
8. **History synced** → Available in web dashboard

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Activation | Option key (⌥) | Less conflict than Fn, works globally |
| Audio format | m4a (AAC) | Native to macOS, Whisper compatible |
| UI style | Wispr Flow | Clean, minimal, professional |
| Prompt tracking | device_id | Works without login, can link later |
| Menu bar | Yes | Easy access without dock clutter |
| Response display | Panel above pill | No text cutoff, clear separation |

---

## Future Plans

See [FUTURE.md](./FUTURE.md) for detailed roadmap including:
- Text-to-speech responses
- Calendar/email integrations
- Windows/mobile apps
- Local LLM option
