import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    forceCodeForRefreshToken: true,
  );

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register new user with email and password
  static Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      secureLog('Starting registration for: $email');
      
      // Create user with email and password
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      secureLog('User created: ${credential.user?.uid}');

      if (credential.user != null) {
        // Update display name
        try {
          await credential.user!.updateDisplayName(name);
          secureLog('Display name updated');
        } catch (e) {
          secureLog('Warning: Could not update display name: $e');
        }

        // Send email verification
        try {
          await credential.user!.sendEmailVerification();
          secureLog('Verification email sent');
        } catch (e) {
          secureLog('Warning: Could not send verification email: $e');
        }

        return AuthResult(
          success: true,
          message: 'Registration successful! Please check your email to verify your account.',
          user: credential.user,
        );
      }

      return AuthResult(
        success: false,
        message: 'Registration failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      secureLog('FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } on FirebaseException catch (e) {
      secureLog('FirebaseException: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      secureLog('General exception: $e');
      // Check if it's a Firebase error with a code
      String errorMessage = e.toString();
      if (errorMessage.contains('email-already-in-use')) {
        return AuthResult(
          success: false,
          message: 'This email is already registered. Please login instead.',
        );
      }
      return AuthResult(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Sign in with email and password
  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Check if email is verified
        if (!credential.user!.emailVerified) {
          return AuthResult(
            success: false,
            message: 'Please verify your email before logging in.',
            requiresEmailVerification: true,
            user: credential.user,
          );
        }

        return AuthResult(
          success: true,
          message: 'Login successful!',
          user: credential.user,
        );
      }

      return AuthResult(
        success: false,
        message: 'Login failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Resend email verification
  static Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return AuthResult(
          success: true,
          message: 'Verification email sent! Please check your inbox.',
        );
      }
      return AuthResult(
        success: false,
        message: 'Unable to send verification email.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error sending verification email: ${e.toString()}',
      );
    }
  }

  /// Check email verification status
  static Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await signOutGoogle();
    await _auth.signOut();
  }

  /// Reset password
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        success: true,
        message: 'Password reset email sent! Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Sign in with Google
  static Future<AuthResult> signInWithGoogle() async {
    try {
      // Sign out first to force account chooser to appear every time
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow with account chooser
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthResult(
          success: false,
          message: 'Google sign-in was cancelled.',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return AuthResult(
          success: true,
          message: 'Google sign-in successful!',
          user: userCredential.user,
        );
      }

      return AuthResult(
        success: false,
        message: 'Google sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      secureLog('FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      secureLog('Error during Google sign-in: $e');
      return AuthResult(
        success: false,
        message: 'An error occurred during Google sign-in. Please try again.',
      );
    }
  }

  /// Sign out from Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      secureLog('Error signing out from Google: $e');
    }
  }

  /// Get user-friendly error messages
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final bool requiresEmailVerification;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.requiresEmailVerification = false,
  });
}
