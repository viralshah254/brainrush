class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation; // Legacy field, use shortExplanation or deepExplanation
  final String category;
  final String difficulty;
  final String topic;
  
  // Education Mode fields (legacy)
  final String? mode; // 'GENERAL', 'EDUCATION_SCHOOL', 'EDUCATION_SAT', 'EDUCATION_GMAT'
  final String? source; // 'AI', 'CURATED'
  final DateTime? createdAt;
  final String? language;
  final String? countryTag;
  
  // NEW Educational Learning Fields (Required)
  final String? questionType; // 'recall', 'conceptual', 'application', 'reasoning', 'misconception_check'
  final String? learningObjective; // What the question teaches
  final String? shortExplanation; // 1-2 sentences, simple explanation
  final String? deepExplanation; // 2-6 sentences, teaches properly
  final Map<String, String>? whyWrong; // Explains why each wrong option is wrong (keys: "0", "1", "2", "3")
  final String? gradeLevel; // 'Kids (5-7)', 'Primary (8-10)', 'Middle School (11-13)', 'High School (14-18)', 'SAT/ACT', 'GMAT/GRE'
  final List<String>? tags; // 3-8 educational tags
  
  // NEW Optional Educational Fields (Recommended)
  final String? lessonId; // Groups questions into learning paths
  final int? lessonOrder; // Order within lesson
  final List<String>? prerequisites; // Prerequisite lesson IDs
  final String? hint; // Helpful hint for the question
  final int? timeLimitSec; // Time limit in seconds (e.g., 15/20/30)
  final List<Question>? followUps; // Reinforcement questions

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    this.difficulty = 'medium',
    this.topic = 'general',
    this.mode = 'GENERAL',
    this.source = 'CURATED',
    this.createdAt,
    this.language = 'EN',
    this.countryTag,
    // New educational fields
    this.questionType,
    this.learningObjective,
    this.shortExplanation,
    this.deepExplanation,
    this.whyWrong,
    this.gradeLevel,
    this.tags,
    this.lessonId,
    this.lessonOrder,
    this.prerequisites,
    this.hint,
    this.timeLimitSec,
    this.followUps,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Parse whyWrong map
    Map<String, String>? whyWrongMap;
    if (json['whyWrong'] != null) {
      final whyWrongData = json['whyWrong'] as Map<String, dynamic>;
      whyWrongMap = whyWrongData.map((key, value) => MapEntry(key, value.toString()));
    }
    
    // Parse tags list
    List<String>? tagsList;
    if (json['tags'] != null) {
      tagsList = List<String>.from(json['tags'] as List);
    }
    
    // Parse prerequisites list
    List<String>? prerequisitesList;
    if (json['prerequisites'] != null) {
      prerequisitesList = List<String>.from(json['prerequisites'] as List);
    }
    
    // Parse followUps list
    List<Question>? followUpsList;
    if (json['followUps'] != null) {
      final followUpsData = json['followUps'] as List<dynamic>;
      followUpsList = followUpsData.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
    }
    
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      // Use legacy explanation if available, otherwise use shortExplanation, otherwise empty string
      explanation: (json['explanation'] as String?) ?? 
                   (json['shortExplanation'] as String?) ?? 
                   '',
      category: json['category'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      topic: json['topic'] as String? ?? 'general',
      mode: json['mode'] as String? ?? 'GENERAL',
      source: json['source'] as String? ?? 'CURATED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      language: json['language'] as String? ?? 'EN',
      countryTag: json['countryTag'] as String?,
      // New educational fields
      questionType: json['questionType'] as String?,
      learningObjective: json['learningObjective'] as String?,
      shortExplanation: json['shortExplanation'] as String?,
      deepExplanation: json['deepExplanation'] as String?,
      whyWrong: whyWrongMap,
      gradeLevel: json['gradeLevel'] as String?,
      tags: tagsList,
      lessonId: json['lessonId'] as String?,
      lessonOrder: json['lessonOrder'] as int?,
      prerequisites: prerequisitesList,
      hint: json['hint'] as String?,
      timeLimitSec: json['timeLimitSec'] as int?,
      followUps: followUpsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'category': category,
      'difficulty': difficulty,
      'topic': topic,
      'mode': mode,
      'source': source,
      'createdAt': createdAt?.toIso8601String(),
      'language': language,
      'countryTag': countryTag,
      // New educational fields
      'questionType': questionType,
      'learningObjective': learningObjective,
      'shortExplanation': shortExplanation,
      'deepExplanation': deepExplanation,
      'whyWrong': whyWrong,
      'gradeLevel': gradeLevel,
      'tags': tags,
      'lessonId': lessonId,
      'lessonOrder': lessonOrder,
      'prerequisites': prerequisites,
      'hint': hint,
      'timeLimitSec': timeLimitSec,
      'followUps': followUps?.map((q) => q.toJson()).toList(),
    };
  }

  String get correctAnswer => options[correctIndex];
  
  /// Get the best available explanation (prefers deepExplanation, falls back to shortExplanation, then legacy explanation)
  String get bestExplanation {
    if (deepExplanation != null && deepExplanation!.isNotEmpty) {
      return deepExplanation!;
    }
    if (shortExplanation != null && shortExplanation!.isNotEmpty) {
      return shortExplanation!;
    }
    return explanation;
  }
  
  /// Get why a specific option is wrong (or correct)
  String? getWhyWrong(int optionIndex) {
    return whyWrong?[optionIndex.toString()];
  }
}

