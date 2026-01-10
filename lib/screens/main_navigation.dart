import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'leagues/leagues_screen.dart';
import 'friends/friends_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;
  late List<Animation<double>> _iconAnimations;

  final List<Widget> _screens = const [
    HomeScreen(),
    LeaguesScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home'),
                _buildNavItem(1, Icons.emoji_events, 'Leagues'),
                _buildNavItem(2, Icons.people, 'Friends'),
                _buildNavItem(3, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryNeon.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? _iconAnimations[index].value : 1.0,
                    child: Icon(
                      icon,
                      color: isSelected
                          ? AppTheme.primaryNeon
                          : Colors.white.withOpacity(0.5),
                      size: 26,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryNeon
                      : Colors.white.withOpacity(0.5),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

