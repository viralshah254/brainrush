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

enum GameDifficulty {
  easy,
  medium,
  hard,
  extraHard,
  random;

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
      case GameDifficulty.extraHard:
        return 'Extra Hard';
      case GameDifficulty.random:
        return 'Random';
    }
  }
}

class Room {
  final String id;
  final String code;
  final String hostId;
  final String topic;
  final int maxPlayers;
  final int totalQuestions;
  final int rounds; // Number of rounds (default: 3)
  final int questionsPerRound; // Questions per round (default: 10)
  final GameDifficulty difficulty; // Game difficulty
  final String? gradeLevel; // Grade level for education mode (e.g., 'US_GRADE_11', 'UK_YEAR_11')
  final bool isEducationMode; // Whether this room uses education questions
  final List<RoomPlayer> players;
  final bool isActive;
  final DateTime createdAt;
  final int prizePot; // Total coins wagered (50 per player)

  const Room({
    required this.id,
    required this.code,
    required this.hostId,
    required this.topic,
    required this.maxPlayers,
    required this.totalQuestions,
    this.rounds = 3,
    this.questionsPerRound = 10,
    this.difficulty = GameDifficulty.medium,
    this.gradeLevel,
    this.isEducationMode = false,
    required this.players,
    this.isActive = true,
    required this.createdAt,
    this.prizePot = 0,
  });

  Room copyWith({
    String? id,
    String? code,
    String? hostId,
    String? topic,
    int? maxPlayers,
    int? totalQuestions,
    int? rounds,
    int? questionsPerRound,
    GameDifficulty? difficulty,
    String? gradeLevel,
    bool? isEducationMode,
    List<RoomPlayer>? players,
    bool? isActive,
    DateTime? createdAt,
    int? prizePot,
  }) {
    return Room(
      id: id ?? this.id,
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      topic: topic ?? this.topic,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      rounds: rounds ?? this.rounds,
      questionsPerRound: questionsPerRound ?? this.questionsPerRound,
      difficulty: difficulty ?? this.difficulty,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      isEducationMode: isEducationMode ?? this.isEducationMode,
      players: players ?? this.players,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      prizePot: prizePot ?? this.prizePot,
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
      rounds: json['rounds'] as int? ?? 3,
      questionsPerRound: json['questionsPerRound'] as int? ?? 10,
      difficulty: json['difficulty'] != null
          ? GameDifficulty.values.firstWhere(
              (e) => e.toString().split('.').last == json['difficulty'],
              orElse: () => GameDifficulty.medium,
            )
          : GameDifficulty.medium,
      gradeLevel: json['gradeLevel'] as String?,
      isEducationMode: json['isEducationMode'] as bool? ?? false,
      players: (json['players'] as List)
          .map((p) => RoomPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      prizePot: json['prizePot'] as int? ?? 0,
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
      'rounds': rounds,
      'questionsPerRound': questionsPerRound,
      'difficulty': difficulty.toString().split('.').last,
      'gradeLevel': gradeLevel,
      'isEducationMode': isEducationMode,
      'players': players.map((p) => p.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'prizePot': prizePot,
    };
  }
}

