enum QuestType {
  playGames,
  correctAnswers,
  playDaily,
  playLeague,
  playWithFriends,
  earnCoins,
  completeCampaign,
}

class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int coinReward;
  final String emoji;
  final bool isCompleted;

  const DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    required this.coinReward,
    required this.emoji,
    this.isCompleted = false,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  DailyQuest copyWith({
    String? id,
    QuestType? type,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    int? coinReward,
    String? emoji,
    bool? isCompleted,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      coinReward: coinReward ?? this.coinReward,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'coinReward': coinReward,
      'emoji': emoji,
      'isCompleted': isCompleted,
    };
  }

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      type: QuestType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => QuestType.playGames,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      coinReward: json['coinReward'] as int,
      emoji: json['emoji'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  // Generate random daily quests
  static List<DailyQuest> generateDailyQuests() {
    final allQuests = [
      DailyQuest(
        id: 'play_3_games',
        type: QuestType.playGames,
        title: 'Play 3 Games',
        description: 'Complete 3 games in any mode',
        targetValue: 3,
        coinReward: 100,
        emoji: '🎮',
      ),
      DailyQuest(
        id: 'daily_challenge',
        type: QuestType.playDaily,
        title: 'Daily Challenge',
        description: 'Complete today\'s daily challenge',
        targetValue: 1,
        coinReward: 200,
        emoji: '⚡',
      ),
      DailyQuest(
        id: 'campaign_round',
        type: QuestType.completeCampaign,
        title: 'Campaign Progress',
        description: 'Complete 2 campaign rounds',
        targetValue: 2,
        coinReward: 175,
        emoji: '🎯',
      ),
      DailyQuest(
        id: 'correct_20',
        type: QuestType.correctAnswers,
        title: 'Answer Correctly',
        description: 'Get 20 correct answers',
        targetValue: 20,
        coinReward: 150,
        emoji: '✅',
      ),
      DailyQuest(
        id: 'play_friends',
        type: QuestType.playWithFriends,
        title: 'Play with Friends',
        description: 'Complete a game with friends',
        targetValue: 1,
        coinReward: 125,
        emoji: '👥',
      ),
    ];

    // Return 2 quests (excluding league and friends)
    // Always include: Play 3 Games and Daily Challenge
    final selectedQuests = [
      allQuests.firstWhere((q) => q.id == 'play_3_games'),
      allQuests.firstWhere((q) => q.id == 'daily_challenge'),
    ];
    
    return selectedQuests;
  }
}

