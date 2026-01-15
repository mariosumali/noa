# noa

**noa** is a personal AI voice assistant for macOS, created by Mario Sumali.

Hold **Option (⌥)** to speak, get instant AI-powered answers displayed in a sleek overlay.

![noa demo](https://img.shields.io/badge/status-beta-blue)

## Features

### Desktop App (macOS)
- 🎤 **Voice-activated** — Hold Option key to speak
- 💬 **AI responses** — Powered by GPT-4
- 🖥️ **Minimal UI** — Tiny pill overlay that expands for responses
- 📋 **Menu bar app** — Quick access to history, settings, account
- 🔐 **Account sync** — Login to sync prompts across devices

### Web Dashboard
- 📊 **Prompt history** — View all your past queries grouped by date
- ⚙️ **Settings** — Manage your account and preferences
- 🎨 **Clean UI** — Wispr Flow-inspired minimal design

## Quick Start

### Prerequisites
- macOS 13.0+
- Node.js 18+
- OpenAI API key
- Supabase account

### 1. Clone the repo
```bash
git clone https://github.com/mariosumali/noa.git
cd noa
```

### 2. Set up the web backend
```bash
cd web
npm install
cp .env.example .env.local
# Edit .env.local with your Supabase and OpenAI keys
npm run dev
```

### 3. Set up the desktop app
```bash
# Create config file
echo "OPENAI_API_KEY=your_key_here
BACKEND_URL=http://localhost:3000" > ~/.noa_config

# Open in Xcode
open desktop/noa.xcodeproj
# Build and run (⌘R)
```

### 4. Use noa
- Look for the **waveform icon** in your menu bar
- Hold **Option (⌥)** and speak
- Release to get your answer

## Tech Stack

| Component | Technology |
|-----------|------------|
| Desktop App | Swift / SwiftUI |
| Web App | Next.js 14, React, Tailwind CSS |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| AI | OpenAI GPT-4, Whisper |
| Hosting | Vercel |

## Project Structure

```
noa/
├── web/                 # Next.js web application
│   ├── app/            # App router pages
│   ├── components/     # React components
│   └── lib/            # Utilities and clients
│
├── desktop/            # Swift macOS application
│   └── noa/           # Source files
│
├── README.md           # This file
├── PLAN.md            # Architecture and design
├── TODO.md            # Task tracking
├── FUTURE.md          # Future features
└── BUGS.md            # Bug tracking
```

## Documentation

- [PLAN.md](./PLAN.md) — Architecture and technical decisions
- [TODO.md](./TODO.md) — Development progress
- [FUTURE.md](./FUTURE.md) — Planned features
- [BUGS.md](./BUGS.md) — Known issues

## Status

✅ **Beta** — Core functionality complete, actively developing

## License

MIT © Mario Sumali
