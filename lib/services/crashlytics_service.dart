import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Crashlytics
/// 
/// This service provides crash reporting and error tracking capabilities
/// to help monitor app stability and quickly identify issues.
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  Future<void> initialize() async {
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable crashlytics collection (enabled for all modes including debug)
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    debugPrint('🔥 Crashlytics initialized and enabled');
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Set custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Record a Flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    _crashlytics.recordFlutterError(details);
  }

  /// Force a crash (for testing purposes only)
  void testCrash() {
    _crashlytics.crash();
  }

  /// Set user properties for better crash context
  Future<void> setUserProperties({
    String? email,
    String? userType,
    String? ngoId,
  }) async {
    if (email != null) {
      await _crashlytics.setCustomKey('user_email', email);
    }
    if (userType != null) {
      await _crashlytics.setCustomKey('user_type', userType);
    }
    if (ngoId != null) {
      await _crashlytics.setCustomKey('ngo_id', ngoId);
    }
  }

  /// Log donation flow for crash context
  Future<void> logDonationFlow(String step, {String? campaignId}) async {
    await _crashlytics.log('Donation flow: $step');
    if (campaignId != null) {
      await _crashlytics.setCustomKey('last_campaign_id', campaignId);
    }
  }

  /// Log SOS alert for crash context
  Future<void> logSOSFlow(String step) async {
    await _crashlytics.log('SOS flow: $step');
    await _crashlytics.setCustomKey('sos_active', true);
  }
}
