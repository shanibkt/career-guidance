# Clean Architecture - Feature-Based Structure 🏗️

## Overview

This project follows **Feature-First Architecture** with **Clean Code principles** for better organization, scalability, and maintainability.

---

## 📁 New Folder Structure

```
lib/
├── core/                          # Shared utilities across features
│   ├── constants/
│   │   ├── app_colors.dart       # Color palette
│   │   └── api_constants.dart    # API endpoints
│   ├── theme/
│   │   └── app_theme.dart        # App-wide theme
│   └── utils/
│       ├── validators.dart       # Form validation functions
│       └── helpers.dart          # Helper utilities
│
├── models/                        # Data models (User, etc.)
│   └── user.dart
│
├── providers/                     # State management (Provider)
│   ├── auth_provider.dart
│   └── profile_provider.dart
│
├── services/                      # Backend/local services
│   ├── api/
│   │   ├── auth_service.dart
│   │   └── profile_service.dart
│   └── local/
│       └── storage_service.dart
│
├── features/                      # Feature-based modules
│   ├── auth/                      # Authentication feature
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   └── widgets/
│   │       ├── auth_button.dart
│   │       └── auth_text_field.dart
│   │
│   ├── home/                      # Home/Dashboard feature
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       ├── home_card.dart
│   │       ├── progress_card.dart
│   │       └── bottom_nav_item.dart
│   │
│   ├── profile/                   # Profile management
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── reg_profile_screen.dart
│   │   └── widgets/
│   │       ├── image_picker_widget.dart
│   │       └── profile_form_fields.dart
│   │
│   ├── quiz/                      # Career quiz feature
│   │   ├── screens/
│   │   │   └── quiz_screen.dart
│   │   ├── widgets/
│   │   │   ├── quiz_question_card.dart
│   │   │   └── quiz_option_button.dart
│   │   └── models/              # (Optional) Quiz-specific models
│   │       └── quiz_model.dart
│   │
│   ├── career/                    # Career suggestions
│   │   ├── screens/
│   │   │   ├── career_suggestions_screen.dart
│   │   │   └── career_detail_screen.dart
│   │   └── widgets/
│   │       ├── career_card.dart
│   │       └── career_filter.dart
│   │
│   ├── learning_path/             # Learning paths
│   │   ├── screens/
│   │   │   ├── learning_path_screen.dart
│   │   │   └── course_video_screen.dart
│   │   └── widgets/
│   │       ├── learning_module_card.dart
│   │       └── video_player_widget.dart
│   │
│   ├── resume_builder/            # Resume builder
│   │   ├── screens/
│   │   │   ├── resume_builder_screen.dart
│   │   │   └── resume_preview_screen.dart
│   │   └── widgets/
│   │       ├── resume_section.dart
│   │       └── resume_template.dart
│   │
│   └── chat/                      # AI chat feature
│       ├── screens/
│       │   └── chat_screen.dart
│       └── widgets/
│           ├── chat_message.dart
│           └── chat_input.dart
│
└── main.dart / main_new.dart      # App entry point
```

---

## 🎯 Clean Code Principles Applied

### 1. **Single Responsibility Principle (SRP)**
- Each file has ONE clear purpose
- Screens only handle UI and user interaction
- Widgets are reusable and focused
- Services handle data/API logic only

### 2. **Feature-First Organization**
- Group by feature, not by type (screens/widgets)
- Easy to find all quiz-related code in `features/quiz/`
- Easy to add/remove entire features

### 3. **DRY (Don't Repeat Yourself)**
- Reusable widgets in `widgets/` folders
- Shared utilities in `core/utils/`
- Common constants in `core/constants/`

### 4. **Separation of Concerns**
- **UI Layer**: `features/*/screens/` and `features/*/widgets/`
- **Business Logic**: `providers/`
- **Data Layer**: `services/` and `models/`

---

## 📋 Benefits of This Structure

✅ **Easier Navigation** - Find code by feature, not file type  
✅ **Better Scalability** - Add new features without touching existing code  
✅ **Team Collaboration** - Multiple developers can work on different features  
✅ **Code Reusability** - Extract common widgets easily  
✅ **Testability** - Test each feature independently  
✅ **Maintainability** - Changes are isolated to specific features  

---

## 🔄 Migration Plan

### Phase 1: Auth Feature ✅
- Move `login.dart`, `sinup.dart`, `forgot_password.dart`, `reset_password.dart`
- Extract common auth widgets
- Update imports

### Phase 2: Quiz Feature
- Move `quiz.dart` → `features/quiz/screens/quiz_screen.dart`
- Extract quiz widgets (question cards, option buttons)
- Create quiz models if needed

### Phase 3: Career Feature
- Move `career.dart`, `career_detail.dart` → `features/career/screens/`
- Extract career cards and filters into widgets
- Create career-specific utilities

### Phase 4: Learning Path Feature
- Move `learning_path.dart`, `course_video.dart` → `features/learning_path/screens/`
- Extract learning widgets (module cards, video players)

### Phase 5: Resume Builder Feature
- Move `resume_builder.dart`, `resume.dart` → `features/resume_builder/screens/`
- Extract resume sections and templates into widgets

### Phase 6: Home & Profile
- Move `homescreen.dart` → `features/home/screens/`
- Extract bottom nav, home cards into widgets
- Move profile screens to `features/profile/screens/`

### Phase 7: Chat Feature
- Move `chat.dart` → `features/chat/screens/`
- Extract chat widgets

---

## 🚀 Usage Examples

### Importing from Features
```dart
// Old way (flat structure)
import '../screens/quiz.dart';
import '../screens/career.dart';

// New way (feature-based)
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/career/screens/career_suggestions_screen.dart';
```

### Creating Reusable Widgets
```dart
// features/quiz/widgets/quiz_question_card.dart
class QuizQuestionCard extends StatelessWidget {
  final String question;
  final List<String> options;
  
  const QuizQuestionCard({
    required this.question,
    required this.options,
  });
  
  @override
  Widget build(BuildContext context) {
    // Widget implementation
  }
}
```

### Using Providers
```dart
// In any feature screen
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

// Inside widget
final authProvider = context.watch<AuthProvider>();
if (authProvider.isAuthenticated) {
  // Show authenticated content
}
```

---

## 📝 Naming Conventions

### Screens
- Use `_screen.dart` suffix
- Example: `quiz_screen.dart`, `login_screen.dart`

### Widgets
- Descriptive names, no suffix needed
- Example: `quiz_question_card.dart`, `career_filter.dart`

### Classes
- PascalCase
- Example: `QuizScreen`, `CareerCard`, `AuthProvider`

### Files
- snake_case
- Example: `career_suggestions_screen.dart`

---

## 🔧 Next Steps

1. **Move files** to new feature folders
2. **Update imports** across the codebase
3. **Extract widgets** from large screen files
4. **Test each feature** independently
5. **Document** any feature-specific logic

---

## 💡 Tips

- Start with one feature at a time
- Test after each migration
- Use VS Code "Find All References" to update imports
- Create widgets when you see repeated UI code
- Keep services and models separate from features

**This is a living document - update as the architecture evolves!** 🚀
