# 🚀 Job Finder - Deployment Checklist

## Pre-Deployment Verification

### Backend Setup
- [ ] SQL migration executed successfully
  ```bash
  mysql -u root -p career_guidance < sql/01_job_tables_migration.sql
  ```
  
- [ ] All 4 tables created:
  - [ ] `saved_jobs`
  - [ ] `job_applications`
  - [ ] `job_search_history`
  - [ ] `job_recommendations`

- [ ] Services registered in `Program.cs`:
  ```csharp
  ✓ AddHttpClient<JobApiService>()
  ✓ AddScoped<JobApiService>()
  ✓ AddScoped<JobDatabaseService>()
  ```

- [ ] JSearch API Key configured:
  - [ ] API key valid and has quota
  - [ ] Host: `jsearch.p.rapidapi.com`
  - [ ] Consider moving to `appsettings.json` for production

- [ ] Database connection string verified:
  ```json
  "DefaultConnection": "Server=localhost;Database=career_guidance;..."
  ```

- [ ] Controllers and Services compiled without errors:
  ```bash
  dotnet build
  ```

- [ ] Backend runs without errors:
  ```bash
  dotnet run
  ```

### Frontend Setup
- [ ] All imports are correct:
  - [ ] `job_provider.dart` added to `main.dart`
  - [ ] `JobProvider` registered in MultiProvider
  
- [ ] API base URL updated in `job_service.dart`:
  ```dart
  static const String baseUrl = 'http://your-backend-url/api';
  ```

- [ ] All new files compile without errors:
  ```bash
  flutter pub get
  flutter analyze
  ```

- [ ] Navigation route exists:
  - [ ] `/jobs` route maps to `JobFinderPage`

### Testing Checklist

#### Authentication
- [ ] [x] User can login
- [ ] [x] JWT token is generated
- [ ] [x] Token is stored securely
- [ ] [x] Token is sent in Authorization header

#### Job Search
- [ ] Search without filters works
- [ ] Search with query works
- [ ] All filter types work:
  - [ ] Job type filter
  - [ ] Experience level filter
  - [ ] Salary range filter
  - [ ] Country filter
  - [ ] Date posted filter
  - [ ] Skills filter
- [ ] Pagination works (load more)
- [ ] Results update correctly
- [ ] Error handling shows proper messages

#### Personalized Jobs
- [ ] User profile has career set
- [ ] User profile has skills set
- [ ] Personalized recommendations load
- [ ] Match percentage displays correctly
- [ ] Jobs are ranked by relevance
- [ ] Empty state shows when no jobs found

#### Save/Bookmark
- [ ] User can save a job
- [ ] Saved jobs appear in "Saved" tab
- [ ] User can unsave a job
- [ ] Saved jobs are persistent (reload app)
- [ ] Database records created correctly

#### Apply for Job
- [ ] User can apply for a job
- [ ] Application is recorded in database
- [ ] Applied status is tracked
- [ ] User can view application history
- [ ] Cannot apply twice for same job

#### UI/UX
- [ ] Tab navigation works smoothly
- [ ] Filter panel opens/closes correctly
- [ ] Job cards display all information
- [ ] No layout issues on different screen sizes
- [ ] Animations are smooth
- [ ] Loading indicators appear during API calls
- [ ] Error messages are clear and helpful

#### Performance
- [ ] Initial load completes in <2 seconds
- [ ] Search results load in <3 seconds
- [ ] Pagination feels responsive
- [ ] No memory leaks detected
- [ ] Images load without issues

#### Security
- [ ] Only authenticated users can search jobs
- [ ] Users can only see their own saved jobs
- [ ] JSearch API key not exposed in frontend
- [ ] JWT tokens are properly validated
- [ ] CORS headers are configured correctly
- [ ] No sensitive data in logs

---

## Deployment Steps

### Step 1: Prepare Backend Server
```bash
# 1. SSH into your server
ssh user@your-server.com

# 2. Clone/pull latest code
cd /path/to/career-guidance-backend
git pull origin main

# 3. Build the application
dotnet build -c Release

# 4. Publish
dotnet publish -c Release -o /path/to/publish
```

### Step 2: Setup Database on Server
```bash
# 1. Connect to MySQL on server
mysql -u root -p

# 2. Run migration
SOURCE /path/to/sql/01_job_tables_migration.sql;

# 3. Verify tables
SHOW TABLES LIKE 'job%';
SHOW TABLES LIKE 'saved%';
```

