import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage local storage for app state
class LocalStorageService {
  static const String _pendingRegistrationIdKey = 'pending_ngo_registration_id';
  static const String _registrationStatusKey = 'ngo_registration_status';
  static const String _ngoLoginIdKey = 'ngo_login_id';
  static const String _ngoLoginNameKey = 'ngo_login_name';
  static const String _isNgoLoggedInKey = 'is_ngo_logged_in';
  
  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final _secureStorage = const FlutterSecureStorage();

  /// Save pending NGO registration ID when form is submitted
  Future<void> savePendingRegistration(String registrationId) async {
    await _secureStorage.write(key: _pendingRegistrationIdKey, value: registrationId);
    await _secureStorage.write(key: _registrationStatusKey, value: 'pending');
    secureLog('LocalStorage: Saved pending registration ID: $registrationId');
  }

  /// Get pending registration ID if exists
  Future<String?> getPendingRegistrationId() async {
    final id = await _secureStorage.read(key: _pendingRegistrationIdKey);
    secureLog('LocalStorage: Retrieved registration ID: $id');
    return id;
  }

  /// Get registration status
  Future<String?> getRegistrationStatus() async {
    return await _secureStorage.read(key: _registrationStatusKey);
  }

  /// Update registration status
  Future<void> updateRegistrationStatus(String status) async {
    await _secureStorage.write(key: _registrationStatusKey, value: status);
    secureLog('LocalStorage: Updated registration status to: $status');
  }

  /// Check if there's a pending registration
  Future<bool> hasPendingRegistration() async {
    final id = await getPendingRegistrationId();
    final status = await getRegistrationStatus();
    return id != null && id.isNotEmpty && status == 'pending';
  }

  /// Clear registration data (when approved/rejected and user acknowledges)
  Future<void> clearRegistrationData() async {
    await _secureStorage.delete(key: _pendingRegistrationIdKey);
    await _secureStorage.delete(key: _registrationStatusKey);
    secureLog('LocalStorage: Cleared registration data');
  }

  /// Mark registration as approved (user can now access the app)
  Future<void> markAsApproved() async {
    await _secureStorage.write(key: _registrationStatusKey, value: 'approved');
    secureLog('LocalStorage: Marked registration as approved');
  }

  /// Mark registration as rejected (user needs to register again)
  Future<void> markAsRejected() async {
    await _secureStorage.write(key: _registrationStatusKey, value: 'rejected');
    secureLog('LocalStorage: Marked registration as rejected');
  }

  /// Save NGO login state
  Future<void> saveNgoLogin(String registrationId, String ngoName) async {
    await _secureStorage.write(key: _ngoLoginIdKey, value: registrationId);
    await _secureStorage.write(key: _ngoLoginNameKey, value: ngoName);
    await _secureStorage.write(key: _isNgoLoggedInKey, value: 'true');
    secureLog('LocalStorage: Saved NGO login - ID: $registrationId, Name: $ngoName');
  }

  /// Check if NGO is logged in
  Future<bool> isNgoLoggedIn() async {
    final value = await _secureStorage.read(key: _isNgoLoggedInKey);
    return value == 'true';
  }

  /// Get logged in NGO ID
  Future<String?> getLoggedInNgoId() async {
    return await _secureStorage.read(key: _ngoLoginIdKey);
  }

  /// Get logged in NGO name
  Future<String?> getLoggedInNgoName() async {
    return await _secureStorage.read(key: _ngoLoginNameKey);
  }

  /// Clear NGO login state
  Future<void> clearNgoLogin() async {
    await _secureStorage.delete(key: _ngoLoginIdKey);
    await _secureStorage.delete(key: _ngoLoginNameKey);
    await _secureStorage.write(key: _isNgoLoggedInKey, value: 'false');
    await clearRegistrationData();
    secureLog('LocalStorage: Cleared NGO login');
  }
}
