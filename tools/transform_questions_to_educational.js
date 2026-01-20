/**
 * Transform questions.json from trivia format to educational learning format
 * 
 * This script:
 * 1. Reads assets/questions/questions.json
 * 2. Transforms each question to include educational fields
 * 3. Writes the transformed questions back to the same file
 * 
 * Run: node tools/transform_questions_to_educational.js
 */

const fs = require('fs');
const path = require('path');

// Grade level mapping based on difficulty and category
function determineGradeLevel(difficulty, category, topic) {
  if (difficulty === 'easy') {
    if (category === 'Math' && (topic.includes('addition') || topic.includes('subtraction') || topic.includes('basic'))) {
      return 'Kids (5-7)';
    }
    return 'Primary (8-10)';
  } else if (difficulty === 'medium') {
    return 'Middle School (11-13)';
  } else if (difficulty === 'hard') {
    return 'High School (14-18)';
  } else if (difficulty === 'very_hard') {
    if (category === 'Math' && (topic.includes('calculus') || topic.includes('advanced'))) {
      return 'GMAT/GRE';
    }
    if (category === 'Literature' || category === 'History') {
      return 'SAT/ACT';
    }
    return 'High School (14-18)';
  }
  return 'Middle School (11-13)';
}

// Determine question type based on question text and category
function determineQuestionType(text, category, topic) {
  const lowerText = text.toLowerCase();
  
  // Conceptual questions
  if (lowerText.includes('what does') || lowerText.includes('what is') || 
      lowerText.includes('what are') || lowerText.includes('meaning') ||
      lowerText.includes('represents') || lowerText.includes('tells you')) {
    return 'conceptual';
  }
  
  // Application questions
  if (lowerText.includes('use') || lowerText.includes('apply') || 
      lowerText.includes('calculate') || lowerText.includes('solve') ||
      lowerText.includes('if you have') || lowerText.includes('scenario')) {
    return 'application';
  }
  
  // Reasoning questions
  if (lowerText.includes('why') || lowerText.includes('how') ||
      lowerText.includes('step') || lowerText.includes('order') ||
      lowerText.includes('process')) {
    return 'reasoning';
  }
  
  // Misconception check
  if (lowerText.includes('common mistake') || lowerText.includes('often confused') ||
      lowerText.includes('not true') || lowerText.includes('incorrect')) {
    return 'misconception_check';
  }
  
  // Default to recall if it's a fact question, but we'll make it educational
  return 'recall';
}

// Generate learning objective based on category and topic
function generateLearningObjective(category, topic, text) {
  const lowerTopic = topic.toLowerCase();
  const lowerText = text.toLowerCase();
  
  if (category === 'Math') {
    if (lowerTopic.includes('addition')) {
      return 'Understand addition as combining quantities.';
    } else if (lowerTopic.includes('subtraction')) {
      return 'Understand subtraction as taking away or finding the difference.';
    } else if (lowerTopic.includes('multiplication')) {
      return 'Understand multiplication as repeated addition or grouping.';
    } else if (lowerTopic.includes('division')) {
      return 'Understand division as sharing or grouping equally.';
    } else if (lowerTopic.includes('fraction')) {
      return 'Understand fractions as parts of a whole.';
    } else if (lowerTopic.includes('percentage')) {
      return 'Understand percentages as parts per hundred.';
    } else if (lowerTopic.includes('algebra')) {
      return 'Understand algebraic expressions and equations.';
    } else if (lowerTopic.includes('geometry')) {
      return 'Understand geometric shapes, properties, and relationships.';
    }
    return 'Apply mathematical concepts to solve problems.';
  } else if (category === 'Science') {
    if (lowerTopic.includes('chemistry')) {
      return 'Understand chemical formulas, elements, and compounds.';
    } else if (lowerTopic.includes('biology')) {
      return 'Understand biological processes and living systems.';
    } else if (lowerTopic.includes('physics')) {
      return 'Understand physical laws and principles.';
    } else if (lowerTopic.includes('earth')) {
      return 'Understand Earth science and natural phenomena.';
    }
    return 'Understand scientific concepts and principles.';
  } else if (category === 'Geography') {
    if (lowerTopic.includes('capital')) {
      return 'Understand what capital cities represent and their significance.';
    } else if (lowerTopic.includes('country')) {
      return 'Understand countries, their locations, and characteristics.';
    } else if (lowerTopic.includes('landform')) {
      return 'Understand geographic features and landforms.';
    }
    return 'Understand geographic concepts and locations.';
  } else if (category === 'History') {
    return 'Understand historical events, their causes, and significance.';
  } else if (category === 'Literature') {
    return 'Understand literary works, authors, and literary devices.';
  }
  
  return `Understand concepts related to ${topic}.`;
}

