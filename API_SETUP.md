# API Connection Setup Guide

## Current Issue
The app is not fetching data from the backend API. This guide will help you fix it.

## Quick Fix Steps

### 1. Find Your PC's IP Address

**Windows:**
```powershell
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter (e.g., `192.168.1.35`)

**Mac/Linux:**
```bash
ifconfig
```
Look for your network interface IP address

### 2. Update the API URL

Open: `lib/core/constants/api_constants.dart`

Update line 5 with your PC's IP:
```dart
static const String baseUrl = 'http://YOUR_PC_IP:5001';
```

Example:
```dart
static const String baseUrl = 'http://192.168.1.35:5001';
```

### 3. Start Your Backend Server

Make sure your backend is running on port 5001:
```bash
cd backend
npm start
# or
node server.js
```

### 4. Test Connection

Run the app and check the console logs:
```bash
flutter run -t lib/main_new.dart
```

Look for network diagnostics output:
```
🔧 NETWORK DIAGNOSTICS
📱 Device Network Info: ...
🔗 Backend URL: http://192.168.1.35:5001
🔍 Testing backend connection...
✅ Backend is reachable!
```

## Troubleshooting

### ❌ "Connection refused"
- Backend server is not running
- Start your backend: `npm start` or `node server.js`

### ❌ "Connection timeout"
- Wrong IP address in `api_constants.dart`
- Update with correct PC IP from `ipconfig`

### ❌ "No route to host"
- Phone and PC not on same WiFi network
- Connect both to the same WiFi

### ❌ "Firewall blocking"
- Windows Firewall may block port 5001
- Allow Node.js through firewall or temporarily disable it

## Network Requirements

✅ **PC and device must be on the same WiFi network**

For **Android Emulator:**
- Use PC's actual IP (not `localhost` or `127.0.0.1`)
- DO NOT use `10.0.2.2` - that won't work for backend on PC

For **Physical Device:**
- Use PC's actual IP address
- Both on same WiFi network

## Backend Health Check

Test if backend is accessible:
```bash
# From PC browser
http://192.168.1.35:5001/api/health

# Should return: 200 OK
```

## Current Configuration

- **Base URL:** `http://192.168.1.35:5001`
- **All services centralized** in `ApiConstants`
- **Auto-diagnostics** run on app startup

## Files Modified

1. `lib/core/constants/api_constants.dart` - Centralized API config
2. `lib/services/api/auth_service.dart` - Uses ApiConstants
3. `lib/services/api/profile_service.dart` - Uses ApiConstants  
4. `lib/core/utils/network_helper.dart` - Diagnostic tools
5. `lib/main_new.dart` - Runs diagnostics on startup

## Next Steps

1. Update IP in `api_constants.dart`
2. Start backend server
3. Run app: `flutter run -t lib/main_new.dart`
4. Check console for diagnostic output
5. Test login/signup

If issues persist, check the console logs for detailed error messages.
