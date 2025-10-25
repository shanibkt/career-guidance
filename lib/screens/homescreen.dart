import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Career Guidance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Career Guidance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Explore career opportunities and get personalized guidance based on your profile.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            _buildFeatureCard(
              icon: Icons.person,
              title: 'Profile',
              subtitle:
                  'Complete your profile to get personalized recommendations',
              onTap: () {
                // Navigate to profile screen
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.search,
              title: 'Career Search',
              subtitle: 'Explore different career paths and opportunities',
              onTap: () {
                // Navigate to career search
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.assessment,
              title: 'Assessments',
              subtitle: 'Take career assessments to discover your strengths',
              onTap: () {
                // Navigate to assessments
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
