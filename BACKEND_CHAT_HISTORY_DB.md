# 💾 Chat History Database Integration - Backend Guide

## 📋 Overview
Implement database storage for chat conversations to enable:
- ✅ Chat history sync across devices
- ✅ Conversation persistence in the cloud
- ✅ Multi-device access to same chat history
- ✅ Advanced features (search, analytics, conversation summaries)

---

## 🗄️ Database Schema

### **Table 1: ChatSessions**
Stores metadata about each conversation.

```sql
CREATE TABLE ChatSessions (
    Id INT PRIMARY KEY IDENTITY(1,1),
    SessionId NVARCHAR(100) NOT NULL UNIQUE,
    UserId INT NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    LastMessage NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    INDEX IX_ChatSessions_UserId (UserId),
    INDEX IX_ChatSessions_SessionId (SessionId),
    INDEX IX_ChatSessions_UpdatedAt (UpdatedAt DESC)
);
```

### **Table 2: ChatMessages**
Stores individual messages within each session.

```sql
CREATE TABLE ChatMessages (
    Id INT PRIMARY KEY IDENTITY(1,1),
    SessionId NVARCHAR(100) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    IsUser BIT NOT NULL,
    Timestamp DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (SessionId) REFERENCES ChatSessions(SessionId) ON DELETE CASCADE,
    INDEX IX_ChatMessages_SessionId (SessionId),
    INDEX IX_ChatMessages_Timestamp (Timestamp)
);
```

---

## 🔧 C# Models

### **Models/ChatSession.cs**

```csharp
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace YourNamespace.Models
{
    public class ChatSession
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string SessionId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; }

        [MaxLength(500)]
        public string LastMessage { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsDeleted { get; set; } = false;

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
        
        public virtual ICollection<ChatMessage> Messages { get; set; }
    }

    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string SessionId { get; set; }

        [Required]
        public string Message { get; set; }

        [Required]
        public bool IsUser { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        // Navigation property
        [ForeignKey("SessionId")]
        public virtual ChatSession Session { get; set; }
    }
}
```

---

## 🎯 API Endpoints

### **1. POST /api/chat/sessions** - Create or Update Session

**Request:**
```json
{
  "sessionId": "1732425600000",
  "title": "Career Path Discussion",
  "lastMessage": "What are the best tech careers?"
}
```

**Response:**
```json
{
  "sessionId": "1732425600000",
  "title": "Career Path Discussion",
  "createdAt": "2025-11-24T10:30:00Z",
  "updatedAt": "2025-11-24T10:30:00Z"
}
```

---

### **2. POST /api/chat/messages** - Save Message

**Request:**
```json
{
  "sessionId": "1732425600000",
  "message": "What skills do I need for software engineering?",
  "isUser": true,
  "timestamp": "2025-11-24T10:30:00Z"
}
```

**Response:**
```json
{
  "id": 123,
  "sessionId": "1732425600000",
  "message": "What skills do I need for software engineering?",
  "isUser": true,
  "timestamp": "2025-11-24T10:30:00Z"
}
```

---

### **3. GET /api/chat/sessions** - Get All Sessions

**Response:**
```json
{
  "sessions": [
    {
      "sessionId": "1732425600000",
      "title": "Career Path Discussion",
      "lastMessage": "What are the best tech careers?",
      "createdAt": "2025-11-24T10:30:00Z",
      "updatedAt": "2025-11-24T11:00:00Z",
      "messageCount": 12
    },
    {
      "sessionId": "1732422000000",
      "title": "Skills Development",
      "lastMessage": "How can I improve my coding?",
      "createdAt": "2025-11-23T15:20:00Z",
      "updatedAt": "2025-11-23T16:00:00Z",
      "messageCount": 8
    }
  ]
}
```

---

### **4. GET /api/chat/sessions/{sessionId}/messages** - Get Messages

