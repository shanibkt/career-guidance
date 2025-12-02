# Testing Guide - Progress Tracking System

## Prerequisites
- ✅ Backend server running on http://192.168.1.102:5001
- ✅ MySQL database: my_database (password: 1234)
- ✅ Flutter app installed on device/emulator
- ✅ User logged in (User ID: 1)

## Test Scenarios

### 1️⃣ Career Selection
**Steps:**
1. Open app and navigate to Career Selection
2. Choose a career (e.g., "Full Stack Developer")
3. Tap "Start Learning Path"

**Expected Results:**
- ✅ Loading spinner appears
- ✅ Career saves to database
- ✅ Navigates to Learning Path screen
- ✅ Career appears on Home screen

**Verify in Database:**
```sql
SELECT * FROM user_career_progress WHERE user_id = 1 AND is_active = TRUE;
```

---

### 2️⃣ Video Progress Tracking
**Steps:**
1. Open a course video
2. Watch for 30 seconds
3. Pause the video
4. Check console logs

**Expected Results:**
- ✅ Video shows real duration (not fake time)
- ✅ Progress bar updates in real-time
- ✅ Progress percentage updates every 3 seconds
- ✅ Console log: "📊 Saved progress..."
- ✅ Progress saves to database

**Verify in Database:**
```sql
SELECT * FROM course_progress 
WHERE user_id = 1 
ORDER BY last_watched DESC 
LIMIT 5;
```

**Check:**
- `watched_percentage` should be ~(30s / total_duration * 100)
- `watch_time_seconds` should be ~30
- `total_duration_seconds` should match video's real duration
- `last_watched` timestamp should be recent

---

### 3️⃣ Progress Persistence
**Steps:**
1. Watch Video A for 1 minute (e.g., Python Basics)
2. Go back to Learning Path
3. Open Video B (e.g., JavaScript Basics)
4. Watch for 30 seconds
5. Go back to Learning Path
6. Check both video cards

**Expected Results:**
- ✅ Video A shows ~X% progress (based on 1 minute watched)
- ✅ Video B shows ~Y% progress (based on 30 seconds watched)
- ✅ Neither progress resets to 0%
- ✅ Progress bars reflect correct percentages

**Database Check:**
```sql
SELECT skill_name, watched_percentage, watch_time_seconds, is_completed
FROM course_progress
WHERE user_id = 1 AND career_name = 'Full Stack Developer';
```

---

### 4️⃣ Video Resume Feature
**Steps:**
1. Open a video and watch for 2 minutes
2. Go back to Learning Path
3. Open the SAME video again
4. Check video position

**Expected Results:**
- ✅ Video automatically seeks to last watched position
- ✅ Video does NOT restart from 0:00
- ✅ Progress bar shows correct percentage
- ✅ Console log: "📊 Loaded progress for {skill}: X%"

**Verify:**
- Video player should start at ~2:00 (or saved position)
- Progress percentage matches database value

---

### 5️⃣ Video Completion
**Steps:**
1. Open a video
2. Skip to near the end (e.g., last 30 seconds)
3. Watch until end or let percentage reach 95%+
4. Check for completion dialog

**Expected Results:**
- ✅ Completion dialog appears at 95% watched
- ✅ Dialog shows "Completed!" message
- ✅ "Back to Learning Path" button appears
- ✅ Course marked as completed in database

**Database Check:**
```sql
SELECT skill_name, watched_percentage, is_completed, last_watched
FROM course_progress
WHERE user_id = 1 AND is_completed = TRUE;
```

**Learning Path Check:**
- ✅ Video card shows "Completed" badge
- ✅ Green checkmark icon appears
- ✅ Overall progress updates

---

### 6️⃣ App Restart Persistence
**Steps:**
1. Watch several videos with different progress levels
2. Close the app completely (force stop)
3. Reopen the app
4. Navigate to Learning Path

**Expected Results:**
- ✅ Selected career loads from database
- ✅ All video progress loads from database
- ✅ Progress bars show correct percentages
- ✅ Completed videos show completion status

**Home Screen Check:**
- ✅ Selected career displays correctly
- ✅ Career loaded from database (check console logs)

---

### 7️⃣ Overall Progress Calculation
**Steps:**
1. Complete 2 out of 5 videos fully (95%+)
2. Watch 2 videos partially (50%)
3. Leave 1 video unwatched (0%)
4. Go to Learning Path screen

