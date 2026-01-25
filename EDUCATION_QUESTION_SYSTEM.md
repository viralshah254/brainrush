# 🎓 Education Question System - Implementation Guide

## ✅ What's Been Created

### 1. **Education Question Bank Service** (`lib/services/education_question_bank.dart`)
- Loads questions from `assets/questions/education_questions.json`
- Supports filtering by:
  - **School System**: US, UK, General
  - **Grade Level**: Grade/Year 5-12
  - **Subject**: Math, Science, English, History, Geography
  - **Difficulty**: easy, medium, hard, very_hard
- Methods:
  - `getQuestions()` - Get questions for specific grade/subject
  - `getQuestionsForCampaignRound()` - Get questions for education campaign
  - `getDailyEducationChallengeQuestions()` - Get daily challenge questions
  - `getQuestionCount()` - Get count of questions available

### 2. **Education Campaign Service** (`lib/services/education_campaign_service.dart`)
- Creates 500 rounds per grade level
- Rotates through 5 subjects (Math, Science, English, History, Geography)
- Progresses through difficulty levels (Easy → Medium → Hard → Super Hard)
- Saves progress per grade level using SharedPreferences
- Separate campaign instance for each grade level

### 3. **Question Generation Script** (`generate_education_questions.py`)
- Generates 500 questions per subject per grade per system
- Total: **60,000 questions** (3 systems × 8 grades × 5 subjects × 500 questions)
- Distributes across difficulty levels:
  - 40% Easy
  - 30% Medium
  - 20% Hard
  - 10% Very Hard
- Includes templates for each subject

### 4. **Home Screen Integration**
- Added Education Campaign card in education mode
- Shows campaign for user's grade level
- Navigates to education campaign screen

## 📋 Next Steps

### Step 1: Generate Questions
Run the Python script to generate education questions:

```bash
cd /Users/v/Desktop/Apps/mind_rush/mind_rush
python3 generate_education_questions.py
```

This will create `assets/questions/education_questions.json` with all 60,000 questions.

### Step 2: Update Campaign Screen
The `CampaignScreen` needs to be updated to support education mode. Currently it only supports general campaign. You'll need to:

1. Add education campaign UI methods (`_buildEducationAppBar`, `_buildEducationStats`, `_buildEducationRoundsList`)
2. Use `EducationCampaignService` when `isEducationMode == true`
3. Update `CampaignGameScreen` to use `EducationQuestionBank` for education mode

### Step 3: Update Game Screens
Update `CampaignGameScreen` and `GameScreen` to:
- Check if in education mode
- Use `EducationQuestionBank` instead of `ExpandedQuestionBank` for education questions
- Pass grade level and school system to question bank

### Step 4: Test
1. Set up education profile (age, grade, school system)
2. Switch to Education mode
3. Tap "Education Campaign"
4. Verify questions are grade-appropriate
5. Verify campaign progress saves correctly

## 📊 Question Structure

Each question in `education_questions.json` should have:
```json
{
  "id": "edu_us_grade6_math_001",
  "text": "What is 12 × 8?",
  "options": ["96", "88", "104", "92"],
  "correctIndex": 0,
  "explanation": "12 × 8 = 96...",
  "category": "Math",
  "difficulty": "easy",
  "topic": "multiplication",
  "mode": "EDUCATION_SCHOOL",
  "gradeLevel": "US_GRADE_6",
  "source": "CURATED",
  "language": "EN"
}
```

## 🎯 Grade Level Codes

### US System:
- `US_GRADE_5` through `US_GRADE_12`

### UK System:
- `UK_YEAR_5` through `UK_YEAR_12`

### General System:
- `GRADE_5` through `GRADE_12`

## 📝 Notes

- The question generation script is a template - you may need to refine it for better quality questions
- Consider using AI/API to generate more diverse and accurate questions
- Questions should be curriculum-aligned for each grade level
- Consider adding more subjects or expanding existing ones










