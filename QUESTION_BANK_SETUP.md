# 📚 Question Bank Setup Guide

## 🎯 Overview

BrainRush uses an intelligent question bank system with:
- **2000+ questions** across 5 categories
- **AI-powered generation** (cost-efficient)
- **Smart caching** (no duplicate generation)
- **User progress tracking** (no repeated questions)
- **Automatic question management**

---

## 🏗️ Architecture

### **1. Question Storage (Backend)**
```
Backend/Database (Firebase/PostgreSQL)
├── Questions Collection
│   ├── Math (400+ questions)
│   ├── Science (400+ questions)
│   ├── History (400+ questions)
│   ├── Geography (400+ questions)
│   └── Literature (400+ questions)
└── User Progress Collection
    └── user_id
        ├── answered_math: [q1, q2, q3...]
        ├── answered_science: [q4, q5, q6...]
        └── ...
```

### **2. AI Generation System**
```
AI Generator (Backend Only)
├── Monitors question stock
├── Generates when stock < threshold
├── Saves to database
└── Serves to all users
```

### **3. Client-Side Caching**
```
Mobile App
├── Fetches questions from backend
├── Caches locally
├── Tracks user progress
└── Requests new when needed
```

---

## 🚀 Setup Instructions

### **Step 1: Generate Initial Question Bank**

#### **Option A: Using OpenAI (Paid but High Quality)**
1. Get API key from https://platform.openai.com/api-keys
2. Cost: ~$0.001 per question (gpt-3.5-turbo)
3. Total cost for 2000 questions: ~$2-3

```dart
// In lib/services/question_generator_script.dart
const apiKey = 'sk-your-openai-api-key';
await QuestionGeneratorScript.generateAllQuestions(apiKey);
```

#### **Option B: Using Google Gemini (Free!)**
1. Get API key from https://makersuite.google.com/app/apikey
2. Free tier: 60 requests/minute
3. Total time for 2000 questions: ~30-40 minutes

```dart
// Use Gemini instead
await _aiGenerator.generateQuestionsWithGemini(
  category: category,
  count: 20,
);
```

#### **Option C: Manual Entry + AI Assistance**
1. Start with 100-200 high-quality manual questions
2. Use AI to generate more over time
3. Review and approve AI-generated questions

### **Step 2: Run Generation Script**

```bash
# Install dependencies
flutter pub get

# Run the generator
dart run lib/services/question_generator_script.dart

# Output will be in: assets/questions/questions.json
```

### **Step 3: Upload to Backend**

#### **Using Firebase Firestore**
```dart
Future<void> uploadQuestionsToFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final questions = await loadQuestionsFromFile();
  
  final batch = firestore.batch();
  for (final question in questions) {
    final docRef = firestore.collection('questions').doc(question.id);
    batch.set(docRef, question.toJson());
  }
  await batch.commit();
}
```

#### **Using PostgreSQL/Supabase**
```sql
CREATE TABLE questions (
  id UUID PRIMARY KEY,
  category VARCHAR(50),
  question_text TEXT,
  options JSONB,
  correct_answer TEXT,
  explanation TEXT,
  difficulty VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_category ON questions(category);
CREATE INDEX idx_difficulty ON questions(difficulty);
```

---

## 💰 Cost-Efficient AI Generation

### **Strategy 1: One-Time Bulk Generation**
- Generate 2000 questions upfront
- Cost: $2-3 (OpenAI) or FREE (Gemini)
- Questions reused for ALL users
- **ROI: Infinite** (pay once, use forever)

### **Strategy 2: Progressive Generation**
- Start with 500 questions
- Generate more when stock is low
- Monitor usage patterns
- Prioritize popular categories

### **Strategy 3: Hybrid Approach** (Recommended)
- 80% curated questions (high quality, verified)
- 20% AI-generated (to maintain freshness)
- Community contributions (moderated)

---

## 📊 Question Management System

### **Automatic Stock Monitoring**
```dart
// Backend cron job (runs daily)
Future<void> monitorQuestionStock() async {
  for (final category in categories) {
    final stock = await getQuestionCount(category);
    final answered = await getAnsweredCount(category);
    final remaining = stock - answered;
    
    if (remaining < 50) {
      // Generate 100 more questions
      await generateQuestions(category, 100);
    }
  }
}
```

### **Smart Question Distribution**
```dart
// Ensure variety
List<Question> getQuestionsForUser(String userId, String category) {
  final answered = getUserAnsweredQuestions(userId, category);
  final available = getQuestions(category)
    .where((q) => !answered.contains(q.id))
    .toList();
  
  if (available.length < 10) {
    // User has answered most questions, reset progress
    resetUserProgress(userId, category);
    return getQuestions(category).take(10).toList();
  }
  
  return available..shuffle();
}
```

