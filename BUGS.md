# Bug Tracker

## Known Issues

### Desktop App

- **Screen Recording Permission (Development)** — macOS prompts for screen recording permission on every new build during Xcode development. This is because each build has a different code signature. 
  - **Workaround**: The app still works, just click "Allow" when prompted
  - **Proper fix**: Enroll in Apple Developer Program ($99/year) for stable code signing

- **Layout Warning** — `_NSDetectedLayoutRecursion` warning appears in console. This is a SwiftUI layout issue that doesn't affect functionality.

### Web App
- None currently reported

### API
- None currently reported

---

## Fixed Issues

### Desktop App
- ✅ **Audio format crash** — Fixed by using m4a/AAC format instead of converting to WAV
- ✅ **API calls hanging** — Fixed by removing app sandbox restrictions  
- ✅ **Config file not loading** — Fixed by using hardcoded fallbacks + ~/.noa_config
- ✅ **Overlay position incorrect** — Fixed by using proper window positioning
- ✅ **Response text cut off** — Fixed by using separate response panel above pill
- ✅ **APIClient singleton access** — Fixed by adding `AppState.shared` pattern
- ✅ **Property name mismatches** — Fixed `mode`→`uiMode`, `responseText`→`aiResponse`
- ✅ **Init order error** — Fixed by initializing deviceId before accessing APIClient

### Web App
- ✅ **Google OAuth redirect** — Fixed by configuring correct callback URL in Supabase
- ✅ **Login not working from desktop** — Fixed by adding /api/auth/login endpoint

### API
- ✅ **Prompts not saving** — Fixed by allowing nullable user_id and adding device_id tracking
- ✅ **GPT-4 Vision not working** — Fixed by using correct image_url content type

---

## Reporting Bugs

Please open an issue on GitHub with:
1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. macOS version / browser
5. Console logs if applicable
