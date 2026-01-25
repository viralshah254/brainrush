# 📚 Expanding Question Bank to 5000+ Questions

## 📊 Current Status

- **JSON File**: 100 questions (`assets/questions/questions.json`)
- **Hardcoded**: ~750 placeholder questions in `expanded_question_bank.dart`
- **Target**: 5000+ questions
- **Need**: ~4900 more questions

---

## 🎯 Question Distribution Plan

### Target: 5000 Questions Total

**Distribution by Category (500 questions each):**
```
General Knowledge: 500 questions
Science:           500 questions
Math:              500 questions
History:           500 questions
Geography:         500 questions
Literature:        500 questions
Technology:        500 questions
Sports:            500 questions
Entertainment:     500 questions
Nature:            500 questions
───────────────────────────────
Total:           5,000 questions
```

**Distribution by Difficulty (per category):**
```
Easy:        125 questions (25%)
Medium:      150 questions (30%)
Hard:        150 questions (30%)
Super Hard:   75 questions (15%)
───────────────────────────────
Total:       500 questions per category
```

---

## 🔧 How the System Works Now

### 1. **JSON-First Loading**
- Questions are loaded from `assets/questions/questions.json`
- Falls back to hardcoded questions if JSON fails
- Supports unlimited questions (no code changes needed)

### 2. **Automatic Categorization**
- Questions are filtered by `category` field
- Supports all 10 subjects automatically
- No manual mapping needed

### 3. **Difficulty Filtering**
- Questions filtered by `difficulty` field
- Supports: `easy`, `medium`, `hard`, `super_hard`
- Falls back to adjacent difficulty if not enough

---

## 📝 How to Add Questions

### Option 1: Add to JSON File (Recommended)

**File**: `assets/questions/questions.json`

**Format**:
```json
[
  {
    "id": "q001",
    "text": "What is 2 + 2?",
    "options": ["3", "4", "5", "6"],
    "correctIndex": 1,
    "correctAnswer": "4",
    "explanation": "2 plus 2 equals 4. This is basic addition.",
    "category": "Math",
    "difficulty": "easy",
    "topic": "arithmetic"
  },
  {
    "id": "q002",
    "text": "What is the capital of France?",
    "options": ["London", "Berlin", "Paris", "Rome"],
    "correctIndex": 2,
    "correctAnswer": "Paris",
    "explanation": "Paris is the capital and largest city of France.",
    "category": "Geography",
    "difficulty": "easy",
    "topic": "capitals"
  }
]
```

**Required Fields**:
- `id`: Unique identifier (e.g., "q001", "math_easy_001")
- `text`: Question text
- `options`: Array of 4 answer options
- `correctIndex`: Index of correct answer (0-3)
- `correctAnswer`: The correct answer text
- `explanation`: Explanation of the answer
- `category`: One of: "General Knowledge", "Science", "Math", "History", "Geography", "Literature", "Technology", "Sports", "Entertainment", "Nature"
- `difficulty`: One of: "easy", "medium", "hard", "super_hard"
- `topic`: Topic/subtopic (e.g., "arithmetic", "capitals", "biology")

---

## 🤖 Option 2: Use AI Question Generator

The app has an AI question generator service that can create questions automatically.

**File**: `lib/services/ai_question_generator.dart`

**Usage**:
```dart
final generator = AIQuestionGenerator();
final questions = await generator.generateQuestions(
  category: 'Math',
  difficulty: 'medium',
  count: 100,
);
```

**Note**: Requires API key and backend integration.

---

## 📋 Question Generation Checklist

### For Each Question:
- [ ] Unique ID
- [ ] Clear, unambiguous question text
- [ ] 4 answer options (one correct, three plausible distractors)
- [ ] Correct answer index (0-3)
- [ ] Correct answer text
- [ ] Explanation
- [ ] Category (matches one of 10 subjects)
- [ ] Difficulty level
- [ ] Topic/subtopic

### Quality Guidelines:
- ✅ Questions should be factually correct
- ✅ Options should be plausible (not obviously wrong)
- ✅ Explanations should be educational
- ✅ Difficulty should match the question complexity
- ✅ Avoid ambiguous wording
- ✅ Use proper grammar and spelling

---

## 🎯 Quick Expansion Strategy

### Phase 1: Get to 1000 Questions (Current: 100)
- Add 900 questions to JSON
- ~90 questions per category
- Mix of all difficulties

### Phase 2: Get to 2500 Questions
- Add 1500 more questions
- ~150 questions per category
- Balanced difficulty distribution

### Phase 3: Get to 5000 Questions
- Add 2500 more questions
- ~250 questions per category
- Full difficulty coverage

---

## 🔍 Question Sources

### Free Resources:
1. **Open Trivia Database** (opentdb.com)
   - Free API with thousands of questions
   - Multiple categories and difficulties
   - Can export to JSON format

