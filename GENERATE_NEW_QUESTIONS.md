# 📚 Generate New Curriculum-Based Education Questions

## Overview
The new question generator creates curriculum-appropriate questions aligned with actual US/UK/General school curricula, not just basic arithmetic.

## Features

### ✅ Curriculum-Aligned Questions
- **Math**: Fractions, algebra, geometry, trigonometry, calculus (based on grade level)
- **Science**: Biology, chemistry, physics, earth science (age-appropriate)
- **English**: Grammar, literature, writing, literary analysis
- **History**: Grade-appropriate historical events and concepts
- **Geography**: Physical and human geography, map skills

### ✅ Proper Difficulty Distribution
- **Easy**: 125 questions per subject per grade
- **Medium**: 150 questions per subject per grade  
- **Hard**: 150 questions per subject per grade
- **Very Hard**: 75 questions per subject per grade
- **Total**: 500 questions per subject per grade

### ✅ Mixed Difficulty Campaign Progression
Campaign rounds now follow a mixed pattern:
- **Rounds 1-50**: Easy → Hard → Medium → Easy → Hard → Medium (repeats)
- **Rounds 51-150**: Easy → Hard → Medium → Super Hard → Easy → Hard → Medium → Super Hard
- **Rounds 151-300**: More Super Hard, but still mixed with Easy breaks
- **Rounds 301-500**: Mostly Hard/Super Hard with Easy breaks

This creates a varied experience with easy questions between harder ones.

## How to Generate

1. **Run the generator:**
   ```bash
   python3 generate_curriculum_education_questions.py
   ```

2. **Wait for completion:**
   - Generates 60,000 questions total (24 grades × 5 subjects × 500 questions)
   - Takes several minutes to complete
   - Shows progress every 1000 questions

3. **Output:**
   - File: `assets/questions/education_questions.json`
   - Replaces the old file with curriculum-appropriate questions

4. **Rebuild the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Question Quality

### Math Examples:
- **Grade 5**: Fractions, decimals, area & perimeter
- **Grade 9**: Quadratic equations, polynomials, factoring
- **Grade 12**: Calculus, integration, derivatives

### Science Examples:
- **Grade 5**: Ecosystems, matter & energy, weather
- **Grade 9**: Biology foundations, chemistry principles
- **Grade 12**: Advanced biology, AP topics, research methods

### English Examples:
- **Grade 5**: Reading comprehension, grammar basics
- **Grade 9**: Literature survey, academic writing
- **Grade 12**: AP Literature, thesis writing, critical analysis

## Coin Deduction

✅ Already implemented: Users lose 5 coins for each wrong answer in campaign mode (see `campaign_game_screen.dart` line 232).

## Verification

After generating, verify:
1. File size should be ~30-40MB
2. JSON is valid: `python3 -c "import json; json.load(open('assets/questions/education_questions.json'))"`
3. Question count: Should have 60,000 questions
4. Difficulty distribution: Check that each difficulty has appropriate counts



