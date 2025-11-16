import 'package:career_guidence/screens/login.dart';
import 'package:career_guidence/screens/quiz.dart';
import 'package:career_guidence/screens/reg_profile.dart';
import 'package:career_guidence/screens/sinup.dart';
import 'package:career_guidence/screens/forgot_password.dart';
import 'package:career_guidence/screens/reset_password.dart';
import 'package:flutter/material.dart';
import 'screens/homescreen.dart';
import 'models/user.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Map<String, dynamic>?> _loadAuthAndUser() async {
    final token = await StorageService.loadAuthToken();
    if (token == null || token.isEmpty) return null;

    final userMap = await StorageService.loadUser();
    return {'token': token, 'user': userMap};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadAuthAndUser(),
      builder: (context, snap) {
        Widget start;
        if (snap.connectionState == ConnectionState.waiting) {
          start = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasData && snap.data != null) {
          final userMap = snap.data!['user'] as Map<String, dynamic>?;
          final user = userMap != null ? User.fromJson(userMap) : null;
          start = HomeScreen(user: user);
        } else {
          start = const LoginPage();
        }

        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: start,
          routes: {
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpScreen(),
            '/reg_profile': (context) => const RegProfileScreen(),
            '/home': (context) => const HomeScreen(),
            '/quiz': (context) => const QuizScreen(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
