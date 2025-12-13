# Firebase Crashlytics Usage Examples

## Basic Usage

### 1. Recording Errors in Try-Catch Blocks

```dart
import 'package:career_guidence/core/services/crashlytics_service.dart';

// In any service or widget
Future<void> fetchUserData() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    // Process response...
  } catch (e, stackTrace) {
    // Record the error to Crashlytics
    await CrashlyticsService.recordError(e, stackTrace);
    
    // Optionally rethrow or handle the error
    rethrow;
  }
}
```

### 2. Recording API Errors with Context

```dart
Future<void> loginUser(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      body: json.encode({'email': email, 'password': password}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    // Record with API-specific context
    await CrashlyticsService.recordApiError(
      '/api/auth/login',
      response?.statusCode,
      e,
      stackTrace,
    );
    rethrow;
  }
}
```

### 3. Setting User Information (After Login)

```dart
// In your AuthProvider or LoginScreen after successful login
Future<void> onLoginSuccess(User user) async {
  // Set user ID for crash tracking
  await CrashlyticsService.setUserId(user.id.toString());
  
  // Add additional user context
  await CrashlyticsService.setCustomKeys({
    'user_email': user.email,
    'user_role': user.role ?? 'user',
    'account_created': user.createdAt.toString(),
  });
}

// On logout
Future<void> onLogout() async {
  await CrashlyticsService.clearUserId();
  // Clear auth tokens and navigate to login
}
```

### 4. Logging User Actions

```dart
// Log important user actions for debugging
void onCareerSelected(String careerName) {
  CrashlyticsService.logUserAction('career_selected', context: {
    'career_name': careerName,
    'timestamp': DateTime.now().toString(),
  });
  
  // Continue with career selection logic
}

void onQuizStarted(String quizType) {
  CrashlyticsService.log('User started quiz: $quizType');
}
```

### 5. Recording Specific Error Types

#### Authentication Errors
```dart
try {
  await authService.login(email, password);
} catch (e, stackTrace) {
  await CrashlyticsService.recordAuthError(
    'login',
    e,
    stackTrace,
  );
}
```

#### Database Errors
```dart
try {
  await database.saveCareerProgress(data);
} catch (e, stackTrace) {
  await CrashlyticsService.recordDatabaseError(
    'save_career_progress',
    e,
    stackTrace,
  );
}
```

#### Navigation Errors
```dart
try {
  Navigator.of(context).pushNamed('/profile');
} catch (e, stackTrace) {
  await CrashlyticsService.recordNavigationError(
    '/profile',
    e,
    stackTrace,
  );
}
```

## Advanced Usage

### 6. Adding Breadcrumbs Before Error

```dart
Future<void> complexOperation() async {
  CrashlyticsService.log('Starting complex operation');
  
  try {
    CrashlyticsService.log('Step 1: Fetching user data');
    final user = await fetchUser();
    
    CrashlyticsService.log('Step 2: Fetching career data');
    final career = await fetchCareer(user.id);
    
    CrashlyticsService.log('Step 3: Calculating recommendations');
    final recommendations = await calculateRecommendations(career);
    
    CrashlyticsService.log('Operation completed successfully');
    return recommendations;
  } catch (e, stackTrace) {
    // All the logs above will be included in the crash report
    await CrashlyticsService.recordError(e, stackTrace);
    rethrow;
  }
}
```

### 7. Custom Keys for Context

```dart
Future<void> submitQuiz(Quiz quiz) async {
  // Add context that will appear in crash reports
  await CrashlyticsService.setCustomKeys({
    'quiz_type': quiz.type,
    'question_count': quiz.questions.length,
    'user_score': quiz.score,
    'completion_time': quiz.completionTime.toString(),
  });
  
  try {
    await apiService.submitQuiz(quiz);
  } catch (e, stackTrace) {
    await CrashlyticsService.recordError(
      e,
      stackTrace,
      reason: 'Failed to submit quiz',
    );
  }
}
```

### 8. Testing Crashlytics (Debug Only)

```dart
// Add a test button in your settings screen (debug builds only)
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  ElevatedButton(
    onPressed: () {
      // This will force a crash for testing
      CrashlyticsService.forceCrash();
    },
    child: Text('Test Crash (Debug Only)'),
  );
}

// Or test non-fatal error
ElevatedButton(
  onPressed: () async {
    try {
      throw Exception('Test exception for Crashlytics');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test error sent to Crashlytics')),
      );
    }
  },
  child: Text('Test Non-Fatal Error'),
);
```

## Integration Examples

### In API Service Classes

```dart
class CareerService {
  Future<List<Career>> getCareers() async {
    CrashlyticsService.log('CareerService.getCareers() called');
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/careers'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load careers: ${response.statusCode}');
      }
      
      CrashlyticsService.log('Successfully loaded ${careers.length} careers');
      return careers;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordApiError(
        '/api/careers',
        response?.statusCode,
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
```

### In Provider Classes

```dart
class AuthProvider extends ChangeNotifier {
  Future<void> login(String email, String password) async {
    try {
      final user = await authService.login(email, password);
      
      // Set user info for crash tracking
      await CrashlyticsService.setUserId(user.id.toString());
      await CrashlyticsService.setCustomKey('user_email', user.email);
      
      CrashlyticsService.logUserAction('login_success');
      
      notifyListeners();
    } catch (e, stackTrace) {
      await CrashlyticsService.recordAuthError('login', e, stackTrace);
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> logout() async {
    CrashlyticsService.logUserAction('logout');
    await CrashlyticsService.clearUserId();
    // Clear tokens and navigate...
  }
}
```

### In Screens/Widgets

```dart
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    CrashlyticsService.log('HomeScreen: Loading data');
    
    try {
      final data = await apiService.getData();
      setState(() {
        _data = data;
      });
      CrashlyticsService.log('HomeScreen: Data loaded successfully');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load home screen data',
      );
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data')),
        );
      }
    }
  }
}
```

## Best Practices

### ✅ DO:
- Record all caught exceptions that might help debugging
- Add custom keys for important context
- Log user actions that lead to errors
- Set user ID after login for better tracking
- Clear user ID on logout
- Use meaningful log messages

### ❌ DON'T:
- Log sensitive information (passwords, tokens, personal data)
- Log every single user action (creates noise)
- Force crashes in production builds
- Record errors for expected behavior (404 on optional data)
- Forget to clear user ID on logout

## Viewing Crashes

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Crashlytics** in left menu
4. View crashes by:
   - **Issue severity** (fatal vs non-fatal)
   - **Affected users**
   - **Occurrence frequency**
   - **App version**
   - **Device type**

## Monitoring Tips

- Set up email alerts for new crash types
- Check Crashlytics dashboard daily
- Filter by app version to identify version-specific issues
- Use custom keys to identify common patterns
- Track crash-free users percentage

## Support

- Check `FIREBASE_SETUP.md` for initial setup
- [Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [FlutterFire Crashlytics](https://firebase.flutter.dev/docs/crashlytics/overview)
