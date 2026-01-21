/// API Achievement Response Model
class ApiAchievementModel {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String? category;
  final int? points;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int? progress;

  ApiAchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.category,
    this.points,
    required this.unlocked,
    this.unlockedAt,
    this.progress,
  });

  factory ApiAchievementModel.fromJson(Map<String, dynamic> json) {
    return ApiAchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
      category: json['category'] as String?,
      points: json['points'] as int?,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'points': points,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
    };
  }
}




