import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/mode_provider.dart';
import '../../services/social_sharing_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _selectedType = LeaderboardType.global;
  LeaderboardCategory _selectedCategory = LeaderboardCategory.all;
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  int? _userRank;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedType = LeaderboardType.global;
              break;
            case 1:
              _selectedType = LeaderboardType.weekly;
              break;
            case 2:
              _selectedType = LeaderboardType.monthly;
              break;
          }
        });
        _loadLeaderboard();
      }
    });
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final modeProvider = context.read<ModeProvider>();
    final user = userProvider.user;
    final isEducationMode = modeProvider.isEducationMode;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final leaderboardService = LeaderboardService();
    final entries = await leaderboardService.getLeaderboard(
      type: _selectedType,
      category: _selectedCategory,
      isEducationMode: isEducationMode,
      currentUserId: user.id,
      limit: 100,
    );

    final userRank = await leaderboardService.getUserRank(
      userId: user.id,
      type: _selectedType,
      isEducationMode: isEducationMode,
      category: _selectedCategory,
    );

    if (mounted) {
      setState(() {
        _entries = entries;
        _userRank = userRank;
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
        title: Text(isEducationMode ? 'Education Leaderboard' : 'Leaderboard'),
        backgroundColor: AppTheme.darkBg,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // User's rank card (if available)
                    if (_userRank != null) _buildUserRankCard(),
                    
                    // Leaderboard list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        color: AppTheme.primaryNeon,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            return _buildLeaderboardEntry(_entries[index], index);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUserRankCard() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null || _userRank == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$_userRank',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Level ${user.level} • ${user.stats.totalScore} points',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final modeProvider = context.read<ModeProvider>();
              final sharingService = SocialSharingService();
              sharingService.shareRank(
                rank: _userRank!,
                type: _selectedType,
                username: user.username,
                isEducationMode: modeProvider.isEducationMode,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final isTopThree = entry.rank <= 3;
    final rankColor = _getRankColor(entry.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppTheme.primaryNeon.withOpacity(0.2)
            : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppTheme.primaryNeon
              : (isTopThree ? rankColor.withOpacity(0.5) : Colors.transparent),
          width: entry.isCurrentUser ? 2 : (isTopThree ? 1 : 0),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree ? rankColor : AppTheme.darkCard,
              shape: BoxShape.circle,
              border: isTopThree
                  ? null
                  : Border.all(color: Colors.white30, width: 1),
            ),
            child: Center(
              child: Text(
                entry.rank.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryNeon.withOpacity(0.2),
            child: Text(
              entry.username[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNeon,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: entry.isCurrentUser
                              ? AppTheme.primaryNeon
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (entry.isEducationMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🎓',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Level ${entry.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(entry.accuracy * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? rankColor : AppTheme.primaryNeon,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return AppTheme.primaryNeon;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.white60,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Leaderboard Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Play games to appear on the leaderboard!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLeaderboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: AppTheme.darkBg,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

