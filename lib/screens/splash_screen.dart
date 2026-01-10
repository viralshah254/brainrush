import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Rotate animation controller
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _logoController.forward();

    // Navigate to home after delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigation(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Animated background particles
          ...List.generate(20, (index) {
            return Positioned(
              left: (index * 50.0) % MediaQuery.of(context).size.width,
              top: (index * 40.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_rotateController.value * 2 * math.pi + index) * 20,
                      math.cos(_rotateController.value * 2 * math.pi + index) * 20,
                    ),
                    child: Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNeon.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryNeon.withOpacity(0.5),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🧠',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // App name
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return AppTheme.primaryGradient.createShader(bounds);
                            },
                            child: const Text(
                              'BrainRush',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep that brain fresh! 🚀',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white60,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryNeon,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

