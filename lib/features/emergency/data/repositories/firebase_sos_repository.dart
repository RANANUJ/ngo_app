import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/sos_alert.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/sos_repository.dart';

class FirebaseSosRepository implements SosRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<SosAlert>> streamActiveAlerts() {
    return _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosAlert.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<SosAlert>> streamRespondingAlerts(String ngoId) {
    return _firestore
        .collection('sos_alerts')
        .where('respondingNgoId', isEqualTo: ngoId)
        .where('status', isEqualTo: 'responding')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosAlert.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<SosAlert>> streamResolvedAlerts(String ngoId) {
    return _firestore
        .collection('sos_alerts')
        .where('respondingNgoId', isEqualTo: ngoId)
        .where('status', isEqualTo: 'resolved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosAlert.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<SosAlert>> streamVolunteerSosAlerts(String volunteerId) {
    return _firestore
        .collection('sos_alerts')
        .where('odid', isEqualTo: volunteerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosAlert.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<SosAlert?> streamSosAlert(String sosId) {
    return _firestore
        .collection('sos_alerts')
        .doc(sosId)
        .snapshots()
        .map((snapshot) => snapshot.exists && snapshot.data() != null
            ? SosAlert.fromMap(snapshot.id, snapshot.data()!)
            : null);
  }

  @override
  Future<String> triggerSosAlert(SosAlert alert, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      final fileName = 'sos_images/${alert.odid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final alertMap = alert.copyWith(imageUrl: imageUrl).toMap();
    alertMap['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('sos_alerts').add(alertMap);
    return docRef.id;
  }

  @override
  Future<void> updateSosAlert(String sosId, Map<String, dynamic> data) async {
    // Replace any raw DateTime object in map with server Timestamp for Firestore consistency
    final updatedData = Map<String, dynamic>.from(data);
    if (updatedData.containsKey('respondedAt') && updatedData['respondedAt'] is DateTime) {
      updatedData['respondedAt'] = FieldValue.serverTimestamp();
    }
    if (updatedData.containsKey('resolvedAt') && updatedData['resolvedAt'] is DateTime) {
      updatedData['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('sos_alerts').doc(sosId).update(updatedData);
  }

  @override
  Future<void> deleteSosAlert(String sosId) async {
    await _firestore.collection('sos_alerts').doc(sosId).delete();
  }

  @override
  Future<void> updateVolunteerLocation(String sosId, double latitude, double longitude) async {
    await _firestore.collection('sos_alerts').doc(sosId).update({
      'latitude': latitude,
      'longitude': longitude,
      'volunteerLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateNgoLocation(String sosId, double latitude, double longitude) async {
    await _firestore.collection('sos_alerts').doc(sosId).update({
      'ngoLatitude': latitude,
      'ngoLongitude': longitude,
      'ngoLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addEmergencyContact(String volunteerId, EmergencyContact contact) async {
    final docRef = _firestore.collection('od_volunteers').doc(volunteerId);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.update({
        'emergencyContacts': FieldValue.arrayUnion([contact.toMap()])
      });
    } else {
      await docRef.set({
        'emergencyContacts': [contact.toMap()]
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> removeEmergencyContact(String volunteerId, EmergencyContact contact) async {
    await _firestore.collection('od_volunteers').doc(volunteerId).update({
      'emergencyContacts': FieldValue.arrayRemove([contact.toMap()])
    });
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts(String volunteerId) async {
    final doc = await _firestore.collection('od_volunteers').doc(volunteerId).get();
    if (doc.exists && doc.data() != null) {
      final list = doc.data()?['emergencyContacts'] as List<dynamic>?;
      if (list != null) {
        return list.map((item) => EmergencyContact.fromMap(Map<String, dynamic>.from(item))).toList();
      }
    }
    return [];
  }

  @override
  Future<String?> getVolunteerPhone(String volunteerId) async {
    final doc = await _firestore.collection('volunteers').doc(volunteerId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()?['phone'] as String?;
    }
    return null;
  }

  @override
  Future<void> createSosNotification({
    required String sosId,
    required String emergencyType,
    required String address,
    required double latitude,
    required double longitude,
    required String volunteerInNeedId,
    required String volunteerInNeedName,
    String? respondingNgoName,
    required String targetType,
  }) async {
    if (targetType == 'ngo') {
      final volunteerPhone = await getVolunteerPhone(volunteerInNeedId);
      await _firestore.collection('sos_notifications').add({
        'sosId': sosId,
        'volunteerId': volunteerInNeedId,
        'volunteerName': volunteerInNeedName,
        'volunteerPhone': volunteerPhone ?? '',
        'emergencyType': emergencyType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } else {
      await _firestore.collection('volunteer_sos_notifications').add({
        'sosId': sosId,
        'emergencyType': emergencyType,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'volunteerInNeedId': volunteerInNeedId,
        'volunteerInNeedName': volunteerInNeedName,
        'createdAt': FieldValue.serverTimestamp(),
        'respondingNgo': respondingNgoName ?? '',
        'status': 'active',
      });
    }
  }
}
