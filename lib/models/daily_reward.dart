enum RewardType {
  coins,
  lives,
  doubleXP,
  hints,
  adFree,
}

class DailyReward {
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final RewardType type;
  final int amount;
  final String emoji;
  final String description;

  const DailyReward({
    required this.dayOfWeek,
    required this.type,
    required this.amount,
    required this.emoji,
    required this.description,
  });

  static const List<DailyReward> weeklyRewards = [
    DailyReward(
      dayOfWeek: 1, // Monday
      type: RewardType.coins,
      amount: 50,
      emoji: '💰',
      description: '50 Coins',
    ),
    DailyReward(
      dayOfWeek: 2, // Tuesday
      type: RewardType.lives,
      amount: 3,
      emoji: '❤️',
      description: '3 Extra Lives',
    ),
    DailyReward(
      dayOfWeek: 3, // Wednesday
      type: RewardType.coins,
      amount: 75,
      emoji: '💎',
      description: '75 Coins',
    ),
    DailyReward(
      dayOfWeek: 4, // Thursday
      type: RewardType.hints,
      amount: 5,
      emoji: '💡',
      description: '5 Hints',
    ),
    DailyReward(
      dayOfWeek: 5, // Friday
      type: RewardType.doubleXP,
      amount: 1,
      emoji: '⚡',
      description: 'Double XP (24h)',
    ),
    DailyReward(
      dayOfWeek: 6, // Saturday
      type: RewardType.coins,
      amount: 100,
      emoji: '🎁',
      description: '100 Coins',
    ),
    DailyReward(
      dayOfWeek: 7, // Sunday
      type: RewardType.adFree,
      amount: 24,
      emoji: '🚫',
      description: 'Ad-Free (24h)',
    ),
  ];

  static DailyReward getTodaysReward() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    return weeklyRewards.firstWhere((reward) => reward.dayOfWeek == dayOfWeek);
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'type': type.name,
      'amount': amount,
      'emoji': emoji,
      'description': description,
    };
  }
}

