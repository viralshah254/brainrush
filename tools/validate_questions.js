/**
 * Validate questions.json to ensure all questions follow the educational format
 * 
 * This script checks:
 * - correctAnswer matches options[correctIndex]
 * - whyWrong has keys "0", "1", "2", "3"
 * - tags length >= 3
 * - All required fields exist
 * - questionType is valid enum
 * - gradeLevel is valid enum
 * 
 * Run: node tools/validate_questions.js
 */

const fs = require('fs');
const path = require('path');

const VALID_QUESTION_TYPES = ['recall', 'conceptual', 'application', 'reasoning', 'misconception_check'];
const VALID_GRADE_LEVELS = [
  'Kids (5-7)',
  'Primary (8-10)',
  'Middle School (11-13)',
  'High School (14-18)',
  'SAT/ACT',
  'GMAT/GRE'
];

const REQUIRED_FIELDS = [
  'id',
  'text',
  'options',
  'correctIndex',
  'correctAnswer',
  'category',
  'difficulty',
  'topic',
  'questionType',
  'learningObjective',
  'shortExplanation',
  'deepExplanation',
  'whyWrong',
  'gradeLevel',
  'tags'
];

function validateQuestion(q, index) {
  const errors = [];
  const warnings = [];
  
  // Check required fields
  for (const field of REQUIRED_FIELDS) {
    if (!(field in q)) {
      errors.push(`Missing required field: ${field}`);
    }
  }
  
  // Validate correctAnswer matches options[correctIndex]
  if (q.correctAnswer && q.options && q.correctIndex !== undefined) {
    if (q.correctAnswer !== q.options[q.correctIndex]) {
      errors.push(`correctAnswer "${q.correctAnswer}" does not match options[${q.correctIndex}] "${q.options[q.correctIndex]}"`);
    }
  }
  
  // Validate correctIndex is in range
  if (q.correctIndex !== undefined) {
    if (q.correctIndex < 0 || q.correctIndex > 3) {
      errors.push(`correctIndex ${q.correctIndex} is out of range (0-3)`);
    }
  }
  
  // Validate options array
  if (q.options) {
    if (!Array.isArray(q.options)) {
      errors.push('options must be an array');
    } else if (q.options.length !== 4) {
      errors.push(`options must have exactly 4 items, found ${q.options.length}`);
    }
  }
  
  // Validate whyWrong
  if (q.whyWrong) {
    if (typeof q.whyWrong !== 'object') {
      errors.push('whyWrong must be an object');
    } else {
      for (let i = 0; i < 4; i++) {
        if (!(i.toString() in q.whyWrong)) {
          errors.push(`whyWrong missing key "${i}"`);
        } else if (!q.whyWrong[i.toString()] || q.whyWrong[i.toString()].trim().length === 0) {
          warnings.push(`whyWrong["${i}"] is empty`);
        }
      }
    }
  }
  
  // Validate questionType
  if (q.questionType && !VALID_QUESTION_TYPES.includes(q.questionType)) {
    errors.push(`Invalid questionType: "${q.questionType}". Must be one of: ${VALID_QUESTION_TYPES.join(', ')}`);
  }
  
  // Validate gradeLevel
  if (q.gradeLevel && !VALID_GRADE_LEVELS.includes(q.gradeLevel)) {
    errors.push(`Invalid gradeLevel: "${q.gradeLevel}". Must be one of: ${VALID_GRADE_LEVELS.join(', ')}`);
  }
  
  // Validate tags
  if (q.tags) {
    if (!Array.isArray(q.tags)) {
      errors.push('tags must be an array');
    } else if (q.tags.length < 3) {
      warnings.push(`tags has only ${q.tags.length} items, should have at least 3`);
    } else if (q.tags.length > 8) {
      warnings.push(`tags has ${q.tags.length} items, should have at most 8`);
    }
  }
  
  // Validate explanations are not empty
  if (q.shortExplanation && q.shortExplanation.trim().length === 0) {
    warnings.push('shortExplanation is empty');
  }
  if (q.deepExplanation && q.deepExplanation.trim().length === 0) {
    warnings.push('deepExplanation is empty');
  }
  
  // Validate learningObjective is not empty
  if (q.learningObjective && q.learningObjective.trim().length === 0) {
    warnings.push('learningObjective is empty');
  }
  
  return { errors, warnings };
}

function validateQuestions() {
  console.log('🔍 Starting question validation...');
  
  const questionsPath = path.join(__dirname, '../assets/questions/questions.json');
  
  try {
    // Read questions
    console.log('📖 Reading questions.json...');
    const fileContent = fs.readFileSync(questionsPath, 'utf8');
    const questions = JSON.parse(fileContent);
    
    console.log(`📊 Found ${questions.length} questions to validate\n`);
    
    let totalErrors = 0;
    let totalWarnings = 0;
    const questionErrors = [];
    
    // Validate each question
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const { errors, warnings } = validateQuestion(q, i);
      
      if (errors.length > 0 || warnings.length > 0) {
        questionErrors.push({
          index: i,
          id: q.id,
          errors,
          warnings
        });
        totalErrors += errors.length;
        totalWarnings += warnings.length;
      }
    }
    
    // Print results
    if (questionErrors.length === 0) {
      console.log('✅ All questions are valid!');
    } else {
      console.log(`❌ Found ${questionErrors.length} questions with issues:`);
      console.log(`   - ${totalErrors} errors`);
      console.log(`   - ${totalWarnings} warnings\n`);
      
      // Show first 10 problematic questions
      const toShow = Math.min(10, questionErrors.length);
      console.log(`📋 Showing first ${toShow} problematic questions:\n`);
      
      for (let i = 0; i < toShow; i++) {
        const qe = questionErrors[i];
        console.log(`Question ${qe.index + 1} (ID: ${qe.id}):`);
        if (qe.errors.length > 0) {
          console.log('  ❌ Errors:');
          qe.errors.forEach(err => console.log(`     - ${err}`));
        }
        if (qe.warnings.length > 0) {
          console.log('  ⚠️  Warnings:');
          qe.warnings.forEach(warn => console.log(`     - ${warn}`));
        }
        console.log('');
      }
      
      if (questionErrors.length > toShow) {
        console.log(`... and ${questionErrors.length - toShow} more questions with issues`);
      }
    }
    
    // Summary
    console.log('\n📊 Validation Summary:');
    console.log(`   Total questions: ${questions.length}`);
    console.log(`   Valid questions: ${questions.length - questionErrors.length}`);
    console.log(`   Questions with issues: ${questionErrors.length}`);
    console.log(`   Total errors: ${totalErrors}`);
    console.log(`   Total warnings: ${totalWarnings}`);
    
    // Exit with error code if there are errors
    if (totalErrors > 0) {
      process.exit(1);
    }
    
  } catch (error) {
    console.error('❌ Error validating questions:', error);
    process.exit(1);
  }
}

// Run validation
validateQuestions();







