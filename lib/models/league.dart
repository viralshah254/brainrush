class LeagueParticipant {
  final String userId;
  final String username;
  final int score;
  final int rank;

  const LeagueParticipant({
    required this.userId,
    required this.username,
    required this.score,
    required this.rank,
  });

  factory LeagueParticipant.fromJson(Map<String, dynamic> json) {
    return LeagueParticipant(
      userId: json['userId'] as String,
      username: json['username'] as String,
      score: json['score'] as int,
      rank: json['rank'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'score': score,
      'rank': rank,
    };
  }
}

class League {
  final String id;
  final String name;
  final String description;
  final String topic;
  final String tier;
  final int entryFee;
  final int maxParticipants;
  final List<LeagueParticipant> participants;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int totalQuestions;

  const League({
    required this.id,
    required this.name,
    required this.description,
    required this.topic,
    required this.tier,
    required this.entryFee,
    required this.maxParticipants,
    required this.participants,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.totalQuestions = 10,
  });

  /// Calculate the total prize pool based on entry fees
  int get prizePot {
    return participants.length * entryFee;
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      topic: json['topic'] as String,
      tier: json['tier'] as String,
      entryFee: json['entryFee'] as int,
      maxParticipants: json['maxParticipants'] as int,
      participants: (json['participants'] as List)
          .map((p) => LeagueParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool,
      totalQuestions: json['totalQuestions'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'topic': topic,
      'tier': tier,
      'entryFee': entryFee,
      'maxParticipants': maxParticipants,
      'participants': participants.map((p) => p.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'totalQuestions': totalQuestions,
    };
  }
}

