import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/utils/network_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/job_provider.dart';
// Feature-based imports
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/profile/screens/reg_profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/quiz/screens/quiz_screen.dart';
import 'features/quiz/screens/skill_quiz_screen.dart';
import 'features/jobs/screens/job_finder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run network diagnostics on startup
  await NetworkHelper.runDiagnostics();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider<JobProvider>(create: (_) => JobProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
      context.read<ProfileProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        Widget start;

        if (authProvider.isLoading) {
          start = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (authProvider.isAuthenticated) {
          start = HomeScreen(user: authProvider.user);
        } else {
          start = const LoginPage();
        }

        return MaterialApp(
          title: 'Career Guidance',
          theme: AppTheme.lightTheme,
          home: start,
          routes: {
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpScreen(),
            '/reg_profile': (context) => const RegProfileScreen(),
            '/home': (context) => const HomeScreen(),
            '/quiz': (context) => const QuizScreen(),
            '/jobs': (context) => const JobFinderPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
          },
          onGenerateRoute: (settings) {
            // Handle routes with arguments
            if (settings.name == '/skill_quiz') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SkillQuizScreen(
                  skillName: args?['skillName'] ?? '',
                  careerTitle: args?['careerTitle'],
                  videoTitle: args?['videoTitle'],
                  youtubeVideoId: args?['youtubeVideoId'],
                ),
              );
            }
            return null;
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
