# Backend Implementation Guide - Skill-Based Quiz System

## Overview
Implement a skill-based quiz generation and evaluation system that creates personalized quizzes based on user profile skills, evaluates answers, and provides career recommendations with match percentages.

---

## Database Schema

### 1. QuizSessions Table
```sql
CREATE TABLE QuizSessions (
    SessionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId INT NOT NULL,
    QuizId NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CompletedAt DATETIME2 NULL,
    TotalScore INT NULL,
    TotalQuestions INT DEFAULT 10,
    Percentage DECIMAL(5,2) NULL,
    FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE INDEX IX_QuizSessions_UserId ON QuizSessions(UserId);
CREATE INDEX IX_QuizSessions_QuizId ON QuizSessions(QuizId);
```

### 2. QuizQuestions Table
```sql
CREATE TABLE QuizQuestions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuizId NVARCHAR(100) NOT NULL,
    QuestionNumber INT NOT NULL,
    Question NVARCHAR(500) NOT NULL,
    QuestionType NVARCHAR(50) DEFAULT 'multiple_choice',
    SkillCategory NVARCHAR(100) NOT NULL,
    CorrectAnswer NVARCHAR(10) NOT NULL, -- A, B, C, or D
    OptionA NVARCHAR(300) NOT NULL,
    OptionB NVARCHAR(300) NOT NULL,
    OptionC NVARCHAR(300) NOT NULL,
    OptionD NVARCHAR(300) NOT NULL,
    CONSTRAINT UK_QuizQuestions UNIQUE (QuizId, QuestionNumber)
);

CREATE INDEX IX_QuizQuestions_QuizId ON QuizQuestions(QuizId);
CREATE INDEX IX_QuizQuestions_Skill ON QuizQuestions(SkillCategory);
```

### 3. QuizAnswers Table
```sql
CREATE TABLE QuizAnswers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuizId NVARCHAR(100) NOT NULL,
    UserId INT NOT NULL,
    QuestionId INT NOT NULL,
    UserAnswer NVARCHAR(10) NOT NULL, -- A, B, C, or D
    IsCorrect BIT NOT NULL,
    AnsweredAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id),
    FOREIGN KEY (QuestionId) REFERENCES QuizQuestions(Id)
);

CREATE INDEX IX_QuizAnswers_QuizId ON QuizAnswers(QuizId);
CREATE INDEX IX_QuizAnswers_UserId ON QuizAnswers(UserId);
```

### 4. SkillScores Table
```sql
CREATE TABLE SkillScores (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuizId NVARCHAR(100) NOT NULL,
    UserId INT NOT NULL,
    SkillName NVARCHAR(100) NOT NULL,
    CorrectAnswers INT NOT NULL,
    TotalQuestions INT NOT NULL,
    Percentage DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE INDEX IX_SkillScores_QuizId ON SkillScores(QuizId);
CREATE INDEX IX_SkillScores_UserId ON SkillScores(UserId);
```

### 5. CareerMatches Table
```sql
CREATE TABLE CareerMatches (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    QuizId NVARCHAR(100) NOT NULL,
    UserId INT NOT NULL,
    CareerId INT NOT NULL,
    CareerName NVARCHAR(200) NOT NULL,
    MatchPercentage DECIMAL(5,2) NOT NULL,
    MatchingSkills NVARCHAR(MAX) NULL, -- JSON array
    MissingSkills NVARCHAR(MAX) NULL,  -- JSON array
    SalaryRange NVARCHAR(100) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES Users(Id),
    FOREIGN KEY (CareerId) REFERENCES Careers(Id)
);

CREATE INDEX IX_CareerMatches_QuizId ON CareerMatches(QuizId);
CREATE INDEX IX_CareerMatches_UserId ON CareerMatches(UserId);
```

---

## API Endpoints

### 1. POST /api/quiz/generate
Generate a personalized quiz based on user's profile skills.

**Request:**
```http
POST /api/quiz/generate
Authorization: Bearer {jwt_token}
```

