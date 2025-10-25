import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive layout
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Use a Stack to place the content over the background gradient
      body: Stack(
        children: <Widget>[
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              // The gradient is a very light blue/purple, slightly faded
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F0FF), // Lighter top color
                  Color(0xFFFFFFFF), // White or very light bottom color
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // 2. Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // 3. App Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF286ED8), // Deep blue background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons
                          .compass_calibration, // Used a similar icon for a compass/direction feel
                      color: Colors.white,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Welcome Text
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 5. Email Text Field
                  _buildTextField(
                    hintText: 'Enter Your Email',
                    icon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 20),

                  // 6. Password Text Field
                  _buildTextField(
                    hintText: 'Enter Your Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 7. Login Button
                  _buildLoginButton(size),

                  const SizedBox(height: 30),

                  // 8. Google Sign-In Button (represented by the image)
                  const Image(
                    image: AssetImage(
                      'assets/google_logo.png',
                    ), // Assumes you have a google_logo.png in your assets folder
                    width: 30,
                    height: 30,
                  ),

                  const SizedBox(height: 20),

                  // 9. Sign Up Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Didn't sign in? ",
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to sign up page
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(
                              0xFF5872C0,
                            ), // A matching blue for the link
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Custom Text Field Widget
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
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
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 10),
            child: Icon(icon, color: Colors.black54),
          ),
          border: InputBorder.none, // Removes the standard underline
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // Custom Gradient Login Button
  Widget _buildLoginButton(Size size) {
    return Container(
      width: size.width * 0.6,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // Soft purple to light purple gradient
          colors: [
            Color(0xFFB18AFF), // Darker purple (bottom/left)
            Color(0xFF8B5CF6), // Lighter purple (top/right)
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle login logic
          },
          borderRadius: BorderRadius.circular(30),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text(
              'Login',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
