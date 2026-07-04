import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngo_app/features/auth/data/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController() {
    // Listen to Firebase auth state changes to update the current user reactively
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
    _currentUser = _auth.currentUser;
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Register with email and password
  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.message;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return AuthResult(success: false, message: e.toString());
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.signInWithEmail(
        email: email,
        password: password,
      );

      _isLoading = false;
      if (!result.success && !result.requiresEmailVerification) {
        _errorMessage = result.message;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return AuthResult(success: false, message: e.toString());
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.signInWithGoogle();
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.message;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return AuthResult(success: false, message: e.toString());
    }
  }

  // Resend email verification
  Future<AuthResult> resendEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.resendEmailVerification();
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.message;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return AuthResult(success: false, message: e.toString());
    }
  }

  // Check if email has been verified
  Future<bool> checkEmailVerified() async {
    try {
      final verified = await AuthService.checkEmailVerified();
      if (verified) {
        _currentUser = _auth.currentUser;
        notifyListeners();
      }
      return verified;
    } catch (e) {
      return false;
    }
  }

  // Send password reset email
  Future<AuthResult> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.resetPassword(email);
      _isLoading = false;
      if (!result.success) {
        _errorMessage = result.message;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return AuthResult(success: false, message: e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await AuthService.signOut();
    
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