2. **Quizlet/Study Sets**
   - Educational question sets
   - Can be converted to app format

3. **Educational Websites**
   - Khan Academy
   - Coursera
   - Educational YouTube channels

### AI Generation:
1. **ChatGPT/Claude**
   - Generate questions in bulk
   - Specify category, difficulty, topic
   - Export in JSON format

2. **Custom AI Service**
   - Use `ai_question_generator.dart`
   - Integrate with OpenAI/Anthropic API
   - Generate questions programmatically

---

## 📊 Current Question Count by Category

Run this to check current counts:
```dart
final bank = ExpandedQuestionBank();
await bank.initialize();
print('Total: ${bank.getTotalQuestionCount()}');
print('Math: ${bank.getQuestionCountByCategory('Math')}');
// ... etc
```

---

## 🚀 Implementation Steps

### Step 1: Expand JSON File
1. Open `assets/questions/questions.json`
2. Add questions following the format
3. Ensure unique IDs
4. Verify category and difficulty fields

### Step 2: Test Loading
```dart
// In your app
await ExpandedQuestionBank.initialize();
final count = ExpandedQuestionBank.getTotalQuestionCount();
print('Loaded $count questions');
```

### Step 3: Verify Distribution
Check that questions are distributed across:
- ✅ All 10 categories
- ✅ All 4 difficulty levels
- ✅ Various topics

### Step 4: Test Game Modes
- ✅ Daily Challenge (should have variety)
- ✅ Campaign Mode (should have enough per round)
- ✅ Practice Mode (should have enough per category)

---

## 📈 Progress Tracking

### Current: ~100 questions
### Target: 5000 questions
### Remaining: ~4900 questions

**Breakdown Needed:**
- 490 questions per category
- ~122 easy, ~147 medium, ~147 hard, ~74 super hard per category

---

## 💡 Tips for Fast Expansion

1. **Use Question Templates**
   - Create templates for common question types
   - Fill in variables (numbers, names, dates)

2. **Batch Generation**
   - Generate 50-100 questions at a time
   - Focus on one category/difficulty at a time

3. **Leverage Existing Content**
   - Convert textbook questions
   - Use quiz websites
   - Import from educational apps

4. **Quality Over Quantity**
   - Better to have 1000 good questions than 5000 bad ones
   - Review questions before adding
   - Test with users

---

## 🔄 Maintenance

### Regular Tasks:
- [ ] Review question quality
- [ ] Fix any errors or typos
- [ ] Add new questions regularly
- [ ] Update explanations if needed
- [ ] Remove duplicate questions

### Monitoring:
- Track which questions are used most
- Identify categories needing more questions
- Balance difficulty distribution

---

## ✅ Success Criteria

**Question Bank is Ready When:**
- ✅ 5000+ questions total
- ✅ ~500 questions per category
- ✅ Balanced difficulty distribution
- ✅ Questions load quickly (<1 second)
- ✅ No duplicate questions
- ✅ All questions have valid format
- ✅ Explanations are helpful
- ✅ Options are plausible

---

## 📚 Example Question Sets

### Math - Easy (Sample)
```json
{
  "id": "math_easy_001",
  "text": "What is 5 × 7?",
  "options": ["30", "35", "40", "45"],
  "correctIndex": 1,
  "correctAnswer": "35",
  "explanation": "5 multiplied by 7 equals 35.",
  "category": "Math",
  "difficulty": "easy",
  "topic": "multiplication"
}
```

### Science - Medium (Sample)
```json
{
  "id": "sci_med_001",
  "text": "What is the chemical formula for table salt?",
  "options": ["NaCl", "KCl", "CaCl2", "MgCl2"],
  "correctIndex": 0,
  "correctAnswer": "NaCl",
  "explanation": "Table salt is sodium chloride (NaCl), composed of sodium and chlorine ions.",
  "category": "Science",
  "difficulty": "medium",
  "topic": "chemistry"
}
```

### History - Hard (Sample)
```json
{
  "id": "hist_hard_001",
  "text": "Which battle marked the turning point of World War II in the Pacific?",
  "options": ["Pearl Harbor", "Midway", "Iwo Jima", "Okinawa"],
  "correctIndex": 1,
  "correctAnswer": "Midway",
  "explanation": "The Battle of Midway (June 1942) was a decisive naval battle that turned the tide of the Pacific War in favor of the Allies.",
  "category": "History",
  "difficulty": "hard",
  "topic": "world wars"
}
```

---

## 🎉 Next Steps

1. **Start Adding Questions**
   - Begin with your strongest category
   - Add 50-100 questions at a time
   - Test after each batch

2. **Use Tools**
   - Question generator scripts
   - JSON validators
   - Bulk import tools

3. **Monitor Progress**
   - Track question count
   - Check distribution
   - Verify quality

**The system is ready to handle 5000+ questions - just add them to the JSON file!** 🚀










