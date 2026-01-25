import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/collectible_card.dart';
import '../../services/card_collection_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/mode_provider.dart';
import '../../services/social_sharing_service.dart';

class CardCollectionScreen extends StatefulWidget {
  const CardCollectionScreen({super.key});

  @override
  State<CardCollectionScreen> createState() => _CardCollectionScreenState();
}

class _CardCollectionScreenState extends State<CardCollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CardCollectionService _cardService = CardCollectionService();
  CardCategory _selectedCategory = CardCategory.mixed;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CardCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = CardCategory.values[_tabController.index];
        });
      }
    });
    _loadCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    await _cardService.loadUserCards();
    
    final modeProvider = context.read<ModeProvider>();
    final stats = _cardService.getCollectionStats(
      educationMode: modeProvider.isEducationMode,
    );
    
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.read<ModeProvider>();
    final isEducationMode = modeProvider.isEducationMode;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Card Collection'),
        backgroundColor: AppTheme.darkBg,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: Colors.white60,
          tabs: CardCategory.values.map((category) {
            return Tab(text: _getCategoryName(category));
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats header
                if (_stats != null) _buildStatsHeader(_stats!),
                
                // Cards grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadCards,
                    color: AppTheme.primaryNeon,
                    child: _buildCardsGrid(isEducationMode),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '${stats['total']}'),
          _buildStatItem('Collected', '${stats['collected']}'),
          _buildStatItem('Missing', '${stats['missing']}'),
          _buildStatItem(
            'Complete',
            '${(stats['completion'] as double).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(bool isEducationMode) {
    final cards = _cardService.getCardsByCategory(
      _selectedCategory,
      educationMode: isEducationMode,
    );
    final userCards = _cardService.userCards;
    final collectedIds = userCards.keys.toSet();

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.collections_outlined,
              size: 80,
              color: Colors.white60,
            ),
            const SizedBox(height: 16),
            Text(
              'No cards in ${_getCategoryName(_selectedCategory)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final hasCard = collectedIds.contains(card.id);
        final userCard = userCards[card.id];
        final quantity = userCard?.quantity ?? 0;

        return _buildCardItem(card, hasCard, quantity);
      },
    );
  }

  Widget _buildCardItem(CollectibleCard card, bool hasCard, int quantity) {
    return GestureDetector(
      onTap: hasCard
          ? () => _showCardDetails(card, quantity)
          : () => _showLockedCard(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: hasCard
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(card.rarityColor),
                    Color(card.rarityColor).withOpacity(0.6),
                  ],
                )
              : null,
          color: hasCard ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasCard
                ? Color(card.rarityColor)
                : Colors.white.withOpacity(0.1),
            width: hasCard ? 2 : 1,
          ),
          boxShadow: hasCard
              ? [
                  BoxShadow(
                    color: Color(card.rarityColor).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card emoji
                  Text(
                    hasCard ? card.emoji : '❓',
                    style: TextStyle(
                      fontSize: hasCard ? 48 : 32,
                      color: hasCard ? null : Colors.white30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Card name
                  Text(
                    hasCard ? card.name : '???',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasCard ? Colors.white : Colors.white30,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (hasCard) ...[
                    const SizedBox(height: 4),
                    // Rarity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card.rarityName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Quantity badge (if has multiple)
            if (hasCard && quantity > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'x$quantity',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            // Lock overlay
            if (!hasCard)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    size: 32,
                    color: Colors.white30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(CollectibleCard card, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Text(
              card.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card.rarityName,
                    style: TextStyle(
                      color: Color(card.rarityColor),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.description,
              style: const TextStyle(color: Colors.white70),
            ),
            if (card.unlockCondition != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked: ${card.unlockCondition}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
            if (quantity > 1) ...[
              const SizedBox(height: 12),
              Text(
                'Quantity: $quantity',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              final sharingService = SocialSharingService();
              final userProvider = context.read<UserProvider>();
              sharingService.shareCard(
                cardName: card.name,
                cardEmoji: card.emoji,
                rarity: card.rarityName,
                username: userProvider.user?.username,
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: AppTheme.darkBg,
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedCard(CollectibleCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Text(
              '❓',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Locked Card',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This card is locked. ${card.unlockCondition ?? "Keep playing to unlock it!"}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (card.unlockValue != null) ...[
              const SizedBox(height: 12),
              Text(
                'Progress needed: ${card.unlockValue}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(CardCategory category) {
    switch (category) {
      case CardCategory.math:
        return 'Math';
      case CardCategory.science:
        return 'Science';
      case CardCategory.history:
        return 'History';
      case CardCategory.geography:
        return 'Geography';
      case CardCategory.literature:
        return 'Literature';
      case CardCategory.mixed:
        return 'Mixed';
      case CardCategory.achievement:
        return 'Achievements';
      case CardCategory.event:
        return 'Events';
    }
  }
}









