import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getUserProfile(String userId, String userType) async {
    try {
      if (userType == 'ngo') {
        final ngoDoc = await _firestore
            .collection('ngo_registrations')
            .doc(userId)
            .get();
        if (ngoDoc.exists && ngoDoc.data() != null) {
          return UserProfile.fromMap(userId, 'ngo', ngoDoc.data()!);
        }
      }

      // Fallback/Check volunteers collection
      final volunteerDoc = await _firestore
          .collection('volunteers')
          .doc(userId)
          .get();
      if (volunteerDoc.exists && volunteerDoc.data() != null) {
        return UserProfile.fromMap(userId, 'volunteer', volunteerDoc.data()!);
      }

      // If userType was volunteer but doc not found under volunteers, check ngo_registrations just in case
      if (userType == 'volunteer') {
        final ngoDoc = await _firestore
            .collection('ngo_registrations')
            .doc(userId)
            .get();
        if (ngoDoc.exists && ngoDoc.data() != null) {
          return UserProfile.fromMap(userId, 'ngo', ngoDoc.data()!);
        }
      }

      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    if (profile.type == 'ngo') {
      await _firestore
          .collection('ngo_registrations')
          .doc(profile.id)
          .set({
        'ngoName': profile.name,
        'name': profile.name,
        'photoUrl': profile.photoUrl,
        'ngoLogo': profile.photoUrl,
        'profileImageUrl': profile.photoUrl,
        'bio': profile.bio,
        'missionVision': profile.bio,
        'city': profile.city,
        'state': profile.state,
        'phone': profile.phone,
        'mobileNo': profile.phone,
        'email': profile.email,
        'username': profile.username?.trim().toLowerCase(),
      }, SetOptions(merge: true));
    } else {
      await _firestore
          .collection('volunteers')
          .doc(profile.id)
          .set({
        'displayName': profile.name,
        'photoUrl': profile.photoUrl,
        'profileImageUrl': profile.photoUrl,
        'bio': profile.bio,
        'city': profile.city,
        'state': profile.state,
        'location': '${profile.city}, ${profile.state}',
        'phone': profile.phone,
        'email': profile.email,
        'username': profile.username?.trim().toLowerCase(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) return false;

    final volQuery = await _firestore
        .collection('volunteers')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    if (volQuery.docs.isNotEmpty) return true;

    final ngoQuery = await _firestore
        .collection('ngo_registrations')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    return ngoQuery.docs.isNotEmpty;
  }
}
