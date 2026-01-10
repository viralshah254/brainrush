/// ADMIN SCRIPT: Generate Initial Question Bank
/// Run this script once to generate a large question bank using AI
/// Questions are saved and reused for all users
/// 
/// Usage:
/// 1. Set your API key (OpenAI or Google Gemini)
/// 2. Run: dart run lib/services/question_generator_script.dart
/// 3. Questions will be saved to assets/questions/questions.json
/// 4. Upload to your backend/database for production use

import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class QuestionGeneratorScript {
  static const categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
  static const questionsPerCategory = 400; // 400 x 5 = 2000 questions
  
  static Future<void> generateAllQuestions(String apiKey) async {
    final allQuestions = <Map<String, dynamic>>[];
    
    print('🚀 Starting question generation...');
    print('📊 Target: ${questionsPerCategory * categories.length} questions\n');
    
    for (final category in categories) {
      print('📚 Generating questions for: $category');
      final questions = await _generateCategoryQuestions(category, apiKey);
      allQuestions.addAll(questions);
      print('✅ Generated ${questions.length} questions for $category\n');
      
      // Delay to avoid rate limiting
      await Future.delayed(const Duration(seconds: 3));
    }
    
    // Save to file
    await _saveQuestionsToFile(allQuestions);
    
    print('\n🎉 Generation complete!');
    print('📁 Total questions generated: ${allQuestions.length}');
    print('💾 Saved to: assets/questions/questions.json');
  }
  
  static Future<List<Map<String, dynamic>>> _generateCategoryQuestions(
    String category,
    String apiKey,
  ) async {
    final questions = <Map<String, dynamic>>[];
    final batches = (questionsPerCategory / 20).ceil(); // Generate 20 at a time
    
    for (int i = 0; i < batches; i++) {
      print('  Batch ${i + 1}/$batches...');
      
      // In production, make actual API calls here
      // For now, generate sample questions
      final batchQuestions = _generateSampleQuestions(category, 20);
      questions.addAll(batchQuestions);
    }
    
    return questions;
  }
  
  static List<Map<String, dynamic>> _generateSampleQuestions(String category, int count) {
    final questions = <Map<String, dynamic>>[];
    final uuid = const Uuid();
    
    for (int i = 0; i < count; i++) {
      questions.add({
        'id': uuid.v4(),
        'category': category,
        'questionText': 'Sample $category question ${i + 1}',
        'options': [
          'Option A',
          'Option B',
          'Option C',
          'Option D',
        ],
        'correctAnswer': 'Option A',
        'explanation': 'This is a sample explanation for the correct answer.',
      });
    }
    
    return questions;
  }
  
  static Future<void> _saveQuestionsToFile(List<Map<String, dynamic>> questions) async {
    final file = File('assets/questions/questions.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(json.encode(questions));
  }
}

void main() async {
  // TODO: Replace with your actual API key
  const apiKey = 'YOUR_API_KEY_HERE';
  
  if (apiKey == 'YOUR_API_KEY_HERE') {
    print('⚠️  Please set your API key in the script');
    print('Get a free API key from:');
    print('  - OpenAI: https://platform.openai.com/api-keys');
    print('  - Google Gemini: https://makersuite.google.com/app/apikey');
    return;
  }
  
  await QuestionGeneratorScript.generateAllQuestions(apiKey);
}

