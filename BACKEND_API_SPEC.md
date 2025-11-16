# Backend API Specification for Career Guidance App

## Overview
This document specifies all backend endpoints needed for the Flutter app to work properly.

**Base URL**: `http://localhost:5001` (or your production URL)

**Authentication**: All profile endpoints require `Bearer <token>` in the `Authorization` header.

---

## 1. Authentication Endpoints

### POST /api/auth/signup
**Status**: ⚠️ Currently returns 404 - NEEDS TO BE CREATED

**Description**: Register a new user account

**Request Body**:
```json
{
  "fullName": "John Doe",
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "phone": "1234567890",
  "age": 25,
  "gender": "Male",
  "dob": "1999-01-15"
}
```

**Success Response** (201 Created):
```json
{
  "user": {
    "id": 123,
    "fullName": "John Doe",
    "username": "johndoe",
    "email": "john@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response** (400 Bad Request):
```json
{
  "message": "Username already exists"
}
```

**Implementation Notes**:
- Hash password before storing (bcrypt recommended)
- Validate email format
- Check for duplicate username/email
- Store phone, age, gender, dob in `UserProfiles` table linked to user ID
- Return JWT token for immediate login

---

### POST /api/auth/login
**Status**: ✅ Working (but needs schema fix)

**Description**: Login with credentials

**Request Body**:
```json
{
  "username": "johndoe",
  "password": "SecurePass123!"
}
```

**Success Response** (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 123,
    "fullName": "John Doe",
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

**⚠️ Current Issue**:
- Database column is `password` but C# model expects `PasswordHash`
- **Fix Option 1**: Use SQL alias: `SELECT password AS PasswordHash FROM Users`
- **Fix Option 2**: Add attribute to C# model: `[Column("password")]`
- **Fix Option 3**: Rename database column to `PasswordHash`

---

## 2. Profile Management Endpoints

### GET /api/userprofile/{userId}
**Status**: ❌ NEEDS TO BE CREATED

**Description**: Fetch user profile data

**Headers**:
```
Authorization: Bearer <token>
```

**Success Response** (200 OK):
```json
{
  "userId": 123,
  "phoneNumber": "1234567890",
  "age": 25,
  "gender": "Male",
  "educationLevel": "Bachelor's Degree",
  "fieldOfStudy": "Computer Science",
  "skills": ["Python", "Flutter", "SQL"],
  "areasOfInterest": "AI, Mobile Development, Cloud Computing",
  "profileImagePath": "uploads/user_123.jpg"
}
```

**Not Found Response** (404):
```json
{
  "message": "Profile not found"
}
```

**Implementation Notes**:
- Return 404 if profile doesn't exist yet (normal for new users)
- Skills should be JSON array or comma-separated string
- Image path should be relative to server's upload directory

---

### POST /api/userprofile
**Status**: ❌ NEEDS TO BE CREATED

**Description**: Create or update user profile

**Headers**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "userId": 123,
  "phoneNumber": "1234567890",
  "age": 25,
  "gender": "Male",
  "educationLevel": "Bachelor's Degree",
  "fieldOfStudy": "Computer Science",
  "skills": ["Python", "Flutter", "SQL"],
  "areasOfInterest": "AI, Mobile Development"
}
```

**Success Response** (200 OK or 201 Created):
```json
{
  "message": "Profile updated successfully"
}
```

**Implementation Notes**:
- Use UPSERT logic (INSERT if not exists, UPDATE if exists)
- Validate userId matches authenticated user
- Handle skills as JSON array or serialize to string
- All fields except userId are optional

---

### PUT /api/profile/{userId}
**Status**: ❌ NEEDS TO BE CREATED

**Description**: Update user account fields (full name, username, email)

