enum CardRarity {
  common,
  rare,
  epic,
  legendary,
}

enum CardCategory {
  math,
  science,
  history,
  geography,
  literature,
  mixed,
  achievement, // Special cards from achievements
  event, // Event-exclusive cards
}

class CollectibleCard {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final CardCategory category;
  final CardRarity rarity;
  final bool isEducationMode; // Whether this is an education mode card
  final String? unlockCondition; // How to unlock this card
  final int? unlockValue; // Value needed to unlock (e.g., 100 correct answers)

  const CollectibleCard({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.rarity,
    this.isEducationMode = false,
    this.unlockCondition,
    this.unlockValue,
  });

  /// Get rarity color
  int get rarityColor {
    switch (rarity) {
      case CardRarity.common:
        return 0xFF808080; // Grey
      case CardRarity.rare:
        return 0xFF2196F3; // Blue
      case CardRarity.epic:
        return 0xFF9C27B0; // Purple
      case CardRarity.legendary:
        return 0xFFFFC107; // Gold/Amber
    }
  }

  /// Get rarity name
  String get rarityName {
    switch (rarity) {
      case CardRarity.common:
        return 'Common';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.epic:
        return 'Epic';
      case CardRarity.legendary:
        return 'Legendary';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'category': category.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'isEducationMode': isEducationMode,
      'unlockCondition': unlockCondition,
      'unlockValue': unlockValue,
    };
  }

  factory CollectibleCard.fromJson(Map<String, dynamic> json) {
    return CollectibleCard(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      category: CardCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => CardCategory.mixed,
      ),
      rarity: CardRarity.values.firstWhere(
        (e) => e.toString().split('.').last == json['rarity'],
        orElse: () => CardRarity.common,
      ),
      isEducationMode: json['isEducationMode'] as bool? ?? false,
      unlockCondition: json['unlockCondition'] as String?,
      unlockValue: json['unlockValue'] as int?,
    );
  }
}

class UserCard {
  final String cardId;
  final int quantity; // How many of this card the user has
  final DateTime? obtainedAt;
  final bool isFavorite;

  const UserCard({
    required this.cardId,
    this.quantity = 1,
    this.obtainedAt,
    this.isFavorite = false,
  });

  UserCard copyWith({
    String? cardId,
    int? quantity,
    DateTime? obtainedAt,
    bool? isFavorite,
  }) {
    return UserCard(
      cardId: cardId ?? this.cardId,
      quantity: quantity ?? this.quantity,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'quantity': quantity,
      'obtainedAt': obtainedAt?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      cardId: json['cardId'] as String,
      quantity: json['quantity'] as int? ?? 1,
      obtainedAt: json['obtainedAt'] != null
          ? DateTime.parse(json['obtainedAt'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}





