import 'dart:io';
import '../models/sos_alert.dart';
import '../models/emergency_contact.dart';

abstract class SosRepository {
  /// Stream active SOS alerts (status == 'active')
  Stream<List<SosAlert>> streamActiveAlerts();

  /// Stream responding SOS alerts for a specific NGO (status == 'responding' and respondingNgoId == ngoId)
  Stream<List<SosAlert>> streamRespondingAlerts(String ngoId);

  /// Stream resolved SOS alerts for a specific NGO (status == 'resolved' and respondingNgoId == ngoId)
  Stream<List<SosAlert>> streamResolvedAlerts(String ngoId);

  /// Stream all SOS alerts for a specific volunteer (by odid)
  Stream<List<SosAlert>> streamVolunteerSosAlerts(String volunteerId);

  /// Stream a single SOS alert by ID
  Stream<SosAlert?> streamSosAlert(String sosId);

  /// Trigger a new SOS alert
  Future<String> triggerSosAlert(SosAlert alert, File? imageFile);

  /// Update an SOS alert document directly
  Future<void> updateSosAlert(String sosId, Map<String, dynamic> data);

  /// Cancel/Delete an SOS alert
  Future<void> deleteSosAlert(String sosId);

  /// Update volunteer location during live tracking
  Future<void> updateVolunteerLocation(String sosId, double latitude, double longitude);

  /// Update NGO location during live tracking response
  Future<void> updateNgoLocation(String sosId, double latitude, double longitude);

  /// Add emergency contact for a volunteer
  Future<void> addEmergencyContact(String volunteerId, EmergencyContact contact);

  /// Remove emergency contact for a volunteer
  Future<void> removeEmergencyContact(String volunteerId, EmergencyContact contact);

  /// Get emergency contacts for a volunteer
  Future<List<EmergencyContact>> getEmergencyContacts(String volunteerId);

  /// Get volunteer phone number
  Future<String?> getVolunteerPhone(String volunteerId);

  /// Create notifications for NGOs/volunteers
  Future<void> createSosNotification({
    required String sosId,
    required String emergencyType,
    required String address,
    required double latitude,
    required double longitude,
    required String volunteerInNeedId,
    required String volunteerInNeedName,
    String? respondingNgoName,
    required String targetType, // 'ngo' or 'volunteer'
  });
}