---

## 🔐 Security & Best Practices

### **API Key Security**
```dart
// ❌ NEVER store API keys in client app
// ✅ Store in backend environment variables

// Backend (Node.js example)
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Mobile app calls backend endpoint
Future<void> requestNewQuestions(String category) async {
  await http.post(
    'https://your-backend.com/api/generate-questions',
    body: {'category': category, 'count': 20},
    headers: {'Authorization': 'Bearer $userToken'},
  );
}
```

### **Question Validation**
```dart
bool validateQuestion(Question q) {
  return q.questionText.isNotEmpty &&
         q.options.length == 4 &&
         q.options.contains(q.correctAnswer) &&
         q.explanation.isNotEmpty &&
         q.questionText.length > 20 &&
         q.explanation.length > 30;
}
```

### **Duplicate Prevention**
```dart
// Check for similar questions using text similarity
bool isDuplicate(Question newQ, List<Question> existing) {
  for (final existingQ in existing) {
    final similarity = calculateSimilarity(
      newQ.questionText,
      existingQ.questionText,
    );
    if (similarity > 0.8) return true; // 80% similar
  }
  return false;
}
```

---

## 📱 Client Implementation

### **Update GameProvider to use QuestionService**
```dart
class GameProvider extends ChangeNotifier {
  final QuestionService _questionService = QuestionService();
  
  Future<void> startGame({
    required String category,
    required int questionCount,
  }) async {
    // Get unanswered questions
    _questions = _questionService.getUnansweredQuestions(
      category,
      limit: questionCount,
    );
    
    // If not enough questions, request more from backend
    if (_questions.length < questionCount) {
      await _requestMoreQuestions(category);
    }
  }
  
  void answerQuestion(String questionId, String category, bool correct) {
    // Mark as answered
    _questionService.markQuestionAsAnswered(questionId, category);
  }
}
```

---

## 📈 Scalability

### **Initial Scale (MVP)**
- 2,000 questions (400 per category)
- Supports 100+ users
- Local caching
- Manual refresh

### **Growth Scale (1K-10K users)**
- 10,000 questions (2,000 per category)
- Backend question service
- Auto-generation when needed
- User-specific progress tracking

### **Enterprise Scale (10K+ users)**
- 50,000+ questions
- Distributed database
- Real-time stock monitoring
- Multiple difficulty levels
- A/B testing for questions
- Analytics on question performance

---

## 💡 Cost Breakdown

### **OpenAI GPT-3.5-turbo**
```
Input: ~250 tokens per request
Output: ~800 tokens per response (20 questions)
Cost: $0.0005/1K input + $0.0015/1K output
Per batch (20 questions): ~$0.001
Total for 2,000 questions: ~$2-3

Monthly cost (with monitoring): ~$5-10
```

### **Google Gemini Pro**
```
Free tier: 60 requests/minute
Paid tier: $0.00025/1K tokens
Cost for 2,000 questions: ~$1 or FREE
```

### **Backend Hosting (Estimated)**
```
Firebase Firestore:
- Storage: $0.18/GB (2000 questions ≈ 5MB = FREE)
- Reads: $0.06/100K (within free tier for most apps)

Total monthly cost: ~$0-5
```

---

## 🎯 Implementation Checklist

### **Phase 1: Setup (Week 1)**
- [ ] Choose AI provider (OpenAI vs Gemini)
- [ ] Set up backend (Firebase/Supabase)
- [ ] Generate initial 2000 questions
- [ ] Upload to database
- [ ] Test question fetching

### **Phase 2: Integration (Week 2)**
- [ ] Update GameProvider
- [ ] Implement QuestionService
- [ ] Add progress tracking
- [ ] Test with real gameplay
- [ ] Verify no duplicates shown

### **Phase 3: Monitoring (Week 3)**
- [ ] Set up stock monitoring
- [ ] Implement auto-generation
- [ ] Add analytics
- [ ] Monitor costs
- [ ] Optimize as needed

---

## 🔄 Continuous Improvement

### **Weekly Tasks**
- Review question performance
- Check stock levels
- Generate if needed
- Update poor-performing questions

### **Monthly Tasks**
- Analyze user feedback
- Add trending topics
- Update categories
- Quality check AI questions

---

## 📞 Next Steps

1. **Choose your AI provider** (Gemini recommended for free tier)
2. **Run the generator script** to create initial bank
3. **Set up Firebase/Supabase** for storage
4. **Update the app** to use QuestionService
5. **Test thoroughly** before launch

---

**Questions saved = Money saved = Happy users! 🎉**

Last Updated: Jan 10, 2026

