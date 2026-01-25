/// API Room Response Model
class ApiRoomModel {
  final String id;
  final String code;
  final String hostId;
  final String status;
  final String? category;
  final int? questionCount;
  final int? maxPlayers;
  final bool? isPrivate;
  final String? mode;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<Map<String, dynamic>>? participants;

  ApiRoomModel({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    this.category,
    this.questionCount,
    this.maxPlayers,
    this.isPrivate,
    this.mode,
    this.createdAt,
    this.expiresAt,
    this.participants,
  });

  factory ApiRoomModel.fromJson(Map<String, dynamic> json) {
    return ApiRoomModel(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['hostId'] as String,
      status: json['status'] as String,
      category: json['category'] as String?,
      questionCount: json['questionCount'] as int?,
      maxPlayers: json['maxPlayers'] as int?,
      isPrivate: json['isPrivate'] as bool?,
      mode: json['mode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      participants: json['participants'] != null
          ? List<Map<String, dynamic>>.from(json['participants'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'hostId': hostId,
      'status': status,
      'category': category,
      'questionCount': questionCount,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
      'mode': mode,
      'createdAt': createdAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'participants': participants,
    };
  }
}