// Generate short explanation (1-2 sentences)
function generateShortExplanation(originalExplanation, category, topic, correctAnswer) {
  if (originalExplanation && originalExplanation.length > 0 && 
      originalExplanation !== 'The answer is ' + correctAnswer + '.' &&
      originalExplanation.length < 150) {
    // Use original if it's good, but make it more educational
    return originalExplanation;
  }
  
  // Generate based on category
  if (category === 'Math') {
    return `The correct answer demonstrates the mathematical concept being tested.`;
  } else if (category === 'Science') {
    return `This answer reflects the scientific principle or fact being taught.`;
  } else if (category === 'Geography') {
    return `This is the correct geographic fact or location.`;
  } else if (category === 'History') {
    return `This answer reflects the historical fact or event.`;
  } else if (category === 'Literature') {
    return `This answer reflects the literary work or author.`;
  }
  
  return `The correct answer is ${correctAnswer}.`;
}

// Generate deep explanation (2-6 sentences)
function generateDeepExplanation(originalExplanation, category, topic, text, correctAnswer, options) {
  let deep = '';
  
  if (originalExplanation && originalExplanation.length > 50 && 
      originalExplanation !== 'The answer is ' + correctAnswer + '.') {
    deep = originalExplanation + ' ';
  }
  
  // Add educational context
  if (category === 'Math') {
    deep += `This question tests your understanding of ${topic}. `;
    deep += `Understanding this concept helps you solve similar problems. `;
    deep += `Practice with these types of questions builds mathematical reasoning skills.`;
  } else if (category === 'Science') {
    deep += `This question tests your understanding of ${topic} in ${category.toLowerCase()}. `;
    deep += `Understanding these scientific concepts helps explain how the world works. `;
    deep += `This knowledge is fundamental to further scientific learning.`;
  } else if (category === 'Geography') {
    deep += `This question helps you understand ${topic}. `;
    deep += `Geographic knowledge helps you understand the world and different cultures. `;
    deep += `This information is useful for understanding global relationships.`;
  } else if (category === 'History') {
    deep += `This question tests your knowledge of ${topic}. `;
    deep += `Understanding history helps us learn from the past and understand the present. `;
    deep += `Historical knowledge provides context for current events.`;
  } else if (category === 'Literature') {
    deep += `This question tests your knowledge of ${topic}. `;
    deep += `Understanding literature helps develop critical thinking and cultural awareness. `;
    deep += `Literary knowledge enriches your understanding of language and storytelling.`;
  } else {
    deep += `This question tests your understanding of ${topic}. `;
    deep += `Learning this concept helps build your knowledge in ${category.toLowerCase()}.`;
  }
  
  return deep.trim();
}

// Generate whyWrong explanations for each option
function generateWhyWrong(optionIndex, correctIndex, options, category, topic, correctAnswer) {
  if (optionIndex === correctIndex) {
    return `Correct: ${options[optionIndex]} is the right answer.`;
  }
  
  const wrongOption = options[optionIndex];
  
  // Generate plausible explanation for why it's wrong
  if (category === 'Math') {
    if (topic.includes('addition')) {
      return `${wrongOption} would be the result of a different addition problem, not this one.`;
    } else if (topic.includes('multiplication')) {
      return `${wrongOption} would be the result of multiplying different numbers.`;
    }
    return `${wrongOption} is not the correct result for this calculation.`;
  } else if (category === 'Geography') {
    if (topic.includes('capital')) {
      return `${wrongOption} is not the capital city for this location.`;
    }
    return `${wrongOption} is not the correct answer for this geographic question.`;
  } else if (category === 'Science') {
    return `${wrongOption} does not match the scientific fact or concept being tested.`;
  } else if (category === 'History') {
    return `${wrongOption} is not the correct historical fact or event.`;
  } else if (category === 'Literature') {
    return `${wrongOption} is not the correct answer for this literary question.`;
  }
  
  return `${wrongOption} is not the correct answer.`;
}

