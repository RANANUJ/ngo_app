import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/models/sos_alert.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/sos_repository.dart';
import '../../../../core/services/analytics_service.dart';

class SosController extends ChangeNotifier {
  final SosRepository _repository;
  final AnalyticsService _analytics = AnalyticsService();

  SosController(this._repository);

  // Geolocation states
  Position? _currentPosition;
  String _currentAddress = 'Getting location...';
  bool _isLoadingLocation = false;

  // Active SOS states
  bool _isSendingSOS = false;
  bool _sosCountdownActive = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  // Emergency contacts states
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoadingContacts = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isSendingSOS => _isSendingSOS;
  bool get sosCountdownActive => _sosCountdownActive;
  int get countdownSeconds => _countdownSeconds;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isLoadingContacts => _isLoadingContacts;

  /// Fetch the current device location and resolve physical address
  Future<void> getCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentAddress = 'Location permission denied';
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentAddress = 'Location permissions permanently denied';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Check service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = 'GPS/Location services disabled';
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _currentAddress = '${place.locality}, ${place.administrativeArea}';
        } else {
          _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        debugPrint('Address geocoding error: $e');
        _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      debugPrint('Location fetching error: $e');
      _currentAddress = 'Tap refresh to get location';
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Start local countdown timer (e.g. 5 seconds) before firing the actual SOS event
  void startSosCountdown({
    required String volunteerId,
    required String volunteerName,
    required VoidCallback onTriggered,
  }) {
    if (_sosCountdownActive) return;

    _sosCountdownActive = true;
    _countdownSeconds = 5;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        cancelSosCountdown();
        onTriggered();
      }
    });
  }

  /// Cancel any pending SOS triggering countdown
  void cancelSosCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _sosCountdownActive = false;
    _countdownSeconds = 5;
    notifyListeners();
  }

  /// Trigger a quick/default SOS event
  Future<String?> triggerQuickSos({
    required String volunteerId,
    required String volunteerName,
  }) async {
    _isSendingSOS = true;
    notifyListeners();

    try {
      final phone = await _repository.getVolunteerPhone(volunteerId) ?? '';
      
      final alert = SosAlert(
        id: '',
        odid: volunteerId,
        odname: volunteerName,
        volunteerPhone: phone,
        emergencyType: 'Quick SOS',
        description: 'Emergency SOS - Immediate help needed!',
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        address: _currentAddress,
        status: 'active',
      );

      final newSosId = await _repository.triggerSosAlert(alert, null);

      // Create notification records
      await _repository.createSosNotification(
        sosId: newSosId,
        emergencyType: 'Quick SOS',
        address: _currentAddress,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        volunteerInNeedId: volunteerId,
        volunteerInNeedName: volunteerName,
        targetType: 'ngo',
      );

      // Log Analytics
      _analytics.logSOSAlert(alertType: 'Quick SOS', location: _currentAddress);

      return newSosId;
    } catch (e) {
      debugPrint('Error triggering quick SOS: $e');
      rethrow;
    } finally {
      _isSendingSOS = false;
      notifyListeners();
    }
  }

  /// Trigger a detailed SOS alert with emergency type, description, and raw image file
  Future<String?> triggerDetailedSos({
    required String volunteerId,
    required String volunteerName,
    required String type,
    required String description,
    File? imageFile,
  }) async {
    _isSendingSOS = true;
    notifyListeners();

    try {
      final phone = await _repository.getVolunteerPhone(volunteerId) ?? '';

      final alert = SosAlert(
        id: '',
        odid: volunteerId,
        odname: volunteerName,
        volunteerPhone: phone,
        emergencyType: type,
        description: description,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        address: _currentAddress,
        status: 'active',
      );

      final newSosId = await _repository.triggerSosAlert(alert, imageFile);

      // Create notification records for NGOs
      await _repository.createSosNotification(
        sosId: newSosId,
        emergencyType: type,
        address: _currentAddress,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        volunteerInNeedId: volunteerId,
        volunteerInNeedName: volunteerName,
        targetType: 'ngo',
      );

      // Log Analytics
      _analytics.logSOSAlert(alertType: type, location: _currentAddress);

      return newSosId;
    } catch (e) {
      debugPrint('Error triggering detailed SOS: $e');
      rethrow;
    } finally {
      _isSendingSOS = false;
      notifyListeners();
    }
  }

  /// Mark an active SOS alert as resolved
  Future<void> resolveSosAlert(String sosId) async {
    try {
      await _repository.updateSosAlert(sosId, {
        'status': 'resolved',
        'resolvedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error resolving SOS: $e');
      rethrow;
    }
  }

  /// Cancel / Delete an active SOS alert
  Future<void> cancelSosAlert(String sosId) async {
    try {
      await _repository.deleteSosAlert(sosId);
    } catch (e) {
      debugPrint('Error deleting/canceling SOS: $e');
      rethrow;
    }
  }

  /// Accept/Respond to an SOS alert (NGO App flow)
  Future<void> respondToSosAlert({
    required String sosId,
    required String ngoId,
    required String ngoName,
    required String ngoPhone,
    required int eta,
  }) async {
    try {
      // Update the main SOS alert status and details
      await _repository.updateSosAlert(sosId, {
        'status': 'responding',
        'respondingNgoId': ngoId,
        'respondingNgoName': ngoName,
        'ngoPhone': ngoPhone,
        'respondedAt': DateTime.now(),
        'estimatedArrival': eta,
        'ngoLatitude': _currentPosition?.latitude,
        'ngoLongitude': _currentPosition?.longitude,
        'ngoAddress': _currentAddress,
      });

      // Fetch the SOS record to notify nearby volunteers about the response
      final alertStream = _repository.streamSosAlert(sosId);
      final alert = await alertStream.first;
      if (alert != null) {
        await _repository.createSosNotification(
          sosId: sosId,
          emergencyType: alert.emergencyType,
          address: alert.address,
          latitude: alert.latitude ?? 0.0,
          longitude: alert.longitude ?? 0.0,
          volunteerInNeedId: alert.odid,
          volunteerInNeedName: alert.odname,
          respondingNgoName: ngoName,
          targetType: 'volunteer',
        );
      }
    } catch (e) {
      debugPrint('Error responding to SOS: $e');
      rethrow;
    }
  }

  /// Update volunteer live location in Firestore during active tracking
  Future<void> updateVolunteerLiveLocation(String sosId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _repository.updateVolunteerLocation(sosId, position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error updating volunteer live tracking location: $e');
    }
  }

  /// Update NGO live location in Firestore during active response tracking
  Future<void> updateNgoLiveLocation(String sosId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _repository.updateNgoLocation(sosId, position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error updating NGO live tracking location: $e');
    }
  }

  /// Load safety contacts list for the volunteer
  Future<void> loadEmergencyContacts(String volunteerId) async {
    _isLoadingContacts = true;
    notifyListeners();

    try {
      _emergencyContacts = await _repository.getEmergencyContacts(volunteerId);
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  /// Add emergency contact for safety helpline
  Future<void> addEmergencyContact(String volunteerId, String name, String phone) async {
    try {
      final contact = EmergencyContact(name: name, phone: phone);
      await _repository.addEmergencyContact(volunteerId, contact);
      await loadEmergencyContacts(volunteerId);
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      rethrow;
    }
  }

  /// Remove emergency contact from safety list
  Future<void> removeEmergencyContact(String volunteerId, EmergencyContact contact) async {
    try {
      await _repository.removeEmergencyContact(volunteerId, contact);
      await loadEmergencyContacts(volunteerId);
    } catch (e) {
      debugPrint('Error removing emergency contact: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
