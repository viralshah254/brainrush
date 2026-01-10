class RoomPlayer {
  final String userId;
  final String username;
  final int score;
  final bool isReady;

  const RoomPlayer({
    required this.userId,
    required this.username,
    this.score = 0,
    this.isReady = false,
  });

  RoomPlayer copyWith({
    String? userId,
    String? username,
    int? score,
    bool? isReady,
  }) {
    return RoomPlayer(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
    );
  }

  factory RoomPlayer.fromJson(Map<String, dynamic> json) {
    return RoomPlayer(
      userId: json['userId'] as String,
      username: json['username'] as String,
      score: json['score'] as int? ?? 0,
      isReady: json['isReady'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'score': score,
      'isReady': isReady,
    };
  }
}

class Room {
  final String id;
  final String code;
  final String hostId;
  final String topic;
  final int maxPlayers;
  final int totalQuestions;
  final List<RoomPlayer> players;
  final bool isActive;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.topic,
    required this.maxPlayers,
    required this.totalQuestions,
    required this.players,
    this.isActive = true,
    required this.createdAt,
  });

  Room copyWith({
    String? id,
    String? code,
    String? hostId,
    String? topic,
    int? maxPlayers,
    int? totalQuestions,
    List<RoomPlayer>? players,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      topic: topic ?? this.topic,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      players: players ?? this.players,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['hostId'] as String,
      topic: json['topic'] as String,
      maxPlayers: json['maxPlayers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      players: (json['players'] as List)
          .map((p) => RoomPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'hostId': hostId,
      'topic': topic,
      'maxPlayers': maxPlayers,
      'totalQuestions': totalQuestions,
      'players': players.map((p) => p.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

