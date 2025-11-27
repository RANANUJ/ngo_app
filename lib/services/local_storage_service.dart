import 'package:shared_preferences/shared_preferences.dart';

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

  /// Save pending NGO registration ID when form is submitted
  Future<void> savePendingRegistration(String registrationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingRegistrationIdKey, registrationId);
    await prefs.setString(_registrationStatusKey, 'pending');
    print('LocalStorage: Saved pending registration ID: $registrationId');
  }

  /// Get pending registration ID if exists
  Future<String?> getPendingRegistrationId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_pendingRegistrationIdKey);
    print('LocalStorage: Retrieved registration ID: $id');
    return id;
  }

  /// Get registration status
  Future<String?> getRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registrationStatusKey);
  }

  /// Update registration status
  Future<void> updateRegistrationStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registrationStatusKey, status);
    print('LocalStorage: Updated registration status to: $status');
  }

  /// Check if there's a pending registration
  Future<bool> hasPendingRegistration() async {
    final id = await getPendingRegistrationId();
    final status = await getRegistrationStatus();
    return id != null && id.isNotEmpty && status == 'pending';
  }

  /// Clear registration data (when approved/rejected and user acknowledges)
  Future<void> clearRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingRegistrationIdKey);
    await prefs.remove(_registrationStatusKey);
    print('LocalStorage: Cleared registration data');
  }

  /// Mark registration as approved (user can now access the app)
  Future<void> markAsApproved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registrationStatusKey, 'approved');
    print('LocalStorage: Marked registration as approved');
  }

  /// Mark registration as rejected (user needs to register again)
  Future<void> markAsRejected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registrationStatusKey, 'rejected');
    print('LocalStorage: Marked registration as rejected');
  }

  /// Save NGO login state
  Future<void> saveNgoLogin(String registrationId, String ngoName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ngoLoginIdKey, registrationId);
    await prefs.setString(_ngoLoginNameKey, ngoName);
    await prefs.setBool(_isNgoLoggedInKey, true);
    print('LocalStorage: Saved NGO login - ID: $registrationId, Name: $ngoName');
  }

  /// Check if NGO is logged in
  Future<bool> isNgoLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isNgoLoggedInKey) ?? false;
  }

  /// Get logged in NGO ID
  Future<String?> getLoggedInNgoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ngoLoginIdKey);
  }

  /// Get logged in NGO name
  Future<String?> getLoggedInNgoName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ngoLoginNameKey);
  }

  /// Clear NGO login state
  Future<void> clearNgoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ngoLoginIdKey);
    await prefs.remove(_ngoLoginNameKey);
    await prefs.setBool(_isNgoLoggedInKey, false);
    await clearRegistrationData();
    print('LocalStorage: Cleared NGO login');
  }
}
