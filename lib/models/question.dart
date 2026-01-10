class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;
  final String difficulty;
  final String topic;
  
  // Education Mode fields
  final String? mode; // 'GENERAL', 'EDUCATION_SCHOOL', 'EDUCATION_SAT', 'EDUCATION_GMAT'
  final String? gradeLevel; // 'GRADE_5', 'GRADE_6', etc. (nullable for exams)
  final String? source; // 'AI', 'CURATED'
  final DateTime? createdAt;
  final String? language;
  final String? countryTag;

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
    this.gradeLevel,
    this.source = 'CURATED',
    this.createdAt,
    this.language = 'EN',
    this.countryTag,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      topic: json['topic'] as String? ?? 'general',
      mode: json['mode'] as String? ?? 'GENERAL',
      gradeLevel: json['gradeLevel'] as String?,
      source: json['source'] as String? ?? 'CURATED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      language: json['language'] as String? ?? 'EN',
      countryTag: json['countryTag'] as String?,
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
      'gradeLevel': gradeLevel,
      'source': source,
      'createdAt': createdAt?.toIso8601String(),
      'language': language,
      'countryTag': countryTag,
    };
  }

  String get correctAnswer => options[correctIndex];
}

