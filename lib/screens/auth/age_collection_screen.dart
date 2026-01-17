import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../main_navigation.dart';

class AgeCollectionScreen extends StatefulWidget {
  const AgeCollectionScreen({super.key});

  @override
  State<AgeCollectionScreen> createState() => _AgeCollectionScreenState();
}

class _AgeCollectionScreenState extends State<AgeCollectionScreen> with SingleTickerProviderStateMixin {
  int? _selectedAge;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your age to continue'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Save age to user provider
    final userProvider = context.read<UserProvider>();
    if (userProvider.user != null) {
      // Update user with selected age
      final updatedUser = userProvider.user!.copyWith(age: _selectedAge);
      userProvider.setUser(updatedUser);
      // Save to SharedPreferences
      await userProvider.saveUserData();
    }
    
    // Navigate to main navigation (which contains home screen)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header
                const Text(
                  'One Last Thing!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select your age to personalize your experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Age Selection Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildAgeCard('Under 13'),
                      _buildAgeCard('13-17'),
                      _buildAgeCard('18-24'),
                      _buildAgeCard('25-34'),
                      _buildAgeCard('35-44'),
                      _buildAgeCard('45-54'),
                      _buildAgeCard('55-64'),
                      _buildAgeCard('65+'),
                      _buildAgeCard('Prefer not to say'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNeon,
                      foregroundColor: AppTheme.darkBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Privacy Note
                Text(
                  'Your age helps us provide age-appropriate content and comply with privacy regulations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeCard(String ageRange) {
    final int? ageValue = _getAgeValue(ageRange);
    final bool isSelected = _selectedAge == ageValue;

    return GestureDetector(
      onTap: () => setState(() => _selectedAge = ageValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppTheme.primaryGradient
              : null,
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryNeon
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            ageRange,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  int? _getAgeValue(String ageRange) {
    switch (ageRange) {
      case 'Under 13':
        return 10;
      case '13-17':
        return 15;
      case '18-24':
        return 21;
      case '25-34':
        return 30;
      case '35-44':
        return 40;
      case '45-54':
        return 50;
      case '55-64':
        return 60;
      case '65+':
        return 70;
      case 'Prefer not to say':
        return 0;
      default:
        return null;
    }
  }
}


