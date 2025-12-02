# 🔧 URGENT: Fix Groq API Chat Integration

## 🔴 Current Issue
**Error:** `Server error. The backend AI service may not be configured properly.`

**Status Code:** 500  
**Endpoint:** `POST /api/chat`  
**Root Cause:** Groq API integration is failing on the backend

---

## ✅ Step-by-Step Fix

### **Step 1: Verify Groq API Key**

Test the API key directly with curl:

```bash
curl https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GROQ_API_KEY_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.1-8b-instant",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello"}
    ]
  }'
```

**Expected Response:**
```json
{
  "choices": [
    {
      "message": {
        "content": "Hello! How can I help you today?"
      }
    }
  ]
}
```

**If you get 401 Unauthorized:**
- The API key is invalid or expired
- Generate a new one at: https://console.groq.com/keys

---

### **Step 2: Add Detailed Logging to ChatController**

Update your `ChatController.cs`:

```csharp
[HttpPost]
public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
{
    try
    {
        Console.WriteLine($"====== CHAT REQUEST START ======");
        Console.WriteLine($"🔵 Received message: {request.Message}");
        
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);
        Console.WriteLine($"🔵 User ID: {userId}");
        
        Console.WriteLine($"🔵 Calling Groq service...");
        var aiResponse = await _groqService.GetChatResponseAsync(request.Message);
        Console.WriteLine($"🟢 Groq Response received: {aiResponse?.Substring(0, Math.Min(100, aiResponse.Length))}...");
        
        var sessionId = request.SessionId ?? Guid.NewGuid().ToString();
        Console.WriteLine($"🔵 Session ID: {sessionId}");
        
        Console.WriteLine($"====== CHAT REQUEST SUCCESS ======");
        return Ok(new { response = aiResponse, sessionId = sessionId });
    }
    catch (HttpRequestException ex)
    {
        Console.WriteLine($"====== GROQ API HTTP ERROR ======");
        Console.WriteLine($"🔴 Error: {ex.Message}");
        Console.WriteLine($"🔴 Stack Trace: {ex.StackTrace}");
        return StatusCode(500, new { error = $"Groq API error: {ex.Message}" });
    }
    catch (Exception ex)
    {
        Console.WriteLine($"====== CHAT ERROR ======");
        Console.WriteLine($"🔴 Error Type: {ex.GetType().Name}");
        Console.WriteLine($"🔴 Error Message: {ex.Message}");
        Console.WriteLine($"🔴 Stack Trace: {ex.StackTrace}");
        if (ex.InnerException != null)
        {
            Console.WriteLine($"🔴 Inner Exception: {ex.InnerException.Message}");
        }
        return StatusCode(500, new { error = $"Chat service error: {ex.Message}" });
    }
}
```

---

### **Step 3: Verify GroqChatService Implementation**

Make sure your `GroqChatService.cs` looks like this:

```csharp
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

public class GroqChatService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly string _apiKey;
    private readonly string _model;

    public GroqChatService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        
        // Load from appsettings.json
        _apiKey = configuration["Groq:ApiKey"] 
            ?? throw new Exception("Groq API key not configured");
        _model = configuration["Groq:Model"] ?? "llama-3.1-8b-instant";
        
        Console.WriteLine($"🔧 GroqChatService initialized with model: {_model}");
        Console.WriteLine($"🔧 API Key (first 20 chars): {_apiKey.Substring(0, 20)}...");
    }

    public async Task<string> GetChatResponseAsync(string userMessage)
    {
        try
        {
            Console.WriteLine($"📤 Calling Groq API...");
            Console.WriteLine($"📤 User message: {userMessage}");

            var requestPayload = new
            {
                model = _model,
                messages = new object[]
                {
                    new 
                    { 
                        role = "system", 
                        content = @"You are an expert AI Career Guidance Assistant. Provide helpful, 
                                   concise career advice in 2-3 paragraphs. Focus on actionable guidance."
                    },
                    new { role = "user", content = userMessage }
                },
                temperature = 0.7,
                max_tokens = 500
            };

            var jsonRequest = JsonSerializer.Serialize(requestPayload);
            Console.WriteLine($"📤 Request payload: {jsonRequest.Substring(0, Math.Min(200, jsonRequest.Length))}...");

            var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
            request.Headers.Add("Authorization", $"Bearer {_apiKey}");
            request.Content = new StringContent(jsonRequest, Encoding.UTF8, "application/json");

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            Console.WriteLine($"📥 Groq API Status: {response.StatusCode}");
            Console.WriteLine($"📥 Response (first 300 chars): {responseBody.Substring(0, Math.Min(300, responseBody.Length))}...");

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"🔴 Groq API returned error {response.StatusCode}");
                throw new HttpRequestException($"Groq API error {response.StatusCode}: {responseBody}");
            }

            var result = JsonSerializer.Deserialize<GroqApiResponse>(responseBody);
            var aiContent = result?.Choices?[0]?.Message?.Content;

            if (string.IsNullOrEmpty(aiContent))
            {
                throw new Exception("Empty response from Groq API");
            }

            Console.WriteLine($"✅ AI response extracted successfully");
            return aiContent;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"🔴 GroqChatService error: {ex.Message}");
            throw;
        }
    }
}

// Response models
public class GroqApiResponse
{
    [JsonPropertyName("choices")]
    public List<GroqChoice> Choices { get; set; }
}

public class GroqChoice
{
    [JsonPropertyName("message")]
    public GroqMessage Message { get; set; }
}

public class GroqMessage
{
    [JsonPropertyName("content")]
    public string Content { get; set; }
}
```