**Response:**
```json
{
  "sessionId": "1732425600000",
  "messages": [
    {
      "id": 1,
      "message": "What skills do I need for software engineering?",
      "isUser": true,
      "timestamp": "2025-11-24T10:30:00Z"
    },
    {
      "id": 2,
      "message": "For software engineering, you'll need...",
      "isUser": false,
      "timestamp": "2025-11-24T10:30:15Z"
    }
  ]
}
```

---

### **5. DELETE /api/chat/sessions/{sessionId}** - Delete Session

**Response:**
```json
{
  "message": "Chat session deleted successfully"
}
```

---

### **6. DELETE /api/chat/sessions** - Clear All History

**Response:**
```json
{
  "message": "All chat history cleared",
  "deletedSessions": 5,
  "deletedMessages": 47
}
```

---

## 💻 Controller Implementation

### **Controllers/ChatHistoryController.cs**

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

[ApiController]
[Route("api/chat")]
[Authorize]
public class ChatHistoryController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ChatHistoryController(ApplicationDbContext context)
    {
        _context = context;
    }

    private int GetUserId()
    {
        return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);
    }

    /// <summary>
    /// Create or update a chat session
    /// </summary>
    [HttpPost("sessions")]
    public async Task<IActionResult> CreateOrUpdateSession([FromBody] ChatSessionRequest request)
    {
        try
        {
            var userId = GetUserId();

            var session = await _context.ChatSessions
                .FirstOrDefaultAsync(s => s.SessionId == request.SessionId && s.UserId == userId);

            if (session == null)
            {
                // Create new session
                session = new ChatSession
                {
                    SessionId = request.SessionId,
                    UserId = userId,
                    Title = request.Title,
                    LastMessage = request.LastMessage,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.ChatSessions.Add(session);
            }
            else
            {
                // Update existing session
                session.Title = request.Title;
                session.LastMessage = request.LastMessage;
                session.UpdatedAt = DateTime.UtcNow;
                _context.ChatSessions.Update(session);
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                sessionId = session.SessionId,
                title = session.Title,
                createdAt = session.CreatedAt,
                updatedAt = session.UpdatedAt
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating/updating session: {ex.Message}");
            return StatusCode(500, new { error = "Failed to save session" });
        }
    }

    /// <summary>
    /// Save a chat message
    /// </summary>
    [HttpPost("messages")]
    public async Task<IActionResult> SaveMessage([FromBody] ChatMessageRequest request)
    {
        try
        {
            var userId = GetUserId();

            // Verify session belongs to user
            var session = await _context.ChatSessions
                .FirstOrDefaultAsync(s => s.SessionId == request.SessionId && s.UserId == userId);

            if (session == null)
            {
                return NotFound(new { error = "Session not found" });
            }

            var message = new ChatMessage
            {
                SessionId = request.SessionId,
                Message = request.Message,
                IsUser = request.IsUser,
                Timestamp = request.Timestamp ?? DateTime.UtcNow
            };

            _context.ChatMessages.Add(message);

            // Update session's last message and timestamp
            session.LastMessage = request.Message.Length > 500 
                ? request.Message.Substring(0, 500) 
                : request.Message;
            session.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                id = message.Id,
                sessionId = message.SessionId,
                message = message.Message,
                isUser = message.IsUser,
                timestamp = message.Timestamp
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error saving message: {ex.Message}");
            return StatusCode(500, new { error = "Failed to save message" });
        }
    }

    /// <summary>
    /// Get all chat sessions for the user
    /// </summary>
    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions()
    {
        try
        {
            var userId = GetUserId();

            var sessions = await _context.ChatSessions
                .Where(s => s.UserId == userId && !s.IsDeleted)
                .OrderByDescending(s => s.UpdatedAt)
                .Select(s => new
                {
                    sessionId = s.SessionId,
                    title = s.Title,
                    lastMessage = s.LastMessage,
                    createdAt = s.CreatedAt,
                    updatedAt = s.UpdatedAt,
                    messageCount = _context.ChatMessages.Count(m => m.SessionId == s.SessionId)
                })
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { sessions });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting sessions: {ex.Message}");
            return StatusCode(500, new { error = "Failed to get sessions" });
        }
    }

    /// <summary>
    /// Get messages for a specific session
    /// </summary>
    [HttpGet("sessions/{sessionId}/messages")]
    public async Task<IActionResult> GetMessages(string sessionId)
    {
        try
        {
            var userId = GetUserId();

            // Verify session belongs to user
            var session = await _context.ChatSessions
                .FirstOrDefaultAsync(s => s.SessionId == sessionId && s.UserId == userId);

            if (session == null)
            {
                return NotFound(new { error = "Session not found" });
            }

            var messages = await _context.ChatMessages
                .Where(m => m.SessionId == sessionId)
                .OrderBy(m => m.Timestamp)
                .Select(m => new
                {
                    id = m.Id,
                    message = m.Message,
                    isUser = m.IsUser,
                    timestamp = m.Timestamp
                })
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { sessionId, messages });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting messages: {ex.Message}");
            return StatusCode(500, new { error = "Failed to get messages" });
        }
    }

    /// <summary>
    /// Delete a specific chat session
    /// </summary>
    [HttpDelete("sessions/{sessionId}")]
    public async Task<IActionResult> DeleteSession(string sessionId)
    {
        try
        {
            var userId = GetUserId();

            var session = await _context.ChatSessions
                .FirstOrDefaultAsync(s => s.SessionId == sessionId && s.UserId == userId);

            if (session == null)
            {
                return NotFound(new { error = "Session not found" });
            }

            // Soft delete or hard delete - your choice
            // Soft delete:
            session.IsDeleted = true;
            await _context.SaveChangesAsync();

            // Hard delete (uncomment if preferred):
            // _context.ChatSessions.Remove(session);
            // await _context.SaveChangesAsync();

            return Ok(new { message = "Chat session deleted successfully" });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error deleting session: {ex.Message}");
            return StatusCode(500, new { error = "Failed to delete session" });
        }
    }

    /// <summary>
    /// Clear all chat history for the user
    /// </summary>
    [HttpDelete("sessions")]
    public async Task<IActionResult> ClearAllHistory()
    {
        try
        {
            var userId = GetUserId();

            var sessions = await _context.ChatSessions
                .Where(s => s.UserId == userId)
                .ToListAsync();

            var sessionIds = sessions.Select(s => s.SessionId).ToList();
            
            var messages = await _context.ChatMessages
                .Where(m => sessionIds.Contains(m.SessionId))
                .ToListAsync();

            var deletedMessagesCount = messages.Count;
            var deletedSessionsCount = sessions.Count;

            _context.ChatMessages.RemoveRange(messages);
            _context.ChatSessions.RemoveRange(sessions);
            
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "All chat history cleared",
                deletedSessions = deletedSessionsCount,
                deletedMessages = deletedMessagesCount
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error clearing history: {ex.Message}");
            return StatusCode(500, new { error = "Failed to clear history" });
        }
    }
}

