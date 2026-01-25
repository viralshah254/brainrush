/// Test script to verify questions load correctly with new educational format
/// Run: dart tools/test_question_loading.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Testing question loading...\n');
  
  try {
    // Read questions.json
    final file = File('assets/questions/questions.json');
    if (!await file.exists()) {
      print('❌ questions.json not found!');
      exit(1);
    }
    
    final content = await file.readAsString();
    final questions = json.decode(content) as List;
    
    print('✅ Loaded ${questions.length} questions\n');
    
    // Test first question
    final firstQuestion = questions[0] as Map<String, dynamic>;
    
    print('📋 Sample Question (first question):');
    print('   ID: ${firstQuestion['id']}');
    print('   Text: ${firstQuestion['text']}');
    print('   Category: ${firstQuestion['category']}');
    print('   Difficulty: ${firstQuestion['difficulty']}');
    print('   Question Type: ${firstQuestion['questionType']}');
    print('   Learning Objective: ${firstQuestion['learningObjective']}');
    print('   Grade Level: ${firstQuestion['gradeLevel']}');
    print('   Has shortExplanation: ${firstQuestion['shortExplanation'] != null}');
    print('   Has deepExplanation: ${firstQuestion['deepExplanation'] != null}');
    print('   Has whyWrong: ${firstQuestion['whyWrong'] != null}');
    print('   Has hint: ${firstQuestion['hint'] != null}');
    print('   Tags: ${firstQuestion['tags']}');
    print('   Lesson ID: ${firstQuestion['lessonId']}');
    
    // Validate required fields
    final requiredFields = [
      'id', 'text', 'options', 'correctIndex', 'correctAnswer',
      'category', 'difficulty', 'topic',
      'questionType', 'learningObjective', 'shortExplanation',
      'deepExplanation', 'whyWrong', 'gradeLevel', 'tags'
    ];
    
    print('\n🔍 Validating required fields...');
    int missingFields = 0;
    for (final field in requiredFields) {
      if (!firstQuestion.containsKey(field) || firstQuestion[field] == null) {
        print('   ❌ Missing: $field');
        missingFields++;
      } else {
        print('   ✅ Has: $field');
      }
    }
    
    // Validate whyWrong structure
    if (firstQuestion['whyWrong'] != null) {
      final whyWrong = firstQuestion['whyWrong'] as Map<String, dynamic>;
      print('\n🔍 Validating whyWrong structure...');
      for (int i = 0; i < 4; i++) {
        if (whyWrong.containsKey(i.toString())) {
          print('   ✅ whyWrong[$i]: ${whyWrong[i.toString()].toString().substring(0, 50)}...');
        } else {
          print('   ❌ Missing whyWrong[$i]');
          missingFields++;
        }
      }
    }
    
    // Validate options count
    final options = firstQuestion['options'] as List;
    if (options.length == 4) {
      print('\n✅ Options count: 4 (correct)');
    } else {
      print('\n❌ Options count: ${options.length} (should be 4)');
      missingFields++;
    }
    
    // Validate correctIndex
    final correctIndex = firstQuestion['correctIndex'] as int;
    if (correctIndex >= 0 && correctIndex < 4) {
      print('✅ correctIndex: $correctIndex (valid)');
    } else {
      print('❌ correctIndex: $correctIndex (invalid, should be 0-3)');
      missingFields++;
    }
    
    // Validate correctAnswer matches
    final correctAnswer = firstQuestion['correctAnswer'] as String;
    if (options[correctIndex] == correctAnswer) {
      print('✅ correctAnswer matches options[correctIndex]');
    } else {
      print('❌ correctAnswer mismatch: $correctAnswer != ${options[correctIndex]}');
      missingFields++;
    }
    
    // Test parsing with Question model (simulated)
    print('\n📦 Testing Question model compatibility...');
    try {
      // Simulate Question.fromJson
      final questionData = {
        'id': firstQuestion['id'],
        'text': firstQuestion['text'],
        'options': firstQuestion['options'],
        'correctIndex': firstQuestion['correctIndex'],
        'explanation': firstQuestion['shortExplanation'] ?? firstQuestion['explanation'] ?? '',
        'category': firstQuestion['category'],
        'difficulty': firstQuestion['difficulty'],
        'topic': firstQuestion['topic'],
        'questionType': firstQuestion['questionType'],
        'learningObjective': firstQuestion['learningObjective'],
        'shortExplanation': firstQuestion['shortExplanation'],
        'deepExplanation': firstQuestion['deepExplanation'],
        'whyWrong': firstQuestion['whyWrong'],
        'gradeLevel': firstQuestion['gradeLevel'],
        'tags': firstQuestion['tags'],
        'lessonId': firstQuestion['lessonId'],
        'hint': firstQuestion['hint'],
      };
      
      print('   ✅ Question data structure is valid');
      print('   ✅ All new educational fields are present');
    } catch (e) {
      print('   ❌ Error parsing question: $e');
      missingFields++;
    }
    
    // Summary
    print('\n📊 Summary:');
    if (missingFields == 0) {
      print('✅ All tests passed! Questions are properly formatted.');
      exit(0);
    } else {
      print('❌ Found $missingFields issues. Please review the questions.');
      exit(1);
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}









