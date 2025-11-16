import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blue[200],
      body: Stack(
        children: <Widget>[
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 75, 135, 245), Color(0xFFFFFFFF)],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.10),
              child: _emailSent ? _buildSuccessView() : _buildForm(size),
            ),
          ),
        ],
      ),
    );
  }

  // Form to enter email
  Widget _buildForm(Size size) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          const SizedBox(height: 20),

          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF286ED8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 60),
          ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          const Text(
            'Enter your email address and we\'ll send you\ninstructions to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 40),

          // Email field
          _buildTextField(
            controller: _emailCtrl,
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // Send reset link button
          _buildSendButton(size),

          const SizedBox(height: 20),

          // Back to login
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: Color(0xFF5872C0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Success view after email sent
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 60),
        ),

        const SizedBox(height: 30),

        // Title
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        // Message
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'We\'ve sent password reset instructions to\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),

        const SizedBox(height: 40),

        // Back to login button
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 6,
          ),
          child: const Text(
            'Back to Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Resend link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text(
            'Didn\'t receive email? Resend',
            style: TextStyle(color: Color(0xFF5872C0), fontSize: 14),
          ),
        ),

        const SizedBox(height: 10),

        // Demo: Simulate clicking email link
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              const Text(
                '📧 Demo: Simulate Email Link',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/reset-password');
                },
                icon: const Icon(Icons.link, size: 16),
                label: const Text(
                  'Go to Reset Password →',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Text form field helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 10),
            child: Icon(icon, color: Colors.black54),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // Send button
  Widget _buildSendButton(Size size) {
    return SizedBox(
      width: size.width * 0.7,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendResetLink,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: const Color(0xFF8B5CF6),
          elevation: 6,
        ),
        child: const Text(
          'Send Reset Link',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // Simulate sending email (UI only for now)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Show success screen
    setState(() {
      _emailSent = true;
      _isLoading = false;
    });

    // TODO: Connect to backend when ready
    // final email = _emailCtrl.text.trim();
    // try {
    //   final result = await AuthService.forgotPassword(email);
    //
    //   if (!mounted) return;
    //
    //   if (result.success) {
    //     setState(() {
    //       _emailSent = true;
    //       _isLoading = false;
    //     });
    //   } else {
    //     setState(() => _isLoading = false);
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(result.message ?? 'Failed to send reset link'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
    // } catch (e) {
    //   if (!mounted) return;
    //   setState(() => _isLoading = false);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    //   );
    // }
  }
}