// Request DTOs
public class ChatSessionRequest
{
    public string SessionId { get; set; }
    public string Title { get; set; }
    public string LastMessage { get; set; }
}

public class ChatMessageRequest
{
    public string SessionId { get; set; }
    public string Message { get; set; }
    public bool IsUser { get; set; }
    public DateTime? Timestamp { get; set; }
}
```

---

## 🔄 Migration Steps

### **1. Create Migration**
```bash
dotnet ef migrations add AddChatHistory
dotnet ef database update
```

### **2. Add to DbContext**
```csharp
public class ApplicationDbContext : DbContext
{
    public DbSet<ChatSession> ChatSessions { get; set; }
    public DbSet<ChatMessage> ChatMessages { get; set; }
    
    // ... existing DbSets ...

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure cascade delete
        modelBuilder.Entity<ChatMessage>()
            .HasOne(m => m.Session)
            .WithMany(s => s.Messages)
            .HasForeignKey(m => m.SessionId)
            .HasPrincipalKey(s => s.SessionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
```

---

## 🧪 Testing with Postman

### **1. Create Session**
```http
POST http://192.168.1.80:5001/api/chat/sessions
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "sessionId": "1732425600000",
  "title": "Career Discussion",
  "lastMessage": "What are tech careers?"
}
```

### **2. Save Message**
```http
POST http://192.168.1.80:5001/api/chat/messages
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "sessionId": "1732425600000",
  "message": "What skills do I need?",
  "isUser": true,
  "timestamp": "2025-11-24T10:30:00Z"
}
```

### **3. Get All Sessions**
```http
GET http://192.168.1.80:5001/api/chat/sessions
Authorization: Bearer YOUR_TOKEN
```

### **4. Get Session Messages**
```http
GET http://192.168.1.80:5001/api/chat/sessions/1732425600000/messages
Authorization: Bearer YOUR_TOKEN
```

### **5. Delete Session**
```http
DELETE http://192.168.1.80:5001/api/chat/sessions/1732425600000
Authorization: Bearer YOUR_TOKEN
```

---

## 📊 Advanced Features (Optional)

### **Search Chat History**
```csharp
[HttpGet("search")]
public async Task<IActionResult> SearchChats([FromQuery] string query)
{
    var userId = GetUserId();
    
    var results = await _context.ChatMessages
        .Where(m => m.Session.UserId == userId && m.Message.Contains(query))
        .Include(m => m.Session)
        .OrderByDescending(m => m.Timestamp)
        .Take(50)
        .AsNoTracking()
        .ToListAsync();
    
    return Ok(new { results });
}
```

### **Get Chat Statistics**
```csharp
[HttpGet("stats")]
public async Task<IActionResult> GetStats()
{
    var userId = GetUserId();
    
    var stats = new
    {
        totalSessions = await _context.ChatSessions.CountAsync(s => s.UserId == userId),
        totalMessages = await _context.ChatMessages
            .CountAsync(m => m.Session.UserId == userId),
        firstChatDate = await _context.ChatSessions
            .Where(s => s.UserId == userId)
            .MinAsync(s => (DateTime?)s.CreatedAt)
    };
    
    return Ok(stats);
}
```

---

## ✅ Implementation Checklist

- [ ] Create database tables (ChatSessions, ChatMessages)
- [ ] Add models (ChatSession.cs, ChatMessage.cs)
- [ ] Create ChatHistoryController
- [ ] Add DbSet to ApplicationDbContext
- [ ] Run migrations
- [ ] Test all endpoints with Postman
- [ ] Add indexes for performance
- [ ] Implement soft delete (IsDeleted flag)
- [ ] Add pagination for large chat histories
- [ ] Test with Flutter app

---

## 🔐 Security Considerations

1. **User Isolation**: Always filter by `UserId` to prevent users accessing other's chats
2. **Input Validation**: Validate sessionId, message length, etc.
3. **SQL Injection**: Use parameterized queries (EF Core does this automatically)
4. **Rate Limiting**: Prevent spam by limiting message frequency
5. **Data Encryption**: Consider encrypting sensitive messages

---

## 📈 Performance Optimization

1. **Indexing**: Already added indexes on UserId, SessionId, Timestamp
2. **Pagination**: Add `.Skip()` and `.Take()` for large result sets
3. **Caching**: Cache frequently accessed sessions
4. **Lazy Loading**: Use `.AsNoTracking()` for read-only queries
5. **Batch Operations**: Save multiple messages in one transaction

---

## 🎯 Expected Results

Once implemented, Flutter app can:
- ✅ Sync chat history to server
- ✅ Access chats from any device
- ✅ Search through past conversations
- ✅ Never lose chat history
- ✅ Track conversation analytics

---

**Ready to implement! Start with the database tables, then the controller, and test each endpoint.** 🚀
