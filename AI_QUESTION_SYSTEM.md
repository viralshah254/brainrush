# 🤖 AI Question Generation System

## 🎯 **System Overview**

BrainRush uses an intelligent, cost-efficient AI system to generate and manage questions:

```
┌─────────────────────────────────────────────────────────┐
│                    USER PLAYS GAME                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            QuestionService (Client)                      │
│  • Fetches unanswered questions                         │
│  • Tracks user progress                                  │
│  • Caches locally                                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│          Backend Question Service                        │
│  • Monitors question stock                               │
│  • Triggers AI generation when needed                    │
│  • Serves questions to all users                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│          AI Generator (OpenAI/Gemini)                    │
│  • Generates 20-50 questions per request                 │
│  • Questions saved to database                           │
│  • NO regeneration of existing questions                 │
└─────────────────────────────────────────────────────────┘
```

---

## 💰 **Cost-Efficiency Strategy**

### **Key Principle: Generate Once, Use Forever**

1. **Question Pooling**
   - Generate 2000+ questions initially
   - Store in database (accessible to ALL users)
   - Cost: One-time $2-3 (OpenAI) or FREE (Gemini)
   - **Never regenerate existing questions**

2. **Smart Stock Management**
   ```dart
   // Backend checks daily
   if (questionsInCategory < 100) {
     generateMore(category, 100);
     // Cost: ~$0.10 per category
   }
   ```

3. **Progressive Generation**
   - Start with 500 questions
   - Add 100 more when stock reaches threshold
   - Spread cost over time
   - **Total monthly cost: $5-10 max**

---

## 🔄 **How It Works**

### **1. Initial Setup (One-Time)**

```bash
# Step 1: Generate initial question bank
dart run lib/services/question_generator_script.dart

# Output: 2000 questions in JSON format
# Time: 30-40 minutes (Gemini) or 10 minutes (OpenAI)
# Cost: FREE (Gemini) or $2-3 (OpenAI)
```

### **2. Upload to Backend**

```dart
// Upload to Firebase/Supabase/PostgreSQL
await uploadQuestionsToDatabase(questions);

// Now available to ALL users
// No need to regenerate!
```

### **3. User Experience**

```dart
// User plays game
1. QuestionService.getUnansweredQuestions(category)
2. Returns questions user hasn't seen
3. User answers → marked as answered
4. Next time: Different questions
5. If all answered: Reset progress or fetch new batch
```

### **4. Automatic Refill (Backend)**

```dart
// Cron job runs daily
async function checkAndRefillQuestions() {
  for (const category of categories) {
    const count = await countQuestions(category);
    const answered = await countAnsweredByAllUsers(category);
    
    // If < 20% questions remain unused
    if ((count - answered) / count < 0.2) {
      await generateNewQuestions(category, 100);
      // Cost: ~$0.10
    }
  }
}
```

---

## 🎨 **AI Prompt Engineering**

### **High-Quality Question Template**

```javascript
const prompt = `
Generate 20 educational ${category} questions.

Quality Requirements:
1. Clear, unambiguous wording
2. Exactly 4 options (one correct, three plausible distractors)
3. Educational value (users should learn something)
4. Factual accuracy (verifiable information)
5. Appropriate difficulty for general audience
6. Diverse topics within ${category}

Format (JSON):
[
  {
    "questionText": "Clear question here?",
    "options": ["A", "B", "C", "D"],
    "correctAnswer": "A",
    "explanation": "Why A is correct and others are wrong"
  }
]

Examples for ${category}:
${getExamplesFor(category)}
`;
```

### **Category-Specific Prompts**

**Math:**
```
- Include calculations, formulas, geometry
- Range: Basic arithmetic to intermediate algebra
- Focus on practical applications
```

**Science:**
```
- Cover physics, chemistry, biology, astronomy
- Mix theoretical and applied concepts
- Include recent discoveries (pre-2024)
```

**History:**
```
- Global perspective (not just Western history)
- Mix ancient, medieval, modern eras
- Include cultural and social history
```

---

## 🔐 **Security & Best Practices**

### **✅ DO:**
- Store API keys in backend environment variables
- Validate all generated questions before saving
- Check for duplicates before adding
- Rate limit AI requests
- Cache aggressively
- Monitor costs

### **❌ DON'T:**
- Store API keys in mobile app
- Make AI calls from client
- Regenerate existing questions
- Skip validation
- Generate on-demand for each user

---

## 📊 **Cost Calculator**

### **OpenAI GPT-3.5-Turbo**
```
Single Batch (20 questions):
- Input tokens: ~300 ($0.0015/1K)
- Output tokens: ~1200 ($0.002/1K)
- Total: ~$0.003 per batch

2000 questions = 100 batches = $0.30
Monthly maintenance (10 categories × 100 questions): $3

Annual cost: ~$40
```

