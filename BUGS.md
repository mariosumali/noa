# Bug Tracker

## Known Issues

### Desktop App
- **Screen Recording Permission** — macOS prompts for screen recording permission on every build during development. This is due to code signing changes between builds. Workaround: Disable screen capture for development, re-enable for production builds with proper signing.

- **Layout Warning** — `_NSDetectedLayoutRecursion` warning appears in console. This is a SwiftUI layout issue that doesn't affect functionality.

### Web App
- None currently reported

### API
- None currently reported

---

## Fixed Issues

### Desktop App
- ✅ Audio format crash — Fixed by using m4a/AAC format instead of converting to WAV
- ✅ API calls hanging — Fixed by removing app sandbox restrictions
- ✅ Config file not loading — Fixed by using hardcoded fallbacks + ~/.noa_config
- ✅ Overlay position incorrect — Fixed by using proper window positioning with Spacer
- ✅ Response text cut off — Fixed by using separate response panel above pill

### Web App
- ✅ Google OAuth redirect — Fixed by configuring correct callback URL in Supabase
- ✅ Login not working from desktop — Fixed by adding /api/auth/login endpoint

### API
- ✅ Prompts not saving — Fixed by allowing nullable user_id and adding device_id tracking

---

## Reporting Bugs

Please open an issue on GitHub with:
1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. macOS version / browser
5. Console logs if applicable
