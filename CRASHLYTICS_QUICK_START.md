# ✅ Firebase Crashlytics - Quick Reference

## What's Done

### 1. Packages Installed ✅
- `firebase_core: ^3.8.1`
- `firebase_crashlytics: ^4.2.0`
- `firebase_analytics: ^11.3.5`

### 2. Code Updated ✅
- **main.dart**: Firebase initialized, crash handlers configured
- **CrashlyticsService**: Wrapper service created for easy usage
- **AuthErrorHandler**: Integrated with Crashlytics logging

### 3. Features Implemented ✅
- ✅ Automatic crash reporting (fatal errors)
- ✅ Non-fatal error tracking
- ✅ User identification support
- ✅ Custom logging and breadcrumbs
- ✅ Custom key-value pairs
- ✅ API error tracking
- ✅ Auth error tracking
- ✅ Navigation error tracking

## What You Need to Do

### Step 1: Firebase Console Setup (5 minutes)
1. Go to https://console.firebase.google.com/
2. Create new project: "career-guidance"
3. Add Android app:
   - Package name: `com.example.career_guidence`
   - Download `google-services.json`
4. Enable Crashlytics in Firebase Console

### Step 2: Add google-services.json
```
Place file here:
career_guidence/
└── android/
    └── app/
        └── google-services.json  ← PUT FILE HERE
```

### Step 3: Update android/build.gradle
Add these lines in dependencies section:
```gradle
classpath 'com.google.gms:google-services:4.4.2'
classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
```

### Step 4: Update android/app/build.gradle
Add at top (after plugins):
```gradle
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

### Step 5: Test
```bash
flutter clean
flutter run
```

## Quick Usage

### Record an Error
```dart
import 'package:career_guidence/core/services/crashlytics_service.dart';

try {
  // Your code
} catch (e, stackTrace) {
  await CrashlyticsService.recordError(e, stackTrace);
}
```

### Set User Info (After Login)
```dart
await CrashlyticsService.setUserId(user.id.toString());
await CrashlyticsService.setCustomKey('user_email', user.email);
```

### Log Events
```dart
CrashlyticsService.log('User started quiz');
CrashlyticsService.logUserAction('career_selected', context: {'career': 'Android Developer'});
```

## Documentation Files
- 📘 **FIREBASE_SETUP.md** - Complete Firebase setup guide
- 📗 **CRASHLYTICS_USAGE.md** - Code examples and best practices
- 📕 **This file** - Quick reference

## Verification
After setup, crashes will appear in Firebase Console → Crashlytics (may take 5-15 minutes).

## Need Help?
Check FIREBASE_SETUP.md for troubleshooting and detailed instructions.
