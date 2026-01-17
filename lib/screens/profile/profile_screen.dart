import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/premium_service.dart';
import '../../services/auth_service.dart';
import '../premium_screen.dart';
import '../auth/simple_auth_screen.dart';
import '../notification_settings_screen.dart';
import '../achievements_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../cards/card_collection_screen.dart';
import '../help_support_screen.dart';
import '../about_screen.dart';
import '../language_selection_screen.dart';
import '../../widgets/invite_friends_dialog.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _isDemoUser = false;
  String? _demoUserEmail;
  String? _demoUserName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDemoAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDemoAuth();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check demo auth whenever the screen is displayed
    _checkDemoAuth();
  }

  Future<void> _checkDemoAuth() async {
    final authService = AuthService();
    final isDemo = await authService.isDemoUserAuthenticated();
    final email = await authService.getDemoUserEmail();
    final name = await authService.getDemoUserName();
    
    // Also check for local users (SharedPreferences)
    final isLocal = await authService.isLocalUserAuthenticated();
    final localEmail = await authService.getLocalUserEmail();
    final localName = await authService.getLocalUserName();
    
    if (mounted) {
      setState(() {
        _isDemoUser = isDemo || isLocal;
        _demoUserEmail = email ?? localEmail;
        _demoUserName = name ?? localName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh demo auth check when screen is built (ensures it updates after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDemoAuth();
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final authService = AuthService();
            // Check Firebase, demo, and local user authentication
            final isSignedIn = authService.isSignedIn || _isDemoUser;
            // User is not a guest if they're signed in (Firebase, demo, or local)
            final isGuest = user.isGuest && !isSignedIn;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    AppLocalizations.of(context)?.profile ?? 'Profile',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Authentication Section (Top Priority)
                  if (isGuest) ...[
                    _buildAuthenticationCard(context),
                    const SizedBox(height: 20),
                  ],

                  // Profile Avatar & Info
                  _buildProfileHeader(context, user, authService, isSignedIn, _demoUserEmail, _demoUserName),
                  const SizedBox(height: 24),

                  // Level/XP Display
                  _buildLevelCard(user),
                  const SizedBox(height: 16),
                  
                  // Stats Grid
                  _buildStatsGrid(user),
                  const SizedBox(height: 24),
                  
                  // Achievements Card
                  _buildAchievementsCard(context),
                  const SizedBox(height: 16),
                  
                  // Leaderboard Card
                  _buildLeaderboardCard(context),
                  const SizedBox(height: 16),
                  
                  // Card Collection Card
                  _buildCardCollectionCard(context),
                  const SizedBox(height: 24),

                  // Premium Banner (if not premium)
                  Consumer<PremiumService>(
                    builder: (context, premiumService, _) {
                      if (!premiumService.isPremium) {
                        return Column(
                          children: [
                            _buildPremiumBanner(context),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Settings Section
                  Text(
                    AppLocalizations.of(context)?.settings ?? 'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(context, isSignedIn),
                  
                  // Account Actions (Bottom)
                  if (isSignedIn) ...[
                    const SizedBox(height: 24),
                    _buildAccountActions(context),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.account_circle, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Sign In or Create Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all features and get 100 coins bonus!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SimpleAuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.darkBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    AuthService authService,
    bool isSignedIn,
    String? demoEmail,
    String? demoName,
  ) {
    // Determine display name and email
    final displayName = demoName ?? (authService.displayName ?? user.username);
    final displayEmail = demoEmail ?? authService.email;
    
    return Center(
                    child: Column(
                      children: [
          // Avatar
                        Container(
            width: 100,
            height: 100,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                  color: AppTheme.primaryNeon.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                displayName[0].toUpperCase(),
                              style: const TextStyle(
                  fontSize: 48,
                                fontWeight: FontWeight.bold,
                  color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
          
          // Username
                        Text(
            displayName,
                          style: const TextStyle(
              fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
          
          // Status Badge
                        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
              color: isSignedIn
                  ? AppTheme.primaryNeon.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                color: isSignedIn
                    ? AppTheme.primaryNeon
                    : Colors.orange,
                            ),
                          ),
                          child: Text(
              isSignedIn
                  ? (demoEmail != null ? '✓ Demo Account' : '✓ ${authService.providerName}')
                  : '👤 Guest',
                            style: TextStyle(
                fontSize: 12,
                color: isSignedIn
                    ? AppTheme.primaryNeon
                    : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
          
          // Email (if signed in)
          if (isSignedIn && displayEmail != null) ...[
            const SizedBox(height: 8),
            Text(
              displayEmail,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelCard(dynamic user) {
    final levelProgress = user.levelProgress;
    final xpNeeded = user.xpForNextLevel - user.xpForCurrentLevel;
    final xpInLevel = user.xp - user.xpForCurrentLevel;
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)?.level ?? 'Level'} ${user.level}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpInLevel / $xpNeeded ${AppLocalizations.of(context)?.xp ?? 'XP'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${user.level}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                        );
                      },
                      child: Container(
        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: AppTheme.primaryNeon,
                size: 28,
              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)?.achievements ?? 'Achievements',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)?.viewProgress ?? 'View your progress and unlocks',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
              color: Colors.white30,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.leaderboard,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.leaderboard ?? 'Leaderboards',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)?.global ?? 'Compete with players worldwide',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCollectionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardCollectionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.collections,
                color: Colors.purple,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.cardCollection ?? 'Card Collection',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)?.collectibleCards ?? 'Collect cards and build your deck',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(dynamic user) {
    final localizations = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('🪙', user.coins.toString(), localizations?.coins ?? 'Coins', Colors.amber),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('🔥', user.streakCount.toString(), localizations?.streak ?? 'Streak', Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🎯',
            '${(user.stats.accuracy * 100).toStringAsFixed(0)}%',
            localizations?.accuracy ?? 'Accuracy',
            AppTheme.primaryNeon,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade700, Colors.purple.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
            Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    AppLocalizations.of(context)?.play ?? 'Go Premium!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                      color: Colors.white,
                ),
              ),
              Text(
                    '${AppLocalizations.of(context)?.freeCoins ?? 'Ad-free'} from \$3.99/month',
                style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isSignedIn) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.notifications,
            title: AppLocalizations.of(context)?.notifications ?? 'Notifications',
            subtitle: AppLocalizations.of(context)?.manageNotifications ?? 'Manage notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          Consumer<LocaleService>(
            builder: (context, localeService, _) {
              final languageName = localeService.getLanguageName(
                localeService.currentLocale.languageCode,
              );
              return _buildSettingItem(
                icon: Icons.language,
                title: AppLocalizations.of(context)?.language ?? 'Language',
                subtitle: languageName,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingItem(
            icon: Icons.person_add,
            title: AppLocalizations.of(context)?.inviteFriends ?? 'Invite Friends',
            subtitle: AppLocalizations.of(context)?.share ?? 'Share and earn coins',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const InviteFriendsDialog(),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingItem(
            icon: Icons.help,
            title: AppLocalizations.of(context)?.helpSupport ?? 'Help & Support',
            subtitle: AppLocalizations.of(context)?.weAreHereToHelp ?? 'Get help',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildSettingItem(
            icon: Icons.info,
            title: AppLocalizations.of(context)?.about ?? 'About',
            subtitle: '${AppLocalizations.of(context)?.appName ?? 'MindRush'} v1.0.3 — ${AppLocalizations.of(context)?.appTagline ?? 'The Thinking Game'}.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryNeon, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white30,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Log Out Button
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => _handleLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 20),
                SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Delete Account Button
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => _handleDeleteAccount(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever, size: 20),
                SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SimpleAuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'All your data will be permanently deleted:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text('• Profile and account', style: TextStyle(color: Colors.white60, fontSize: 13)),
            Text('• Game progress and stats', style: TextStyle(color: Colors.white60, fontSize: 13)),
            Text('• Coins and achievements', style: TextStyle(color: Colors.white60, fontSize: 13)),
            Text('• All saved data', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await AuthService().deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SimpleAuthScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
