import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'age_collection_screen.dart';
import 'forgot_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Smart authentication screen with social login options
/// Detects first-time vs returning users
class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({super.key});

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = true; // Default to sign-up for first-time users
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showAppleSignIn = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkReturningUser();
    _checkAppleSignInAvailability();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  /// Check if user is returning (has visited before)
  Future<void> _checkReturningUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasVisitedBefore = prefs.getBool('has_visited_auth') ?? false;
    
    if (!hasVisitedBefore) {
      // First time - mark as visited and show sign-up
      await prefs.setBool('has_visited_auth', true);
      setState(() => _isSignUp = true);
    } else {
      // Returning user - show sign-in
      setState(() => _isSignUp = false);
    }
  }

  /// Check if Apple Sign In is available (iOS only)
  Future<void> _checkAppleSignInAvailability() async {
    if (Platform.isIOS) {
      final isAvailable = await _authService.isAppleSignInAvailable();
      setState(() => _showAppleSignIn = isAvailable);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please agree to Terms & Privacy Policy to continue');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AgeCollectionScreen()),
          );
        }
      } else {
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen (home)
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(_authService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handle social login
  Future<void> _handleSocialLogin(Future<dynamic> Function() loginFunction, String provider) async {
    if (!_agreedToTerms) {
      _showError('Please agree to Terms & Privacy Policy to continue');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await loginFunction();
      if (result != null && mounted) {
        // Check if it's a new user (sign up) or existing user (sign in)
        final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // New user - collect age
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AgeCollectionScreen()),
          );
        } else {
          // Existing user - go to home
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '$provider sign-in failed. ';
        
        // Provide helpful error messages
        if (provider == 'Apple' && e.toString().contains('1000')) {
          errorMessage = 'Apple Sign In is not available on simulator. Please use a physical device or try another sign-in method.';
        } else if (provider == 'Google' && e.toString().contains('DEVELOPER_ERROR')) {
          errorMessage = 'Google Sign In is not configured. Please use email sign-in for now.';
        } else {
          errorMessage += 'Please try email sign-in instead.';
        }
        
        _showError(errorMessage);
        debugPrint('❌ $provider Sign In error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse('https://www.dvtechventures.com/TandCs');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/mindrush_logo.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Join the MindRush community'
                        : 'Sign in to continue your journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  // Temporarily disabled social login - needs Firebase OAuth configuration
                  // TODO: Enable after configuring Google/Apple/Facebook in Firebase Console
                  // const SizedBox(height: 32),
                  // _buildSocialLoginSection(),
                  // const SizedBox(height: 32),
                  // Row(
                  //   children: [
                  //     Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //       child: Text(
                  //         'Or continue with email',
                  //         style: TextStyle(
                  //           color: Colors.white.withOpacity(0.5),
                  //           fontSize: 12,
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                  //   ],
                  // ),

                  const SizedBox(height: 40),

                  // Name Field (Sign Up only)
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: AppTheme.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.person, color: AppTheme.primaryNeon),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: AppTheme.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.email, color: AppTheme.primaryNeon),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: AppTheme.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.lock, color: AppTheme.primaryNeon),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (_isSignUp && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Confirm Password Field (Sign Up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: AppTheme.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppTheme.primaryNeon),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Forgot Password (Sign In only)
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: AppTheme.primaryNeon),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Terms & Privacy Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value ?? false),
                        activeColor: AppTheme.primaryNeon,
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Privacy Policy',
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _launchPrivacyPolicy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
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
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle Sign In / Sign Up
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        children: [
                          TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? '),
                          TextSpan(
                            text: _isSignUp ? 'Sign In' : 'Sign Up',
                            style: const TextStyle(
                              color: AppTheme.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _formKey.currentState?.reset();
                                });
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Secure authentication powered by Firebase',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build social login buttons section
  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        // Apple Sign In (iOS only)
        if (_showAppleSignIn) ...[
          _buildSocialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            backgroundColor: Colors.white,
            textColor: Colors.black,
            onPressed: () => _handleSocialLogin(
              _authService.signInWithApple,
              'Apple',
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Google Sign In
        _buildSocialButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black,
          onPressed: () => _handleSocialLogin(
            _authService.signInWithGoogle,
            'Google',
          ),
        ),
        const SizedBox(height: 12),

        // Facebook Sign In
        _buildSocialButton(
          icon: Icons.facebook,
          label: 'Continue with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
          onPressed: () => _handleSocialLogin(
            _authService.signInWithFacebook,
            'Facebook',
          ),
        ),
      ],
    );
  }

  /// Build a social login button
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: textColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