**Implementation Logic:**
```csharp
[HttpPost("generate")]
[Authorize]
public async Task<IActionResult> GenerateQuiz()
{
    var userId = GetUserIdFromToken();
    
    // 1. Get user's skills from profile
    var userProfile = await _context.UserProfiles
        .FirstOrDefaultAsync(p => p.UserId == userId);
    
    if (userProfile == null || string.IsNullOrEmpty(userProfile.Skills))
    {
        return BadRequest(new { error = "Please add skills to your profile first" });
    }
    
    var skills = JsonSerializer.Deserialize<List<string>>(userProfile.Skills);
    
    if (skills == null || skills.Count == 0)
    {
        return BadRequest(new { error = "No skills found in profile" });
    }
    
    // 2. Generate unique quiz ID
    var quizId = Guid.NewGuid().ToString();
    
    // 3. Generate questions (5 questions per skill, max 10 total)
    var questions = await GenerateQuestionsForSkills(skills, quizId);
    
    // 4. Save quiz session
    var session = new QuizSession
    {
        SessionId = Guid.NewGuid(),
        UserId = userId,
        QuizId = quizId,
        TotalQuestions = questions.Count
    };
    
    _context.QuizSessions.Add(session);
    await _context.SaveChangesAsync();
    
    // 5. Return response
    return Ok(new
    {
        quizId = quizId,
        questions = questions.Select(q => new
        {
            id = q.Id,
            question = q.Question,
            type = q.QuestionType,
            skill_category = q.SkillCategory,
            correct_answer = q.CorrectAnswer,
            options = new[]
            {
                $"A) {q.OptionA}",
                $"B) {q.OptionB}",
                $"C) {q.OptionC}",
                $"D) {q.OptionD}"
            }
        })
    });
}

private async Task<List<QuizQuestion>> GenerateQuestionsForSkills(
    List<string> skills, 
    string quizId)
{
    var questions = new List<QuizQuestion>();
    var questionsPerSkill = Math.Max(1, 10 / skills.Count); // Distribute 10 questions
    var questionNumber = 1;
    
    foreach (var skill in skills.Take(5)) // Max 5 different skills
    {
        var skillQuestions = await GetQuestionsForSkill(
            skill, 
            questionsPerSkill, 
            quizId, 
            questionNumber
        );
        
        questions.AddRange(skillQuestions);
        questionNumber += skillQuestions.Count;
        
        if (questions.Count >= 10) break;
    }
    
    // Ensure exactly 10 questions
    questions = questions.Take(10).ToList();
    
    await _context.QuizQuestions.AddRangeAsync(questions);
    await _context.SaveChangesAsync();
    
    return questions;
}

private async Task<List<QuizQuestion>> GetQuestionsForSkill(
    string skill, 
    int count, 
    string quizId, 
    int startNumber)
{
    // You can either:
    // Option 1: Pre-populate a question bank in database
    // Option 2: Use AI to generate questions (Groq API, OpenAI, etc.)
    // Option 3: Have a hardcoded question set
    
    // Example using a question bank:
    var questionBank = await _context.QuestionBank
        .Where(q => q.SkillCategory.ToLower() == skill.ToLower())
        .OrderBy(q => Guid.NewGuid()) // Random order
        .Take(count)
        .ToListAsync();
    
    var questions = new List<QuizQuestion>();
    var number = startNumber;
    
    foreach (var template in questionBank)
    {
        questions.Add(new QuizQuestion
        {
            QuizId = quizId,
            QuestionNumber = number++,
            Question = template.Question,
            QuestionType = "multiple_choice",
            SkillCategory = skill,
            CorrectAnswer = template.CorrectAnswer,
            OptionA = template.OptionA,
            OptionB = template.OptionB,
            OptionC = template.OptionC,
            OptionD = template.OptionD
        });
    }
    
    return questions;
}
```

**Response:**
```json
{
  "quizId": "550e8400-e29b-41d4-a716-446655440000",
  "questions": [
    {
      "id": 1,
      "question": "In Flutter, which widget is used for creating scrollable lists?",
      "type": "multiple_choice",
      "skill_category": "Flutter",
      "correct_answer": "B",
      "options": [
        "A) Container",
        "B) ListView",
        "C) Column",
        "D) Stack"
      ]
    }
    // ... 9 more questions
  ]
}
```

---

### 2. POST /api/quiz/submit
Submit quiz answers and get results with career recommendations.

