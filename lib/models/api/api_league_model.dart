/// API League Response Model
class ApiLeagueModel {
  final String id;
  final String name;
  final String tier;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? prizePool;
  final String status;
  final String? gradeLevel;
  final int? participantCount;

  ApiLeagueModel({
    required this.id,
    required this.name,
    required this.tier,
    this.startDate,
    this.endDate,
    this.prizePool,
    required this.status,
    this.gradeLevel,
    this.participantCount,
  });

  factory ApiLeagueModel.fromJson(Map<String, dynamic> json) {
    return ApiLeagueModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: json['tier'] as String,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      prizePool: json['prizePool'] as int?,
      status: json['status'] as String,
      gradeLevel: json['gradeLevel'] as String?,
      participantCount: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>)['participants'] as int?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'prizePool': prizePool,
      'status': status,
      'gradeLevel': gradeLevel,
      'participantCount': participantCount,
    };
  }
}