**Headers**:
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "fullName": "John Updated Doe",
  "username": "johndoe_new",
  "email": "newemail@example.com"
}
```

**Success Response** (200 OK or 204 No Content):
```json
{
  "message": "User updated successfully"
}
```

**Implementation Notes**:
- Validate userId matches authenticated user (prevent unauthorized updates)
- Check for duplicate username/email before updating
- Only update provided fields (partial update)

---

### POST /api/profile/upload-image
**Status**: ❌ NEEDS TO BE CREATED

**Description**: Upload profile image

**Headers**:
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body** (multipart form):
- `userId`: integer
- `image`: file (jpeg/png)

**Success Response** (200 OK):
```json
{
  "imagePath": "uploads/user_123.jpg"
}
```

**Implementation Notes**:
- Accept JPEG/PNG only, validate file type
- Limit file size (e.g., 5MB max)
- Store in `wwwroot/uploads/` or similar
- Rename file to `user_{userId}.{ext}` to prevent conflicts
- Return relative path for storage in database

---

### DELETE /api/profile/{userId}
**Status**: ❌ NEEDS TO BE CREATED (optional, for future)

**Description**: Delete user account and all associated data

**Headers**:
```
Authorization: Bearer <token>
```

**Success Response** (200 OK or 204 No Content):
```json
{
  "message": "Account deleted successfully"
}
```

**Implementation Notes**:
- Validate userId matches authenticated user
- Delete from `Users` table (cascade delete `UserProfiles`)
- Delete profile image from uploads folder
- Optionally soft-delete instead of hard-delete

---

## 3. Database Schema

### Users Table
```sql
CREATE TABLE Users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fullName VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,  -- Hashed password
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### UserProfiles Table
```sql
CREATE TABLE UserProfiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    userId INT UNIQUE NOT NULL,
    phoneNumber VARCHAR(20),
    age INT,
    gender VARCHAR(20),
    educationLevel VARCHAR(255),
    fieldOfStudy VARCHAR(255),
    skills JSON,  -- JSON array
    areasOfInterest TEXT,
    profileImagePath VARCHAR(500),
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);
```

---

## 4. C# Model Classes

### User.cs
```csharp
public class User
{
    public int Id { get; set; }
    public string FullName { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    
    [Column("password")]  // FIX: Map to 'password' column
    public string PasswordHash { get; set; }
    
    public DateTime CreatedAt { get; set; }
}
```

### UserProfile.cs
```csharp
public class UserProfile
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string PhoneNumber { get; set; }
    public int? Age { get; set; }
    public string Gender { get; set; }
    public string EducationLevel { get; set; }
    public string FieldOfStudy { get; set; }
    public string Skills { get; set; }  // Store as JSON string
    public string AreasOfInterest { get; set; }
    public string ProfileImagePath { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Navigation property
    public User User { get; set; }
}
```

### SignupRequest.cs (DTO)
```csharp
public class SignupRequest
{
    public string FullName { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
    public string Phone { get; set; }
    public int? Age { get; set; }
    public string Gender { get; set; }
    public DateTime? Dob { get; set; }
}
```

---

## 5. Testing Checklist

### After implementing signup endpoint:
- [ ] POST /api/auth/signup with valid data → 201 Created
- [ ] POST /api/auth/signup with duplicate username → 400 Bad Request
- [ ] Verify user created in `Users` table
- [ ] Verify profile data saved in `UserProfiles` table
- [ ] Verify token returned and valid

### After implementing profile endpoints:
- [ ] GET /api/userprofile/123 with valid token → 200 OK
- [ ] GET /api/userprofile/123 without token → 401 Unauthorized
- [ ] POST /api/userprofile with valid data → 200 OK
- [ ] PUT /api/profile/123 to update user fields → 200 OK
- [ ] POST /api/profile/upload-image with image → 200 OK

### Flutter integration test:
- [ ] Signup → Login → Navigate to Profile → See phone/age/gender
- [ ] Edit profile → Save → Reload app → Data persists
- [ ] Upload image → See image in profile

---

## 6. Quick Start for Backend Developer

1. **Fix login endpoint**:
   - Add `[Column("password")]` to PasswordHash property in User.cs

2. **Create signup endpoint**:
   ```csharp
   [HttpPost("signup")]
   public async Task<IActionResult> Signup([FromBody] SignupRequest request)
   {
       // 1. Hash password
       // 2. Create user in Users table
       // 3. Create profile in UserProfiles table
       // 4. Generate JWT token
       // 5. Return { token, user }
   }
   ```

3. **Create profile endpoints** (see controller examples above)

4. **Test with Swagger** or Postman before Flutter testing

---

## 7. Flutter App Behavior

**Current behavior** (with local storage only):
- Signup saves phone/age/gender locally
- Login loads cached data
- Profile displays from local storage
- Data lost on app reinstall or device change

**After backend integration**:
- Signup saves to database
- Login fetches profile from server
- Profile syncs with server on edit
- Data persists across devices

---

## 8. Next Steps

1. ✅ ProfileService created in Flutter (ready to use)
2. ⚠️ Create POST /api/auth/signup in .NET
3. ⚠️ Fix password column mapping in login
4. ⚠️ Create GET /api/userprofile/{userId}
5. ⚠️ Create POST /api/userprofile
6. ⚠️ Create PUT /api/profile/{userId}
7. ⚠️ Create POST /api/profile/upload-image

Once endpoints are ready, the Flutter app will automatically sync with the backend!