### **Google Gemini Pro**
```
Free Tier:
- 60 requests/minute
- Unlimited tokens per request
- Cost: $0

Paid Tier (if needed):
- $0.00025/1K tokens
- 2000 questions: ~$0.50

Annual cost: ~$0-10
```

### **Backend Hosting**
```
Firebase Firestore:
- Storage: 5MB of questions = FREE
- Reads: 50K/day × 30 = 1.5M/month
- First 50K reads/day are FREE
- Additional: $0.06/100K = ~$0.90/month

Total Backend: ~$1-2/month
```

### **Total System Cost**
```
Initial setup: $0-3 (one-time)
Monthly: $1-5 (hosting + occasional generation)
Annual: $12-60

Cost per user: $0.01-0.05 per year
**Extremely cost-efficient!**
```

---

## 🚀 **Implementation Guide**

### **Phase 1: Setup (Day 1)**

1. **Choose AI Provider**
   ```dart
   // Option A: Google Gemini (Recommended - FREE)
   final generator = AIQuestionGenerator();
   generator.setApiKey('YOUR_GEMINI_API_KEY');
   
   // Option B: OpenAI (Better quality, small cost)
   generator.setApiKey('YOUR_OPENAI_API_KEY');
   ```

2. **Generate Initial Bank**
   ```bash
   # Run generator script
   dart run lib/services/question_generator_script.dart
   
   # Wait 30-40 minutes
   # Output: assets/questions/questions.json
   ```

3. **Upload to Backend**
   ```dart
   await uploadToFirestore(questions);
   // or
   await uploadToSupabase(questions);
   ```

### **Phase 2: Integration (Day 2)**

1. **Update GameProvider**
   ```dart
   // Replace static question bank with QuestionService
   final questions = await QuestionService().getUnansweredQuestions(
     category,
     limit: 10,
   );
   ```

2. **Track Progress**
   ```dart
   // After user answers
   await QuestionService().markQuestionAsAnswered(
     questionId,
     category,
   );
   ```

### **Phase 3: Monitoring (Ongoing)**

1. **Backend Cron Job**
   ```javascript
   // Cloud Function (runs daily)
   exports.monitorQuestions = functions.pubsub
     .schedule('every 24 hours')
     .onRun(async () => {
       await checkAndRefillQuestions();
     });
   ```

2. **Analytics Dashboard**
   ```
   Track:
   - Questions per category
   - User progress
   - Generation frequency
   - Cost per month
   ```

---

## 🎯 **Quality Assurance**

### **Automated Validation**
```dart
bool validateQuestion(Question q) {
  // Length checks
  if (q.questionText.length < 20) return false;
  if (q.explanation.length < 30) return false;
  
  // Structure checks
  if (q.options.length != 4) return false;
  if (!q.options.contains(q.correctAnswer)) return false;
  
  // Content checks
  if (containsProfanity(q.questionText)) return false;
  if (isDuplicate(q)) return false;
  
  return true;
}
```

### **Manual Review**
```dart
// Flag questions for review
if (userReportCount > 3) {
  await flagForReview(question);
}

// Admin dashboard to approve/reject
```

---

## 📈 **Scaling Strategy**

### **MVP (0-1K users)**
- 2,000 questions
- Manual monitoring
- Generate when needed
- Cost: ~$5/month

### **Growth (1K-10K users)**
- 10,000 questions
- Automated monitoring
- Category-specific difficulty levels
- Cost: ~$10-20/month

### **Scale (10K+ users)**
- 50,000+ questions
- Real-time analytics
- A/B testing
- Multiple languages
- Cost: ~$50-100/month

---

## 🎉 **Benefits Summary**

✅ **Cost-Efficient**
- Pay once, use forever
- Share questions across all users
- Predictable costs

✅ **High Quality**
- AI-generated + human-validated
- Consistent format
- Educational value

✅ **Scalable**
- Easy to add more questions
- Automatic refilling
- No manual work

✅ **User-Friendly**
- Never see same question twice
- Always fresh content
- Progress tracking

---

## 📞 **Quick Start Checklist**

- [ ] Get API key (Gemini or OpenAI)
- [ ] Run question generator script
- [ ] Upload questions to backend
- [ ] Update app to use QuestionService
- [ ] Test question fetching
- [ ] Monitor costs
- [ ] Set up auto-refill (optional)
- [ ] Launch! 🚀

---

**Cost: $0-5/month | Quality: High | Maintenance: Low**

**Perfect for indie developers and startups! 💡**

---

Last Updated: Jan 10, 2026
Status: ✅ Ready to Implement

