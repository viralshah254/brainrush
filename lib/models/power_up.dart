enum PowerUpType {
  timeFreeze, // Add 5 seconds to timer
  hint, // Remove 2 wrong answers
  doubleCoins, // Double coins earned this game
  perfectScore, // Guarantee 100% accuracy (auto-correct)
  skipQuestion, // Skip current question
}

class PowerUp {
  final PowerUpType type;
  final String name;
  final String description;
  final String emoji;
  final int cost; // Coins to purchase
  final int maxUses; // Max uses per game

  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cost,
    this.maxUses = 1,
  });

  static const List<PowerUp> allPowerUps = [
    PowerUp(
      type: PowerUpType.timeFreeze,
      name: 'Time Freeze',
      description: 'Add 5 seconds to the timer',
      emoji: '⏸️',
      cost: 50,
      maxUses: 3,
    ),
    PowerUp(
      type: PowerUpType.hint,
      name: '50/50 Hint',
      description: 'Remove 2 wrong answers',
      emoji: '💡',
      cost: 75,
      maxUses: 2,
    ),
    PowerUp(
      type: PowerUpType.doubleCoins,
      name: 'Double Coins',
      description: 'Double all coins earned this game',
      emoji: '💰',
      cost: 100,
      maxUses: 1,
    ),
    PowerUp(
      type: PowerUpType.skipQuestion,
      name: 'Skip Question',
      description: 'Skip to the next question',
      emoji: '⏭️',
      cost: 50,
      maxUses: 2,
    ),
  ];

  static PowerUp? getByType(PowerUpType type) {
    try {
      return allPowerUps.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }
}

class UserPowerUp {
  final PowerUpType type;
  int quantity; // How many the user owns
  int usesThisGame; // How many times used in current game

  UserPowerUp({
    required this.type,
    this.quantity = 0,
    this.usesThisGame = 0,
  });

  bool canUse(PowerUp powerUp) {
    return quantity > 0 && usesThisGame < powerUp.maxUses;
  }

  void use() {
    if (quantity > 0) {
      quantity--;
      usesThisGame++;
    }
  }

  void resetGame() {
    usesThisGame = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'quantity': quantity,
    };
  }

  factory UserPowerUp.fromJson(Map<String, dynamic> json) {
    return UserPowerUp(
      type: PowerUpType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PowerUpType.hint,
      ),
      quantity: json['quantity'] as int? ?? 0,
    );
  }
}