**Expected Results:**
- ✅ Overall progress = Average of all video progress
- ✅ Calculation: (100 + 100 + 50 + 50 + 0) / 5 = 60%
- ✅ Progress card shows correct overall percentage

**Database Check:**
```sql
SELECT 
  AVG(watched_percentage) as overall_progress,
  SUM(CASE WHEN is_completed = TRUE THEN 1 ELSE 0 END) as completed_count,
  COUNT(*) as total_courses
FROM course_progress
WHERE user_id = 1 AND career_name = 'Full Stack Developer';
```

---

### 8️⃣ Multiple Users Test
**Steps:**
1. Create another user account (User ID: 2)
2. Select a different career
3. Watch different videos
4. Check database isolation

**Expected Results:**
- ✅ User 1's progress is independent
- ✅ User 2's progress is independent
- ✅ No data mixing between users

**Database Check:**
```sql
SELECT user_id, career_name, COUNT(*) as videos_watched
FROM course_progress
GROUP BY user_id, career_name;
```

---

## Console Logs to Look For

### Success Logs
```
📍 Loaded career from database: {careerTitle: Full Stack Developer}
📚 Fetching videos from database for skills: [Python, React, ...]
📊 Loaded progress for Python: 45.5%
✅ Career saved successfully
✅ Progress saved successfully
```

### Warning Logs
```
⚠️ Failed to load career from database, using local storage
⚠️ No videos found in database for provided skills
```

### Error Logs (Should NOT appear)
```
❌ Error loading videos from database
❌ Failed to save career
❌ Failed to save progress
```

---

## Database Quick Checks

### View All Progress Data
```sql
-- User's selected career
SELECT * FROM user_career_progress WHERE user_id = 1;

-- All course progress
SELECT 
  skill_name,
  video_title,
  watched_percentage,
  is_completed,
  last_watched
FROM course_progress
WHERE user_id = 1
ORDER BY last_watched DESC;

-- Career path in profile
SELECT Id, UserId, career_path FROM UserProfiles WHERE UserId = 1;
```

### Clear Progress (For Re-testing)
```sql
-- Clear all progress for user 1
DELETE FROM course_progress WHERE user_id = 1;
DELETE FROM user_career_progress WHERE user_id = 1;
UPDATE UserProfiles SET career_path = NULL WHERE UserId = 1;
```

---

## Performance Checks

### Network Calls
- Progress saves every 10 seconds (not every second)
- Max ~360 API calls for a 1-hour video
- Acceptable load for remote database

### UI Responsiveness
- Video player should not lag
- Progress bar updates smoothly
- No freezing during saves

### Memory Usage
- No memory leaks from timer
- Timer properly disposed on screen exit

---

## Known Edge Cases

### 1. Network Failure
- App falls back to local storage
- Progress queues for next sync (future enhancement)

### 2. Video < 10 Seconds
- Still tracks progress correctly
- Saves on completion even if < 10s

### 3. Seeking/Skipping
- Progress updates based on current position
- Cannot "cheat" completion by skipping

### 4. Background/Minimize
- Timer pauses when video pauses
- Final position saved on background

---

## Success Criteria

✅ **All bugs fixed:**
- Real duration displayed
- Progress persists across sessions
- Videos resume from last position
- Career saved to database

✅ **Database integration:**
- All progress in `course_progress` table
- Career in `user_career_progress` table
- Profile shows selected career

✅ **User experience:**
- No data loss
- Smooth playback
- Accurate progress
- Fast load times

---

## Troubleshooting

### Progress Not Saving
1. Check backend server is running: `Test-NetConnection 192.168.1.102 -Port 5001`
2. Check auth token: Look for "Token validated for user: X" in backend logs
3. Check database connection: Run any SQL query manually
4. Check Flutter logs for "❌" error messages

### Videos Restarting
1. Verify `startAt` flag in YoutubePlayerController
2. Check `_loadSavedProgress()` is called in initState
3. Verify progress exists in database for that video

### Duration Shows Wrong
1. Check `_controller!.metadata.duration` has valid data
2. Ensure `_isPlayerReady = true` before accessing metadata
3. Verify video loaded successfully (not restricted/private)

---

## Next Steps After Testing

1. **Gather user feedback** on the new progress system
2. **Monitor database growth** - add cleanup for old progress data
3. **Add analytics** - track which videos are most watched
4. **Implement offline sync** - queue updates when no network
5. **Profile integration** - show career and progress on profile page

Happy Testing! 🎉
