# Import Migration Guide

## How to Update Your Imports

After restructuring, you need to update imports in existing files to point to the new locations. Here's how to systematically migrate:

### 1. Core Imports (New)

#### Old Way:
```dart
// Colors were scattered or hardcoded
Container(color: Color(0xFF6366F1))
```

#### New Way:
```dart
import 'package:career_guidence/core/constants/app_colors.dart';

Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

#### Validators Old vs New:
```dart
// Old: Inline validation
validator: (v) {
  if (v == null || v.isEmpty) return 'Email required';
  if (!v.contains('@')) return 'Invalid email';
  return null;
}

// New: Reusable validator
import 'package:career_guidence/core/utils/validators.dart';
validator: Validators.validateEmail,
```

### 2. Service Imports

#### Auth Service:
```dart
// Old
import 'package:career_guidence/services/auth_service.dart';

// New
import 'package:career_guidence/services/api/auth_service.dart';
```

#### Storage Service:
```dart
// Old
import 'package:career_guidence/services/storage_service.dart';

// New
import 'package:career_guidence/services/local/storage_service.dart';
```

#### Profile Service:
```dart
// Old
import 'package:career_guidence/services/profile_service.dart';

// New
import 'package:career_guidence/services/api/profile_service.dart';
```

### 3. Screen Imports

#### Auth Screens:
```dart
// Old
import 'package:career_guidence/screens/login.dart';
import 'package:career_guidence/screens/sinup.dart';
import 'package:career_guidence/screens/forgot_password.dart';

// New
import 'package:career_guidence/screens/auth/login_screen.dart';
import 'package:career_guidence/screens/auth/signup_screen.dart';
import 'package:career_guidence/screens/auth/forgot_password_screen.dart';
```

#### Profile Screens:
```dart
// Old
import 'package:career_guidence/screens/reg_profile.dart';
import 'package:career_guidence/screens/profile.dart';

// New
import 'package:career_guidence/screens/profile/reg_profile_screen.dart';
import 'package:career_guidence/screens/profile/profile_screen.dart';
```

#### Home Screen:
```dart
// Old
import 'package:career_guidence/screens/homescreen.dart';

// New
import 'package:career_guidence/screens/home/homescreen.dart';
```

### 4. Widget Imports (New)

```dart
// Profile widgets
import 'package:career_guidence/screens/profile/widgets/image_picker_widget.dart';
import 'package:career_guidence/screens/profile/widgets/profile_form_fields.dart';
```

### 5. Complete File Examples

#### Example: Updating login.dart → login_screen.dart

**Old imports:**
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'homescreen.dart';
import 'sinup.dart';
```

**New imports:**
```dart
import 'package:flutter/material.dart';
import '../../services/api/auth_service.dart';
import '../../services/local/storage_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../home/homescreen.dart';
import 'signup_screen.dart';
```

### 6. Path Depth Changes

**Important:** When moving files to subdirectories, the `../` depth changes:

```dart
// File at: lib/screens/login.dart
import '../services/auth_service.dart';  // Goes up 1 level

// File at: lib/screens/auth/login_screen.dart
import '../../services/api/auth_service.dart';  // Goes up 2 levels
```

### 7. Quick Find & Replace

Use VS Code's Find & Replace (Ctrl+Shift+H) to batch update:

**Find:** `import '../services/auth_service.dart';`  
**Replace:** `import '../../services/api/auth_service.dart';`

**Find:** `import '../services/storage_service.dart';`  
**Replace:** `import '../../services/local/storage_service.dart';`

**Find:** `import 'homescreen.dart';`  
**Replace:** `import '../home/homescreen.dart';`

### 8. Class Name Changes

Some classes are renamed for consistency:

| Old | New |
|-----|-----|
| `LoginPage` | `LoginScreen` |
| `SignUpScreen` | `SignupScreen` (already consistent) |
| `ForgotPasswordPage` | `ForgotPasswordScreen` |
| `ResetPasswordPage` | `ResetPasswordScreen` |
| `RegProfileScreen` | `RegProfileScreen` (no change) |

### 9. Gradual Migration Strategy

You DON'T have to migrate everything at once. Here's the recommended order:

1. ✅ **Keep using old files** - They still work
2. ✅ **Use new utilities** - Start using AppColors, Validators in new code
3. ✅ **Copy & adapt** - Copy old file to new structure, update imports
4. ✅ **Update references** - Update places that import the old file
5. ✅ **Delete old file** - Only after all references updated

### 10. Compatibility Layer (Optional)

You can create barrel files for backward compatibility:

**lib/services/auth_service.dart:**
```dart
// Barrel file for backward compatibility
export 'api/auth_service.dart';
```

This way old imports still work while you gradually migrate.

### 11. Testing After Migration

After updating a file:
1. Run `flutter analyze` to find broken imports
2. Fix any red squiggles in VS Code
3. Hot reload to verify it works
4. Test the feature manually

### 12. Common Migration Errors

**Error:** `Target of URI doesn't exist`
- **Fix:** Check the path depth (`../` vs `../../`)

**Error:** `Undefined class`
- **Fix:** Import the file, or check if class was renamed

**Error:** `The import is unused`
- **Fix:** You might have imported the old and new file

### 13. Automated Migration Script (PowerShell)

```powershell
# Rename files (run from lib directory)
Move-Item "screens/login.dart" "screens/auth/login_screen.dart"
Move-Item "screens/sinup.dart" "screens/auth/signup_screen.dart"
Move-Item "services/auth_service.dart" "services/api/auth_service.dart"
Move-Item "services/storage_service.dart" "services/local/storage_service.dart"
```

## Summary

The key to successful migration:
- **Start small** - Migrate one screen at a time
- **Test frequently** - Hot reload after each change
- **Use new patterns** - Adopt AppColors, Validators, Helpers
- **Stay organized** - Keep related files together in feature folders

The new structure is more maintainable and follows Flutter best practices!
