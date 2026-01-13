# Caption Extraction Debug Guide

## Current Status ✅

**All videos have captions!** The script confirmed 100% of videos have English captions available.

## Problem

The app still shows: "This video doesn't have captions" - but we know they exist!

## Root Cause

The issue is in the **caption downloading process**, not the videos themselves.

## Common Reasons & Solutions

### 1. Network Timeout ⏱️

**Symptom:** "Caption fetch timed out"

**Solution:** 
- Increased timeout from 15s → 30s in skill_quiz_screen.dart
- Try on better network connection
- Check if device has stable internet

### 2. YouTube Rate Limiting 🚫

**Symptom:** Multiple caption fetches fail in short time

**Solution:**
- Wait a few minutes between quiz attempts
- YouTube may be rate-limiting requests
- Try again after 5-10 minutes

### 3. YouTube API Changes 🔄

**Symptom:** Sudden failures across all videos

**Solution:**
```bash
flutter pub upgrade youtube_explode_dart
```

### 4. Device Network Issues 📱

**Symptom:** Works on one device, fails on another

**Solution:**
- Check firewall settings
- Try on different network (WiFi vs Mobile data)
- Disable VPN if active

## Debugging Steps

### Step 1: Check Console Output

When you try to generate a quiz, watch for these logs:

✅ **Success Pattern:**
```
🎬 Attempting to extract transcript...
🎬 Video ID: VPvVD8t02U8
📡 Calling YouTube API for captions manifest...
📋 SUCCESS! Found 5 caption tracks
✅ Found English captions
✅ Transcript extracted: 15432 characters
```

❌ **Failure Pattern:**
```
🎬 Attempting to extract transcript...
🎬 Video ID: VPvVD8t02U8
❌ ========================================
❌ CAPTION EXTRACTION FAILED
❌ Video ID: VPvVD8t02U8
❌ Error Type: TimeoutException
❌ Error Message: Caption fetch timed out
❌ ========================================
```

### Step 2: Test Different Videos

Try quizzes for different skills:
1. **Flutter** - Has auto-generated captions (simpler)
2. **Python** - Has 45 caption tracks (more complex)
3. **SQL** - Has manual captions (better quality)

If some work and others don't → specific video issue
If all fail → network/API issue

### Step 3: Test Network Speed

Run this in your app's console:
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivity = await Connectivity().checkConnectivity();
print('Network: $connectivity');
```

### Step 4: Check youtube_explode_dart Version

In pubspec.yaml:
```yaml
dependencies:
  youtube_explode_dart: ^2.0.4  # Make sure this is latest
```

Update if needed:
```bash
flutter pub upgrade youtube_explode_dart
flutter pub get
```

## Enhanced Error Logging

I've updated the code to show detailed errors:
- Video ID being processed
- Error type (TimeoutException, SocketException, etc.)
- Full error message
- Stack trace for debugging

## Testing Instructions

1. **Clear app cache:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run app with verbose logging:**
   ```bash
   flutter run --verbose
   ```

3. **Navigate to a video and try to take quiz**

4. **Check console output for:**
   ```
   ❌ CAPTION EXTRACTION FAILED
   ❌ Error Type: [LOOK FOR THIS]
   ```

## Expected Error Types

### TimeoutException
- **Cause:** Network too slow or YouTube API slow
- **Fix:** Better internet, increase timeout further

### SocketException
- **Cause:** No internet connection
- **Fix:** Check network connection

### VideoUnplayableException
- **Cause:** Video restricted or removed
- **Fix:** Replace video in database

### HttpException
- **Cause:** YouTube API error or rate limit
- **Fix:** Wait and try again

## Next Steps

1. ✅ **Run your app**
2. ✅ **Try to generate a quiz** (pick any video)
3. ✅ **Check console logs** for the error pattern
4. ✅ **Share the error details** (Error Type and Message)

Then we can fix the specific issue!

## Quick Test

Try this simple test:

1. Go to a video page in your app
2. Click "Take Quiz"
3. Look at console/logs
4. If you see:
   - "📋 SUCCESS!" → Captions downloaded ✅
   - "❌ CAPTION EXTRACTION FAILED" → See error type ❌

**Report back with:**
- Which video you tested
- Error type (from logs)
- Your network type (WiFi/Mobile)

---

**Remember:** The videos have captions (we proved this). Now we need to find why the app can't download them.
