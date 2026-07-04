import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getUserProfile(String userId, String userType);
  Future<void> updateUserProfile(UserProfile profile);
  Future<bool> checkUsernameExists(String username);
}
