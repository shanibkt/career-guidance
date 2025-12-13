# Firebase Crashlytics Verification Guide

## Current Status
✅ Firebase Core initialized
✅ google-services.json configured
✅ Gradle plugins added
✅ Code setup complete

## Why Crashlytics Data Isn't Showing

### Common Reasons:
1. **Crashlytics not enabled in Firebase Console** ⚠️ MOST COMMON
2. No crashes have occurred yet
3. Data sync delay (5-15 minutes)
4. Debug mode filters crash reports

## Steps to Enable & Verify Crashlytics

### Step 1: Enable Crashlytics in Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project: **career-guidence-cfa73**
3. In the left sidebar, click **Build** → **Crashlytics**
4. Click **"Enable Crashlytics"** or **"Get Started"** if you see it
5. Wait for initialization (may take a few minutes)

### Step 2: Trigger a Test Crash
The app needs to send crash data before anything appears in the console.

**Option A: Add Test Button (Recommended)**
Add this to your home screen or profile screen temporarily:

```dart
// In your build method, add this button:
if (kDebugMode)
  ElevatedButton(
    onPressed: () {
      FirebaseCrashlytics.instance.crash();
    },
    child: const Text('Test Crash'),
  ),
```

**Option B: Use CrashlyticsService**
```dart
import 'package:career_guidence/core/services/crashlytics_service.dart';

// Log an error
CrashlyticsService.recordError(
  Exception('Test error from app'),
  StackTrace.current,
  reason: 'Testing Crashlytics connection',
);

// Log custom message
CrashlyticsService.log('Testing Firebase Crashlytics integration');
```

### Step 3: Force Upload Crash Reports
In debug mode, crashes are sometimes held locally. To force upload:

```bash
# Stop the app
# Then restart it normally
flutter run
```

### Step 4: Check Firebase Console
1. Open https://console.firebase.google.com/
2. Go to your project → Crashlytics
3. Wait 5-15 minutes for data to sync
4. You should see crash reports appear

## Verification Checklist

- [ ] Firebase Crashlytics enabled in Firebase Console
- [ ] App ran at least once after enabling
- [ ] Test crash triggered (if using Option A or B)
- [ ] Waited 10-15 minutes
- [ ] Checked Firebase Console → Crashlytics dashboard
- [ ] Verified app package name matches: `com.example.career_guidence`

## Expected Firebase Console View

When working correctly, you'll see:
- **Crash-free users percentage** (e.g., 95%)
- **Issue list** with crash details
- **Stack traces** for each crash
- **Affected users count**
- **Breadcrumbs** (logs leading to crash)

## Debug Logs to Verify

When Crashlytics is working, you should see logs like:
```
I/FirebaseCrashlytics: Crashlytics report upload has completed
D/FirebaseCrashlytics: Crash reporting enabled for com.example.career_guidence
```

## Current Implementation

Your app already has:
✅ Automatic crash capture (FlutterError.onError)
✅ Async error capture (PlatformDispatcher.onError)
✅ Zone error capture (runZonedGuarded)
✅ CrashlyticsService wrapper for manual logging

## Next Steps

1. **Enable Crashlytics in Firebase Console** (if not already enabled)
2. Run the app and navigate through different screens
3. Trigger a test crash using one of the methods above
4. Wait 10-15 minutes
5. Check Firebase Console → Crashlytics

## Troubleshooting

### If still not showing data:

**Check Firebase Project Settings:**
```
Firebase Console → Project Settings → General
- Verify Project ID: career-guidence-cfa73
- Verify package name: com.example.career_guidence
- Check if Crashlytics SDK is listed under "Your apps"
```

**Verify Gradle Build:**
```bash
cd android
./gradlew app:dependencies | findstr crashlytics
```

Should show:
```
+--- com.google.firebase:firebase-crashlytics:XX.X.X
```

**Check AndroidManifest.xml:**
```bash
# Ensure internet permission exists
<uses-permission android:name="android.permission.INTERNET" />
```

## Manual Test Script

Add this to main.dart temporarily for testing:

```dart
// After Firebase.initializeApp()
if (kDebugMode) {
  // Test Crashlytics is working
  FirebaseCrashlytics.instance.log('App started - Crashlytics test');
  
  // Force enable collection in debug mode
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  print('🔥 Firebase Crashlytics initialized');
  print('🔥 Collection enabled: ${FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled}');
}
```

## Contact Support

If issues persist after following all steps:
1. Check Firebase Status: https://status.firebase.google.com/
2. Review Firebase docs: https://firebase.google.com/docs/crashlytics
3. Verify all services are enabled in Google Cloud Console
