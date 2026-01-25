# Question Transformation Tools

This directory contains tools for transforming and validating the educational question bank.

## Files

- `transform_questions_to_educational.js` - Transforms questions.json from trivia format to educational learning format
- `validate_questions.js` - Validates that all questions follow the educational format

## Usage

### Transform Questions

Transform all questions in `assets/questions/questions.json` to the educational format:

```bash
node tools/transform_questions_to_educational.js
```

This will:
- Read `assets/questions/questions.json`
- Transform each question to include educational fields
- Write the transformed questions back to the same file
- Show a sample transformed question

### Validate Questions

Validate that all questions follow the educational format:

```bash
node tools/validate_questions.js
```

This will check:
- ✅ `correctAnswer` matches `options[correctIndex]`
- ✅ `whyWrong` has keys "0", "1", "2", "3"
- ✅ `tags` length >= 3
- ✅ All required fields exist
- ✅ `questionType` is valid enum
- ✅ `gradeLevel` is valid enum

## Required Node.js

Make sure you have Node.js installed:

```bash
node --version  # Should be v12 or higher
```

## Educational Format Schema

### Required Fields

- `id` (string)
- `text` (string)
- `options` (array of 4 strings)
- `correctIndex` (int 0..3)
- `correctAnswer` (string)
- `category` (string)
- `difficulty` (easy | medium | hard | very_hard)
- `topic` (string)
- `questionType` (recall | conceptual | application | reasoning | misconception_check)
- `learningObjective` (string)
- `shortExplanation` (string, 1-2 sentences)
- `deepExplanation` (string, 2-6 sentences)
- `whyWrong` (object with keys "0", "1", "2", "3")
- `gradeLevel` (Kids (5-7) | Primary (8-10) | Middle School (11-13) | High School (14-18) | SAT/ACT | GMAT/GRE)
- `tags` (array of 3-8 strings)

### Optional Fields

- `lessonId` (string) - Groups questions into learning paths
- `lessonOrder` (number) - Order within lesson
- `prerequisites` (array of strings) - Prerequisite lesson IDs
- `hint` (string) - Helpful hint
- `timeLimitSec` (number) - Time limit in seconds
- `followUps` (array of question objects) - Reinforcement questions

## Backup

**IMPORTANT:** Before running the transformation, make a backup of `assets/questions/questions.json`:

```bash
cp assets/questions/questions.json assets/questions/questions.json.backup
```







