# Learning Videos Database Integration

## Overview
Migrated learning path video content from hardcoded Flutter code to MySQL database, enabling centralized video management and dynamic content delivery.

## Implementation Summary

### 1. Database Schema
**File:** `MyFirstApi/sql/create_learning_videos_table.sql`

**Table Structure:**
```sql
CREATE TABLE learning_videos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    video_title VARCHAR(255) NOT NULL,
    video_description TEXT,
    youtube_video_id VARCHAR(50) NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 0,
    thumbnail_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_skill_name (skill_name)
)
```

**Video Content Coverage:**
- **80+ skills** with YouTube tutorial videos
- Categories: Programming Languages, Web Dev, Mobile Dev, Databases, Frameworks, DevOps, Cloud, Data Science, AI, Design, Testing, Security, Emerging Tech

**Sample Data:**
- Python, Java, JavaScript, C#, C++, PHP, Ruby, Go, Swift, Kotlin, Dart
- HTML, CSS, React, Angular, Vue.js, TypeScript, Node.js
- Flutter, React Native, Android SDK, iOS SDK
- SQL, MySQL, PostgreSQL, MongoDB, Redis
- Docker, Kubernetes, AWS, Azure, Git, Linux
- Machine Learning, Deep Learning, TensorFlow, PyTorch
- And many more...

### 2. Backend API
**File:** `MyFirstApi/Controllers/LearningVideosController.cs`

**Endpoints:**

#### GET `/api/learningvideos`
Fetch all available learning videos.

**Response:**
```json
{
  "videos": [
    {
      "id": 1,
      "skillName": "Python",
      "videoTitle": "Python Complete Tutorial",
      "videoDescription": "Master Python from basics to advanced concepts",
      "youtubeVideoId": "_uQrJ0TkZlc",
      "durationMinutes": 280,
      "thumbnailUrl": "https://img.youtube.com/vi/_uQrJ0TkZlc/maxresdefault.jpg"
    }
  ]
}
```

#### GET `/api/learningvideos/skills?skills=["Python","React","Docker"]`
Fetch videos for specific skills (URL-encoded JSON array).

**Parameters:**
- `skills` (query): JSON array of skill names

**Response:**
```json
{
  "videos": [
    {
      "id": 1,
      "skillName": "Python",
      "videoTitle": "Python Complete Tutorial",
      "youtubeVideoId": "_uQrJ0TkZlc",
      "durationMinutes": 280
    },
    {
      "id": 13,
      "skillName": "React",
      "videoTitle": "React Tutorial",
      "youtubeVideoId": "bMknfKXIFA8",
      "durationMinutes": 144
    }
  ]
}
```

#### GET `/api/learningvideos/{skillName}`
Fetch single video by skill name.

**Example:** `/api/learningvideos/Python`

**Response:**
```json
{
  "id": 1,
  "skillName": "Python",
  "videoTitle": "Python Complete Tutorial",
  "videoDescription": "Master Python from basics to advanced concepts",
  "youtubeVideoId": "_uQrJ0TkZlc",
  "durationMinutes": 280,
  "thumbnailUrl": "https://img.youtube.com/vi/_uQrJ0TkZlc/maxresdefault.jpg"
}
```

**Features:**
- All endpoints are `[AllowAnonymous]` - no authentication required
- Automatic thumbnail URL generation from YouTube video ID
- Parameterized queries to prevent SQL injection
- Maintains skill order in results using `FIELD()` function

### 3. Flutter Service
**File:** `lib/services/api/learning_video_service.dart`

**Class:** `LearningVideoService`

**Methods:**

```dart
// Fetch all videos
static Future<List<CourseModule>> getAllVideos()

// Fetch videos for specific skills
static Future<List<CourseModule>> getVideosBySkills(List<String> skills)

// Fetch single video by skill name
static Future<CourseModule?> getVideoBySkill(String skillName)
```

**Features:**
- Converts API response to `CourseModule` objects
- 30-second timeout for API requests
- Comprehensive error handling with debug prints
- URL encoding for query parameters

### 4. Learning Path Screen Update
**File:** `lib/features/learning_path/screens/learning_path_screen.dart`

**Changes:**
- ❌ **Removed:** 100+ lines of hardcoded skill-to-video mapping
- ✅ **Added:** Dynamic video fetching from database
- ✅ **Added:** Error handling with fallback to empty list
- ✅ **Maintained:** Progress tracking and course completion features

**New `_loadCourses()` Logic:**
```dart
Future<void> _loadCourses() async {
  if (widget.requiredSkills.isEmpty) {
    // No skills provided
    setState(() { courses = []; });
    return;
  }

  try {
    // Fetch from database
    generatedCourses = await LearningVideoService.getVideosBySkills(
      widget.requiredSkills,
    );
  } catch (e) {
    // Handle errors gracefully
    print('Error loading videos: $e');
    generatedCourses = [];
  }

  // Load progress for each course
  // Update state
}
```

## Benefits

### 1. **Centralized Management**
- Single source of truth for video content
- Easy to add/update/remove videos via database
- No code changes required for content updates

### 2. **Scalability**
- Support for unlimited skills and videos
- Easy to expand to new career paths
- Database indexing for fast queries

### 3. **Maintainability**
- Removed 100+ lines of hardcoded data from Flutter
- Cleaner, more focused frontend code
- Separation of concerns (data vs. presentation)

### 4. **Flexibility**
- Can add video metadata (ratings, difficulty, prerequisites)
- Can implement video playlists or learning sequences
- Can track video popularity and usage

### 5. **Performance**
- Fetch only required videos for selected skills
- Database query optimization with indexes
- Reduced app bundle size (no hardcoded video data)

