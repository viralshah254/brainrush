import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
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

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

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
  
  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('📧 Creating account for: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      debugPrint('✅ Email sign up successful');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Email sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 Signing in with email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email sign in successful');
      return userCredential;
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
  
  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');
      
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


