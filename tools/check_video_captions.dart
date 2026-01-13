import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Script to check which YouTube videos have captions available
/// Run this to verify your video database has caption-enabled videos
void main() async {
  final yt = YoutubeExplode();

  // List of video IDs from your database
  final videoIds = {
    'Python': '_uQrJ0TkZlc',
    'Java': 'eIrMbAQSU34',
    'JavaScript': 'PkZNo7MFNFg',
    'C#': 'GhQdlIFylQ8',
    'C++': 'vLnPwxZdW4Y',
    'PHP': 'OK_JCtrrv-c',
    'Ruby': 't_ispmWmdjY',
    'Go': 'YS4e4q9oBaU',
    'Swift': 'CwA1VWP0Ldw',
    'Kotlin': 'F9UC9DY-vIU',
    'Dart': '5xlVP04905w',
    'HTML': 'qz0aGYrrlhU',
    'CSS': 'yfoY53QXEnI',
    'React': 'bMknfKXIFA8',
    'Angular': 'k5E2AVpwsko',
    'Vue.js': 'FXpIoQ_rT_c',
    'TypeScript': 'd56mG7DezGs',
    'Node.js': 'TlB_eWDSMt4',
    'Flutter': 'VPvVD8t02U8',
    'React Native': '0-S5a0eXPoc',
    'Android SDK': 'fis26HvvDII',
    'iOS SDK': '09TeUXjzpKs',
    'SQL': 'HXV3zeQKqGY',
    'MySQL': '7S_tz1z_5bA',
    'PostgreSQL': 'qw--VYLpxG4',
    'MongoDB': 'c2M-rlkkT5o',
    'Redis': 'jgpVdJB2sKQ',
  };

  print('🔍 Checking caption availability for ${videoIds.length} videos...\n');
  print('=' * 80);

  int withCaptions = 0;
  int withoutCaptions = 0;
  List<String> videosWithCaptions = [];
  List<String> videosWithoutCaptions = [];

  for (var entry in videoIds.entries) {
    final skill = entry.key;
    final videoId = entry.value;

    try {
      print('\n📹 Checking: $skill');
      print('   Video ID: $videoId');

      final manifest = await yt.videos.closedCaptions.getManifest(videoId);

      if (manifest.tracks.isNotEmpty) {
        withCaptions++;
        videosWithCaptions.add(skill);
        print('   ✅ HAS CAPTIONS (${manifest.tracks.length} tracks)');

        // Show available languages
        final languages = manifest.tracks
            .map((t) => t.language.name)
            .join(', ');
        print('   📝 Languages: $languages');

        // Check for English
        final hasEnglish = manifest.tracks.any((t) => t.language.code == 'en');
        if (hasEnglish) {
          print('   🇬🇧 English captions available');
        } else {
          print('   ⚠️  No English captions (quiz will use first available)');
        }
      } else {
        withoutCaptions++;
        videosWithoutCaptions.add(skill);
        print('   ❌ NO CAPTIONS AVAILABLE');
        print('   💡 Quiz will be skill-based instead of transcript-based');
      }
    } catch (e) {
      withoutCaptions++;
      videosWithoutCaptions.add(skill);
      print('   ❌ ERROR: $e');
      print('   💡 Video might be unavailable or restricted');
    }

    // Small delay to avoid rate limiting
    await Future.delayed(Duration(milliseconds: 500));
  }

  print('\n' + '=' * 80);
  print('\n📊 SUMMARY:');
  print('   Total videos checked: ${videoIds.length}');
  print(
    '   ✅ Videos with captions: $withCaptions (${(withCaptions / videoIds.length * 100).toStringAsFixed(1)}%)',
  );
  print(
    '   ❌ Videos without captions: $withoutCaptions (${(withoutCaptions / videoIds.length * 100).toStringAsFixed(1)}%)',
  );

  if (videosWithCaptions.isNotEmpty) {
    print('\n✅ Skills with caption-enabled videos:');
    for (var skill in videosWithCaptions) {
      print('   • $skill');
    }
  }

  if (videosWithoutCaptions.isNotEmpty) {
    print('\n❌ Skills without caption-enabled videos:');
    for (var skill in videosWithoutCaptions) {
      print('   • $skill');
    }
    print(
      '\n💡 These videos need to be replaced with caption-enabled alternatives.',
    );
  }

  print('\n' + '=' * 80);
  print('\n📌 RECOMMENDATIONS:');
  print(
    '   1. Replace videos without captions with alternatives that have captions',
  );
  print('   2. Look for videos with "CC" badge on YouTube');
  print(
    '   3. Use videos from educational channels (they usually have captions)',
  );
  print('   4. Consider using official documentation videos');
  print('   5. Test captions before adding to database');

  yt.close();
}
