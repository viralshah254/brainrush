import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/collectible_card.dart';

/// Card Collection Service - Works for both General and Education modes
class CardCollectionService extends ChangeNotifier {
  static final CardCollectionService _instance = CardCollectionService._internal();
  factory CardCollectionService() => _instance;
  CardCollectionService._internal() {
    _initializeCards();
  }

  // All available cards
  List<CollectibleCard> _allCards = [];
  
  // User's card collection
  Map<String, UserCard> _userCards = {};

  /// Initialize all available cards
  void _initializeCards() {
    _allCards = [
      // Math Cards
      CollectibleCard(
        id: 'math_basics',
        name: 'Math Basics',
        description: 'Master the fundamentals of mathematics',
        emoji: '🔢',
        category: CardCategory.math,
        rarity: CardRarity.common,
        unlockCondition: 'Answer 50 Math questions correctly',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'math_advanced',
        name: 'Math Master',
        description: 'Advanced mathematics expert',
        emoji: '📐',
        category: CardCategory.math,
        rarity: CardRarity.rare,
        unlockCondition: 'Answer 200 Math questions correctly',
        unlockValue: 200,
      ),
      CollectibleCard(
        id: 'math_legend',
        name: 'Math Legend',
        description: 'Ultimate mathematics champion',
        emoji: '∞',
        category: CardCategory.math,
        rarity: CardRarity.legendary,
        unlockCondition: 'Answer 1000 Math questions correctly',
        unlockValue: 1000,
      ),
      
      // Science Cards
      CollectibleCard(
        id: 'science_basics',
        name: 'Science Explorer',
        description: 'Begin your scientific journey',
        emoji: '🔬',
        category: CardCategory.science,
        rarity: CardRarity.common,
        unlockCondition: 'Answer 50 Science questions correctly',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'science_advanced',
        name: 'Science Genius',
        description: 'Master of scientific knowledge',
        emoji: '⚗️',
        category: CardCategory.science,
        rarity: CardRarity.epic,
        unlockCondition: 'Answer 200 Science questions correctly',
        unlockValue: 200,
      ),
      
      // History Cards
      CollectibleCard(
        id: 'history_basics',
        name: 'History Buff',
        description: 'Know your history',
        emoji: '📜',
        category: CardCategory.history,
        rarity: CardRarity.common,
        unlockCondition: 'Answer 50 History questions correctly',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'history_master',
        name: 'History Master',
        description: 'Expert in historical knowledge',
        emoji: '🏛️',
        category: CardCategory.history,
        rarity: CardRarity.rare,
        unlockCondition: 'Answer 200 History questions correctly',
        unlockValue: 200,
      ),
      
      // Geography Cards
      CollectibleCard(
        id: 'geo_basics',
        name: 'Geography Explorer',
        description: 'Explore the world',
        emoji: '🌍',
        category: CardCategory.geography,
        rarity: CardRarity.common,
        unlockCondition: 'Answer 50 Geography questions correctly',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'geo_master',
        name: 'World Traveler',
        description: 'Know every corner of the world',
        emoji: '🗺️',
        category: CardCategory.geography,
        rarity: CardRarity.epic,
        unlockCondition: 'Answer 200 Geography questions correctly',
        unlockValue: 200,
      ),
      
      // Literature Cards
      CollectibleCard(
        id: 'lit_basics',
        name: 'Bookworm',
        description: 'Love for literature',
        emoji: '📚',
        category: CardCategory.literature,
        rarity: CardRarity.common,
        unlockCondition: 'Answer 50 Literature questions correctly',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'lit_master',
        name: 'Literary Genius',
        description: 'Master of words and stories',
        emoji: '✍️',
        category: CardCategory.literature,
        rarity: CardRarity.rare,
        unlockCondition: 'Answer 200 Literature questions correctly',
        unlockValue: 200,
      ),
      
      // Achievement Cards
      CollectibleCard(
        id: 'first_steps',
        name: 'First Steps',
        description: 'Completed your first game',
        emoji: '👣',
        category: CardCategory.achievement,
        rarity: CardRarity.common,
        unlockCondition: 'Complete first game',
      ),
      CollectibleCard(
        id: 'streak_master',
        name: 'Streak Master',
        description: '30-day login streak',
        emoji: '🔥',
        category: CardCategory.achievement,
        rarity: CardRarity.epic,
        unlockCondition: 'Reach 30-day streak',
      ),
      CollectibleCard(
        id: 'perfect_game',
        name: 'Perfect Game',
        description: 'Achieved 100% accuracy',
        emoji: '⭐',
        category: CardCategory.achievement,
        rarity: CardRarity.rare,
        unlockCondition: 'Get 100% accuracy in a game',
      ),
      CollectibleCard(
        id: 'level_50',
        name: 'Level 50 Champion',
        description: 'Reached level 50',
        emoji: '🏆',
        category: CardCategory.achievement,
        rarity: CardRarity.legendary,
        unlockCondition: 'Reach level 50',
      ),
      
      // Education Mode Cards
      CollectibleCard(
        id: 'edu_student',
        name: 'Dedicated Student',
        description: 'Master education mode',
        emoji: '🎓',
        category: CardCategory.mixed,
        rarity: CardRarity.rare,
        isEducationMode: true,
        unlockCondition: 'Complete 50 education mode games',
        unlockValue: 50,
      ),
      CollectibleCard(
        id: 'edu_expert',
        name: 'Education Expert',
        description: 'Excel in education mode',
        emoji: '📖',
        category: CardCategory.mixed,
        rarity: CardRarity.epic,
        isEducationMode: true,
        unlockCondition: 'Complete 200 education mode games',
        unlockValue: 200,
      ),
    ];
  }

