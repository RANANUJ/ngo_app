import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
      print('Starting registration for: $email');
      
      // Create user with email and password
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('User created: ${credential.user?.uid}');

      if (credential.user != null) {
        // Update display name
        try {
          await credential.user!.updateDisplayName(name);
          print('Display name updated');
        } catch (e) {
          print('Warning: Could not update display name: $e');
        }

        // Send email verification
        try {
          await credential.user!.sendEmailVerification();
          print('Verification email sent');
        } catch (e) {
          print('Warning: Could not send verification email: $e');
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
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      print('General exception: $e');
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
