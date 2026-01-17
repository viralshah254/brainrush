import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/league_service.dart';
import '../../models/league.dart';
import '../../providers/user_provider.dart';
import '../../widgets/out_of_coins_dialog.dart';
import '../game_screen.dart';
import '../../providers/game_provider.dart';
import '../../l10n/app_localizations.dart';

class LeaguesScreen extends StatefulWidget {
  final String? gradeLevel; // For education mode grade filtering
  final bool isEducationMode; // Whether this is education mode

  const LeaguesScreen({
    super.key,
    this.gradeLevel,
    this.isEducationMode = false,
  });

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final _leagueService = LeagueService();
  String _selectedTopic = 'All';
  String _selectedStatus = 'Active';
  List<League> _leagues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    setState(() => _isLoading = true);
    final leagues = await _leagueService.getLeagues(
      topic: _selectedTopic,
      status: _selectedStatus,
    );
    setState(() {
      _leagues = leagues;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show back button if we can pop (i.e., navigated via push, not from bottom nav)
    final canPop = Navigator.canPop(context);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.globalLeagues ?? 'Global Leagues'),
        backgroundColor: AppTheme.darkBg,
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Topic Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _leagueService.getAvailableTopics().map((topic) {
                final isSelected = _selectedTopic == topic;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(topic),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedTopic = topic);
                      _loadLeagues();
                    },
                    backgroundColor: AppTheme.darkCard,
                    selectedColor: AppTheme.primaryNeon,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.darkBg : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Status Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Active', 'Upcoming', 'Completed'].map((status) {
                final isSelected = _selectedStatus == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Center(child: Text(status)),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        _loadLeagues();
                      },
                      backgroundColor: AppTheme.darkCard,
                      selectedColor: AppTheme.primaryNeon,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.darkBg : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Leagues List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leagues.isEmpty
                    ? const Center(
                        child: Text(
                          'No leagues found',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeagues,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leagues.length,
                          itemBuilder: (context, index) {
                            return _LeagueCard(
                              league: _leagues[index],
                              onJoin: () => _joinLeague(_leagues[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinLeague(League league) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    // Check if user has enough coins
    if (user.coins < league.entryFee) {
      // Show out of coins dialog if they have 0 coins
      if (user.coins == 0) {
        showOutOfCoinsDialog(context);
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough coins! Need ${league.entryFee}, have ${user.coins}'),
        ),
      );
      }
      return;
    }

    try {
      // Deduct entry fee
      context.read<UserProvider>().spendCoins(league.entryFee);

      // Join league
      final success = await _leagueService.joinLeague(
        league.id,
        user.id,
        user.username,
      );

      if (!mounted) return;

      if (success) {
        // Start league game
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              category: league.topic,
              questionCount: league.totalQuestions,
              mode: GameMode.league,
              leagueId: league.id, // Pass league ID
            ),
          ),
        );
      } else {
        // Refund coins if join failed
        context.read<UserProvider>().addCoins(league.entryFee);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join league')),
        );
      }
    } catch (e) {
      // Refund coins on error
      context.read<UserProvider>().addCoins(league.entryFee);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _LeagueCard extends StatelessWidget {
  final League league;
  final VoidCallback onJoin;

  const _LeagueCard({
    required this.league,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(league.tier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tierColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Tier Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tierColor),
                  ),
                  child: Text(
                    league.tier,
                    style: TextStyle(
                      color: tierColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Topic
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    league.topic,
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (league.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              league.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              league.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.people,
                  label: '${league.participants.length}/${league.maxParticipants}',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: '${league.daysRemaining}d left',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.monetization_on,
                  label: '${league.entryFee} coins',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Join & Play',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.primaryNeon;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