  /// Get all available cards
  List<CollectibleCard> get allCards => _allCards;

  /// Get user's card collection
  Map<String, UserCard> get userCards => _userCards;

  /// Get cards by category
  List<CollectibleCard> getCardsByCategory(CardCategory category, {bool educationMode = false}) {
    return _allCards.where((card) {
      if (educationMode && !card.isEducationMode && card.category != CardCategory.achievement) {
        return false;
      }
      return card.category == category;
    }).toList();
  }

  /// Get cards by rarity
  List<CollectibleCard> getCardsByRarity(CardRarity rarity) {
    return _allCards.where((card) => card.rarity == rarity).toList();
  }

  /// Get user's collected cards
  List<CollectibleCard> getCollectedCards({bool educationMode = false}) {
    final collectedIds = _userCards.keys.toSet();
    return _allCards.where((card) {
      if (educationMode && !card.isEducationMode && card.category != CardCategory.achievement) {
        return false;
      }
      return collectedIds.contains(card.id);
    }).toList();
  }

  /// Get user's missing cards
  List<CollectibleCard> getMissingCards({bool educationMode = false}) {
    final collectedIds = _userCards.keys.toSet();
    return _allCards.where((card) {
      if (educationMode && !card.isEducationMode && card.category != CardCategory.achievement) {
        return false;
      }
      return !collectedIds.contains(card.id);
    }).toList();
  }

  /// Check if user has a card
  bool hasCard(String cardId) {
    return _userCards.containsKey(cardId);
  }

  /// Get card quantity
  int getCardQuantity(String cardId) {
    return _userCards[cardId]?.quantity ?? 0;
  }

  /// Add a card to user's collection
  Future<void> addCard(String cardId, {bool fromPack = false}) async {
    if (!_allCards.any((card) => card.id == cardId)) {
      debugPrint('⚠️ Card $cardId does not exist');
      return;
    }

    if (_userCards.containsKey(cardId)) {
      // Increase quantity
      final existing = _userCards[cardId]!;
      _userCards[cardId] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      // New card
      _userCards[cardId] = UserCard(
        cardId: cardId,
        quantity: 1,
        obtainedAt: DateTime.now(),
      );
    }

    await _saveUserCards();
    notifyListeners();
    debugPrint('✅ Card added: $cardId');
  }

