import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/course_module.dart';
import '../../../services/api/career_progress_service.dart';
import '../../../services/course_progress_service.dart';

class CourseVideoPage extends StatefulWidget {
  final CourseModule course;
  final String careerTitle;

  const CourseVideoPage({
    super.key,
    required this.course,
    required this.careerTitle,
  });

  @override
  State<CourseVideoPage> createState() => _CourseVideoPageState();
}

class _CourseVideoPageState extends State<CourseVideoPage> {
  YoutubePlayerController? _controller;
  Timer? _progressTimer;
  bool _isPlayerReady = false;
  bool _isLoading = true; // Add loading state
  double _currentProgress = 0.0;
  int _lastSavedPosition = 0;
  int _savedWatchTimeSeconds = 0; // Store actual watch time
  int _realDurationSeconds = 0; // Store real duration from YouTube

  @override
  void initState() {
    super.initState();
    _initializePlayerWithProgress();
  }

  Future<void> _initializePlayerWithProgress() async {
    // Load progress from database FIRST
    final progressList = await CareerProgressService.getCourseProgress(
      careerName: widget.careerTitle,
    );

    // Find this course's progress
    final courseProgress = progressList.firstWhere(
      (p) => p['courseId'] == widget.course.id,
      orElse: () => <String, dynamic>{},
    );

    if (courseProgress.isNotEmpty) {
      final watchedPercentage = courseProgress['watchedPercentage'];
      final watchTimeSeconds = courseProgress['watchTimeSeconds'];

      widget.course.watchedPercentage = (watchedPercentage is num)
          ? watchedPercentage.toDouble()
          : 0.0;
      widget.course.isCompleted = courseProgress['isCompleted'] == true;

      _currentProgress = widget.course.watchedPercentage;
      _savedWatchTimeSeconds = (watchTimeSeconds is num)
          ? watchTimeSeconds.toInt()
          : 0;

      print(
        '📊 Loaded progress for ${widget.course.skillName}: ${_currentProgress.toStringAsFixed(1)}% at ${_savedWatchTimeSeconds}s',
      );
    }

    // NOW initialize player with the loaded progress
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.course.youtubeVideoId,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        // Seek to saved position using actual watch time seconds
        startAt: (_savedWatchTimeSeconds > 0 && _currentProgress < 95)
            ? _savedWatchTimeSeconds
            : 0,
      ),
    )..addListener(_onPlayerStateChange); // Start tracking when player is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
          _isLoading = false; // Hide loading spinner
        });
      }
    });
  }

  void _onPlayerStateChange() {
    if (_controller == null || !mounted) return;

    // Start tracking when video is playing
    if (_controller!.value.isPlaying && _progressTimer == null) {
      _startProgressTracking();
    } else if (!_controller!.value.isPlaying && _progressTimer != null) {
      _stopProgressTracking();
    }
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller == null || !mounted) {
        timer.cancel();
        return;
      }

      if (!_controller!.value.isPlaying) {
        _stopProgressTracking();
        return;
      }

      final position = _controller!.value.position;
      final duration = _controller!.metadata.duration;

      if (duration.inSeconds > 0) {
        final currentSeconds = position.inSeconds;
        final totalSeconds = duration.inSeconds;
        final percentage = (currentSeconds / totalSeconds * 100).clamp(
          0.0,
          100.0,
        );
        final isCompleted = percentage >= 95.0;

        // Store real duration if we haven't yet
        if (_realDurationSeconds == 0) {
          _realDurationSeconds = totalSeconds;
        }

        // Only save to database every 10 seconds to reduce API calls
        if ((currentSeconds - _lastSavedPosition).abs() >= 10 || isCompleted) {
          _lastSavedPosition = currentSeconds;

          // Save to database
          CareerProgressService.saveCourseProgress(
            careerName: widget.careerTitle,
            courseId: widget.course.id,
            skillName: widget.course.skillName,
            videoTitle: widget.course.title,
            youtubeVideoId: widget.course.youtubeVideoId,
            watchedPercentage: percentage,
            watchTimeSeconds: currentSeconds,
            totalDurationSeconds: totalSeconds,
            isCompleted: isCompleted,
          );

          // Also save to local storage as backup
          CourseProgressService.saveProgress(
            widget.course.id,
            percentage,
            isCompleted,
          );
        }

        if (mounted) {
          setState(() {
            _currentProgress = percentage;
            widget.course.watchedPercentage = percentage;
            widget.course.isCompleted = isCompleted;
          });
        }

        if (isCompleted && _progressTimer != null) {
          _stopProgressTracking();
          _showCompletionDialog();
        }
      }
    });
  }

  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;

    // Save final position when stopping
    if (_controller != null && mounted) {
      final position = _controller!.value.position;
      final duration = _controller!.metadata.duration;

      if (duration.inSeconds > 0) {
        final percentage = (position.inSeconds / duration.inSeconds * 100)
            .clamp(0.0, 100.0);

        // Save to database
        CareerProgressService.saveCourseProgress(
          careerName: widget.careerTitle,
          courseId: widget.course.id,
          skillName: widget.course.skillName,
          videoTitle: widget.course.title,
          youtubeVideoId: widget.course.youtubeVideoId,
          watchedPercentage: percentage,
          watchTimeSeconds: position.inSeconds,
          totalDurationSeconds: duration.inSeconds,
          isCompleted: percentage >= 95.0,
        );

        // Save to local storage as backup
        CourseProgressService.saveProgress(
          widget.course.id,
          percentage,
          percentage >= 95.0,
        );
      }
    }
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Completed!'),
          ],
        ),
        content: Text(
          'Congratulations! You\'ve completed "${widget.course.skillName}" course.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to learning path
            },
            child: const Text('Back to Learning Path'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  void dispose() {
    _stopProgressTracking();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        onReady: () {
          if (mounted) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        },
        onEnded: (metaData) {
          _stopProgressTracking();
          _showCompletionDialog();
        },
      ),
      builder: (context, player) {
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
                  onPressed: () {
                    _stopProgressTracking();
                    Navigator.pop(context);
                  },
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
                    // YouTube Video Player
                    Container(
                      margin: const EdgeInsets.all(16),
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
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: player,
                          ),
                          // Loading overlay
                          if (_isLoading)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Loading video...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ), // Course Info Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Skill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.course.skillName,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Duration
                          if (_isPlayerReady && _controller != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Duration: ${_formatDuration(_controller!.metadata.duration)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          else if (_isLoading)
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading duration...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),

                          // Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Your Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${_currentProgress.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _currentProgress >= 95
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _currentProgress / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _currentProgress >= 95
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Completion Badge
                          if (widget.course.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Description
                          const Text(
                            'About this course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