**Request:**
```http
POST /api/quiz/submit
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "quizId": "550e8400-e29b-41d4-a716-446655440000",
  "answers": [
    { "questionId": 1, "answer": "B" },
    { "questionId": 2, "answer": "A" },
    { "questionId": 3, "answer": "C" }
  ]
}
```

**Implementation:**
```csharp
[HttpPost("submit")]
[Authorize]
public async Task<IActionResult> SubmitQuiz([FromBody] SubmitQuizRequest request)
{
    var userId = GetUserIdFromToken();
    
    // 1. Validate quiz session
    var session = await _context.QuizSessions
        .FirstOrDefaultAsync(s => s.QuizId == request.QuizId && s.UserId == userId);
    
    if (session == null)
    {
        return BadRequest(new { error = "Invalid quiz session" });
    }
    
    // 2. Get all questions for this quiz
    var questions = await _context.QuizQuestions
        .Where(q => q.QuizId == request.QuizId)
        .ToListAsync();
    
    // 3. Evaluate answers
    var results = EvaluateAnswers(questions, request.Answers, userId, request.QuizId);
    
    // 4. Save answers to database
    await _context.QuizAnswers.AddRangeAsync(results.Answers);
    
    // 5. Calculate skill breakdown
    var skillScores = CalculateSkillScores(results.Answers, questions);
    await _context.SkillScores.AddRangeAsync(
        skillScores.Select(s => new SkillScore
        {
            QuizId = request.QuizId,
            UserId = userId,
            SkillName = s.Skill,
            CorrectAnswers = s.Correct,
            TotalQuestions = s.Total,
            Percentage = s.Percentage
        })
    );
    
    // 6. Generate career matches
    var careerMatches = await GenerateCareerMatches(userId, skillScores, request.QuizId);
    await _context.CareerMatches.AddRangeAsync(careerMatches);
    
    // 7. Update session
    session.CompletedAt = DateTime.UtcNow;
    session.TotalScore = results.TotalScore;
    session.Percentage = results.Percentage;
    
    await _context.SaveChangesAsync();
    
    // 8. Return results
    return Ok(new
    {
        totalScore = results.TotalScore,
        totalQuestions = questions.Count,
        percentage = results.Percentage,
        skillBreakdown = skillScores.Select(s => new
        {
            skill = s.Skill,
            correct = s.Correct,
            total = s.Total,
            percentage = s.Percentage
        }),
        careerMatches = careerMatches
            .OrderByDescending(c => c.MatchPercentage)
            .Select(c => new
            {
                careerId = c.CareerId,
                careerName = c.CareerName,
                matchPercentage = c.MatchPercentage,
                matchingSkills = JsonSerializer.Deserialize<List<string>>(c.MatchingSkills),
                missingSkills = JsonSerializer.Deserialize<List<string>>(c.MissingSkills),
                salaryRange = c.SalaryRange
            })
    });
}

private QuizEvaluationResult EvaluateAnswers(
    List<QuizQuestion> questions,
    List<QuizAnswerDto> userAnswers,
    int userId,
    string quizId)
{
    var answers = new List<QuizAnswer>();
    var correctCount = 0;
    
    foreach (var userAnswer in userAnswers)
    {
        var question = questions.FirstOrDefault(q => q.Id == userAnswer.QuestionId);
        if (question == null) continue;
        
        var isCorrect = question.CorrectAnswer.Equals(
            userAnswer.Answer, 
            StringComparison.OrdinalIgnoreCase
        );
        
        if (isCorrect) correctCount++;
        
        answers.Add(new QuizAnswer
        {
            QuizId = quizId,
            UserId = userId,
            QuestionId = userAnswer.QuestionId,
            UserAnswer = userAnswer.Answer.ToUpper(),
            IsCorrect = isCorrect
        });
    }
    
    var percentage = (decimal)correctCount / questions.Count * 100;
    
    return new QuizEvaluationResult
    {
        Answers = answers,
        TotalScore = correctCount,
        Percentage = Math.Round(percentage, 2)
    };
}

private List<SkillScoreDto> CalculateSkillScores(
    List<QuizAnswer> answers,
    List<QuizQuestion> questions)
{
    var skillGroups = questions.GroupBy(q => q.SkillCategory);
    var skillScores = new List<SkillScoreDto>();
    
    foreach (var group in skillGroups)
    {
        var skill = group.Key;
        var skillQuestionIds = group.Select(q => q.Id).ToList();
        var skillAnswers = answers.Where(a => skillQuestionIds.Contains(a.QuestionId));
        
        var correct = skillAnswers.Count(a => a.IsCorrect);
        var total = skillAnswers.Count();
        var percentage = total > 0 ? (decimal)correct / total * 100 : 0;
        
        skillScores.Add(new SkillScoreDto
        {
            Skill = skill,
            Correct = correct,
            Total = total,
            Percentage = Math.Round(percentage, 2)
        });
    }
    
    return skillScores;
}

private async Task<List<CareerMatch>> GenerateCareerMatches(
    int userId,
    List<SkillScoreDto> skillScores,
    string quizId)
{
    // Get user's skills from profile
    var userProfile = await _context.UserProfiles
        .FirstOrDefaultAsync(p => p.UserId == userId);
    
    var userSkills = JsonSerializer.Deserialize<List<string>>(userProfile.Skills);
    
    // Get all careers from database
    var careers = await _context.Careers.ToListAsync();
    
    var matches = new List<CareerMatch>();
    
    foreach (var career in careers)
    {
        var careerSkills = JsonSerializer.Deserialize<List<string>>(career.RequiredSkills);
        if (careerSkills == null || careerSkills.Count == 0) continue;
        
        // Calculate match percentage based on:
        // 1. User has the skill (50% weight)
        // 2. User's performance in quiz for that skill (50% weight)
        
        var matchingSkills = new List<string>();
        var missingSkills = new List<string>();
        var totalScore = 0.0;
        var maxScore = careerSkills.Count * 100.0;
        
        foreach (var careerSkill in careerSkills)
        {
            var userHasSkill = userSkills.Any(
                s => s.Equals(careerSkill, StringComparison.OrdinalIgnoreCase)
            );
            
            if (userHasSkill)
            {
                matchingSkills.Add(careerSkill);
                
                // Get quiz performance for this skill
                var skillScore = skillScores.FirstOrDefault(
                    s => s.Skill.Equals(careerSkill, StringComparison.OrdinalIgnoreCase)
                );
                
                if (skillScore != null)
                {
                    // Skill exists + quiz performance
                    totalScore += 50 + (skillScore.Percentage * 0.5);
                }
                else
                {
                    // Skill exists but no quiz questions (give base points)
                    totalScore += 50;
                }
            }
            else
            {
                missingSkills.Add(careerSkill);
            }
        }
        
        var matchPercentage = (decimal)(totalScore / maxScore * 100);
        
        // Only include careers with > 30% match
        if (matchPercentage > 30)
        {
            matches.Add(new CareerMatch
            {
                QuizId = quizId,
                UserId = userId,
                CareerId = career.Id,
                CareerName = career.Name,
                MatchPercentage = Math.Round(matchPercentage, 2),
                MatchingSkills = JsonSerializer.Serialize(matchingSkills),
                MissingSkills = JsonSerializer.Serialize(missingSkills),
                SalaryRange = career.SalaryRange
            });
        }
    }
    
    return matches.OrderByDescending(m => m.MatchPercentage).Take(10).ToList();
}

// DTOs
public class SubmitQuizRequest
{
    public string QuizId { get; set; }
    public List<QuizAnswerDto> Answers { get; set; }
}

public class QuizAnswerDto
{
    public int QuestionId { get; set; }
    public string Answer { get; set; }
}

public class QuizEvaluationResult
{
    public List<QuizAnswer> Answers { get; set; }
    public int TotalScore { get; set; }
    public decimal Percentage { get; set; }
}

public class SkillScoreDto
{
    public string Skill { get; set; }
    public int Correct { get; set; }
    public int Total { get; set; }
    public decimal Percentage { get; set; }
}
```

