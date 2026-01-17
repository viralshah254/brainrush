# 📚 Education Question Difficulty Guide

## Overview

This guide explains how difficulty levels work in education questions and how they're used in "Study With Friends" mode.

## Difficulty Levels

The education question bank uses **4 difficulty levels**:

1. **`easy`** - Basic questions appropriate for the grade level
2. **`medium`** - Standard questions that require understanding
3. **`hard`** - Challenging questions that test deeper knowledge
4. **`very_hard`** - Extra hard questions for advanced students (mapped from "extra hard" in UI)

## Current Distribution

Based on validation of `education_questions.json`:

- **Easy**: ~37,660 questions (24.1%)
- **Medium**: ~43,456 questions (27.8%)
- **Hard**: ~35,562 questions (22.8%)
- **Very Hard**: ~15,460 questions (9.9%)

**Total**: ~156,000+ questions

## How It Works in "Study With Friends"

### 1. **Difficulty Selection**

When creating a room in "Study With Friends", users can select:
- Easy
- Medium
- Hard
- Extra Hard (mapped to `very_hard` in questions)
- Random (mix of all difficulties)

### 2. **Question Filtering**

The system filters questions based on:

1. **Grade Level** - Only questions matching the user's grade (e.g., `US_GRADE_11`)
2. **Subject** - Only questions in the selected subject (Math, Science, etc.)
3. **Difficulty** - Only questions matching the selected difficulty level

### 3. **Fallback Logic**

If not enough questions are found for the exact difficulty:

- **Education Mode**: Tries adjacent difficulty levels
  - Easy → Medium
  - Medium → Easy, Hard
  - Hard → Medium, Very Hard
  - Very Hard → Hard

- **General Mode**: Falls back to any difficulty

### 4. **Question Selection**

- Questions are shuffled randomly
- No duplicates within a round
- No duplicates across rounds (tracked via `_usedQuestionIds`)
- Each round gets 10 unique questions

## Code Mapping

### UI to Question Bank Mapping

```dart
GameDifficulty.easy      → "easy"
GameDifficulty.medium    → "medium"
GameDifficulty.hard      → "hard"
GameDifficulty.extraHard → "very_hard"  // ⚠️ Important mapping
GameDifficulty.random    → null (all difficulties)
```

### Key Files

- **Question Loading**: `lib/services/education_question_bank.dart`
  - `getQuestions()` - Filters by grade, subject, and difficulty
  
- **Multiplayer Game**: `lib/screens/multiplayer/multiplayer_game_screen.dart`
  - `_loadRoundQuestions()` - Loads questions for each round
  - `_mapDifficultyToQuestionBank()` - Maps UI difficulty to question bank format

## Validation

Run the validation script to check question difficulties:

```bash
python3 scripts/validate_education_question_difficulties.py
```

This script:
- ✅ Checks all questions have valid difficulty values
- ✅ Reports missing or invalid difficulties
- ✅ Shows distribution statistics
- ✅ Provides recommendations for balancing

## Best Practices

### For Question Creation

1. **Easy Questions**:
   - Basic concepts
   - Single-step problems
   - Direct recall
   - ~25-35% of questions per grade/subject

2. **Medium Questions**:
   - Standard application
   - Multi-step problems
   - Requires understanding
   - ~30-40% of questions per grade/subject

3. **Hard Questions**:
   - Complex problems
   - Requires analysis
   - Multiple concepts
   - ~20-30% of questions per grade/subject

4. **Very Hard Questions**:
   - Advanced concepts
   - Requires synthesis
   - Challenging applications
   - ~10-20% of questions per grade/subject

### For Game Balance

- **Easy Mode**: Good for beginners, confidence building
- **Medium Mode**: Standard gameplay, balanced challenge
- **Hard Mode**: For students who want a challenge
- **Extra Hard Mode**: For advanced students and competitive play
- **Random Mode**: Provides variety and tests all skill levels

## Troubleshooting

### Issue: Not enough questions for selected difficulty

**Solution**: The system automatically falls back to adjacent difficulties in education mode. This ensures games can always start even if a specific difficulty has limited questions.

### Issue: Questions seem too easy/hard

**Solution**: 
1. Check the question's difficulty tag in `education_questions.json`
2. Verify the grade level matches the user's grade
3. Run the validation script to check distribution

### Issue: Same questions appearing

**Solution**: The system tracks used questions via `_usedQuestionIds` to prevent duplicates within and across rounds. If you see duplicates, check:
- Question IDs are unique
- `_usedQuestionIds` is being properly maintained

## Future Improvements

- [ ] Add difficulty validation during question import
- [ ] Implement difficulty calibration based on user performance
- [ ] Add difficulty progression recommendations
- [ ] Create difficulty adjustment based on answer accuracy

---

**Last Updated**: January 2026  
**Maintained By**: Development Team

