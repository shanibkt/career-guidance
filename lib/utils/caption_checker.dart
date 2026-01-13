import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Utility to check if a YouTube video has captions before adding to database
class CaptionChecker {
  static Future<CaptionCheckResult> checkVideo(String videoId) async {
    final yt = YoutubeExplode();

    try {
      print('🔍 Checking video: $videoId');

      // Get video info
      final video = await yt.videos.get(videoId);
      print('📹 Title: ${video.title}');
      print('⏱️  Duration: ${video.duration}');

      // Check for captions
      final manifest = await yt.videos.closedCaptions.getManifest(videoId);

      if (manifest.tracks.isEmpty) {
        print('❌ No captions available');
        yt.close();
        return CaptionCheckResult(
          videoId: videoId,
          title: video.title,
          duration: video.duration ?? Duration.zero,
          hasCaptions: false,
          hasEnglishCaptions: false,
          availableLanguages: [],
          message: 'No captions available - will use skill-based quiz',
        );
      }

      final languages = manifest.tracks.map((t) => t.language.name).toList();
      final hasEnglish = manifest.tracks.any((t) => t.language.code == 'en');

      print('✅ Has ${manifest.tracks.length} caption track(s)');
      print('📝 Languages: ${languages.join(", ")}');
      print('🇬🇧 English: ${hasEnglish ? "Yes" : "No"}');

      // Test downloading a caption
      if (hasEnglish) {
        try {
          final track = manifest.getByLanguage('en').first;
          final captions = await yt.videos.closedCaptions.get(track);
          final transcriptLength = captions.captions
              .map((c) => c.text)
              .join(' ')
              .length;

          print('📥 Downloaded ${transcriptLength} characters of transcript');
        } catch (e) {
          print('⚠️  Could not download captions: $e');
        }
      }

      yt.close();

      return CaptionCheckResult(
        videoId: videoId,
        title: video.title,
        duration: video.duration ?? Duration.zero,
        hasCaptions: true,
        hasEnglishCaptions: hasEnglish,
        availableLanguages: languages,
        message: hasEnglish
            ? 'Perfect! Has English captions - will generate video-specific quiz'
            : 'Has captions but no English - will use first available language',
      );
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack trace: $stackTrace');
      yt.close();

      return CaptionCheckResult(
        videoId: videoId,
        title: 'Error',
        duration: Duration.zero,
        hasCaptions: false,
        hasEnglishCaptions: false,
        availableLanguages: [],
        message: 'Error checking video: $e',
        error: e.toString(),
      );
    }
  }

  /// Check multiple videos and return summary
  static Future<List<CaptionCheckResult>> checkMultipleVideos(
    Map<String, String> skillToVideoId,
  ) async {
    final results = <CaptionCheckResult>[];

    print('\n🔍 Checking ${skillToVideoId.length} videos...\n');
    print('=' * 80);

    for (var entry in skillToVideoId.entries) {
      final skill = entry.key;
      final videoId = entry.value;

      print('\n📚 Skill: $skill');
      final result = await checkVideo(videoId);
      results.add(result);

      // Small delay to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 500));
    }

    print('\n' + '=' * 80);
    _printSummary(results);

    return results;
  }

  static void _printSummary(List<CaptionCheckResult> results) {
    final withCaptions = results.where((r) => r.hasCaptions).length;
    final withEnglish = results.where((r) => r.hasEnglishCaptions).length;
    final withoutCaptions = results.where((r) => !r.hasCaptions).length;
    final errors = results.where((r) => r.error != null).length;

    print('\n📊 SUMMARY:');
    print('   Total: ${results.length}');
    print(
      '   ✅ With captions: $withCaptions (${(withCaptions / results.length * 100).toStringAsFixed(1)}%)',
    );
    print(
      '   🇬🇧 With English: $withEnglish (${(withEnglish / results.length * 100).toStringAsFixed(1)}%)',
    );
    print(
      '   ❌ No captions: $withoutCaptions (${(withoutCaptions / results.length * 100).toStringAsFixed(1)}%)',
    );
    if (errors > 0) {
      print('   ⚠️  Errors: $errors');
    }

    if (withoutCaptions > 0) {
      print('\n⚠️  Videos needing replacement:');
      for (var result in results.where(
        (r) => !r.hasCaptions && r.error == null,
      )) {
        print('   • ${result.videoId} - ${result.title}');
      }
    }
  }
}

class CaptionCheckResult {
  final String videoId;
  final String title;
  final Duration duration;
  final bool hasCaptions;
  final bool hasEnglishCaptions;
  final List<String> availableLanguages;
  final String message;
  final String? error;

  CaptionCheckResult({
    required this.videoId,
    required this.title,
    required this.duration,
    required this.hasCaptions,
    required this.hasEnglishCaptions,
    required this.availableLanguages,
    required this.message,
    this.error,
  });

  bool get isSuccess => error == null && hasCaptions;

  Color get statusColor {
    if (error != null) return Colors.red;
    if (hasEnglishCaptions) return Colors.green;
    if (hasCaptions) return Colors.orange;
    return Colors.red;
  }

  IconData get statusIcon {
    if (error != null) return Icons.error;
    if (hasEnglishCaptions) return Icons.check_circle;
    if (hasCaptions) return Icons.warning;
    return Icons.cancel;
  }

  String get statusText {
    if (error != null) return 'Error';
    if (hasEnglishCaptions) return 'Perfect';
    if (hasCaptions) return 'Has Captions';
    return 'No Captions';
  }
}

/// Widget to display caption check results
class CaptionCheckResultCard extends StatelessWidget {
  final CaptionCheckResult result;
  final String? skillName;

  const CaptionCheckResultCard({
    super.key,
    required this.result,
    this.skillName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(result.statusIcon, color: result.statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (skillName != null)
                        Text(
                          skillName!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        result.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    result.hasEnglishCaptions
                        ? Icons.video_library
                        : Icons.text_fields,
                    color: result.statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.message,
                      style: TextStyle(
                        color: result.statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (result.availableLanguages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Languages: ${result.availableLanguages.join(", ")}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(result.duration),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  result.videoId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