**Response:**
```json
{
  "totalScore": 7,
  "totalQuestions": 10,
  "percentage": 70.00,
  "skillBreakdown": [
    {
      "skill": "Flutter",
      "correct": 4,
      "total": 5,
      "percentage": 80.00
    },
    {
      "skill": "Java",
      "correct": 3,
      "total": 5,
      "percentage": 60.00
    }
  ],
  "careerMatches": [
    {
      "careerId": 11,
      "careerName": "Flutter Developer",
      "matchPercentage": 95.50,
      "matchingSkills": ["Flutter", "Dart", "Mobile Development"],
      "missingSkills": ["UI/UX"],
      "salaryRange": "$60,000 - $120,000"
    }
  ]
}
```

---

## Question Bank Setup

### Create QuestionBank Table
```sql
CREATE TABLE QuestionBank (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SkillCategory NVARCHAR(100) NOT NULL,
    Question NVARCHAR(500) NOT NULL,
    CorrectAnswer NVARCHAR(10) NOT NULL,
    OptionA NVARCHAR(300) NOT NULL,
    OptionB NVARCHAR(300) NOT NULL,
    OptionC NVARCHAR(300) NOT NULL,
    OptionD NVARCHAR(300) NOT NULL,
    Difficulty NVARCHAR(20) DEFAULT 'medium',
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX IX_QuestionBank_Skill ON QuestionBank(SkillCategory);
```