---

### **Step 4: Register Service in Program.cs**

Make sure this is in your `Program.cs`:

```csharp
// Add HttpClient for GroqChatService
builder.Services.AddHttpClient<GroqChatService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(60);
});

// OR if you prefer singleton:
builder.Services.AddSingleton<GroqChatService>();
```

---

### **Step 5: Update appsettings.json (Optional)**

```json
{
  "Groq": {
    "ApiKey": "YOUR_GROQ_API_KEY_HERE",
    "Model": "llama-3.1-8b-instant"
  }
}
```

---

### **Step 6: Test with Hardcoded Response First**

Before fixing Groq, verify the endpoint works:

```csharp
[HttpPost]
public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
{
    // TEMPORARY TEST - Remove after Groq works
    return Ok(new { 
        response = "Hello! This is a test response. Your Flutter app is working correctly. " +
                   "Once the Groq API is configured, you'll get real AI responses here.",
        sessionId = Guid.NewGuid().ToString()
    });
}
```

**If this works in Flutter:**
- ✅ Flutter app is working perfectly
- 🔴 Problem is 100% in Groq API integration

---

## 🔍 Common Issues & Solutions

### **Issue 1: "Unauthorized" from Groq API**
**Solution:** API key is invalid
- Go to https://console.groq.com/keys
- Generate new API key
- Update in code or appsettings.json

### **Issue 2: "Rate limit exceeded"**
**Solution:** Free tier limits reached
- Check usage at https://console.groq.com
- Wait for limit reset (usually hourly)
- Upgrade plan if needed

### **Issue 3: "Model not found"**
**Solution:** Wrong model name
- Use: `llama-3.1-8b-instant` (fast)
- Or: `llama-3.1-70b-versatile` (better quality, slower)

### **Issue 4: HttpClient timeout**
**Solution:** Groq taking too long
- Increase timeout in Program.cs to 60 seconds
- Check internet connection
- Try faster model (8b instead of 70b)

### **Issue 5: "GroqChatService not found"**
**Solution:** Service not registered
- Add `builder.Services.AddHttpClient<GroqChatService>();` in Program.cs
- Or add `builder.Services.AddSingleton<GroqChatService>();`

---

## ✅ Verification Steps

After making changes:

1. **Restart backend server**
2. **Check startup logs** for:
   ```
   🔧 GroqChatService initialized with model: llama-3.1-8b-instant
   🔧 API Key (first 20 chars): gsk_Z2k8ul1v4HrjWX7Z...
   ```

3. **Test with Flutter app** - send a chat message

4. **Check console logs** for:
   ```
   ====== CHAT REQUEST START ======
   🔵 Received message: Hello
   🔵 User ID: 1
   🔵 Calling Groq service...
   📤 Calling Groq API...
   📥 Groq API Status: OK
   🟢 Groq Response received: Hello! How can I help you...
   ====== CHAT REQUEST SUCCESS ======
   ```

5. **Flutter should display AI response** without errors

---

## 🎯 Expected Result

**Before fix:**
```
User: "Hello"
AI: ❌ Server error. The backend AI service may not be configured properly.
```

**After fix:**
```
User: "Hello"
AI: Hello! I'm your AI Career Guidance Assistant. How can I help you explore 
    your career options today?
```

---

## 📞 Still Having Issues?

Check these in order:
1. ✅ API key valid (test with curl)
2. ✅ GroqChatService registered in Program.cs
3. ✅ Backend console shows detailed logs
4. ✅ Hardcoded test response works in Flutter
5. ✅ No firewall blocking https://api.groq.com

If all above pass but still failing, share the **complete console logs** from step 3.

---

**The Flutter app is ready and working correctly. This is purely a backend Groq API configuration issue.**