## Setup Instructions

### Step 1: Create Database Table
Run the SQL script to create the table and populate initial data:

```bash
cd MyFirstApi/sql
mysql -u root -p career_guidance_db < create_learning_videos_table.sql
```

Or manually execute in MySQL:
```bash
mysql -u root -p
use career_guidance_db;
source /path/to/create_learning_videos_table.sql;
```

### Step 2: Verify Data
Check that videos were inserted:
```sql
SELECT COUNT(*) FROM learning_videos;
-- Should return 80+ rows

SELECT skill_name, video_title FROM learning_videos LIMIT 10;
```

### Step 3: Test API Endpoints

**Test all videos:**
```bash
curl http://localhost:5001/api/learningvideos
```

**Test specific skills:**
```bash
curl "http://localhost:5001/api/learningvideos/skills?skills=[\"Python\",\"React\"]"
```

**Test single skill:**
```bash
curl http://localhost:5001/api/learningvideos/Python
```

### Step 4: Flutter Integration
The Flutter app automatically uses the new service. No additional setup required.

## Usage Flow

1. **User selects career** → Career has `required_skills` JSON array
2. **Navigate to Learning Path** → Pass `requiredSkills` to `LearningPathPage`
3. **Fetch videos** → `LearningVideoService.getVideosBySkills(requiredSkills)`
4. **Display courses** → Convert API response to `CourseModule` list
5. **Track progress** → Use existing `CourseProgressService`

## API Examples

### Fetch Videos for Frontend Developer Career
**Career Skills:** `["HTML", "CSS", "JavaScript", "React", "TypeScript"]`

**Request:**
```http
GET /api/learningvideos/skills?skills=["HTML","CSS","JavaScript","React","TypeScript"]
```

**Response:**
```json
{
  "videos": [
    {
      "id": 12,
      "skillName": "HTML",
      "videoTitle": "HTML Full Course",
      "youtubeVideoId": "qz0aGYrrlhU",
      "durationMinutes": 120
    },
    {
      "id": 13,
      "skillName": "CSS",
      "videoTitle": "CSS Complete Guide",
      "youtubeVideoId": "yfoY53QXEnI",
      "durationMinutes": 180
    },
    {
      "id": 14,
      "skillName": "JavaScript",
      "videoTitle": "JavaScript Tutorial",
      "youtubeVideoId": "PkZNo7MFNFg",
      "durationMinutes": 195
    },
    {
      "id": 15,
      "skillName": "React",
      "videoTitle": "React Tutorial",
      "youtubeVideoId": "bMknfKXIFA8",
      "durationMinutes": 144
    },
    {
      "id": 18,
      "skillName": "TypeScript",
      "videoTitle": "TypeScript Course",
      "youtubeVideoId": "d56mG7DezGs",
      "durationMinutes": 180
    }
  ]
}
```

## Error Handling

### Backend Errors
- **Invalid skills parameter**: Returns 400 Bad Request
- **Database connection error**: Returns 500 Internal Server Error
- **Skill not found**: Returns 404 Not Found (for single skill endpoint)

### Frontend Errors
- **Network timeout**: Falls back to empty course list
- **Invalid response**: Logs error and shows empty state
- **No videos found**: Displays message to user

## Future Enhancements

### 1. Video Metadata
- Add difficulty level (Beginner, Intermediate, Advanced)
- Add prerequisites for each skill
- Add estimated completion time
- Add video language options

### 2. Content Management
- Admin panel to add/edit/delete videos
- Bulk import from CSV/JSON
- Video quality ratings and reviews
- Alternative video sources (Vimeo, self-hosted)

### 3. Personalization
- Track user's watched videos
- Recommend next videos based on progress
- Adaptive learning paths
- Bookmark favorite videos

### 4. Analytics
- Track video popularity
- Monitor completion rates
- Identify content gaps
- A/B test different video selections

### 5. Advanced Features
- Video playlists for complex skills
- Multiple videos per skill (beginner/advanced)
- Video transcripts and captions
- Practice exercises linked to videos

## Troubleshooting

### Videos Not Loading in Flutter
1. Check API endpoint is accessible: `curl http://192.168.1.102:5001/api/learningvideos`
2. Verify `ApiConstants.baseUrl` is correct in Flutter
3. Check network connectivity from device/emulator
4. Review Flutter console logs for error messages

### Empty Video List
1. Verify skills are spelled correctly (case-sensitive)
2. Check database has videos for requested skills
3. Ensure SQL script was executed successfully
4. Query database directly: `SELECT * FROM learning_videos WHERE skill_name = 'Python'`

### API Returns 500 Error
1. Check MySQL service is running
2. Verify connection string in `appsettings.json`
3. Review backend console logs for exception details
4. Check database user has SELECT permissions

## Migration Checklist

- [x] Create `learning_videos` database table
- [x] Insert 80+ skill videos into database
- [x] Create `LearningVideosController` with 3 endpoints
- [x] Create `LearningVideoService` in Flutter
- [x] Update `learning_path_screen.dart` to use API
- [x] Remove hardcoded video data (100+ lines)
- [x] Test API endpoints
- [x] Test Flutter integration
- [x] Document implementation

## Conclusion

The learning videos database integration successfully migrates hardcoded video content to a scalable, maintainable database solution. This enables dynamic content management, easier updates, and better separation of concerns between frontend and backend.

**Code Reduction:** -100 lines in Flutter (removed hardcoded data)  
**Database Records:** 80+ learning videos  
**API Endpoints:** 3 new endpoints  
**Maintenance:** Content updates now require only database changes
