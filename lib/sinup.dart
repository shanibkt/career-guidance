import 'package:career_guidence/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
// secure storage not used here; keep signup flow simple and navigate to login

import 'services/api/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String _gender = 'Gender';
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;

  // No local token persistence on signup; users should log in after creating an account.

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _ageCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthDate, DateTime now) {
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone number';
    // Remove spaces, dashes and parentheses for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final re = RegExp(r'^\+?[0-9]{7,15}$');
    return re.hasMatch(cleaned)
        ? null
        : 'Enter a valid phone number (7-15 digits, optional +)';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, "0")}/${picked.month.toString().padLeft(2, "0")}/${picked.year}';
      _dobCtrl.text = formatted;
      final age = _calculateAge(picked, DateTime.now());
      _ageCtrl.text = age.toString();
      setState(() {});
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted || !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and privacy policy')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'fullName': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'age': _ageCtrl.text.isEmpty ? null : int.tryParse(_ageCtrl.text),
      'dob': _dobCtrl.text.trim(),
      'gender': _gender == 'Gender' ? null : _gender,
    };
    // remove empty values more cleanly
    payload.removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );

    try {
      final result = await AuthService.signup(payload);
      if (result.success) {
        // Don't persist token on signup; direct user to login to authenticate.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful — please sign in')),
        );
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Signup failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: _inputDecoration('Full name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter full name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter email';
                          }
                          final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          return re.hasMatch(v) ? null : 'Enter valid email';
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Phone number'),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: _inputDecoration('Username'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter username'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: _inputDecoration('Password'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter password';
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: _inputDecoration('Confirm password'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirm password';
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Age'),
                              readOnly: true,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Select DOB to calculate age'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dobCtrl,
                              decoration: _inputDecoration('DD/MM/YYYY'),
                              readOnly: true,
                              onTap: _pickDob,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Pick date of birth'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        items: const [
                          DropdownMenuItem(
                            value: 'Gender',
                            child: Text('Gender'),
                          ),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        decoration: _inputDecoration('Gender'),
                        onChanged: (v) =>
                            setState(() => _gender = v ?? 'Gender'),
                        validator: (v) => (v == null || v == 'Gender')
                            ? 'Select gender'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      CheckboxListTile(
                        value: _termsAccepted,
                        onChanged: (v) =>
                            setState(() => _termsAccepted = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('I accept the Terms & Conditions'),
                      ),
                      CheckboxListTile(
                        value: _privacyAccepted,
                        onChanged: (v) =>
                            setState(() => _privacyAccepted = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('I accept the Privacy Policy'),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
