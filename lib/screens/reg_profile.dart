import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class RegProfileScreen extends StatefulWidget {
  const RegProfileScreen({super.key});

  @override
  State<RegProfileScreen> createState() => _RegProfileScreenState();
}

class _RegProfileScreenState extends State<RegProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _education;
  final List<String> _quickLevels = ['+2', 'Bachelor', 'Master'];
  int _selectedQuick = -1;

  // initial/default values will be set in initState below when loading saved profile

  final _fieldCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final List<String> _skills = [];

  final _areasCtrl = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _skillCtrl.dispose();
    _areasCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load saved profile if any
    StorageService.loadProfile().then((map) {
      if (map != null) {
        setState(() {
          _education = map['education'] as String? ?? _education;
          _fieldCtrl.text = map['field'] as String? ?? '';
          final skills = map['skills'];
          if (skills is List) {
            _skills.clear();
            _skills.addAll(skills.map((e) => e.toString()));
          }
          _areasCtrl.text = map['areas'] as String? ?? '';
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

  void _onQuickSelect(int index) {
    setState(() {
      _selectedQuick = index;
      _education = _quickLevels[index];
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? true) {
      // collect data
      final data = {
        'education': _education,
        'field': _fieldCtrl.text.trim(),
        'skills': _skills,
        'areas': _areasCtrl.text.trim(),
      };

      // persist
      StorageService.saveProfile(data);
      if (_imagePath != null) StorageService.saveProfileImagePath(_imagePath!);

      // Return to caller with result
      Navigator.of(context).pop(data);
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
                          value: _education,
                          isExpanded: true,
                          // Show the selected education directly; no placeholder
                          decoration: const InputDecoration(
                            border: InputBorder.none,
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

                      // Quick choices
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_quickLevels.length, (i) {
                          final sel = _selectedQuick == i;
                          return GestureDetector(
                            onTap: () => _onQuickSelect(i),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _quickLevels[i],
                                style: TextStyle(
                                  color: sel ? Colors.black : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }),
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
