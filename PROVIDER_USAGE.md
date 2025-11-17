# Provider Usage Guide 🚀

## How to Use Provider in Your Screens

Provider is now integrated! Here's how to use it across your app.

---

## 1. Login Screen Example

### Using AuthProvider for Login

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/utils/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Helpers.showSnackBar(context, 'Login successful!');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Login failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleLogin,
                child: authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 2. Home Screen Example

### Reading User Data from Provider

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch providers - screen rebuilds when they change
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${authProvider.user?.fullName ?? "User"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display profile image
          if (profileProvider.profileImagePath != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: FileImage(File(profileProvider.profileImagePath!)),
            ),
          
          // Display user info
          Text('Email: ${authProvider.user?.email}'),
          Text('Phone: ${profileProvider.phoneNumber ?? "Not set"}'),
          Text('Age: ${profileProvider.age ?? "Not set"}'),
          Text('Skills: ${profileProvider.skills.join(", ")}'),
        ],
      ),
    );
  }
}
```

---

## 3. Profile Screen Example

### Updating Profile with Provider

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../core/utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing data
    final profileProvider = context.read<ProfileProvider>();
    _phoneController.text = profileProvider.phoneNumber ?? '';
    _ageController.text = profileProvider.age?.toString() ?? '';
  }

  Future<void> _saveProfile() async {
    final profileProvider = context.read<ProfileProvider>();

    final profileData = {
      'phoneNumber': _phoneController.text,
      'age': int.tryParse(_ageController.text),
    };

    final success = await profileProvider.updateProfile(profileData);

    if (!mounted) return;

    if (success) {
      Helpers.showSnackBar(context, 'Profile updated!');
    } else {
      Helpers.showSnackBar(
        context,
        profileProvider.error ?? 'Update failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Column(
            children: [
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              ElevatedButton(
                onPressed: profileProvider.isLoading ? null : _saveProfile,
                child: profileProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 4. Image Upload Example

```dart
Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image != null) {
    final profileProvider = context.read<ProfileProvider>();
    final success = await profileProvider.uploadProfileImage(image.path);
    
    if (!mounted) return;
    
    if (success) {
      Helpers.showSnackBar(context, 'Image uploaded!');
    } else {
      Helpers.showSnackBar(context, 'Upload failed', isError: true);
    }
  }
}
```

---

## 5. Skills Management Example

```dart
import 'package:provider/provider.dart';

// Add skill
Future<void> _addSkill(String skill) async {
  await context.read<ProfileProvider>().addSkill(skill);
  Helpers.showSnackBar(context, 'Skill added!');
}

// Remove skill
Future<void> _removeSkill(int index) async {
  await context.read<ProfileProvider>().removeSkill(index);
  Helpers.showSnackBar(context, 'Skill removed!');
}

// Display skills with delete option
Widget buildSkillsList() {
  return Consumer<ProfileProvider>(
    builder: (context, profileProvider, child) {
      final skills = profileProvider.skills;
      
      return Wrap(
        children: skills.asMap().entries.map((entry) {
          return Chip(
            label: Text(entry.value),
            onDeleted: () => _removeSkill(entry.key),
          );
        }).toList(),
      );
    },
  );
}
```

---

## Key Concepts

### `context.read<T>()` vs `context.watch<T>()`

**Use `context.read<T>()`:**
- Inside button `onPressed`, callbacks
- When you DON'T want widget to rebuild
- Just need to call a method

```dart
ElevatedButton(
  onPressed: () {
    context.read<AuthProvider>().logout(); // Just call method
  },
  child: const Text('Logout'),
)
```

**Use `context.watch<T>()`:**
- Inside `build()` method
- When you WANT widget to rebuild on changes
- Need to display data

```dart
@override
Widget build(BuildContext context) {
  final user = context.watch<AuthProvider>().user; // Rebuilds on change
  return Text(user?.name ?? 'Guest');
}
```

**Use `Consumer<T>`:**
- When you want only part of widget to rebuild
- Better performance for large widgets

```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text(authProvider.user?.name ?? 'Guest');
  },
)
```

---

## Common Patterns

### 1. Check Authentication
```dart
final isLoggedIn = context.watch<AuthProvider>().isAuthenticated;

if (isLoggedIn) {
  return HomeScreen();
} else {
  return LoginScreen();
}
```

### 2. Show Loading State
```dart
final isLoading = context.watch<AuthProvider>().isLoading;

if (isLoading) {
  return const CircularProgressIndicator();
}
```

### 3. Display Error
```dart
final error = context.watch<AuthProvider>().error;

if (error != null) {
  return Text(error, style: TextStyle(color: Colors.red));
}
```

### 4. Logout
```dart
Future<void> _logout() async {
  await context.read<AuthProvider>().logout();
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## Benefits You Get

✅ **No More Repetitive Code** - Load user once, use everywhere  
✅ **Automatic Updates** - Change profile → all screens update  
✅ **Centralized Logic** - All auth logic in AuthProvider  
✅ **Easy Testing** - Mock providers for tests  
✅ **Better Performance** - Only rebuild what changed  

---

## Quick Reference

### Available Providers:

**AuthProvider:**
- `user` - Current user object
- `token` - Auth token
- `isAuthenticated` - Boolean
- `isLoading` - Boolean
- `error` - Error message
- `login(email, password)` - Login method
- `logout()` - Logout method
- `signup(userData)` - Signup method

**ProfileProvider:**
- `profileData` - Full profile map
- `profileImagePath` - Image path
- `phoneNumber`, `age`, `gender`, etc. - Specific fields
- `skills` - List of skills
- `isLoading` - Boolean
- `error` - Error message
- `updateProfile(data)` - Update profile
- `uploadProfileImage(path)` - Upload image
- `addSkill(skill)` - Add skill
- `removeSkill(index)` - Remove skill

---

**Start using Provider today and enjoy cleaner, more maintainable code!** 🎉
