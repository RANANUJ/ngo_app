import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Connect & Contribute'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @myFeed.
  ///
  /// In en, this message translates to:
  /// **'My Feed'**
  String get myFeed;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @liveEvents.
  ///
  /// In en, this message translates to:
  /// **'Live Events'**
  String get liveEvents;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @sosAlert.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert'**
  String get sosAlert;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @discoverNGO.
  ///
  /// In en, this message translates to:
  /// **'Discover NGO'**
  String get discoverNGO;

  /// No description provided for @volunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get volunteer;

  /// No description provided for @govtProg.
  ///
  /// In en, this message translates to:
  /// **'Govt Prog.'**
  String get govtProg;

  /// No description provided for @donationNow.
  ///
  /// In en, this message translates to:
  /// **'Donation Now'**
  String get donationNow;

  /// No description provided for @csrIntegration.
  ///
  /// In en, this message translates to:
  /// **'CSR Integration'**
  String get csrIntegration;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @eventsJoined.
  ///
  /// In en, this message translates to:
  /// **'Events Joined'**
  String get eventsJoined;

  /// No description provided for @ngosFollowed.
  ///
  /// In en, this message translates to:
  /// **'NGOs Followed'**
  String get ngosFollowed;

  /// No description provided for @totalDonated.
  ///
  /// In en, this message translates to:
  /// **'Total Donated'**
  String get totalDonated;

  /// No description provided for @hoursVolunteered.
  ///
  /// In en, this message translates to:
  /// **'Hours Volunteered'**
  String get hoursVolunteered;

  /// No description provided for @campaignsJoined.
  ///
  /// In en, this message translates to:
  /// **'Campaigns Joined'**
  String get campaignsJoined;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @myCampaigns.
  ///
  /// In en, this message translates to:
  /// **'My Campaigns'**
  String get myCampaigns;

  /// No description provided for @donationHistory.
  ///
  /// In en, this message translates to:
  /// **'Donation History'**
  String get donationHistory;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @savedNGOs.
  ///
  /// In en, this message translates to:
  /// **'Saved NGOs'**
  String get savedNGOs;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @showProfile.
  ///
  /// In en, this message translates to:
  /// **'Show Profile'**
  String get showProfile;

  /// No description provided for @showProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow others to view your profile'**
  String get showProfileDesc;

  /// No description provided for @showActivity.
  ///
  /// In en, this message translates to:
  /// **'Show Activity'**
  String get showActivity;

  /// No description provided for @showActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Show your activity to others'**
  String get showActivityDesc;

  /// No description provided for @allowMessages.
  ///
  /// In en, this message translates to:
  /// **'Allow Messages'**
  String get allowMessages;

  /// No description provided for @allowMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Let others send you messages'**
  String get allowMessagesDesc;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get darkModeDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get changePasswordDesc;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get downloadMyData;

  /// No description provided for @downloadMyDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Export your personal data'**
  String get downloadMyDataDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountDesc;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon!'**
  String comingSoonMessage(String feature);

  /// No description provided for @campaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaigns;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donations;

  /// No description provided for @volunteers.
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get volunteers;

  /// No description provided for @impact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impact;

  /// No description provided for @createCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get createCampaign;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @sendSOS.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sendSOS;

  /// No description provided for @viewSOSAlerts.
  ///
  /// In en, this message translates to:
  /// **'View SOS Alerts'**
  String get viewSOSAlerts;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @ngoName.
  ///
  /// In en, this message translates to:
  /// **'NGO Name'**
  String get ngoName;

  /// No description provided for @campaignName.
  ///
  /// In en, this message translates to:
  /// **'Campaign Name'**
  String get campaignName;

  /// No description provided for @eventName.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venue;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @donateNow.
  ///
  /// In en, this message translates to:
  /// **'Donate Now'**
  String get donateNow;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @thankyou.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thankyou;

  /// No description provided for @donationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your donation was successful'**
  String get donationSuccess;

  /// No description provided for @donationFailed.
  ///
  /// In en, this message translates to:
  /// **'Donation failed. Please try again.'**
  String get donationFailed;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @postUpdate.
  ///
  /// In en, this message translates to:
  /// **'Post Update'**
  String get postUpdate;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload successful'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get readLess;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated successfully'**
  String get photoUpdated;

  /// No description provided for @photoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo'**
  String get photoUpdateFailed;

  /// No description provided for @readyToMakeDifference.
  ///
  /// In en, this message translates to:
  /// **'Ready to make in difference'**
  String get readyToMakeDifference;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @reportHelp.
  ///
  /// In en, this message translates to:
  /// **'Report Help'**
  String get reportHelp;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @opportunities.
  ///
  /// In en, this message translates to:
  /// **'Opportunities'**
  String get opportunities;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @cause.
  ///
  /// In en, this message translates to:
  /// **'Cause'**
  String get cause;

  /// No description provided for @needs.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get needs;

  /// No description provided for @yourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your Impact'**
  String get yourImpact;

  /// No description provided for @greatJobCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Great job! You\'ve joined {count} campaign so far.'**
  String greatJobCampaigns(int count);

  /// No description provided for @percentToNextBadge.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to next badge'**
  String percentToNextBadge(int percent);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'DONATION'**
  String get donation;

  /// No description provided for @internationalNGODay.
  ///
  /// In en, this message translates to:
  /// **'INTERNATIONAL NGO DAY'**
  String get internationalNGODay;

  /// No description provided for @internationalNGODayDesc.
  ///
  /// In en, this message translates to:
  /// **'Let\'s remember the power of a single person to change a child\'s life.'**
  String get internationalNGODayDesc;

  /// No description provided for @jobIntern.
  ///
  /// In en, this message translates to:
  /// **'Job / Intern'**
  String get jobIntern;

  /// No description provided for @monthlyGiving.
  ///
  /// In en, this message translates to:
  /// **'Monthly Giving'**
  String get monthlyGiving;

  /// No description provided for @volunteers_count.
  ///
  /// In en, this message translates to:
  /// **'{count} volunteers'**
  String volunteers_count(int count);

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @flexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexible;

  /// No description provided for @needed.
  ///
  /// In en, this message translates to:
  /// **'needed'**
  String get needed;

  /// No description provided for @animalWelfare.
  ///
  /// In en, this message translates to:
  /// **'Animal Welfare'**
  String get animalWelfare;

  /// No description provided for @teachingSlumKids.
  ///
  /// In en, this message translates to:
  /// **'Teaching slum kids'**
  String get teachingSlumKids;

  /// No description provided for @womenEmpowerment.
  ///
  /// In en, this message translates to:
  /// **'Women Empowerment'**
  String get womenEmpowerment;

  /// No description provided for @elderlyCare.
  ///
  /// In en, this message translates to:
  /// **'Elderly Care'**
  String get elderlyCare;

  /// No description provided for @environmentProtection.
  ///
  /// In en, this message translates to:
  /// **'Environment Protection'**
  String get environmentProtection;

  /// No description provided for @healthCare.
  ///
  /// In en, this message translates to:
  /// **'Health Care'**
  String get healthCare;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @childWelfare.
  ///
  /// In en, this message translates to:
  /// **'Child Welfare'**
  String get childWelfare;

  /// No description provided for @disasterRelief.
  ///
  /// In en, this message translates to:
  /// **'Disaster Relief'**
  String get disasterRelief;

  /// No description provided for @povertyAlleviation.
  ///
  /// In en, this message translates to:
  /// **'Poverty Alleviation'**
  String get povertyAlleviation;

  /// No description provided for @startYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey by joining a campaign!'**
  String get startYourJourney;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @noOpportunitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No opportunities found'**
  String get noOpportunitiesFound;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new opportunities'**
  String get checkBackLater;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get pleaseLogin;

  /// No description provided for @loginToSeeSentRequests.
  ///
  /// In en, this message translates to:
  /// **'Login to see your sent requests'**
  String get loginToSeeSentRequests;

  /// No description provided for @noSentRequests.
  ///
  /// In en, this message translates to:
  /// **'No sent requests'**
  String get noSentRequests;

  /// No description provided for @appliedOpportunitiesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your applied opportunities will appear here'**
  String get appliedOpportunitiesAppearHere;

  /// No description provided for @noAcceptedRequests.
  ///
  /// In en, this message translates to:
  /// **'No accepted requests'**
  String get noAcceptedRequests;

  /// No description provided for @acceptedOpportunitiesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your accepted opportunities will appear here'**
  String get acceptedOpportunitiesAppearHere;

  /// No description provided for @loginToSeeAcceptedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Login to see your accepted opportunities'**
  String get loginToSeeAcceptedOpportunities;

  /// No description provided for @noAcceptedOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No accepted opportunities'**
  String get noAcceptedOpportunities;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get currentMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @donationReq.
  ///
  /// In en, this message translates to:
  /// **'Donation Req'**
  String get donationReq;

  /// No description provided for @shareResource.
  ///
  /// In en, this message translates to:
  /// **'Share Resource'**
  String get shareResource;

  /// No description provided for @shareImpact.
  ///
  /// In en, this message translates to:
  /// **'Share Impact'**
  String get shareImpact;

  /// No description provided for @needsForecasting.
  ///
  /// In en, this message translates to:
  /// **'Needs Forecasting'**
  String get needsForecasting;

  /// No description provided for @viewDonationOpportunities.
  ///
  /// In en, this message translates to:
  /// **'View Donation Opportunities'**
  String get viewDonationOpportunities;

  /// No description provided for @campaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaign;

  /// No description provided for @shortDescriptionOfCampaign.
  ///
  /// In en, this message translates to:
  /// **'Short Description of Campaign'**
  String get shortDescriptionOfCampaign;

  /// No description provided for @joinCampaign.
  ///
  /// In en, this message translates to:
  /// **'Join Campaign'**
  String get joinCampaign;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive email updates'**
  String get receiveEmailUpdates;

  /// No description provided for @campaignUpdates.
  ///
  /// In en, this message translates to:
  /// **'Campaign Updates'**
  String get campaignUpdates;

  /// No description provided for @getNotifiedAboutCampaignUpdates.
  ///
  /// In en, this message translates to:
  /// **'Get notified about campaign updates'**
  String get getNotifiedAboutCampaignUpdates;

  /// No description provided for @eventReminders.
  ///
  /// In en, this message translates to:
  /// **'Event Reminders'**
  String get eventReminders;

  /// No description provided for @receiveRemindersForEvents.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for events'**
  String get receiveRemindersForEvents;

  /// No description provided for @donationReceipts.
  ///
  /// In en, this message translates to:
  /// **'Donation Receipts'**
  String get donationReceipts;

  /// No description provided for @getDonationReceipts.
  ///
  /// In en, this message translates to:
  /// **'Get donation receipts'**
  String get getDonationReceipts;

  /// No description provided for @sosAlerts.
  ///
  /// In en, this message translates to:
  /// **'SOS Alerts'**
  String get sosAlerts;

  /// No description provided for @receiveEmergencySOSAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive emergency SOS alerts'**
  String get receiveEmergencySOSAlerts;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @updateYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updateYourPassword;

  /// No description provided for @exportYourPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Export your personal data'**
  String get exportYourPersonalData;

  /// No description provided for @permanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteYourAccount;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @rateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateTheApp;

  /// No description provided for @connectNGO.
  ///
  /// In en, this message translates to:
  /// **'Connect NGO'**
  String get connectNGO;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String lastUpdated(String date);

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// No description provided for @welcomeToConnectNGO.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Connect NGO. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.'**
  String get welcomeToConnectNGO;

  /// No description provided for @pleaseReadPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.'**
  String get pleaseReadPrivacyPolicy;

  /// No description provided for @informationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get informationWeCollect;

  /// No description provided for @weCollectInformation.
  ///
  /// In en, this message translates to:
  /// **'We collect information that you provide directly to us, including:'**
  String get weCollectInformation;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @personalInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Personal Information: Name, email address, phone number, location, profile photo'**
  String get personalInfoDesc;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @accountInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Account Information: Login credentials, preferences, settings'**
  String get accountInfoDesc;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get pushNotificationsDesc;

  /// No description provided for @emailNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive email updates'**
  String get emailNotificationsDesc;

  /// No description provided for @campaignUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about campaign updates'**
  String get campaignUpdatesDesc;

  /// No description provided for @eventRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for events'**
  String get eventRemindersDesc;

  /// No description provided for @donationReceiptsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get donation receipts'**
  String get donationReceiptsDesc;

  /// No description provided for @sosAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive emergency SOS alerts'**
  String get sosAlertsDesc;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @visitUs.
  ///
  /// In en, this message translates to:
  /// **'Visit Us'**
  String get visitUs;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @howDoIRegisterAsVolunteer.
  ///
  /// In en, this message translates to:
  /// **'How do I register as a volunteer?'**
  String get howDoIRegisterAsVolunteer;

  /// No description provided for @howDoIMakeDonation.
  ///
  /// In en, this message translates to:
  /// **'How do I make a donation?'**
  String get howDoIMakeDonation;

  /// No description provided for @howDoIJoinCampaign.
  ///
  /// In en, this message translates to:
  /// **'How do I join a campaign?'**
  String get howDoIJoinCampaign;

  /// No description provided for @howDoIUseSOSFeature.
  ///
  /// In en, this message translates to:
  /// **'How do I use the SOS feature?'**
  String get howDoIUseSOSFeature;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
