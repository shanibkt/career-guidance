# Firebase Crashlytics Setup Guide

## Prerequisites
- Google Account
- Android Studio installed
- Flutter project ready

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `career-guidance` (or your preferred name)
4. **Disable Google Analytics** (optional, or enable if you want analytics)
5. Click **"Create project"**
6. Wait for project creation to complete

## Step 2: Add Android App to Firebase

1. In Firebase Console, click **"Add app"** and select **Android**
2. **Android package name**: `com.example.career_guidence`
   - Find this in: `android/app/build.gradle` → `applicationId`
3. **App nickname** (optional): `Career Guidance`
4. **Debug signing certificate SHA-1** (optional for now)
5. Click **"Register app"**

## Step 3: Download google-services.json

1. Download the `google-services.json` file
2. **IMPORTANT**: Place it in `android/app/` directory
   ```
   career_guidence/
   └── android/
       └── app/
           └── google-services.json  ← Place here
   ```

## Step 4: Update Android Build Files

### 4.1 Update `android/build.gradle`

Open `android/build.gradle` and add:

```gradle
buildscript {
    ext.kotlin_version = '1.9.24'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.7.3'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        
        // ADD THIS LINE
        classpath 'com.google.gms:google-services:4.4.2'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
    }
}
```

### 4.2 Update `android/app/build.gradle`

Open `android/app/build.gradle` and add at the **TOP** (after `plugins {}`):

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// ADD THESE LINES
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

Also ensure minimum SDK version is 21+:

```gradle
android {
    defaultConfig {
        minSdk = 21  // Make sure this is at least 21
        targetSdk = flutter.targetSdkVersion
        // ...
    }
}
```

## Step 5: Install Flutter Packages

Run in terminal:

```bash
flutter pub get
```

## Step 6: Enable Crashlytics in Firebase Console

1. In Firebase Console, go to **Build** → **Crashlytics**
2. Click **"Enable Crashlytics"**
3. Follow the setup wizard (most steps already done above)

## Step 7: Test Crashlytics

### Option A: Force a Test Crash

Add this code temporarily to test:

```dart
// In any screen, add a button to test crash
ElevatedButton(
  onPressed: () {
    FirebaseCrashlytics.instance.crash();
  },
  child: Text('Test Crash'),
)
```

### Option B: Log Non-Fatal Error

```dart
try {
  throw Exception('Test exception from Flutter');
} catch (e, stackTrace) {
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
}
```

## Step 8: Run the App

1. Build and run:
   ```bash
   flutter run
   ```

2. Trigger a crash (if using test button)

3. Wait 3-5 minutes, then check Firebase Console → Crashlytics
   - First crash may take up to 15 minutes to appear

## Features Already Configured

✅ **Automatic crash reporting** - All uncaught errors are logged
✅ **Fatal error tracking** - Framework errors captured
✅ **Asynchronous error handling** - Background errors captured
✅ **User identification ready** - Can add user IDs later

## Optional: Add User Information

To track which user experienced a crash:

```dart
// After user logs in
FirebaseCrashlytics.instance.setUserIdentifier(userId.toString());

// Add custom keys
FirebaseCrashlytics.instance.setCustomKey('user_email', userEmail);
FirebaseCrashlytics.instance.setCustomKey('user_role', userRole);
```

## Optional: Add Custom Logs

```dart
FirebaseCrashlytics.instance.log('User performed search: $searchQuery');
```

## Troubleshooting

### Issue: "Default FirebaseApp is not initialized"
- Make sure `google-services.json` is in `android/app/`
- Clean and rebuild: `flutter clean && flutter run`

### Issue: No crashes appearing in console
- Wait 15 minutes for first crash
- Make sure app is in **release mode** for production crashes
- Check internet connection
- Verify Firebase project setup

### Issue: Build errors
- Update `minSdk` to 21+ in `android/app/build.gradle`
- Update Gradle version if needed
- Run `flutter clean`

## Testing in Release Mode

Crashlytics works best in release mode:

```bash
flutter build apk --release
flutter install
```

## Important Files Checklist

- ✅ `pubspec.yaml` - Firebase dependencies added
- ✅ `lib/main.dart` - Firebase initialized
- ⚠️ `android/app/google-services.json` - **YOU NEED TO ADD THIS**
- ⚠️ `android/build.gradle` - **UPDATE THIS**
- ⚠️ `android/app/build.gradle` - **UPDATE THIS**

## Next Steps

1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Update `android/build.gradle` with Google services plugin
4. Update `android/app/build.gradle` with apply plugins
5. Run `flutter pub get`
6. Run `flutter clean`
7. Run `flutter run`
8. Test crash reporting
9. Check Firebase Console after 5-15 minutes

## Production Best Practices

1. **Never commit** `google-services.json` to public repositories
2. Add to `.gitignore`: `android/app/google-services.json`
3. Enable ProGuard/R8 for obfuscation in release builds
4. Monitor Crashlytics dashboard regularly
5. Set up email alerts for new crash types
6. Use custom logs sparingly to avoid noise

## Support

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/crashlytics/overview)
- [Firebase Console](https://console.firebase.google.com/)
