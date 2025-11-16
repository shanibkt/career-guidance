import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../models/user.dart';
import 'homescreen.dart';

class RegProfileScreen extends StatefulWidget {
  final bool isFromSignup;

  const RegProfileScreen({super.key, this.isFromSignup = false});

  @override
  State<RegProfileScreen> createState() => _RegProfileScreenState();
}

class _RegProfileScreenState extends State<RegProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // User fields (from database)
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Profile fields
  String? _education;

  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _gender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // initial/default values will be set in initState below when loading saved profile

  final _fieldCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final List<String> _skills = [];

  final _areasCtrl = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _fieldCtrl.dispose();
    _skillCtrl.dispose();
    _areasCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load saved user data
    StorageService.loadUser().then((userMap) {
      if (userMap != null) {
        setState(() {
          _fullNameCtrl.text = userMap['fullName'] ?? '';
          _usernameCtrl.text = userMap['username'] ?? '';
          _emailCtrl.text = userMap['email'] ?? '';
        });
      }
    });

    // Load saved profile if any
    StorageService.loadProfile().then((map) {
      if (map != null) {
        setState(() {
          // Support both old and new column names for backward compatibility
          _education =
              (map['educationLevel'] ?? map['education']) as String? ??
              _education;
          _fieldCtrl.text =
              (map['fieldOfStudy'] ?? map['field'])?.toString() ?? '';
          _phoneCtrl.text =
              (map['phoneNumber'] ?? map['phone'])?.toString() ?? '';
          _ageCtrl.text = map['age']?.toString() ?? '';
          _gender = map['gender'] as String? ?? _gender;
          final skills = map['skills'];
          if (skills is List) {
            _skills.clear();
            _skills.addAll(skills.map((e) => e.toString()));
          }
          _areasCtrl.text =
              (map['areasOfInterest'] ?? map['areas'])?.toString() ?? '';
        });
      }
    });
    StorageService.loadProfileImagePath().then((p) {
      if (p != null) setState(() => _imagePath = p);
    });
  }

  void _addSkill() {
    final text = _skillCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_skills.contains(text)) _skills.add(text);
      _skillCtrl.clear();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() => _imagePath = file.path);
      }
    } catch (e) {
      // ignore
    }
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Prepare user data (full name, username, email)
        final userData = {
          'fullName': _fullNameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        };

        // Prepare profile data - match backend column names
        final ageText = _ageCtrl.text.trim();
        final profileData = <String, dynamic>{
          'educationLevel': _education,
          'phoneNumber': _phoneCtrl.text.trim(),
          'age': ageText.isNotEmpty ? int.tryParse(ageText) : null,
          'gender': _gender,
          'fieldOfStudy': _fieldCtrl.text.trim(),
          'skills': _skills,
          'areasOfInterest': _areasCtrl.text.trim(),
        };
        // Remove null and empty values
        profileData.removeWhere(
          (key, value) =>
              value == null ||
              (value is String && value.isEmpty) ||
              (value is List && value.isEmpty),
        );

        // Try to sync with backend if logged in
        final token = await StorageService.loadAuthToken();
        final existingUser = await StorageService.loadUser();
        final userId = existingUser?['id'] as int?;

        if (token != null && userId != null) {
          // Update user fields on backend
          final userSuccess = await ProfileService.updateUser(
            userId,
            token,
            userData,
          );

          // Update profile fields on backend
          final profileSuccess = await ProfileService.updateProfile(
            userId,
            token,
            profileData,
          );

          // Upload image if changed
          debugPrint('Image path check: _imagePath = $_imagePath');
          if (_imagePath != null && _imagePath!.isNotEmpty) {
            debugPrint('Attempting to upload profile image...');
            final uploadedPath = await ProfileService.uploadProfileImage(
              userId,
              token,
              _imagePath!,
            );
            if (uploadedPath != null) {
              debugPrint(
                '✅ Profile image uploaded successfully: $uploadedPath',
              );
            } else {
              debugPrint('❌ Profile image upload failed - check logs above');
            }
          } else {
            debugPrint('⚠️ No image selected - skipping upload');
          }

          if (!userSuccess || !profileSuccess) {
            debugPrint('Backend sync failed - saving locally only');
          }
        }

        // Always save locally (as cache and fallback)
        // Prepare local storage data - use backend column names for consistency
        final localProfileData = <String, dynamic>{
          if (_education != null && _education!.isNotEmpty)
            'educationLevel': _education,
          if (_phoneCtrl.text.trim().isNotEmpty)
            'phoneNumber': _phoneCtrl.text.trim(),
          if (_ageCtrl.text.trim().isNotEmpty) 'age': _ageCtrl.text.trim(),
          if (_gender != null && _gender!.isNotEmpty) 'gender': _gender,
          if (_fieldCtrl.text.trim().isNotEmpty)
            'fieldOfStudy': _fieldCtrl.text.trim(),
          if (_skills.isNotEmpty) 'skills': List<String>.from(_skills),
          if (_areasCtrl.text.trim().isNotEmpty)
            'areasOfInterest': _areasCtrl.text.trim(),
        };

        final localUserData = <String, dynamic>{
          'fullName': _fullNameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        };

        if (existingUser != null && existingUser['id'] != null) {
          localUserData['id'] = existingUser['id'];
        }

        await StorageService.saveUser(localUserData);
        await StorageService.saveProfile(localProfileData);
        if (_imagePath != null && _imagePath!.isNotEmpty) {
          await StorageService.saveProfileImagePath(_imagePath!);
        }

        debugPrint(
          'RegProfile._save - saved localProfileData: $localProfileData',
        );
        debugPrint('RegProfile._save - saved localUserData: $localUserData');

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        // Check if we're coming from signup or editing existing profile
        if (widget.isFromSignup) {
          // Coming from signup - navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile completed successfully!')),
          );

          // Create user object from saved data
          final savedUser = await StorageService.loadUser();
          if (savedUser != null && savedUser['id'] != null) {
            final user = User(
              id: savedUser['id'] as int,
              fullName: savedUser['fullName'] as String,
              username: savedUser['username'] as String,
              email: savedUser['email'] as String,
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
            );
          } else {
            // Fallback: navigate to home without user (shouldn't happen)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          // Editing existing profile - return to profile page
          Navigator.of(context).pop(localProfileData);
        }
      } catch (e) {
        debugPrint('Error saving profile: $e');
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving profile')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.0);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBBD9FF), Color(0xFF9CC2FF)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Complete Your Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        image: _imagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagePath == null
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _fullNameCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your full name'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Username
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.account_circle),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your username'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Email
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Education dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _education,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Education Level',
                            prefixIcon: Icon(Icons.school),
                          ),
                          items: <String>['+2', 'Bachelor', 'Master', 'PhD']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _education = v),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Select education level'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Phone number
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Phone number',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Age and Gender row
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: radius,
                              ),
                              child: TextFormField(
                                controller: _ageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Age',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: radius,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                hint: const Text('Gender'),
                                items: _genders
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Field of study
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _fieldCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Field of Study',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Skills with add button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _skillCtrl,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Skills',
                                ),
                                onFieldSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _addSkill,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black87,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_skills.length, (i) {
                          return Chip(
                            label: Text(_skills[i]),
                            onDeleted: () => _removeSkill(i),
                          );
                        }),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Career Aspirations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                        ),
                        child: TextFormField(
                          controller: _areasCtrl,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Areas of interest',
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Save button (pill)
                      Center(
                        child: GestureDetector(
                          onTap: _save,
                          child: Container(
                            width: 160,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9B6BFF), Color(0xFF8B5CF6)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
