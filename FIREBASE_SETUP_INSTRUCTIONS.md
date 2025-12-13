# Firebase Crashlytics Setup Instructions

## Current Status
✅ Dependencies added (firebase_core, firebase_crashlytics)
✅ Android Gradle configuration complete
✅ Main.dart initialization code added
❌ **Missing: google-services.json file**

## Steps to Complete Setup

### Step 1: Create/Access Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard (you can disable Google Analytics if you want)

### Step 2: Register Your Android App
1. In the Firebase Console, click the Android icon to add an Android app
2. Enter the Android package name: **`com.example.career_guidence`**
3. App nickname (optional): Career Guidance
4. Click "Register app"

### Step 3: Download google-services.json
1. Download the `google-services.json` file
2. Move this file to: **`android/app/google-services.json`**
   - Full path: `c:\Users\Dell\Desktop\Career guidence\career_guidence\android\app\google-services.json`

### Step 4: Enable Crashlytics in Firebase Console
1. In Firebase Console, go to "Crashlytics" in the left menu
2. Click "Enable Crashlytics"
3. Follow the setup steps (most are already done in the code)

### Step 5: Test the Integration
Run your app once to initialize Firebase:
```powershell
flutter run
```

### Step 6: Force a Test Crash (Optional)
Add this code temporarily to test crash reporting:
```dart
// Add this button somewhere in your UI
ElevatedButton(
  onPressed: () {
    FirebaseCrashlytics.instance.crash(); // Force crash for testing
  },
  child: Text('Test Crash'),
),
```

## Troubleshooting

### If you see "MissingPluginException"
Run:
```powershell
flutter clean
flutter pub get
```

### If you see "Default FirebaseApp is not initialized"
Make sure `google-services.json` is in the correct location.

### To verify the file is in the right place
Run:
```powershell
Test-Path "android\app\google-services.json"
```
It should return `True`.

## Quick Reference
- **Package Name**: com.example.career_guidence
- **File Location**: android/app/google-services.json
- **Firebase Console**: https://console.firebase.google.com/
