import 'package:flutter/material.dart';
import 'career_detail_screen.dart';
import '../../../services/api/career_service.dart';
import '../../../models/career.dart';

// Career Suggestions Page
class CareerSuggestionsPage extends StatefulWidget {
  final List<String> userSkills;

  const CareerSuggestionsPage({super.key, this.userSkills = const []});

  @override
  State<CareerSuggestionsPage> createState() => _CareerSuggestionsPageState();
}

class _CareerSuggestionsPageState extends State<CareerSuggestionsPage> {
  List<Career> _sortedCareers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  Future<void> _loadCareers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final careers = await CareerService.getAllCareers();

      // Calculate match percentages for each career
      final careersWithMatches = careers
          .map((career) => career.copyWithMatchPercentage(widget.userSkills))
          .toList();

      // Sort by match percentage (highest first)
      careersWithMatches.sort(
        (a, b) => b.matchPercentage.compareTo(a.matchPercentage),
      );

      setState(() {
        _sortedCareers = careersWithMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load careers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadCareers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _sortedCareers.isEmpty
          ? const Center(
              child: Text(
                'No careers available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _sortedCareers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final career = _sortedCareers[index];
                return _buildSuggestionCard(
                  context,
                  career,
                  _getCareerColor(index),
                );
              },
            ),
    );
  }

  Color _getCareerColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  IconData _getCareerIcon(String careerName) {
    final name = careerName.toLowerCase();
    if (name.contains('developer') || name.contains('engineer')) {
      return Icons.computer;
    } else if (name.contains('data') || name.contains('scientist')) {
      return Icons.analytics;
    } else if (name.contains('design')) {
      return Icons.design_services;
    } else if (name.contains('mobile')) {
      return Icons.phone_android;
    } else if (name.contains('backend')) {
      return Icons.storage;
    } else if (name.contains('frontend')) {
      return Icons.web;
    }
    return Icons.work_outline;
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    Career career,
    Color color,
  ) {
    // Determine match level color
    Color matchColor;
    String matchLabel;
    if (career.matchPercentage >= 70) {
      matchColor = Colors.green;
      matchLabel = 'High Match';
    } else if (career.matchPercentage >= 40) {
      matchColor = Colors.orange;
      matchLabel = 'Medium Match';
    } else {
      matchColor = Colors.grey;
      matchLabel = 'Low Match';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CareerDetailPage(
              careerTitle: career.name,
              overview: career.description,
              requiredSkills: career.requiredSkills,
              userSkills: widget.userSkills,
              accentColor: color,
            ),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCareerIcon(career.name),
                    color: color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        career.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matchLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: matchColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Match percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: matchColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: matchColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: matchColor),
                      const SizedBox(width: 4),
                      Text(
                        '${career.matchPercentage.round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: matchColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: career.matchPercentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(matchColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${career.requiredSkills.length} skills required',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
