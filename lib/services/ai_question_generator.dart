import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import 'package:uuid/uuid.dart';

/// AI-powered question generator using OpenAI/Gemini API
/// Generates questions that are then saved to database for all users
class AIQuestionGenerator {
  static final AIQuestionGenerator _instance = AIQuestionGenerator._internal();
  factory AIQuestionGenerator() => _instance;
  AIQuestionGenerator._internal();

  // TODO: Store API key securely (use environment variables or backend)
  String? _apiKey;
  String _apiEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  // Or use Google Gemini (free tier available)
  // String _apiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  void setApiKey(String key) {
    _apiKey = key;
  }

  /// Generate questions using AI
  /// This should be called from backend to avoid exposing API keys
  Future<List<Question>> generateQuestions({
    required String category,
    required int count,
    String difficulty = 'medium',
  }) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = _buildPrompt(category, count, difficulty);
      
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo', // or 'gpt-4' for better quality
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert educational content creator specializing in creating engaging, accurate multiple-choice questions.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseAIResponse(content, category);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error generating questions: $e');
      return [];
    }
  }

  String _buildPrompt(String category, int count, String difficulty) {
    return '''
Generate $count educational multiple-choice questions for the category: $category
Difficulty level: $difficulty

Requirements:
1. Each question should be clear, educational, and engaging
2. Provide exactly 4 answer options (A, B, C, D)
3. Mark the correct answer
4. Provide a brief, informative explanation
5. Questions should be factual and verifiable
6. Avoid controversial or subjective topics
7. Make questions diverse within the category

Format your response as a JSON array:
[
  {
    "text": "What is...",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Brief explanation..."
  },
  ...
]

Category-specific guidelines:
- Math: Include calculations, formulas, geometry, algebra
- Science: Cover physics, chemistry, biology, astronomy
- History: Events, dates, figures, civilizations
- Geography: Countries, capitals, features, climate
- Literature: Authors, works, genres, literary devices

Return ONLY the JSON array, no additional text.
''';
  }

  List<Question> _parseAIResponse(String content, String category) {
    try {
      // Clean up the response (remove markdown code blocks if present)
      String cleanContent = content.trim();
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      }
      if (cleanContent.startsWith('```')) {
        cleanContent = cleanContent.substring(3);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      cleanContent = cleanContent.trim();

      final List<dynamic> jsonList = json.decode(cleanContent);
      final questions = <Question>[];

      for (final item in jsonList) {
        questions.add(Question(
          id: const Uuid().v4(),
          category: category,
          text: item['text'],
          options: List<String>.from(item['options']),
          correctIndex: item['correctIndex'] as int,
          explanation: item['explanation'],
        ));
      }

      return questions;
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing AI response: $e');
      return [];
    }
  }

  /// Generate questions using Google Gemini (free alternative)
  Future<List<Question>> generateQuestionsWithGemini({
    required String category,
    required int count,
    String difficulty = 'medium',
  }) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = _buildPrompt(category, count, difficulty);
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseAIResponse(content, category);
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error generating questions with Gemini: $e');
      return [];
    }
  }
}

/// Backend service to manage AI-generated questions
/// This should run on your backend to:
/// 1. Generate questions when stock is low
/// 2. Cache generated questions in database
/// 3. Serve questions to all users
class QuestionGenerationService {
  static final QuestionGenerationService _instance = QuestionGenerationService._internal();
  factory QuestionGenerationService() => _instance;
  QuestionGenerationService._internal();

  final AIQuestionGenerator _aiGenerator = AIQuestionGenerator();
  
  /// Check if we need to generate more questions for a category
  Future<void> ensureQuestionStock(String category, {int minStock = 100}) async {
    // In production, check database for question count
    // If count < minStock, generate more
    
    // Example logic:
    // final currentCount = await database.getQuestionCount(category);
    // if (currentCount < minStock) {
    //   await generateAndSaveQuestions(category, 50);
    // }
  }

  /// Generate questions and save to database (backend only)
  Future<void> generateAndSaveQuestions(String category, int count) async {
    try {
      // Generate questions
      final questions = await _aiGenerator.generateQuestions(
        category: category,
        count: count,
        difficulty: 'medium',
      );

      // Save to database (Firestore, PostgreSQL, etc.)
      // await database.saveQuestions(questions);
      
      // ignore: avoid_print
      print('Generated and saved $count questions for $category');
    } catch (e) {
      // ignore: avoid_print
      print('Error in generateAndSaveQuestions: $e');
    }
  }

  /// Batch generate questions for all categories
  Future<void> generateBatchQuestions() async {
    final categories = ['Math', 'Science', 'History', 'Geography', 'Literature'];
    
    for (final category in categories) {
      await generateAndSaveQuestions(category, 100);
      // Add delay to avoid rate limiting
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

