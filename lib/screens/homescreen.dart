import 'package:flutter/material.dart';

import '../models/user.dart';

class HomeScreen extends StatelessWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? user?.username ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'AI Career Pathfinder',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // Welcome section with dynamic name
              Text(
                'Hi, $displayName', // Using the displayName from user parameter
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Progress section
              Row(
                children: [
                  const Text(
                    'learning progress',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '60%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar
              LinearProgressIndicator(
                value: 0.6,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 20),

              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 20),

              // Career Quiz section
              _buildSection(
                icon: Icons.help_outline,
                title: 'Career Quiz',
                subtitle: 'Discover your ideal career path',
                buttonText: 'Start',
                onPressed: () {},
              ),
              const SizedBox(height: 20),

              // Career Suggestions section
              _buildSection(
                icon: Icons.check_circle_outline,
                title: 'Career suggestions',
                subtitle: '3 New',
                buttonText: 'View',
                onPressed: () {},
                hasBadge: true,
              ),
              const SizedBox(height: 20),

              // Learning Path section
              _buildSection(
                icon: Icons.school_outlined,
                title: 'Learning Path',
                subtitle: 'Track your learning journey',
                buttonText: '2 Check',
                onPressed: () {},
              ),
              const SizedBox(height: 20),

              // Resume Builder section
              _buildSection(
                icon: Icons.description_outlined,
                title: 'Resume Builder',
                subtitle: 'Create professional resumes',
                buttonText: 'Build',
                onPressed: () {},
                showDoubleButton: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    bool hasBadge = false,
    bool showDoubleButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasBadge ? Colors.green : Colors.grey[600],
                    fontWeight: hasBadge ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (showDoubleButton) ...[
            _buildActionButton(buttonText, onPressed),
            const SizedBox(width: 8),
            _buildActionButton(buttonText, onPressed),
          ] else
            _buildActionButton(buttonText, onPressed),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