### Sample Questions to Seed
```sql
-- Flutter Questions
INSERT INTO QuestionBank (SkillCategory, Question, CorrectAnswer, OptionA, OptionB, OptionC, OptionD) VALUES
('Flutter', 'Which widget is used for creating scrollable lists?', 'B', 'Container', 'ListView', 'Column', 'Stack'),
('Flutter', 'What is the purpose of setState() in Flutter?', 'A', 'Rebuild the widget with updated state', 'Initialize widget state', 'Dispose widget resources', 'Create new widget instance'),
('Flutter', 'Which widget would you use to make a widget take up all available space?', 'C', 'Container', 'SizedBox', 'Expanded', 'Padding'),
('Flutter', 'What is the main function of a StatefulWidget?', 'B', 'Display static content', 'Manage mutable state', 'Handle routing', 'Store global data'),
('Flutter', 'Which layout widget arranges children in a vertical column?', 'A', 'Column', 'Row', 'Stack', 'Wrap');

-- Java Questions
INSERT INTO QuestionBank (SkillCategory, Question, CorrectAnswer, OptionA, OptionB, OptionC, OptionD) VALUES
('Java', 'Which keyword is used to create a subclass in Java?', 'C', 'implements', 'inherits', 'extends', 'derives'),
('Java', 'What is the default value of a boolean variable in Java?', 'A', 'false', 'true', 'null', '0'),
('Java', 'Which collection allows duplicate elements?', 'B', 'Set', 'List', 'Map', 'None'),
('Java', 'What is the access modifier that makes a member accessible only within its own class?', 'D', 'public', 'protected', 'default', 'private'),
('Java', 'Which method must be implemented in a thread?', 'A', 'run()', 'start()', 'execute()', 'init()');

-- Python Questions
INSERT INTO QuestionBank (SkillCategory, Question, CorrectAnswer, OptionA, OptionB, OptionC, OptionD) VALUES
('Python', 'Which of the following is a mutable data type?', 'C', 'tuple', 'string', 'list', 'int'),
('Python', 'What is the output of len([1, 2, 3])?', 'B', '2', '3', '4', '1'),
('Python', 'Which keyword is used to define a function?', 'A', 'def', 'function', 'fun', 'define'),
('Python', 'What does the range(5) function return?', 'D', '1 to 5', '0 to 4', 'A list [0,1,2,3,4]', 'An iterable from 0 to 4'),
('Python', 'Which operator is used for floor division?', 'C', '/', '%', '//', '**');

-- Add more for other skills: JavaScript, SQL, C++, etc.
```

---

## Model Classes

