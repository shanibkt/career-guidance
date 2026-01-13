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
    print('🎬 CourseVideoPage initState called');
    print('🎬 Video ID: ${widget.course.youtubeVideoId}');
    print('🎬 Course Title: ${widget.course.title}');

    // Initialize player immediately to prevent null controller
    _initializePlayerWithProgress();
  }

  Future<void> _initializePlayerWithProgress() async {
    try {
      print('🎬 Starting player initialization...');

      // Validate video ID
      if (widget.course.youtubeVideoId.isEmpty) {
        throw Exception('Video ID is empty');
      }

      // First check local storage (fast, no network)
      final localProgress = await CourseProgressService.loadProgress(
        widget.course.id,
      );

      if (localProgress != null) {
        _currentProgress = (localProgress['watchedPercentage'] as num)
            .toDouble();
        final isCompleted = localProgress['isCompleted'] as bool;

        // Get the actual saved watch time from local storage
        _savedWatchTimeSeconds =
            (localProgress['watchTimeSeconds'] as num?)?.toInt() ?? 0;

        if (!isCompleted &&
            _currentProgress < 95 &&
            _savedWatchTimeSeconds == 0) {
          // Fallback: Estimate watch time from percentage if not saved
          _savedWatchTimeSeconds =
              ((widget.course.durationMinutes * 60) * (_currentProgress / 100))
                  .round();
        }

        widget.course.watchedPercentage = _currentProgress;
        widget.course.isCompleted = isCompleted;

        print(
          '📊 Loaded progress: ${_currentProgress.toStringAsFixed(1)}% at ${_savedWatchTimeSeconds}s',
        );
      } else {
        print('📊 No saved progress found, starting from beginning');
      }

      // Initialize player with saved position
      print(
        '🎬 Creating YouTube controller (startAt: $_savedWatchTimeSeconds seconds)',
      );

      _controller = YoutubePlayerController(
        initialVideoId: widget.course.youtubeVideoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          controlsVisibleAtStart: true,
          startAt: (_savedWatchTimeSeconds > 0 && _currentProgress < 95)
              ? _savedWatchTimeSeconds
              : 0,
        ),
      )..addListener(_onPlayerStateChange);

      print('✅ YouTube controller created successfully');

      // Update UI
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
          _isLoading = false;
        });
        print('✅ UI updated - video should be visible now');
      }

      // Then load accurate progress from database in background
      _updateProgressFromDatabase();
    } catch (e, stackTrace) {
      print('❌ FATAL: Error initializing player: $e');
      print('❌ Stack trace: $stackTrace');

      // Create controller anyway with default values to prevent null error
      if (_controller == null) {
        print('🔧 Creating fallback controller...');
        try {
          _controller = YoutubePlayerController(
            initialVideoId: widget.course.youtubeVideoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          )..addListener(_onPlayerStateChange);
          print('✅ Fallback controller created');
        } catch (fallbackError) {
          print('❌ Fallback controller also failed: $fallbackError');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlayerReady = true;
        });
      }
    }
  }

  Future<void> _updateProgressFromDatabase() async {
    try {
      // Load accurate progress from database in background with timeout
      final progressList =
          await CareerProgressService.getCourseProgress(
            careerName: widget.careerTitle,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ Database progress load timed out, using cached data');
              return [];
            },
          );

      // Find this course's progress
      final courseProgress = progressList.firstWhere(
        (p) => p['courseId'] == widget.course.id,
        orElse: () => <String, dynamic>{},
      );

      if (courseProgress.isNotEmpty && mounted) {
        final watchedPercentage = courseProgress['watchedPercentage'];
        final watchTimeSeconds = courseProgress['watchTimeSeconds'];
        final totalDurationSeconds = courseProgress['totalDurationSeconds'];

        widget.course.watchedPercentage = (watchedPercentage is num)
            ? watchedPercentage.toDouble()
            : 0.0;
        widget.course.isCompleted = courseProgress['isCompleted'] == true;

        _currentProgress = widget.course.watchedPercentage;

        // Update with accurate watch time from database
        final accurateWatchTime = (watchTimeSeconds is num)
            ? watchTimeSeconds.toInt()
            : 0;

        // Update real duration if available
        if (totalDurationSeconds is num && totalDurationSeconds > 0) {
          _realDurationSeconds = totalDurationSeconds.toInt();
        }

        print(
          '📊 Updated from database: ${_currentProgress.toStringAsFixed(1)}% at ${accurateWatchTime}s',
        );

        setState(() {});
      }
    } catch (e) {
      print('⚠️ Error loading progress from database: $e');
      // Continue anyway - video started from local storage position
    }
  }

  void _onPlayerStateChange() {
    if (_controller == null || !mounted) return;

    try {
      // Start tracking when video is playing
      if (_controller!.value.isPlaying && _progressTimer == null) {
        _startProgressTracking();
      } else if (!_controller!.value.isPlaying && _progressTimer != null) {
        _stopProgressTracking();
      }
    } catch (e) {
      print('⚠️ Error in player state change: $e');
    }
  }

  void _startProgressTracking() {
    // Check progress every 5 seconds instead of 3 to reduce CPU usage
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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

        // Only save to database every 15 seconds to reduce API calls and improve performance
        if ((currentSeconds - _lastSavedPosition).abs() >= 15 || isCompleted) {
          _lastSavedPosition = currentSeconds;

          // Save to database asynchronously (don't wait for response)
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
          ).catchError((e) {
            // Log error but don't interrupt playback
            print('⚠️ Progress save error (will retry): $e');
            return false;
          });

          // Also save to local storage as backup (fast, no network)
          CourseProgressService.saveProgress(
            widget.course.id,
            percentage,
            isCompleted,
            watchTimeSeconds: currentSeconds,
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
          watchTimeSeconds: position.inSeconds,
        );
      }
    }
  }

  void _showCompletionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
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
          'Congratulations! You\'ve completed "${widget.course.skillName}" course.\n\nYou can now take a quiz to test your knowledge!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to learning path
            },
            child: const Text(
              'Back to Learning Path',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _navigateToSkillQuiz();
            },
            icon: const Icon(Icons.quiz),
            label: const Text('Take Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSkillQuiz() {
    // Navigate to quiz screen with the skill context
    Navigator.pushNamed(
      context,
      '/skill_quiz',
      arguments: {
        'skillName': widget.course.skillName,
        'careerTitle': widget.careerTitle,
        'videoTitle': widget.course.title,
        'youtubeVideoId': widget.course.youtubeVideoId,
      },
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
    print('🧹 Disposing CourseVideoPage resources...');
    _stopProgressTracking();
    _progressTimer?.cancel();
    _progressTimer = null;
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    _controller = null;
    print('✅ Resources disposed successfully');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while controller is being created
    if (_controller == null || _isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Loading Video...'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading ${widget.course.title}...',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Video ID: ${widget.course.youtubeVideoId}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
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

                          // Quiz Button - appears at 90% progress
                          if (_currentProgress >= 90 &&
                              !widget.course.isCompleted)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ElevatedButton.icon(
                                onPressed: _navigateToSkillQuiz,
                                icon: const Icon(Icons.quiz, size: 24),
                                label: const Text(
                                  'Test Your Knowledge',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),

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
