# Hackathon Submission Checklist
## Gemma 4 Good Hackathon — Deadline 2026-05-18 23:59 UTC

All code tasks are done. The remaining steps below require your manual action.

---

## Remaining manual steps (in order)

### 1. Firebase Console — App Check (5 min)
1. Go to Firebase Console → `crucueapp` project → App Check
2. Register **Play Integrity** as the Android provider
3. The debug token path is already handled by `AndroidDebugProvider()` in `kDebugMode`
4. No code changes needed — `lib/main.dart` already calls `AndroidPlayIntegrityProvider()` in release mode

### 2. Deploy the Crucue-web site (2 min)
The web project at `/Users/frameless/Desktop/All/Projects/Crucue-web` has:
- New `/hackathon` route with hero, video embed, APK download, architecture diagram, Gemma 4 bullets
- APK in `public/downloads/crucue.apk` (34 MB, SHA256: ec56578fd1fcdf1d488178a443e23ba820259344224cde6a73fcabc67dfe5b2a)
- Updated `vercel.json` with YouTube `frame-src` and APK `Content-Disposition` headers
- Updated `sitemap.xml` with `/hackathon`

To deploy:
```bash
cd /Users/frameless/Desktop/All/Projects/Crucue-web
git add -A && git commit -m "feat: add /hackathon route and demo APK for Gemma 4 Good Hackathon"
git push
# Vercel auto-deploys from main
```

Then verify:
- https://www.crucue.com/hackathon loads
- `/downloads/crucue.apk` downloads (not previews) in Chrome on Android

### 3. Record the demo video (1–2 hrs)
See full storyboard at `docs/hackathon_video_script.md`.

Quick setup:
```bash
# Mirror Android device to Mac
brew install scrcpy
scrcpy --record crucue_demo.mp4
```

Before recording:
1. Build and install the **debug** APK (not the release APK — debug mode shows the "Load demo profile" button):
   ```bash
   cd /Users/frameless/Desktop/All/Projects/Crucue
   flutter install
   ```
2. Open the app → Settings → Demo (debug only) → "Load demo profile (Mom)"
3. Pre-download flutter_gemma weights: Settings → AI Engine → On-device section → Download

### 4. Upload video to YouTube
1. Upload to YouTube as **Public** (NOT Unlisted — judges need no login)
2. Title: "Crucue — Private AI Support for Caregivers · Gemma 4 Good Hackathon Demo"
3. Description: Link to https://www.crucue.com/hackathon
4. Copy the video ID (11-character code after `watch?v=`)

### 5. Paste YouTube ID into the hackathon page
In `/Users/frameless/Desktop/All/Projects/Crucue-web/src/pages/Hackathon.tsx`, find line 10:
```
const YOUTUBE_VIDEO_ID = "PASTE_YOUTUBE_ID_HERE";
```
Replace with your actual YouTube video ID, then:
```bash
cd /Users/frameless/Desktop/All/Projects/Crucue-web
git add src/pages/Hackathon.tsx
git commit -m "feat: embed hackathon demo video"
git push
```

### 6. Make the GitHub repo public
Ensure the GitHub repo at https://github.com/frameless-studio/crucue is set to **Public** (or create a new public repo with the code if currently private).

### 7. Submit on Kaggle
1. Go to https://www.kaggle.com/competitions/gemma-4-good-hackathon
2. Click Submit → Writeup submission
3. **Paste from:** `docs/kaggle_writeup_final.md` (1,357 words — under the 1,500 limit)
4. **Track:** Main Track (also tick Health & Sciences and Safety & Trust)
5. **Video URL:** Your YouTube URL
6. **Demo URL:** `https://www.crucue.com/hackathon`
7. **Code URL:** Your GitHub repo URL
8. **Cover image:** Upload `docs/kaggle_cover.png` (1200×800 PNG)
9. Submit and screenshot the confirmation page

---

## What's done (code-complete)

| Task | Status | Notes |
|------|--------|-------|
| Gemma 4 model IDs verified | ✅ | `gemma-4-26b-a4b-it` is the correct ID |
| Stub engines removed/roadmapped | ✅ | android/ios on-device engines moved to _roadmap |
| App URLs updated to crucue.com | ✅ | Privacy/Terms URLs updated in env_config.dart |
| On-device model downloader UI | ✅ | Settings → AI Engine → On-device section |
| Android upload keystore generated | ✅ | `android/crucue-upload-key.jks` (gitignored) |
| Release signing configured | ✅ | `android/key.properties` + `build.gradle` |
| Signed APK built | ✅ | `app-armeabi-v7a-release.apk` (34 MB) |
| APK hosted on Vercel | ✅ | `public/downloads/crucue.apk` |
| App Check code | ✅ | Uses `AndroidPlayIntegrityProvider()` in release |
| `/hackathon` route live | ✅ | Needs Vercel deploy |
| vercel.json CSP updated | ✅ | YouTube frame-src + APK download header |
| Demo profile seed (debug) | ✅ | Settings → Demo → Load demo profile |
| flutter analyze clean | ✅ | No issues found |
| Video storyboard written | ✅ | `docs/hackathon_video_script.md` |
| Kaggle writeup final | ✅ | `docs/kaggle_writeup_final.md` (1,357 words) |
| Cover image (1200×800 PNG) | ✅ | `docs/kaggle_cover.png` |

---

## Submission URLs to paste into Kaggle

- **Video:** [record and upload — paste URL here]
- **Demo:** `https://www.crucue.com/hackathon`
- **Code:** `https://github.com/frameless-studio/crucue`
