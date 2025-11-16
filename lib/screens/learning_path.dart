import 'package:flutter/material.dart';
import '../models/course_module.dart';
import '../services/course_progress_service.dart';
import 'course_video.dart';

// Learning Path Page
class LearningPathPage extends StatefulWidget {
  final String careerTitle;
  final Color accentColor;

  const LearningPathPage({
    super.key,
    required this.careerTitle,
    this.accentColor = const Color(0xFF286ED8),
  });

  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  List<CourseModule> courses = [];
  double overallProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final loadedCourses = CourseProgressService.getCoursesForCareer(
      widget.careerTitle,
    );

    // Load progress for each course
    for (var course in loadedCourses) {
      final progress = await CourseProgressService.loadProgress(course.id);
      if (progress != null) {
        course.watchedPercentage = (progress['watchedPercentage'] as num)
            .toDouble();
        course.isCompleted = progress['isCompleted'] as bool;
      }
    }

    final overall = await CourseProgressService.calculateOverallProgress(
      widget.careerTitle,
    );

    setState(() {
      courses = loadedCourses;
      overallProgress = overall;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: widget.accentColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Learning Path',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.school, size: 60, color: Colors.white70),
                      const SizedBox(height: 8),
                      Text(
                        widget.careerTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Progress Card
                  _buildOverallProgressCard(),

                  const SizedBox(height: 24),

                  // Course List Header
                  const Text(
                    'Course Modules',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Course List
                  if (courses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No courses available yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...courses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final course = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(course, index + 1),
                      );
                    }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    final completedCount = courses.where((c) => c.isCompleted).length;
    final totalCount = courses.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.accentColor.withOpacity(0.8), widget.accentColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / $totalCount Completed',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? overallProgress / 100 : 0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '${overallProgress.toInt()}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModule course, int number) {
    final statusColor = course.isCompleted
        ? Colors.green
        : course.watchedPercentage > 0
        ? Colors.orange
        : Colors.grey;

    final statusText = course.isCompleted
        ? 'Completed'
        : course.watchedPercentage > 0
        ? 'In Progress'
        : 'Not Started';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseVideoPage(course: course),
          ),
        );
        // Reload progress after returning from video
        _loadCourses();
      },
      child: Container(
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
              children: [
                // Number Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor.withOpacity(0.8),
                        widget.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.label,
                            size: 14,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.skillName,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        course.isCompleted
                            ? Icons.check_circle
                            : course.watchedPercentage > 0
                            ? Icons.play_circle_outline
                            : Icons.circle_outlined,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              course.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: course.watchedPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${course.watchedPercentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Duration and Play Button
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${course.durationMinutes} min',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor.withOpacity(0.8),
                        widget.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Watch',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
