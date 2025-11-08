import 'package:career_guidence/screens/login.dart';
import 'package:career_guidence/screens/quiz.dart';
import 'package:career_guidence/screens/reg_profile.dart';
import 'package:career_guidence/screens/sinup.dart';
import 'package:flutter/material.dart';

import 'screens/homescreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignUpScreen(),
        '/reg_profile': (context) => const RegProfileScreen(),
        '/home': (context) => const HomeScreen(),
        '/quiz': (context) => const QuizScreen(),
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
