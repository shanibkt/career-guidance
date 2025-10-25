import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegProfileScreen extends StatefulWidget {
  const RegProfileScreen({super.key});

  @override
  State<RegProfileScreen> createState() => _RegProfileScreenState();
}

class _RegProfileScreenState extends State<RegProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profile Picture
  File? _profileImage;

  // Education
  String? _education;
  int _selectedEducationLevelIndex = -1;
  static const List<String> _educationLevels = [
    '+2',
    'Bachelor',
    'Master',
    'PhD',
  ];

  // Controllers
  final _fieldOfStudyController = TextEditingController();
  final _skillController = TextEditingController();
  final _careerAspirationsController = TextEditingController();

  // Skills
  final List<String> _skills = [];

  // Constants
  static const _radius = BorderRadius.all(Radius.circular(18.0));
  static const _gradientColors = [Color(0xFFBBD9FF), Color(0xFF9CC2FF)];
  static const _buttonGradientColors = [Color(0xFF9B6BFF), Color(0xFF8B5CF6)];
  static const _titleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const _aspirationTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const _buttonTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  @override
  void dispose() {
    _fieldOfStudyController.dispose();
    _skillController.dispose();
    _careerAspirationsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
                if (_profileImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _profileImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addSkill() {
    final text = _skillController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_skills.contains(text)) _skills.add(text);
      _skillController.clear();
    });
  }

  void _removeSkill(int index) {
    setState(() => _skills.removeAt(index));
  }

  void _onEducationLevelSelected(int index) {
    setState(() {
      _selectedEducationLevelIndex = index;
      _education = _educationLevels[index];
    });
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'profileImage': _profileImage?.path,
        'education': _education,
        'field': _fieldOfStudyController.text.trim(),
        'skills': _skills,
        'areas': _careerAspirationsController.text.trim(),
      };
      Navigator.of(context).pop(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            _buildProfileAvatar(),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._buildFormFields(),
                      const SizedBox(height: 22),
                      _buildSaveButton(),
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

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        const Expanded(
          child: Text('Complete Your Profile', style: _titleTextStyle),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 84,
                        height: 84,
                      ),
                    )
                  : const Icon(Icons.person, size: 44, color: Colors.black54),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    return [
      // Education dropdown
      _buildDropdown(),
      const SizedBox(height: 12),
      // Quick choices
      _buildEducationQuickChoices(),
      const SizedBox(height: 18),
      // Field of study
      _buildTextField(_fieldOfStudyController, 'Field of Study'),
      const SizedBox(height: 12),
      // Skills with add button
      _buildSkillInput(),
      const SizedBox(height: 8),
      _buildSkillChips(),
      const SizedBox(height: 18),
      const Text('Career Aspirations', style: _aspirationTextStyle),
      const SizedBox(height: 8),
      _buildMultilineTextField(
        _careerAspirationsController,
        'Areas of interest',
      ),
    ];
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _education,
        isExpanded: true,
        hint: const Text('Current Education Level'),
        decoration: const InputDecoration(border: InputBorder.none),
        items: _educationLevels
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _education = v),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Select education level' : null,
      ),
    );
  }

  Widget _buildEducationQuickChoices() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_educationLevels.length, (i) {
        final isSelected = _selectedEducationLevelIndex == i;
        return GestureDetector(
          onTap: () => _onEducationLevelSelected(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _educationLevels[i],
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }

  Widget _buildSkillInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _skillController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Skills',
              ),
              onFieldSubmitted: (_) => _addSkill(),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _addSkill,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black87,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_skills.length, (i) {
        return Chip(label: Text(_skills[i]), onDeleted: () => _removeSkill(i));
      }),
    );
  }

  Widget _buildMultilineTextField(
    TextEditingController controller,
    String hintText,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveProfile,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 160,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(colors: _buttonGradientColors),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('Save', style: _buttonTextStyle),
          ),
        ),
      ),
    );
  }
}
