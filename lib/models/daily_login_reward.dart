class DailyLoginReward {
  final int day;
  final int coins;
  final String description;
  final String emoji;
  final bool isSpecial;

  const DailyLoginReward({
    required this.day,
    required this.coins,
    required this.description,
    required this.emoji,
    this.isSpecial = false,
  });

  static List<DailyLoginReward> getRewards() {
    return const [
      DailyLoginReward(
        day: 1,
        coins: 50,
        description: '50 Coins',
        emoji: '🪙',
      ),
      DailyLoginReward(
        day: 2,
        coins: 75,
        description: '75 Coins',
        emoji: '💰',
      ),
      DailyLoginReward(
        day: 3,
        coins: 100,
        description: '100 Coins',
        emoji: '💵',
      ),
      DailyLoginReward(
        day: 4,
        coins: 150,
        description: '150 Coins',
        emoji: '💸',
      ),
      DailyLoginReward(
        day: 5,
        coins: 200,
        description: '200 Coins',
        emoji: '🎁',
        isSpecial: true,
      ),
      DailyLoginReward(
        day: 6,
        coins: 250,
        description: '250 Coins',
        emoji: '🏆',
      ),
      DailyLoginReward(
        day: 7,
        coins: 500,
        description: '500 Coins MEGA BONUS!',
        emoji: '👑',
        isSpecial: true,
      ),
    ];
  }

  static DailyLoginReward getRewardForDay(int day) {
    final rewards = getRewards();
    final cycleDay = ((day - 1) % 7) + 1;
    return rewards.firstWhere((r) => r.day == cycleDay);
  }
}

