# noa

**noa** is a personal AI voice assistant for macOS. Hold **Option (⌥)** to speak and receive instant responses in a minimal overlay.

![noa demo](https://img.shields.io/badge/status-beta-blue)

## Features

### Desktop App
- **Voice-Activated**: Global Option key hotkey for instant access.
- **Screen Awareness**: Visual context for queries like "What's on my screen?".
- **Minimal Interface**: Unobtrusive overlay that expands only when needed.
- **System Integration**: Menu bar access, clipboard operations, and native macOS feel.

### Web Dashboard
- **History**: Searchable archive of all voice interactions.
- **Integrations**: Connect external services like Gmail.
- **Settings**: Manage account preferences and device synchronization.

## Quick Start

### Prerequisites
- macOS 13.0+
- Node.js 18+
- OpenAI API key
- Supabase account
- Google Cloud Project (for Gmail)

### Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/mariosumali/noa.git
   cd noa
   ```

2. **Setup Backend**
   ```bash
   cd web
   npm install
   cp .env.example .env.local
   # Configure Supabase, OpenAI, and Google credentials
   npm run dev
   ```

3. **Setup Desktop App**
   ```bash
   # Create local config
   echo "OPENAI_API_KEY=your_key_here
   BACKEND_URL=http://localhost:3000" > ~/.noa_config

   # Open workspace
   open desktop/noa.xcodeproj
   # Build and Run (Cmd+R)
   ```

## Usage

1. Launch `noa` from Xcode or the Applications folder.
2. Hold **Option (⌥)** to activate the microphone.
3. Speak your query (e.g., "Summarize this email" or "What's on my screen?").
4. Release the key to process.

**Screen Capture Triggers**:
- "What's on my screen?"
- "Explain this"
- "Read this text"

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Core** | Swift, SwiftUI, ScreenCaptureKit |
| **Web/API** | Next.js 14, React, TypeScript |
| **Database** | Supabase (PostgreSQL) |
| **AI** | GPT-4o, GPT-4 Vision, Whisper |
| **Integrations** | Gmail API, Google OAuth |

## Project Structure

- `web/`: Next.js frontend and API backend.
- `desktop/`: Native Swift macOS application.
- `docs/`: Technical documentation and planning files.

## License

MIT © Mario Sumali