### Step 3: Update Configuration
```json
// appsettings.Production.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=production-db-server;Database=career_guidance;User=db_user;Password=SECURE_PASSWORD;"
  },
  "JSearch": {
    "ApiKey": "YOUR_JSEARCH_API_KEY",
    "Host": "jsearch.p.rapidapi.com"
  },
  "Jwt": {
    "Key": "YOUR_JWT_SECRET_KEY",
    "Issuer": "your-issuer",
    "Audience": "your-audience"
  }
}
```

### Step 4: Deploy Backend
```bash
# 1. Start the application
dotnet /path/to/publish/MyFirstApi.dll

# 2. OR use systemd service
sudo systemctl start career-guidance-api
sudo systemctl enable career-guidance-api
```

### Step 5: Update Frontend
```dart
// In lib/services/api/job_service.dart
static const String baseUrl = 'https://your-production-domain.com/api';
```

### Step 6: Build & Deploy Flutter App
```bash
# 1. Build APK (Android)
flutter build apk --release

# 2. Build iOS
flutter build ios --release

# 3. Or web
flutter build web --release

# 4. Upload to app stores or distribute
```

---

## Post-Deployment Verification

- [ ] Backend API is accessible
- [ ] Database migrations are applied
- [ ] All tables exist with correct structure
- [ ] JSearch API integration works
- [ ] Frontend can connect to backend
- [ ] Search queries return results
- [ ] Save/Apply functionality works
- [ ] Logs show no errors
- [ ] Performance is acceptable
- [ ] Security headers are set

---

## Monitoring

### Backend Monitoring
```
Monitor these metrics:
- API response time
- Database query performance
- JSearch API rate limits
- Error rates
- User authentication failures
- Save/Apply success rates
```

### Database Monitoring
```
Monitor these tables:
- saved_jobs (growth)
- job_applications (growth)
- job_search_history (search patterns)
- job_recommendations (accuracy)
```

### Frontend Monitoring
```
Track:
- Search completion rate
- Apply completion rate
- Average session duration
- Error messages
- User feedback
```

---

## Troubleshooting Production Issues

### API Returns 500
```bash
# Check backend logs
tail -f /var/log/career-guidance-api.log

# Check database connection
mysql -u db_user -p -h your-db-server -e "SELECT 1"

# Verify services are running
systemctl status career-guidance-api
```

### No Job Results
```bash
# Check JSearch API key
curl -X GET https://jsearch.p.rapidapi.com/search \
  -H "x-rapidapi-key: YOUR_KEY" \
  -H "x-rapidapi-host: jsearch.p.rapidapi.com"

# Check API quota on RapidAPI dashboard
```

### Save Jobs Not Working
```bash
# Check database table
mysql -u root -p career_guidance
SELECT * FROM saved_jobs LIMIT 1;

# Check user ID
SELECT * FROM Users WHERE Id = 1;
```

### Authentication Failures
```bash
# Check JWT configuration
grep -i "jwt" /path/to/appsettings.json

# Verify token expiration
# Sync server time: ntpdate -s time.nist.gov
```

---

## Rollback Plan

If deployment fails:

```bash
# 1. Revert database
RESTORE DATABASE career_guidance FROM BACKUP...

# 2. Revert backend code
git revert HEAD

# 3. Rebuild and restart
dotnet build -c Release
dotnet run

# 4. Notify team
# Send notification about rollback
```

---

## Performance Optimization (Post-Deployment)

- [ ] Enable database query caching
- [ ] Add Redis for job result caching
- [ ] Implement CDN for static assets
- [ ] Enable GZIP compression
- [ ] Optimize images and assets
- [ ] Implement rate limiting for API
- [ ] Add database connection pooling
- [ ] Enable HTTP/2

---

## Security Hardening (Post-Deployment)

- [ ] Enable HTTPS only
- [ ] Configure WAF rules
- [ ] Set security headers (HSTS, CSP, etc.)
- [ ] Enable API key rotation
- [ ] Implement request signing
- [ ] Add IP whitelisting if needed
- [ ] Enable database encryption
- [ ] Implement audit logging

---

## Success Criteria

✅ All API endpoints respond correctly
✅ Job search returns results
✅ Users can save jobs
✅ Users can apply for jobs
✅ Personalized recommendations work
✅ No errors in logs
✅ Response time < 2 seconds
✅ 99.9% uptime in first week
✅ Users can complete full flow
✅ Database is healthy

---

**Deployment Status**: Ready for Staging → Production
**Estimated Deployment Time**: 30-45 minutes
**Rollback Time**: 10 minutes
**Success Rate Expected**: 95%+

---

For questions or issues during deployment, refer to:
- `JOB_FINDER_SETUP.md` - Detailed setup guide
- `JOB_FINDER_QUICK_START.md` - Quick reference
- `JOB_FINDER_IMPLEMENTATION.md` - Complete documentation
