import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Accent colors
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBBD9FF), Color(0xFF9CC2FF)],
  );

  static const LinearGradient lightBlueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE3F2FD), Colors.white],
  );

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Colors.white;

  // Background colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Colors.white;

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ATS Score colors
  static Color atsExcellent = Colors.green.shade600;
  static Color atsGood = Colors.blue.shade600;
  static Color atsFair = Colors.orange.shade600;
  static Color atsNeedsImprovement = Colors.red.shade600;

  static Color getATSColor(int score) {
    if (score >= 80) return atsExcellent;
    if (score >= 60) return atsGood;
    if (score >= 40) return atsFair;
    return atsNeedsImprovement;
  }

  static LinearGradient getATSGradient(int score) {
    final color = getATSColor(score);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