```csharp
public class QuizSession
{
    public Guid SessionId { get; set; }
    public int UserId { get; set; }
    public string QuizId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public int? TotalScore { get; set; }
    public int TotalQuestions { get; set; } = 10;
    public decimal? Percentage { get; set; }
    
    public User User { get; set; }
}

public class QuizQuestion
{
    public int Id { get; set; }
    public string QuizId { get; set; }
    public int QuestionNumber { get; set; }
    public string Question { get; set; }
    public string QuestionType { get; set; } = "multiple_choice";
    public string SkillCategory { get; set; }
    public string CorrectAnswer { get; set; }
    public string OptionA { get; set; }
    public string OptionB { get; set; }
    public string OptionC { get; set; }
    public string OptionD { get; set; }
}

public class QuizAnswer
{
    public int Id { get; set; }
    public string QuizId { get; set; }
    public int UserId { get; set; }
    public int QuestionId { get; set; }
    public string UserAnswer { get; set; }
    public bool IsCorrect { get; set; }
    public DateTime AnsweredAt { get; set; } = DateTime.UtcNow;
    
    public User User { get; set; }
    public QuizQuestion Question { get; set; }
}

public class SkillScore
{
    public int Id { get; set; }
    public string QuizId { get; set; }
    public int UserId { get; set; }
    public string SkillName { get; set; }
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public decimal Percentage { get; set; }
    
    public User User { get; set; }
}

public class CareerMatch
{
    public int Id { get; set; }
    public string QuizId { get; set; }
    public int UserId { get; set; }
    public int CareerId { get; set; }
    public string CareerName { get; set; }
    public decimal MatchPercentage { get; set; }
    public string MatchingSkills { get; set; } // JSON
    public string MissingSkills { get; set; }  // JSON
    public string SalaryRange { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public User User { get; set; }
    public Career Career { get; set; }
}
```

---

## Error Handling

```csharp
// 400 Bad Request - No skills in profile
if (userProfile == null || string.IsNullOrEmpty(userProfile.Skills))
{
    return BadRequest(new { error = "Please add skills to your profile first" });
}

// 400 Bad Request - Invalid quiz ID
if (session == null)
{
    return BadRequest(new { error = "Invalid quiz session" });
}

// 401 Unauthorized - Missing or invalid token
[Authorize] // Handles this automatically

// 500 Internal Server Error - Database errors
try 
{
    // ... your code
}
catch (Exception ex)
{
    _logger.LogError(ex, "Error in quiz generation");
    return StatusCode(500, new { error = "An error occurred while processing your request" });
}
```

---

## Testing Endpoints

### Test Generate Quiz
```bash
curl -X POST http://localhost:5001/api/quiz/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test Submit Quiz
```bash
curl -X POST http://localhost:5001/api/quiz/submit \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quizId": "550e8400-e29b-41d4-a716-446655440000",
    "answers": [
      {"questionId": 1, "answer": "B"},
      {"questionId": 2, "answer": "A"}
    ]
  }'
```

---

## Additional Features to Implement

1. **Quiz History Endpoint**
```csharp
[HttpGet("history")]
[Authorize]
public async Task<IActionResult> GetQuizHistory()
{
    var userId = GetUserIdFromToken();
    
    var history = await _context.QuizSessions
        .Where(s => s.UserId == userId && s.CompletedAt != null)
        .OrderByDescending(s => s.CreatedAt)
        .Select(s => new
        {
            s.QuizId,
            s.CreatedAt,
            s.TotalScore,
            s.TotalQuestions,
            s.Percentage
        })
        .ToListAsync();
    
    return Ok(history);
}
```

2. **Retry Quiz Endpoint**
```csharp
[HttpPost("retry/{quizId}")]
[Authorize]
public async Task<IActionResult> RetryQuiz(string quizId)
{
    // Allow user to retake the same quiz
    // Return same questions but create new session
}
```

3. **Question Bank Management**
```csharp
[HttpPost("admin/questions")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> AddQuestion([FromBody] QuestionBankDto question)
{
    // Add new questions to the bank
}
```

---

## Performance Optimization

1. **Cache question bank in memory**
2. **Use async/await throughout**
3. **Add database indexes on frequently queried columns**
4. **Limit career matches to top 10**
5. **Use pagination for quiz history**

---

## Summary Checklist

✅ Create all database tables  
✅ Seed QuestionBank with questions for each skill  
✅ Implement POST /api/quiz/generate endpoint  
✅ Implement POST /api/quiz/submit endpoint  
✅ Calculate skill breakdown correctly  
✅ Implement career matching algorithm  
✅ Add proper error handling  
✅ Test with user having multiple skills  
✅ Verify career recommendations are relevant  
✅ Add logging for debugging  