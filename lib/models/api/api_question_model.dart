/// API Question Response Model
class ApiQuestionModel {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String? category;
  final String? difficulty;
  final int? timeLimit;

  ApiQuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.category,
    this.difficulty,
    this.timeLimit,
  });

  factory ApiQuestionModel.fromJson(Map<String, dynamic> json) {
    return ApiQuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      timeLimit: json['timeLimit'] as int?,
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
      'timeLimit': timeLimit,
    };
  }
}









