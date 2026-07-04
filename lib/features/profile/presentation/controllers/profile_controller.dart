import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileController(this._repository);

  // Getters
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<UserProfile?> loadUserProfile(String userId, String userType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.getUserProfile(userId, userType);
      _profile = profile;
      _isLoading = false;
      notifyListeners();
      return profile;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }

  Future<bool> updateProfile(UserProfile profile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateUserProfile(profile);
      _profile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> isUsernameUnique(String username, String userId) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) return false;

    try {
      final exists = await _repository.checkUsernameExists(cleanUsername);
      if (!exists) return true;

      if (_profile != null && _profile!.id == userId && _profile!.username?.trim().toLowerCase() == cleanUsername) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
