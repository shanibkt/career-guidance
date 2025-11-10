import 'package:career_guidence/screens/login.dart';
import 'package:career_guidence/screens/quiz.dart';
import 'package:career_guidence/screens/reg_profile.dart';
import 'package:career_guidence/screens/sinup.dart';
import 'package:flutter/material.dart';
import 'screens/homescreen.dart';
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
  Future<bool> _hasToken() async {
    final t = await StorageService.loadAuthToken();
    return t != null && t.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snap) {
        final start = (snap.data == true)
            ? const HomeScreen()
            : const LoginPage();
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: start,
          routes: {
            '/signup': (context) => const SignUpScreen(),
            '/reg_profile': (context) => const RegProfileScreen(),
            '/home': (context) => const HomeScreen(),
            '/quiz': (context) => const QuizScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
