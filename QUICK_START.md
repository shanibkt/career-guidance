# Quick Start: Using the New Structure 🚀

## 5-Minute Quick Start

Your code has been restructured! Here's how to start using it **right now** without changing any existing files.

## Step 1: Use AppColors (30 seconds)

In any file where you use colors:

```dart
// Add this import at the top
import 'package:career_guidence/core/constants/app_colors.dart';

// Then replace hardcoded colors with:
AppColors.primary           // Main blue
AppColors.accent            // Green accent
AppColors.primaryGradient   // Blue gradient
AppColors.accentGradient    // Green gradient
AppColors.blueGradient      // Light blue gradient
AppColors.error             // Red for errors
AppColors.success           // Green for success
```

**Example:**
```dart
// Old
Container(color: Color(0xFF6366F1))

// New
Container(color: AppColors.primary)
```

## Step 2: Use Validators (1 minute)

In any form:

```dart
// Add this import
import 'package:career_guidence/core/utils/validators.dart';

// Then use in TextFormField:
TextFormField(
  validator: Validators.validateEmail,
  // or
  validator: Validators.validatePassword,
  // or
  validator: Validators.validatePhone,
  // or
  validator: (v) => Validators.validateRequired(v, 'Username'),
)
```

## Step 3: Use Helpers (1 minute)

For snackbars and dialogs:

```dart
// Add this import
import 'package:career_guidence/core/utils/helpers.dart';

// Replace all snackbars with:
Helpers.showSnackBar(context, 'Success message!');
Helpers.showSnackBar(context, 'Error message', isError: true);

// Replace loading dialogs with:
Helpers.showLoadingDialog(context);
// ... do async work ...
Helpers.hideLoadingDialog(context);
```

## Step 4: Use Reusable Widgets (2 minutes)

For profile image picker:

```dart
// Add this import
import 'package:career_guidence/screens/profile/widgets/image_picker_widget.dart';

// Replace your image picker code with:
ImagePickerWidget(
  imagePath: _imagePath,
  onImagePicked: (path) => setState(() => _imagePath = path),
)
```

For form fields:

```dart
// Add this import
import 'package:career_guidence/screens/profile/widgets/profile_form_fields.dart';

// Use instead of TextFormField:
ProfileFormField(
  controller: _nameController,
  label: 'Full Name',
  icon: Icons.person,
  validator: Validators.validateFullName,
)

// Use for dropdowns:
ProfileDropdownField(
  value: _gender,
  label: 'Gender',
  icon: Icons.person,
  items: ['Male', 'Female', 'Other'],
  onChanged: (value) => setState(() => _gender = value),
)

// Use for skills:
SkillsInputField(
  controller: _skillController,
  skills: _skills,
  onAdd: () => _addSkill(),
  onRemove: (index) => _removeSkill(index),
)
```

## Step 5: Update Services (1 minute)

Update your imports:

```dart
// Old
import '../services/auth_service.dart';
import '../services/storage_service.dart';

// New
import 'package:career_guidence/services/api/auth_service.dart';
import 'package:career_guidence/services/local/storage_service.dart';
```

**That's it!** You're now using the structured codebase. 🎉

---

## Common Use Cases

### Show Success Message
```dart
Helpers.showSnackBar(context, 'Profile saved successfully!');
```

### Show Error Message
```dart
Helpers.showSnackBar(context, 'Failed to save profile', isError: true);
```

### Show Loading
```dart
Helpers.showLoadingDialog(context, message: 'Saving...');
await _saveData();
Helpers.hideLoadingDialog(context);
```

### Validate Email
```dart
TextFormField(
  controller: _emailController,
  validator: Validators.validateEmail,
)
```

### Use App Colors
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

---

## Files You Can Use Right Now

### ✅ Ready to Use Immediately:

1. **lib/core/constants/app_colors.dart**
   - All app colors and gradients
   - No dependencies, works everywhere

2. **lib/core/utils/validators.dart**
   - Form validation functions
   - Pure functions, no dependencies

3. **lib/core/utils/helpers.dart**
   - Snackbar, dialog helpers
   - Works in any screen

4. **lib/screens/profile/widgets/image_picker_widget.dart**
   - Profile image picker with camera/gallery
   - Fully self-contained

5. **lib/screens/profile/widgets/profile_form_fields.dart**
   - Reusable form fields
   - Consistent styling

6. **lib/services/api/auth_service.dart**
   - Refactored auth service
   - Same API, better structure

7. **lib/services/local/storage_service.dart**
   - Enhanced storage service
   - Additional helper methods

---

## What NOT to Do

❌ Don't delete your existing files yet  
❌ Don't change all imports at once  
❌ Don't migrate everything today

✅ Keep existing files working  
✅ Use new utils in new code  
✅ Migrate gradually, one screen at a time

---

## Example: Update One Screen (5 minutes)

Let's say you want to update `forgot_password.dart`:

**1. Add imports at the top:**
```dart
import 'package:career_guidence/core/constants/app_colors.dart';
import 'package:career_guidence/core/utils/validators.dart';
import 'package:career_guidence/core/utils/helpers.dart';
```

**2. Replace colors:**
```dart
// Find all Color(0x...) and replace with AppColors.*
```

**3. Replace validators:**
```dart
// In email field:
validator: Validators.validateEmail,
```

**4. Replace snackbars:**
```dart
// Old
ScaffoldMessenger.of(context).showSnackBar(...)

// New
Helpers.showSnackBar(context, 'Message here');
```

**Done!** Screen now uses the new structure.

---

## Next Steps

1. **Today**: Start using AppColors, Validators, Helpers in any file you're working on
2. **This Week**: Refactor 1-2 screens to use new structure
3. **Next Week**: Create new features using the organized structure
4. **Future**: All screens following best practices

---

## Get Help

- **Structure overview**: See `RESTRUCTURING_GUIDE.md`
- **Migration guide**: See `IMPORT_MIGRATION.md`
- **Complete example**: See `REFACTORING_EXAMPLE.md`
- **Full README**: See `README_RESTRUCTURING.md`

---

## Summary

✅ **No breaking changes** - your code still works  
✅ **Immediate benefits** - use new utils right away  
✅ **Gradual migration** - migrate at your own pace  
✅ **Better code** - consistent, reusable, maintainable

**Start coding with the new structure today!** 🚀
