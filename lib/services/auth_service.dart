import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Comprehensive authentication service supporting multiple providers
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in (including demo user and local users)
  bool get isSignedIn {
    // Check Firebase first
    if (currentUser != null) return true;
    
    // Note: For demo and local users, we check asynchronously in the screens
    // This getter is synchronous, so it only checks Firebase
    return false;
  }
  
  /// Check if local user is authenticated (SharedPreferences)
  Future<bool> isLocalUserAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('local_user_authenticated') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get local user email (SharedPreferences)
  Future<String?> getLocalUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('local_user_email');
    } catch (e) {
      return null;
    }
  }
  
  /// Get local user name (SharedPreferences)
  Future<String?> getLocalUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('local_user_name');
    } catch (e) {
      return null;
    }
  }
  
  /// Get local user ID (SharedPreferences)
  Future<String?> getLocalUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('local_user_id');
    } catch (e) {
      return null;
    }
  }
  
  /// Check if demo user is authenticated (frontend-only, no Firebase)
  Future<bool> isDemoUserAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('demo_user_authenticated') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get demo user email (frontend-only)
  Future<String?> getDemoUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_user_email');
    } catch (e) {
      return null;
    }
  }
  
  /// Get demo user name (frontend-only)
  Future<String?> getDemoUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_user_name');
    } catch (e) {
      return null;
    }
  }

  /// Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== GOOGLE SIGN IN =====
  
  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google Sign In cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('✅ Google Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign In error: $e');
      rethrow;
    }
  }

  // ===== APPLE SIGN IN =====
  
  /// Check if Apple Sign In is available
  Future<bool> isAppleSignInAvailable() async {
    if (!Platform.isIOS) return false;
    return await SignInWithApple.isAvailable();
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🍎 Starting Apple Sign In...');
      
      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      debugPrint('✅ Apple Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Apple Sign In error: $e');
      rethrow;
    }
  }

  // ===== FACEBOOK SIGN IN =====
  
  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      debugPrint('📘 Starting Facebook Sign In...');
      
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        debugPrint('❌ Facebook Sign In failed: ${result.status}');
        return null;
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      // Sign in to Firebase with the Facebook credential
      final userCredential = await _auth.signInWithCredential(facebookAuthCredential);
      
      debugPrint('✅ Facebook Sign In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Facebook Sign In error: $e');
      rethrow;
    }
  }

  // ===== EMAIL/PASSWORD SIGN IN =====
  
  /// Ensure demo account exists (create if it doesn't)
  Future<void> ensureDemoAccount() async {
    const demoEmail = 'demo@mindrushgame.com';
    const demoPassword = 'Demo@123';
    const demoName = 'Demo User';
    
    try {
      // Try to sign in first (to check if account exists)
      try {
        await _auth.signInWithEmailAndPassword(
          email: demoEmail,
          password: demoPassword,
        );
        debugPrint('✅ Demo account already exists');
        // Sign out after checking
        await _auth.signOut();
      } catch (e) {
        // If sign in fails, try to create the account
        if (e is FirebaseAuthException && 
            (e.code == 'user-not-found' || e.code == 'wrong-password')) {
          debugPrint('📧 Creating demo account...');
          try {
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: demoEmail,
              password: demoPassword,
            );
            
            // Update display name
            await userCredential.user?.updateDisplayName(demoName);
            debugPrint('✅ Demo account created successfully');
            
            // Sign out after creating (user will sign in manually)
            await _auth.signOut();
          } catch (createError) {
            if (createError is FirebaseAuthException && 
                createError.code == 'email-already-in-use') {
              debugPrint('✅ Demo account already exists (email-already-in-use)');
            } else {
              debugPrint('❌ Error creating demo account: $createError');
            }
          }
        } else {
          debugPrint('❌ Error checking demo account: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error ensuring demo account: $e');
    }
  }
  
  /// Sign up with email and password
  /// Saves user info to SharedPreferences (frontend-only for now)
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('📧 Creating account for: $email');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user already exists
      final existingUsers = prefs.getStringList('registered_users') ?? [];
      if (existingUsers.contains(email.toLowerCase())) {
        throw Exception('An account with this email already exists');
      }
      
      // Generate user ID
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save user info to SharedPreferences
      await prefs.setString('user_${email.toLowerCase()}_email', email);
      await prefs.setString('user_${email.toLowerCase()}_password', password); // In production, hash this
      await prefs.setString('user_${email.toLowerCase()}_name', displayName);
      await prefs.setString('user_${email.toLowerCase()}_id', userId);
      await prefs.setString('user_${email.toLowerCase()}_createdAt', DateTime.now().toIso8601String());
      
      // Add to registered users list
      existingUsers.add(email.toLowerCase());
      await prefs.setStringList('registered_users', existingUsers);
      
      // Set as authenticated user
      await prefs.setBool('local_user_authenticated', true);
      await prefs.setString('local_user_email', email);
      await prefs.setString('local_user_name', displayName);
      await prefs.setString('local_user_id', userId);
      
      debugPrint('✅ Email sign up successful (saved to SharedPreferences)');
      debugPrint('✅ User ID: $userId');
      
      // Return null since we're not using Firebase, but the signup screen will handle it
      return null;
    } catch (e) {
      debugPrint('❌ Email sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  /// Checks SharedPreferences first, then Firebase (for backward compatibility)
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 Signing in with email: $email');
      
      // Check if this is the demo account - bypass Firebase
      if (email.toLowerCase() == 'demo@mindrushgame.com' && password == 'Demo@123') {
        debugPrint('🎮 Demo account detected - using frontend-only authentication');
        
        // Create a mock user credential for demo (frontend-only)
        // We'll use a local flag instead of Firebase
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('demo_user_authenticated', true);
        await prefs.setString('demo_user_email', email);
        await prefs.setString('demo_user_name', 'Demo User');
        
        debugPrint('✅ Demo login successful (frontend-only)');
        
        // Return null since we're not using Firebase, but the login screen will handle it
        return null;
      }
      
      // Check SharedPreferences for locally registered users
      final prefs = await SharedPreferences.getInstance();
      final emailKey = email.toLowerCase();
      
      // Check if user exists in local storage
      final savedPassword = prefs.getString('user_${emailKey}_password');
      if (savedPassword != null) {
        // User exists in local storage
        if (savedPassword == password) {
          // Password matches - authenticate locally
          final savedName = prefs.getString('user_${emailKey}_name') ?? 'User';
          final savedUserId = prefs.getString('user_${emailKey}_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
          
          await prefs.setBool('local_user_authenticated', true);
          await prefs.setString('local_user_email', email);
          await prefs.setString('local_user_name', savedName);
          await prefs.setString('local_user_id', savedUserId);
          
          debugPrint('✅ Email sign in successful (from SharedPreferences)');
          return null; // Return null for local auth
        } else {
          throw Exception('Incorrect password');
        }
      }
      
      // If not found in local storage, try Firebase (for backward compatibility)
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        debugPrint('✅ Email sign in successful (from Firebase)');
        return userCredential;
      } catch (firebaseError) {
        // If Firebase also fails, throw the original error
        throw Exception('No account found with this email');
      }
    } catch (e) {
      debugPrint('❌ Email sign in error: $e');
      rethrow;
    }
  }

  // ===== PASSWORD RESET =====
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      rethrow;
    }
  }

  // ===== SIGN OUT =====
  
  /// Sign out from all providers (including demo user)
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');
      
      // Clear demo user authentication
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('demo_user_authenticated');
      await prefs.remove('demo_user_email');
      await prefs.remove('demo_user_name');
      debugPrint('✅ Demo user signed out');
      
      // Clear local user authentication
      await prefs.remove('local_user_authenticated');
      await prefs.remove('local_user_email');
      await prefs.remove('local_user_name');
      await prefs.remove('local_user_id');
      debugPrint('✅ Local user signed out');
      
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        debugPrint('✅ Signed out from Google');
      }
      
      // Sign out from Facebook
      await FacebookAuth.instance.logOut();
      debugPrint('✅ Signed out from Facebook');
      
      // Sign out from Firebase
      await _auth.signOut();
      
      debugPrint('✅ Sign out complete');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // ===== USER MANAGEMENT =====
  
  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      debugPrint('✅ Account deleted');
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      rethrow;
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      debugPrint('✅ Display name updated to: $displayName');
    } catch (e) {
      debugPrint('❌ Update display name error: $e');
      rethrow;
    }
  }

  /// Get user display name
  String? get displayName => currentUser?.displayName;

  /// Get user email
  String? get email => currentUser?.email;

  /// Get user ID
  String? get userId => currentUser?.uid;

  /// Get auth provider
  String? get provider {
    final providerData = currentUser?.providerData;
    if (providerData == null || providerData.isEmpty) return null;
    return providerData.first.providerId;
  }

  /// Get human-readable provider name
  String get providerName {
    switch (provider) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'facebook.com':
        return 'Facebook';
      case 'password':
        return 'Email';
      default:
        return 'Unknown';
    }
  }

  // ===== ERROR HANDLING =====
  
  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in method.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}


