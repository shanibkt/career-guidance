# Code Restructuring Guide

## New Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         ✅ Created - Color constants and gradients
│   │   └── api_constants.dart      ✅ Created - API endpoints and URLs
│   ├── theme/
│   │   └── app_theme.dart          ✅ Created - App-wide theme configuration
│   └── utils/
│       ├── validators.dart         ✅ Created - Form validation functions
│       └── helpers.dart            ✅ Created - Helper utilities (snackbar, dialogs, etc.)
│
├── models/
│   ├── user.dart                   ✓ Existing
│   └── course_module.dart          ✓ Existing
│
├── services/
│   ├── api/
│   │   ├── auth_service.dart       → Move from services/
│   │   ├── profile_service.dart    → Move from services/
│   │   └── course_service.dart     → Create new
│   └── local/
│       ├── storage_service.dart    → Move from services/
│       └── course_progress_service.dart → Move from services/
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart       → Rename from login.dart
│   │   ├── signup_screen.dart      → Rename from sinup.dart
│   │   ├── forgot_password_screen.dart → Rename from forgot_password.dart
│   │   └── reset_password_screen.dart  → Rename from reset_password.dart
│   │
│   ├── profile/
│   │   ├── profile_screen.dart     → Rename from profile.dart
│   │   ├── reg_profile_screen.dart ✅ Created - Refactored from reg_profile.dart
│   │   └── widgets/
│   │       ├── image_picker_widget.dart     ✅ Created
│   │       └── profile_form_fields.dart     ✅ Created
│   │
│   ├── career/
│   │   ├── career_screen.dart      → Rename from career.dart
│   │   ├── career_detail_screen.dart → Rename from career_detail.dart
│   │   └── widgets/
│   │       ├── career_card.dart    → Extract from career.dart
│   │       └── skill_chip.dart     → Extract from career_detail.dart
│   │
│   ├── learning/
│   │   ├── learning_path_screen.dart → Rename from learning_path.dart
│   │   ├── course_video_screen.dart  → Rename from course_video.dart
│   │   └── widgets/
│   │       ├── course_module_card.dart → Extract widgets
│   │       └── progress_card.dart      → Extract widgets
│   │
│   ├── resume/
│   │   ├── resume_builder_screen.dart → Rename from resume_builder.dart
│   │   └── widgets/
│   │       ├── resume_preview.dart    → Extract preview widget
│   │       ├── ats_score_tab.dart     → Extract ATS tab
│   │       └── section_widgets.dart   → Extract form sections
│   │
│   ├── chat/
│   │   └── chat_screen.dart        → Rename from chat.dart
│   │
│   └── home/
│       ├── homescreen.dart         → Move from screens/
│       └── widgets/
│           ├── home_app_bar.dart   → Extract app bar
│           └── feature_card.dart   → Extract feature cards
│
└── main.dart                       ✓ Update imports
```

## Benefits of New Structure

### 1. **Separation of Concerns**
- **core/**: Shared constants, theme, and utilities
- **services/**: Split into `api/` (backend calls) and `local/` (device storage)
- **screens/**: Grouped by feature with dedicated widget folders

### 2. **Reusability**
- Widgets like `ImagePickerWidget`, `ProfileFormField` can be used anywhere
- Validators are pure functions, easy to test and reuse
- Color constants ensure consistent styling

### 3. **Maintainability**
- Easy to locate files: `screens/profile/` has all profile-related code
- Widget extraction makes files smaller and focused
- Clear naming conventions

### 4. **Scalability**
- Adding new features follows clear patterns
- New screens go in appropriate feature folders
- New widgets go in feature's `widgets/` subfolder

### 5. **Testing**
- Pure functions in `core/utils/` are easily testable
- Service separation allows mocking API vs local storage
- Widget isolation enables unit testing

## Implementation Status

✅ **Completed:**
- Core structure (constants, theme, utils)
- Profile screen widgets (ImagePicker, FormFields)
- Refactored RegProfileScreen

🔄 **In Progress:**
- Organizing existing screens into feature folders
- Updating import paths

⏳ **Pending:**
- Extract widgets from large screen files
- Update main.dart with new theme
- Update all import statements

## Usage Examples

### Using AppColors
```dart
import '../../core/constants/app_colors.dart';

Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### Using Validators
```dart
import '../../core/utils/validators.dart';

TextFormField(
  validator: Validators.validateEmail,
  // or
  validator: (v) => Validators.validateRequired(v, 'Username'),
)
```

### Using Helpers
```dart
import '../../core/utils/helpers.dart';

// Show success message
Helpers.showSnackBar(context, 'Profile saved!');

// Show error
Helpers.showSnackBar(context, 'Error occurred', isError: true);

// Show loading
Helpers.showLoadingDialog(context, message: 'Saving...');
Helpers.hideLoadingDialog(context);
```

### Using Reusable Widgets
```dart
import 'widgets/image_picker_widget.dart';

ImagePickerWidget(
  imagePath: _imagePath,
  onImagePicked: (path) => setState(() => _imagePath = path),
)
```

## Next Steps

1. **Move Existing Services** to api/ and local/ folders
2. **Reorganize Screens** into feature folders
3. **Extract Widgets** from large screen files
4. **Update Imports** across the app
5. **Apply Theme** in main.dart
6. **Test** all screens work with new structure
