import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course_module.dart';
import '../services/course_progress_service.dart';

class CourseVideoPage extends StatefulWidget {
  final CourseModule course;

  const CourseVideoPage({super.key, required this.course});

  @override
  State<CourseVideoPage> createState() => _CourseVideoPageState();
}

class _CourseVideoPageState extends State<CourseVideoPage> {
  Timer? _progressTimer;
  int _currentSeconds = 0;
  bool _isWatching = false;

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final progress = await CourseProgressService.loadProgress(widget.course.id);
    if (progress != null) {
      widget.course.watchedPercentage = (progress['watchedPercentage'] as num)
          .toDouble();
      widget.course.isCompleted = progress['isCompleted'] as bool;
      setState(() {});
    }
  }

  void _startProgressTracking() {
    if (_progressTimer != null) return;

    setState(() => _isWatching = true);

    // Simulate progress tracking every 10 seconds
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _currentSeconds += 10;
      final totalSeconds = widget.course.durationMinutes * 60;
      final percentage = (_currentSeconds / totalSeconds * 100).clamp(
        0.0,
        100.0,
      );
      final isCompleted = percentage >= 95;

      CourseProgressService.saveProgress(
        widget.course.id,
        percentage,
        isCompleted,
      );

      if (mounted) {
        setState(() {
          widget.course.watchedPercentage = percentage;
          widget.course.isCompleted = isCompleted;
        });
      }

      if (isCompleted) {
        timer.cancel();
      }
    });
  }

  void _openYouTubeVideo() {
    final youtubeUrl =
        'https://www.youtube.com/watch?v=${widget.course.youtubeVideoId}';

    // Show dialog with YouTube URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open in YouTube'),
        content: Text('Opening video in browser:\n\n$youtubeUrl'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startProgressTracking();
            },
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 60,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Course',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player Card with Thumbnail
                GestureDetector(
                  onTap: _openYouTubeVideo,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // YouTube Thumbnail
                          Image.network(
                            'https://img.youtube.com/vi/${widget.course.youtubeVideoId}/maxresdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade700,
                                      Colors.purple.shade700,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          // Dark overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Play button
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isWatching
                                    ? Icons.play_arrow
                                    : Icons.play_arrow,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          // Watch status indicator
                          if (_isWatching)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Watching',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Course Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Skill Tag
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.course.skillName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Progress Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.course.watchedPercentage.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: widget.course.watchedPercentage / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            widget.course.isCompleted
                                ? Icons.check_circle
                                : Icons.access_time,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.course.isCompleted
                                ? 'Completed!'
                                : '${widget.course.durationMinutes} minutes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF286ED8),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'About this course',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.course.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to favorites'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade50,
                            foregroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