  /// Open a card pack (random cards)
  Future<List<CollectibleCard>> openCardPack({
    int cardsPerPack = 3,
    bool educationMode = false,
  }) async {
    final availableCards = educationMode
        ? _allCards.where((card) => card.isEducationMode || card.category == CardCategory.achievement).toList()
        : _allCards;

    if (availableCards.isEmpty) {
      return [];
    }

    final random = Random();
    final openedCards = <CollectibleCard>[];

    for (int i = 0; i < cardsPerPack; i++) {
      // Weighted random based on rarity
      CollectibleCard selectedCard;
      final roll = random.nextDouble();
      
      if (roll < 0.5) {
        // 50% chance for common
        final commonCards = availableCards.where((c) => c.rarity == CardRarity.common).toList();
        selectedCard = commonCards.isNotEmpty
            ? commonCards[random.nextInt(commonCards.length)]
            : availableCards[random.nextInt(availableCards.length)];
      } else if (roll < 0.8) {
        // 30% chance for rare
        final rareCards = availableCards.where((c) => c.rarity == CardRarity.rare).toList();
        selectedCard = rareCards.isNotEmpty
            ? rareCards[random.nextInt(rareCards.length)]
            : availableCards[random.nextInt(availableCards.length)];
      } else if (roll < 0.95) {
        // 15% chance for epic
        final epicCards = availableCards.where((c) => c.rarity == CardRarity.epic).toList();
        selectedCard = epicCards.isNotEmpty
            ? epicCards[random.nextInt(epicCards.length)]
            : availableCards[random.nextInt(availableCards.length)];
      } else {
        // 5% chance for legendary
        final legendaryCards = availableCards.where((c) => c.rarity == CardRarity.legendary).toList();
        selectedCard = legendaryCards.isNotEmpty
            ? legendaryCards[random.nextInt(legendaryCards.length)]
            : availableCards[random.nextInt(availableCards.length)];
      }

      openedCards.add(selectedCard);
      await addCard(selectedCard.id, fromPack: true);
    }

    return openedCards;
  }

  /// Check and unlock cards based on user progress
  Future<void> checkCardUnlocks({
    required Map<CardCategory, int> categoryCorrectAnswers,
    required int totalGames,
    required int streakDays,
    required int level,
    required bool hasPerfectGame,
    required bool isEducationMode,
  }) async {
    // Check category mastery cards
    for (final entry in categoryCorrectAnswers.entries) {
      final category = entry.key;
      final correctAnswers = entry.value;
      
      final categoryCards = getCardsByCategory(category, educationMode: isEducationMode);
      for (final card in categoryCards) {
        if (card.unlockValue != null && 
            correctAnswers >= card.unlockValue! && 
            !hasCard(card.id)) {
          await addCard(card.id);
          debugPrint('🎴 Card unlocked: ${card.name}');
        }
      }
    }

    // Check achievement cards
    final achievementCards = getCardsByCategory(CardCategory.achievement);
    for (final card in achievementCards) {
      bool shouldUnlock = false;
      
      if (card.id == 'first_steps' && totalGames >= 1 && !hasCard(card.id)) {
        shouldUnlock = true;
      } else if (card.id == 'streak_master' && streakDays >= 30 && !hasCard(card.id)) {
        shouldUnlock = true;
      } else if (card.id == 'perfect_game' && hasPerfectGame && !hasCard(card.id)) {
        shouldUnlock = true;
      } else if (card.id == 'level_50' && level >= 50 && !hasCard(card.id)) {
        shouldUnlock = true;
      }

      if (shouldUnlock) {
        await addCard(card.id);
        debugPrint('🎴 Achievement card unlocked: ${card.name}');
      }
    }
  }

  /// Save user cards to storage
  Future<void> _saveUserCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = json.encode(
        _userCards.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString('user_card_collection', cardsJson);
    } catch (e) {
      debugPrint('❌ Error saving user cards: $e');
    }
  }

  /// Load user cards from storage
  Future<void> loadUserCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString('user_card_collection');
      
      if (cardsJson != null && cardsJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(cardsJson);
        _userCards = decoded.map(
          (key, value) => MapEntry(key, UserCard.fromJson(value as Map<String, dynamic>)),
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user cards: $e');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String cardId) async {
    if (_userCards.containsKey(cardId)) {
      final card = _userCards[cardId]!;
      _userCards[cardId] = card.copyWith(isFavorite: !card.isFavorite);
      await _saveUserCards();
      notifyListeners();
    }
  }

  /// Get collection stats
  Map<String, dynamic> getCollectionStats({bool educationMode = false}) {
    final allCards = educationMode
        ? _allCards.where((c) => c.isEducationMode || c.category == CardCategory.achievement).toList()
        : _allCards;
    
    final collected = getCollectedCards(educationMode: educationMode);
    final missing = getMissingCards(educationMode: educationMode);
    
    final byRarity = <CardRarity, int>{};
    for (final rarity in CardRarity.values) {
      byRarity[rarity] = collected.where((c) => c.rarity == rarity).length;
    }

    return {
      'total': allCards.length,
      'collected': collected.length,
      'missing': missing.length,
      'completion': allCards.isNotEmpty ? (collected.length / allCards.length * 100) : 0.0,
      'byRarity': byRarity,
    };
  }
}





