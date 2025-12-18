import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Remote Config
/// 
/// This service allows you to change app behavior and appearance
/// without publishing an app update, by changing server-side parameter values.
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode 
            ? const Duration(minutes: 5)  // Shorter interval for debugging
            : const Duration(hours: 12),  // Production interval
      ));

      // Set default values
      await _remoteConfig.setDefaults(_defaultValues);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      debugPrint('🔥 Remote Config initialized');
      debugPrint('   - Featured Campaign: $featuredCampaignId');
      debugPrint('   - Maintenance Mode: $isMaintenanceMode');
    } catch (e) {
      debugPrint('❌ Remote Config initialization failed: $e');
    }
  }

  /// Default values for Remote Config parameters
  static const Map<String, dynamic> _defaultValues = {
    // Feature Flags
    'feature_sos_enabled': true,
    'feature_donations_enabled': true,
    'feature_volunteer_enabled': true,
    'feature_community_enabled': true,
    'feature_csr_enabled': true,
    
    // App Settings
    'maintenance_mode': false,
    'maintenance_message': 'We are currently performing maintenance. Please try again later.',
    'force_update_version': '0.0.0',
    'recommended_update_version': '0.0.0',
    
    // Campaign Settings
    'featured_campaign_id': '',
    'featured_campaign_priority': 0,
    'donation_minimum_amount': 10,
    'donation_suggested_amounts': '100,500,1000,5000',
    
    // Emergency Settings
    'sos_cooldown_minutes': 5,
    'sos_max_alerts_per_day': 10,
    'emergency_helpline_numbers': '112,100,108',
    
    // UI Customization
    'home_banner_text': '',
    'home_banner_color': '#0099B8',
    'home_banner_enabled': false,
    
    // API Settings
    'api_timeout_seconds': 30,
    'max_upload_size_mb': 10,
  };

  /// Fetch latest values from server
  Future<bool> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      debugPrint('🔥 Remote Config fetched and activated: $activated');
      return activated;
    } catch (e) {
      debugPrint('❌ Remote Config fetch failed: $e');
      return false;
    }
  }

  // ==================== Feature Flags ====================

  /// Check if SOS feature is enabled
  bool get isSOSEnabled => _remoteConfig.getBool('feature_sos_enabled');

  /// Check if donations feature is enabled
  bool get isDonationsEnabled => _remoteConfig.getBool('feature_donations_enabled');

  /// Check if volunteer feature is enabled
  bool get isVolunteerEnabled => _remoteConfig.getBool('feature_volunteer_enabled');

  /// Check if community feature is enabled
  bool get isCommunityEnabled => _remoteConfig.getBool('feature_community_enabled');

  /// Check if CSR feature is enabled
  bool get isCSREnabled => _remoteConfig.getBool('feature_csr_enabled');

  // ==================== App Settings ====================

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode => _remoteConfig.getBool('maintenance_mode');

  /// Get maintenance message
  String get maintenanceMessage => _remoteConfig.getString('maintenance_message');

  /// Get force update version
  String get forceUpdateVersion => _remoteConfig.getString('force_update_version');

  /// Get recommended update version
  String get recommendedUpdateVersion => _remoteConfig.getString('recommended_update_version');

  // ==================== Campaign Settings ====================

  /// Get featured campaign ID
  String get featuredCampaignId => _remoteConfig.getString('featured_campaign_id');

  /// Get minimum donation amount
  int get donationMinimumAmount => _remoteConfig.getInt('donation_minimum_amount');

  /// Get suggested donation amounts as list
  List<int> get donationSuggestedAmounts {
    final amounts = _remoteConfig.getString('donation_suggested_amounts');
    return amounts.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();
  }

  // ==================== Emergency Settings ====================

  /// Get SOS cooldown in minutes
  int get sosCooldownMinutes => _remoteConfig.getInt('sos_cooldown_minutes');

  /// Get max SOS alerts per day
  int get sosMaxAlertsPerDay => _remoteConfig.getInt('sos_max_alerts_per_day');

  /// Get emergency helpline numbers
  List<String> get emergencyHelplineNumbers {
    final numbers = _remoteConfig.getString('emergency_helpline_numbers');
    return numbers.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  // ==================== UI Customization ====================

  /// Check if home banner is enabled
  bool get isHomeBannerEnabled => _remoteConfig.getBool('home_banner_enabled');

  /// Get home banner text
  String get homeBannerText => _remoteConfig.getString('home_banner_text');

  /// Get home banner color
  String get homeBannerColor => _remoteConfig.getString('home_banner_color');

  // ==================== API Settings ====================

  /// Get API timeout in seconds
  int get apiTimeoutSeconds => _remoteConfig.getInt('api_timeout_seconds');

  /// Get max upload size in MB
  int get maxUploadSizeMB => _remoteConfig.getInt('max_upload_size_mb');

  // ==================== Helper Methods ====================

  /// Get any string value
  String getString(String key) => _remoteConfig.getString(key);

  /// Get any bool value
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// Get any int value
  int getInt(String key) => _remoteConfig.getInt(key);

  /// Get any double value
  double getDouble(String key) => _remoteConfig.getDouble(key);

  /// Check if a feature flag is enabled
  bool isFeatureEnabled(String featureKey) => _remoteConfig.getBool(featureKey);

  /// Add listener for config updates
  void addOnConfigUpdatedListener(Function() onUpdate) {
    _remoteConfig.onConfigUpdated.listen((event) {
      _remoteConfig.activate().then((_) => onUpdate());
    });
  }
}