// Generate tags based on category, topic, and difficulty
function generateTags(category, topic, difficulty) {
  const tags = [];
  
  // Category tag
  tags.push(category.toLowerCase());
  
  // Topic tags
  const topicWords = topic.toLowerCase().split(/[\s,_-]+/);
  topicWords.forEach(word => {
    if (word.length > 2 && !tags.includes(word)) {
      tags.push(word);
    }
  });
  
  // Difficulty tag
  tags.push(difficulty);
  
  // Add category-specific tags
  if (category === 'Math') {
    tags.push('mathematics', 'problem-solving');
  } else if (category === 'Science') {
    tags.push('science', 'scientific-method');
  } else if (category === 'Geography') {
    tags.push('geography', 'world-knowledge');
  } else if (category === 'History') {
    tags.push('history', 'historical-knowledge');
  } else if (category === 'Literature') {
    tags.push('literature', 'reading-comprehension');
  }
  
  // Ensure we have 3-8 tags
  return tags.slice(0, 8);
}

// Generate lessonId based on category and topic
function generateLessonId(category, topic) {
  const catPrefix = category.toLowerCase().substring(0, 3);
  const topicClean = topic.toLowerCase()
    .replace(/[^a-z0-9]/g, '_')
    .replace(/_+/g, '_')
    .substring(0, 20);
  return `${catPrefix}_${topicClean}_01`;
}

// Transform a single question
function transformQuestion(q) {
  const gradeLevel = determineGradeLevel(q.difficulty, q.category, q.topic);
  const questionType = determineQuestionType(q.text, q.category, q.topic);
  const learningObjective = generateLearningObjective(q.category, q.topic, q.text);
  const shortExplanation = generateShortExplanation(q.explanation, q.category, q.topic, q.correctAnswer);
  const deepExplanation = generateDeepExplanation(q.explanation, q.category, q.topic, q.text, q.correctAnswer, q.options);
  
  // Generate whyWrong for all 4 options
  const whyWrong = {};
  for (let i = 0; i < 4; i++) {
    whyWrong[i.toString()] = generateWhyWrong(i, q.correctIndex, q.options, q.category, q.topic, q.correctAnswer);
  }
  
  const tags = generateTags(q.category, q.topic, q.difficulty);
  const lessonId = generateLessonId(q.category, q.topic);
  
  // Build transformed question
  const transformed = {
    id: q.id,
    text: q.text,
    options: q.options,
    correctIndex: q.correctIndex,
    correctAnswer: q.correctAnswer,
    category: q.category,
    difficulty: q.difficulty,
    topic: q.topic,
    
    // Preserve legacy explanation field for backward compatibility
    explanation: q.explanation || shortExplanation,
    
    // New required educational fields
    questionType: questionType,
    learningObjective: learningObjective,
    shortExplanation: shortExplanation,
    deepExplanation: deepExplanation,
    whyWrong: whyWrong,
    gradeLevel: gradeLevel,
    tags: tags,
    
    // Optional but recommended fields
    lessonId: lessonId,
    lessonOrder: 1, // Default to 1, can be updated later
    hint: `Think about ${q.topic} and what you know about ${q.category.toLowerCase()}.`,
  };
  
  return transformed;
}

// Main transformation function
function transformQuestions() {
  console.log('🔄 Starting question transformation...');
  
  const inputPath = path.join(__dirname, '../assets/questions/questions.json');
  const outputPath = inputPath; // Overwrite same file
  
  try {
    // Read questions
    console.log('📖 Reading questions.json...');
    const fileContent = fs.readFileSync(inputPath, 'utf8');
    const questions = JSON.parse(fileContent);
    
    console.log(`📊 Found ${questions.length} questions to transform`);
    
    // Transform each question
    console.log('🔄 Transforming questions...');
    const transformed = questions.map((q, index) => {
      if ((index + 1) % 1000 === 0) {
        console.log(`   Processed ${index + 1}/${questions.length} questions...`);
      }
      return transformQuestion(q);
    });
    
    // Write transformed questions
    console.log('💾 Writing transformed questions...');
    fs.writeFileSync(outputPath, JSON.stringify(transformed, null, 2), 'utf8');
    
    console.log(`✅ Successfully transformed ${transformed.length} questions!`);
    console.log(`📁 Output written to: ${outputPath}`);
    
    // Validate a sample
    console.log('\n🔍 Sample transformed question:');
    console.log(JSON.stringify(transformed[0], null, 2));
    
  } catch (error) {
    console.error('❌ Error transforming questions:', error);
    process.exit(1);
  }
}

// Run transformation
transformQuestions();

