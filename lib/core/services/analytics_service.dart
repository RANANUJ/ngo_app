import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive Firebase Analytics Service
/// 
/// This service provides methods for logging events, user properties,
/// and tracking user behavior to populate all Firebase Analytics features:
/// - Dashboard, Realtime Analytics, Events, DebugView, Audiences, etc.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get the analytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ==================== INITIALIZATION ====================

  /// Initialize analytics with user context
  Future<void> initialize({String? userId, String? userType}) async {
    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(true);
    
    // Set default event parameters for all events
    await _analytics.setDefaultEventParameters({
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
    });

    // Set user properties if provided
    if (userId != null) {
      await setUserId(userId);
    }
    if (userType != null) {
      await setUserType(userType);
    }

    debugPrint('📊 Analytics initialized');
  }

  // ==================== USER PROPERTIES (Custom Definitions) ====================

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user type (volunteer, ngo, donor, admin)
  Future<void> setUserType(String userType) async {
    await _analytics.setUserProperty(name: 'user_type', value: userType);
  }

  /// Set user's preferred language
  Future<void> setUserLanguage(String language) async {
    await _analytics.setUserProperty(name: 'preferred_language', value: language);
  }

  /// Set user's location/city
  Future<void> setUserCity(String city) async {
    await _analytics.setUserProperty(name: 'user_city', value: city);
  }

  /// Set registration complete status
  Future<void> setRegistrationComplete(bool complete) async {
    await _analytics.setUserProperty(
      name: 'registration_complete',
      value: complete ? 'true' : 'false',
    );
  }

  /// Set NGO ID for NGO users
  Future<void> setNgoId(String ngoId) async {
    await _analytics.setUserProperty(name: 'ngo_id', value: ngoId);
  }

  /// Set total donations count
  Future<void> setTotalDonations(int count) async {
    await _analytics.setUserProperty(name: 'total_donations', value: count.toString());
  }

  /// Set volunteer hours
  Future<void> setVolunteerHours(int hours) async {
    await _analytics.setUserProperty(name: 'volunteer_hours', value: hours.toString());
  }

  // ==================== STANDARD EVENTS ====================

  /// Log app open
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// Log user login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log user signup
  Future<void> logSignup(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(screenName: screenName, screenClass: screenClass);
  }

  /// Log search
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  /// Log share action
  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method ?? 'share',
    );
  }

  /// Log select content
  Future<void> logSelectContent({required String contentType, required String itemId}) async {
    await _analytics.logSelectContent(contentType: contentType, itemId: itemId);
  }

  // ==================== DONATION EVENTS (E-Commerce) ====================

  /// Log donation started
  Future<void> logDonationStarted({
    required String campaignId,
    required String campaignName,
    required double amount,
  }) async {
    await _analytics.logAddToCart(
      currency: 'INR',
      value: amount,
      items: [AnalyticsEventItem(itemId: campaignId, itemName: campaignName, itemCategory: 'donation', price: amount, quantity: 1)],
    );
  }

  /// Log donation checkout
  Future<void> logDonationCheckout({
    required String campaignId,
    required String campaignName,
    required double amount,
  }) async {
    await _analytics.logBeginCheckout(
      currency: 'INR',
      value: amount,
      items: [AnalyticsEventItem(itemId: campaignId, itemName: campaignName, itemCategory: 'donation', price: amount, quantity: 1)],
    );
  }

  /// Log donation completed (shows in revenue)
  Future<void> logDonationCompleted({
    required String transactionId,
    required String campaignId,
    required String campaignName,
    required double amount,
    String? ngoId,
    String? ngoName,
  }) async {
    await _analytics.logPurchase(
      transactionId: transactionId,
      currency: 'INR',
      value: amount,
      items: [AnalyticsEventItem(itemId: campaignId, itemName: campaignName, itemCategory: 'donation', price: amount, quantity: 1, affiliation: ngoName)],
    );
    await _analytics.logEvent(name: 'donation_completed', parameters: {
      'transaction_id': transactionId,
      'campaign_id': campaignId,
      'amount': amount,
      if (ngoId != null) 'ngo_id': ngoId,
    });
  }

  /// Log donation failed
  Future<void> logDonationFailed({required String campaignId, required double amount, required String error}) async {
    await _analytics.logEvent(name: 'donation_failed', parameters: {'campaign_id': campaignId, 'amount': amount, 'error': error});
  }

  // ==================== CAMPAIGN EVENTS ====================

  /// Log campaign view
  Future<void> logCampaignView(String campaignId, String campaignName) async {
    await _analytics.logViewItem(
      currency: 'INR',
      value: 0,
      items: [AnalyticsEventItem(itemId: campaignId, itemName: campaignName, itemCategory: 'campaign')],
    );
  }

  /// Log campaign list view
  Future<void> logCampaignListView(List<Map<String, String>> campaigns) async {
    await _analytics.logViewItemList(
      itemListId: 'campaigns',
      itemListName: 'Campaign List',
      items: campaigns.map((c) => AnalyticsEventItem(itemId: c['id'] ?? '', itemName: c['name'] ?? '', itemCategory: 'campaign')).toList(),
    );
  }

  // ==================== VOLUNTEER EVENTS ====================

  /// Log volunteer registration
  Future<void> logVolunteerRegistration({required String eventId, required String eventName, String? ngoId}) async {
    await _analytics.logEvent(name: 'volunteer_registration', parameters: {'event_id': eventId, 'event_name': eventName, if (ngoId != null) 'ngo_id': ngoId});
  }

  /// Log volunteer check-in
  Future<void> logVolunteerCheckIn(String eventId) async {
    await _analytics.logEvent(name: 'volunteer_check_in', parameters: {'event_id': eventId});
  }

  /// Log volunteer hours completed
  Future<void> logVolunteerHoursCompleted({required String eventId, required int hours}) async {
    await _analytics.logEvent(name: 'volunteer_hours_completed', parameters: {'event_id': eventId, 'hours': hours});
  }

  // ==================== SOS/EMERGENCY EVENTS ====================

  /// Log SOS alert triggered
  Future<void> logSOSAlert({required String alertType, String? location}) async {
    await _analytics.logEvent(name: 'sos_alert_triggered', parameters: {'alert_type': alertType, if (location != null) 'location': location});
  }

  /// Log SOS resolved
  Future<void> logSOSResolved(String alertId) async {
    await _analytics.logEvent(name: 'sos_alert_resolved', parameters: {'alert_id': alertId});
  }

  // ==================== COMMUNITY EVENTS ====================

  /// Log post created
  Future<void> logPostCreated(String postType) async {
    await _analytics.logEvent(name: 'post_created', parameters: {'post_type': postType});
  }

  /// Log post viewed
  Future<void> logPostViewed(String postId) async {
    await _analytics.logEvent(name: 'post_viewed', parameters: {'post_id': postId});
  }

  /// Log post liked
  Future<void> logPostLiked(String postId) async {
    await _analytics.logEvent(name: 'post_liked', parameters: {'post_id': postId});
  }

  /// Log post commented
  Future<void> logPostCommented(String postId) async {
    await _analytics.logEvent(name: 'post_commented', parameters: {'post_id': postId});
  }

  // ==================== NGO EVENTS ====================

  /// Log NGO profile viewed
  Future<void> logNGOProfileView(String ngoId, String ngoName) async {
    await _analytics.logEvent(name: 'ngo_profile_view', parameters: {'ngo_id': ngoId, 'ngo_name': ngoName});
  }

  /// Log NGO followed
  Future<void> logNGOFollowed(String ngoId) async {
    await _analytics.logEvent(name: 'ngo_followed', parameters: {'ngo_id': ngoId});
  }

  // ==================== SCHEME EVENTS ====================

  /// Log scheme view
  Future<void> logSchemeView(String schemeId, String schemeName) async {
    await _analytics.logEvent(name: 'scheme_view', parameters: {'scheme_id': schemeId, 'scheme_name': schemeName});
  }

  /// Log scheme application
  Future<void> logSchemeApplication(String schemeId) async {
    await _analytics.logEvent(name: 'scheme_application', parameters: {'scheme_id': schemeId});
  }

  // ==================== ENGAGEMENT EVENTS ====================

  /// Log notification received
  Future<void> logNotificationReceived(String type) async {
    await _analytics.logEvent(name: 'notification_received', parameters: {'type': type});
  }

  /// Log notification opened
  Future<void> logNotificationOpened(String type) async {
    await _analytics.logEvent(name: 'notification_opened', parameters: {'type': type});
  }

  /// Log feature used
  Future<void> logFeatureUsed(String feature) async {
    await _analytics.logEvent(name: 'feature_used', parameters: {'feature': feature});
  }

  /// Log error
  Future<void> logError({required String errorType, required String message, String? screen}) async {
    await _analytics.logEvent(name: 'app_error', parameters: {
      'error_type': errorType,
      'message': message.length > 100 ? message.substring(0, 100) : message,
      if (screen != null) 'screen': screen,
    });
  }

  /// Log custom event
  Future<void> logCustomEvent(String eventName, Map<String, Object>? parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }

  /// Reset analytics data (for logout)
  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }
}
