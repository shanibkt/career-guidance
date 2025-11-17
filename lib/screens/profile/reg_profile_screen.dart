import 'package:flutter/material.dart';
import '../../services/local/storage_service.dart';
import '../../services/api/profile_service.dart';
import '../../models/user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../homescreen.dart';
import 'widgets/image_picker_widget.dart';
import 'widgets/profile_form_fields.dart';

class RegProfileScreen extends StatefulWidget {
  final bool isFromSignup;

  const RegProfileScreen({super.key, this.isFromSignup = false});

  @override
  State<RegProfileScreen> createState() => _RegProfileScreenState();
}

class _RegProfileScreenState extends State<RegProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();

  // State
  String? _education;
  String? _gender;
  final List<String> _skills = [];
  String? _imagePath;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _educationLevels = [
    'High School',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileData();
    _loadProfileImage();
  }

  Future<void> _loadUserData() async {
    final userMap = await StorageService.loadUser();
    if (userMap != null && mounted) {
      setState(() {
        _fullNameCtrl.text = userMap['fullName'] ?? '';
        _usernameCtrl.text = userMap['username'] ?? '';
        _emailCtrl.text = userMap['email'] ?? '';
      });
    }
  }

  Future<void> _loadProfileData() async {
    final map = await StorageService.loadProfile();
    if (map != null && mounted) {
      setState(() {
        _education = (map['educationLevel'] ?? map['education']) as String?;
        _fieldCtrl.text =
            (map['fieldOfStudy'] ?? map['field'])?.toString() ?? '';
        _phoneCtrl.text =
            (map['phoneNumber'] ?? map['phone'])?.toString() ?? '';
        _ageCtrl.text = map['age']?.toString() ?? '';
        _gender = map['gender'] as String?;
        final skills = map['skills'];
        if (skills is List) {
          _skills.clear();
          _skills.addAll(skills.map((e) => e.toString()));
        }
        _areasCtrl.text =
            (map['areasOfInterest'] ?? map['areas'])?.toString() ?? '';
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final path = await StorageService.loadProfileImagePath();
    if (path != null && mounted) {
      setState(() => _imagePath = path);
    }
  }

  void _addSkill() {
    final text = _skillCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_skills.contains(text)) _skills.add(text);
      _skillCtrl.clear();
    });
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Prepare user data
      final userData = {
        'fullName': _fullNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };

      // Prepare profile data
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

      // Try to sync with backend
      final token = await StorageService.loadAuthToken();
      final existingUser = await StorageService.loadUser();
      final userId = existingUser?['id'] as int?;

      if (token != null && userId != null) {
        await ProfileService.updateUser(userId, token, userData);
        await ProfileService.updateProfile(userId, token, profileData);

        if (_imagePath != null && _imagePath!.isNotEmpty) {
          await ProfileService.uploadProfileImage(userId, token, _imagePath!);
        }
      }

      // Save locally
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

      if (!mounted) return;

      if (widget.isFromSignup) {
        Helpers.showSnackBar(context, 'Profile completed successfully!');
        final savedUser = await StorageService.loadUser();
        if (savedUser != null && savedUser['id'] != null) {
          final user = User(
            id: savedUser['id'],
            fullName: savedUser['fullName'] ?? '',
            username: savedUser['username'] ?? '',
            email: savedUser['email'] ?? '',
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        Navigator.of(context).pop(localProfileData);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Error saving profile', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blueGradient),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ImagePickerWidget(
              imagePath: _imagePath,
              onImagePicked: (path) => setState(() => _imagePath = path),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        const Text(
          'Complete Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _fullNameCtrl,
              label: 'Full Name',
              icon: Icons.person,
              validator: Validators.validateFullName,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email,
              validator: Validators.validateUsername,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _ageCtrl,
              label: 'Age',
              icon: Icons.cake,
              keyboardType: TextInputType.number,
              validator: Validators.validateAge,
            ),
            const SizedBox(height: 16),
            ProfileDropdownField(
              value: _gender,
              label: 'Gender',
              icon: Icons.person_outline,
              items: _genders,
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 24),
            const Text(
              'Education & Career',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ProfileDropdownField(
              value: _education,
              label: 'Education Level',
              icon: Icons.school,
              items: _educationLevels,
              onChanged: (value) => setState(() => _education = value),
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _fieldCtrl,
              label: 'Field of Study',
              icon: Icons.book,
              validator: (v) =>
                  Validators.validateRequired(v, 'Field of study'),
            ),
            const SizedBox(height: 16),
            ProfileFormField(
              controller: _areasCtrl,
              label: 'Areas of Interest',
              icon: Icons.interests,
              validator: (v) =>
                  Validators.validateRequired(v, 'Areas of interest'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SkillsInputField(
              controller: _skillCtrl,
              skills: _skills,
              onAdd: _addSkill,
              onRemove: _removeSkill,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _fieldCtrl.dispose();
    _skillCtrl.dispose();
    _areasCtrl.dispose();
    super.dispose();
  }
}
