import 'package:flutter/material.dart';

// Career Suggestions Page
class CareerSuggestionsPage extends StatelessWidget {
  const CareerSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FF),
      appBar: AppBar(
        title: const Text('Career Suggestions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSuggestionCard(
            'Software Developer',
            'High demand role with great growth potential',
            Icons.computer,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSuggestionCard(
            'Data Scientist',
            'Analyze data to drive business decisions',
            Icons.analytics,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildSuggestionCard(
            'UX Designer',
            'Create intuitive user experiences',
            Icons.design_services,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
        ],
      ),
    );
  }
}
