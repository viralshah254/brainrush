class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;
  final String difficulty;
  final String topic;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    this.difficulty = 'medium',
    this.topic = 'general',
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
    };
  }

  String get correctAnswer => options[correctIndex];
}

