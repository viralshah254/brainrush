/// API Reward Response Model
class ApiRewardModel {
  final String id;
  final int dayOfWeek;
  final String type;
  final int amount;
  final String? description;
  final bool claimed;
  final DateTime? claimedAt;

  ApiRewardModel({
    required this.id,
    required this.dayOfWeek,
    required this.type,
    required this.amount,
    this.description,
    required this.claimed,
    this.claimedAt,
  });

  factory ApiRewardModel.fromJson(Map<String, dynamic> json) {
    return ApiRewardModel(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      type: json['type'] as String,
      amount: json['amount'] as int,
      description: json['description'] as String?,
      claimed: json['claimed'] as bool? ?? false,
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'type': type,
      'amount': amount,
      'description': description,
      'claimed': claimed,
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }
}







