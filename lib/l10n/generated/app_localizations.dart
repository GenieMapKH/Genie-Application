import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('km'),
  ];

  /// No description provided for @callInProgress.
  ///
  /// In en, this message translates to:
  /// **'Call in progress'**
  String get callInProgress;

  /// No description provided for @chatManagedSecurity.
  ///
  /// In en, this message translates to:
  /// **'Messages are encrypted when sent and stored.'**
  String get chatManagedSecurity;

  /// No description provided for @callMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize call'**
  String get callMinimize;

  /// No description provided for @callReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get callReturn;

  /// No description provided for @propertyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get propertyUnavailable;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get commonTooManyAttempts;

  /// No description provided for @commonOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Connect for updates.'**
  String get commonOffline;

  /// No description provided for @connectionOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get connectionOffline;

  /// No description provided for @connectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for network…'**
  String get connectionWaiting;

  /// No description provided for @connectionWeak.
  ///
  /// In en, this message translates to:
  /// **'Slow connection'**
  String get connectionWeak;

  /// No description provided for @connectionWeakDetail.
  ///
  /// In en, this message translates to:
  /// **'Loading may take longer'**
  String get connectionWeakDetail;

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get connectionRestored;

  /// No description provided for @loadFailureOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get loadFailureOfflineTitle;

  /// No description provided for @loadFailureOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet. This page will reload when you reconnect.'**
  String get loadFailureOfflineBody;

  /// No description provided for @loadFailureSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Your connection is too slow'**
  String get loadFailureSlowTitle;

  /// No description provided for @loadFailureSlowBody.
  ///
  /// In en, this message translates to:
  /// **'Loading took too long. Check your connection and retry.'**
  String get loadFailureSlowBody;

  /// No description provided for @loadFailureServerBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again shortly.'**
  String get loadFailureServerBody;

  /// No description provided for @failureOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your Wi-Fi or mobile data and try again.'**
  String get failureOffline;

  /// No description provided for @failureSlow.
  ///
  /// In en, this message translates to:
  /// **'Your connection is too slow. Move to a better spot and try again.'**
  String get failureSlow;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again shortly.'**
  String get failureServer;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navMyProperties.
  ///
  /// In en, this message translates to:
  /// **'My Properties'**
  String get navMyProperties;

  /// No description provided for @navListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get navListings;

  /// No description provided for @navUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get navUser;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Required'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up to continue.'**
  String get loginRequiredMessage;

  /// No description provided for @loginRequiredAction.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up'**
  String get loginRequiredAction;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get accountLoadFailed;

  /// No description provided for @accountSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionAccount;

  /// No description provided for @accountSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get accountSectionPreferences;

  /// No description provided for @accountSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get accountSectionMore;

  /// No description provided for @accountPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get accountPersonalInfo;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountSecurity;

  /// No description provided for @accountAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountAppearance;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & cookies'**
  String get accountPrivacy;

  /// No description provided for @accountSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get accountSubscription;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountDefaultName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get accountDefaultName;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get avatarTakePhoto;

  /// No description provided for @avatarChooseFromStorage.
  ///
  /// In en, this message translates to:
  /// **'Choose from storage'**
  String get avatarChooseFromStorage;

  /// No description provided for @avatarSyncFromGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sync from Google Account'**
  String get avatarSyncFromGoogle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @glassNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation theme'**
  String get glassNavigationTitle;

  /// No description provided for @glassNavigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your phone\'s see-through bars'**
  String get glassNavigationSubtitle;

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfoTitle;

  /// No description provided for @personalInfoSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get personalInfoSectionProfile;

  /// No description provided for @personalInfoSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalInfoSectionDetails;

  /// No description provided for @personalInfoSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get personalInfoSectionContact;

  /// No description provided for @personalInfoUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get personalInfoUsername;

  /// No description provided for @personalInfoUsernameHelp.
  ///
  /// In en, this message translates to:
  /// **'People can find you by username. Use 3–30 lowercase letters, numbers, \"_\" or \".\".'**
  String get personalInfoUsernameHelp;

  /// No description provided for @personalInfoUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3 to 30 lowercase letters, numbers, \"_\" or \".\".'**
  String get personalInfoUsernameInvalid;

  /// No description provided for @personalInfoUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get personalInfoUsernameTaken;

  /// No description provided for @personalInfoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personalInfoName;

  /// No description provided for @personalInfoNameHelp.
  ///
  /// In en, this message translates to:
  /// **'The name people see. Change it anytime.'**
  String get personalInfoNameHelp;

  /// No description provided for @personalInfoFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get personalInfoFirstName;

  /// No description provided for @personalInfoLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get personalInfoLastName;

  /// No description provided for @personalInfoSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get personalInfoSex;

  /// No description provided for @personalInfoSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get personalInfoSexMale;

  /// No description provided for @personalInfoSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get personalInfoSexFemale;

  /// No description provided for @personalInfoSexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get personalInfoSexOther;

  /// No description provided for @personalInfoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get personalInfoPhone;

  /// No description provided for @personalInfoPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'For signing in and calls from buyers.'**
  String get personalInfoPhoneHelp;

  /// No description provided for @personalInfoPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already used by another account.'**
  String get personalInfoPhoneTaken;

  /// No description provided for @personalInfoPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number, for example 012 345 678.'**
  String get personalInfoPhoneInvalid;

  /// No description provided for @personalInfoEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get personalInfoEmail;

  /// No description provided for @personalInfoTooLong.
  ///
  /// In en, this message translates to:
  /// **'This is too long.'**
  String get personalInfoTooLong;

  /// Title of the dialog that edits one field, e.g. "Edit Username".
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String personalInfoEdit(String field);

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securitySectionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get securitySectionSignIn;

  /// No description provided for @securitySectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get securitySectionAccount;

  /// No description provided for @securityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securityChangePassword;

  /// No description provided for @securityDevices.
  ///
  /// In en, this message translates to:
  /// **'Logged-in devices'**
  String get securityDevices;

  /// No description provided for @securityRemoveAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate or delete account'**
  String get securityRemoveAccount;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordNew;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get passwordConfirm;

  /// No description provided for @passwordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get passwordCurrentRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from the current one.'**
  String get passwordSameAsCurrent;

  /// No description provided for @passwordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get passwordIncorrect;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Your other devices were signed out.'**
  String get passwordChanged;

  /// No description provided for @passwordIntro.
  ///
  /// In en, this message translates to:
  /// **'Changing your password signs out all other devices.'**
  String get passwordIntro;

  /// No description provided for @devicesIntro.
  ///
  /// In en, this message translates to:
  /// **'Don’t recognise a device? Sign it out and change your password.'**
  String get devicesIntro;

  /// No description provided for @devicesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your devices'**
  String get devicesLoadFailed;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other devices are signed in.'**
  String get devicesEmpty;

  /// No description provided for @devicesThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get devicesThisDevice;

  /// No description provided for @devicesUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get devicesUnknownDevice;

  /// No description provided for @devicesUnknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get devicesUnknownLocation;

  /// No description provided for @devicesActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get devicesActiveNow;

  /// No description provided for @devicesLastUsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last used 1 minute ago} other{Last used {count} minutes ago}}'**
  String devicesLastUsedMinutes(int count);

  /// No description provided for @devicesLastUsedHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last used 1 hour ago} other{Last used {count} hours ago}}'**
  String devicesLastUsedHours(int count);

  /// No description provided for @devicesLastUsedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last used yesterday} other{Last used {count} days ago}}'**
  String devicesLastUsedDays(int count);

  /// No description provided for @devicesSignedInOn.
  ///
  /// In en, this message translates to:
  /// **'Signed in {date}'**
  String devicesSignedInOn(String date);

  /// No description provided for @devicesSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get devicesSignOut;

  /// No description provided for @devicesSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get devicesSignOutAll;

  /// No description provided for @devicesSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out this device?'**
  String get devicesSignOutConfirmTitle;

  /// No description provided for @devicesSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{device} will have to sign in again.'**
  String devicesSignOutConfirmMessage(String device);

  /// No description provided for @devicesSignOutAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices?'**
  String get devicesSignOutAllConfirmTitle;

  /// No description provided for @devicesSignOutAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Every device, including this one, will have to sign in again.'**
  String get devicesSignOutAllConfirmMessage;

  /// No description provided for @devicesSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Device signed out.'**
  String get devicesSignedOut;

  /// No description provided for @devicesSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign the device out. Please try again.'**
  String get devicesSignOutFailed;

  /// No description provided for @removeAccountDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get removeAccountDeactivateTitle;

  /// No description provided for @removeAccountDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'Hide your profile and listings, and sign out everywhere. Sign in to restore them.'**
  String get removeAccountDeactivateBody;

  /// No description provided for @removeAccountDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get removeAccountDeactivateAction;

  /// No description provided for @removeAccountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get removeAccountDeleteTitle;

  /// No description provided for @removeAccountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account, listings, saved properties and chats. This cannot be undone.'**
  String get removeAccountDeleteBody;

  /// No description provided for @removeAccountDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get removeAccountDeleteAction;

  /// No description provided for @removeAccountDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get removeAccountDeleteConfirmAction;

  /// No description provided for @removeAccountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Your account was deactivated.'**
  String get removeAccountDeactivated;

  /// No description provided for @removeAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get removeAccountDeleted;

  /// No description provided for @identityConfirmPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue.'**
  String get identityConfirmPasswordHelp;

  /// No description provided for @identityConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get identityConfirmPassword;

  /// No description provided for @identityConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get identityConfirmPasswordRequired;

  /// No description provided for @identityConfirmPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get identityConfirmPasswordWrong;

  /// No description provided for @identityConfirmWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Google'**
  String get identityConfirmWithGoogle;

  /// No description provided for @identityConfirmGoogleHelp.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your Google account to continue.'**
  String get identityConfirmGoogleHelp;

  /// No description provided for @identityConfirmGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm your Google account. Please try again.'**
  String get identityConfirmGoogleFailed;

  /// No description provided for @identityConfirmOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get identityConfirmOr;

  /// No description provided for @authCreateAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAnAccount;

  /// No description provided for @authAccountCreatedSuccessfullyPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Please login.'**
  String get authAccountCreatedSuccessfullyPleaseLogin;

  /// No description provided for @authSuccessfullyAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Successfully authenticated!'**
  String get authSuccessfullyAuthenticated;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get authForgotPassword;

  /// No description provided for @authEnterYourEmailAddressToGet.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password.'**
  String get authEnterYourEmailAddressToGet;

  /// No description provided for @authPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get authPasswordReset;

  /// No description provided for @authCreateAAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a Account'**
  String get authCreateAAccount;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailAddress;

  /// No description provided for @authExampleGmailCom.
  ///
  /// In en, this message translates to:
  /// **'example@gmail.com'**
  String get authExampleGmailCom;

  /// No description provided for @authVerificationCodeSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email'**
  String get authVerificationCodeSentToYourEmail;

  /// No description provided for @authPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneNumber;

  /// No description provided for @authGetCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get authGetCode;

  /// No description provided for @authPhoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get authPhoneVerified;

  /// No description provided for @authPhoneVerificationExpired.
  ///
  /// In en, this message translates to:
  /// **'Phone verification expired. Get a new code.'**
  String get authPhoneVerificationExpired;

  /// No description provided for @authPhoneVerificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the SMS code. Please try again later.'**
  String get authPhoneVerificationUnavailable;

  /// No description provided for @authVerifyPhoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number before signing up.'**
  String get authVerifyPhoneFirst;

  /// No description provided for @authLoginFailedPleaseCheckYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your details and retry.'**
  String get authLoginFailedPleaseCheckYourCredentials;

  /// No description provided for @authSuccessfullyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in!'**
  String get authSuccessfullyLoggedIn;

  /// No description provided for @authOtpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get authOtpVerification;

  /// No description provided for @authEnterTheVerificationCodeWeJust.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email.'**
  String get authEnterTheVerificationCodeWeJust;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get authResendOtp;

  /// No description provided for @authPleaseEnterAll6Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get authPleaseEnterAll6Digits;

  /// No description provided for @authNewVerificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'New verification code sent'**
  String get authNewVerificationCodeSent;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authEnterYourNewPasswordTwiceBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password twice.'**
  String get authEnterYourNewPasswordTwiceBelow;

  /// No description provided for @authEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get authEnterNewPassword;

  /// No description provided for @authReEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get authReEnterNewPassword;

  /// No description provided for @authPasswordResetSuccessfullyPleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Sign in with your new password.'**
  String get authPasswordResetSuccessfullyPleaseLogIn;

  /// No description provided for @authWelcomeToTheApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the app'**
  String get authWelcomeToTheApp;

  /// No description provided for @authFindAndSharePropertiesWithExact.
  ///
  /// In en, this message translates to:
  /// **'Find and share properties with exact map location'**
  String get authFindAndSharePropertiesWithExact;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authExploreWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Explore without account'**
  String get authExploreWithoutAccount;

  /// No description provided for @authOrSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get authOrSignInWith;

  /// No description provided for @authAlreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAnAccount;

  /// No description provided for @authSignInHere.
  ///
  /// In en, this message translates to:
  /// **'Sign in here'**
  String get authSignInHere;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authTermsOfServices.
  ///
  /// In en, this message translates to:
  /// **'terms of service'**
  String get authTermsOfServices;

  /// No description provided for @authForgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget Password?'**
  String get authForgetPassword;

  /// No description provided for @authKeepMeSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authKeepMeSignedIn;

  /// No description provided for @authWelcomeBackToTheApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to the app'**
  String get authWelcomeBackToTheApp;

  /// No description provided for @chatCouldNotOpenYourPhotos.
  ///
  /// In en, this message translates to:
  /// **'Could not open your photos.'**
  String get chatCouldNotOpenYourPhotos;

  /// No description provided for @chatTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get chatTryAgain;

  /// No description provided for @chatPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account password'**
  String get chatPasswordTitle;

  /// No description provided for @chatPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Account password'**
  String get chatPasswordLabel;

  /// No description provided for @chatPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'That is not your account password.'**
  String get chatPasswordWrong;

  /// No description provided for @chatPasswordTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a few minutes and try again.'**
  String get chatPasswordTooManyTries;

  /// No description provided for @chatMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get chatMoreOptions;

  /// No description provided for @chatArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get chatArchivedChats;

  /// No description provided for @chatNoArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'No archived chats'**
  String get chatNoArchivedChats;

  /// No description provided for @chatArchivedChatsHint.
  ///
  /// In en, this message translates to:
  /// **'New messages move chats back to your inbox.'**
  String get chatArchivedChatsHint;

  /// No description provided for @chatArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get chatArchive;

  /// No description provided for @chatUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get chatUnarchive;

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  /// No description provided for @chatArchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Archive chat'**
  String get chatArchiveChat;

  /// No description provided for @chatUnarchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Move back to chats'**
  String get chatUnarchiveChat;

  /// No description provided for @chatDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatDeleteChat;

  /// No description provided for @chatDeleteChatQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get chatDeleteChatQuestion;

  /// No description provided for @chatDeleteForMeExplained.
  ///
  /// In en, this message translates to:
  /// **'Only deleted for you. {name} keeps the chat.'**
  String chatDeleteForMeExplained(String name);

  /// No description provided for @chatDeleteForBoth.
  ///
  /// In en, this message translates to:
  /// **'Also delete for {name}'**
  String chatDeleteForBoth(String name);

  /// No description provided for @chatDeleteForBothExplained.
  ///
  /// In en, this message translates to:
  /// **'Delete all messages and photos for both of you. This cannot be undone.'**
  String get chatDeleteForBothExplained;

  /// No description provided for @chatArchivedDone.
  ///
  /// In en, this message translates to:
  /// **'Chat archived'**
  String get chatArchivedDone;

  /// No description provided for @chatUnarchivedDone.
  ///
  /// In en, this message translates to:
  /// **'Chat moved back to your chats'**
  String get chatUnarchivedDone;

  /// No description provided for @chatDeletedDone.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeletedDone;

  /// No description provided for @chatUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get chatUndo;

  /// No description provided for @chatActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not do that. Check your connection and retry.'**
  String get chatActionFailed;

  /// No description provided for @chatThisIsYourOwnAccount.
  ///
  /// In en, this message translates to:
  /// **'This is your own account.'**
  String get chatThisIsYourOwnAccount;

  /// No description provided for @chatSignInToChatOrCheck.
  ///
  /// In en, this message translates to:
  /// **'Sign in to chat, or check your connection.'**
  String get chatSignInToChatOrCheck;

  /// No description provided for @chatNoChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet!'**
  String get chatNoChatsYet;

  /// No description provided for @chatMessageAPropertyOwnerToStart.
  ///
  /// In en, this message translates to:
  /// **'Message an owner to start chatting.'**
  String get chatMessageAPropertyOwnerToStart;

  /// No description provided for @chatCouldNotLoadYourChats.
  ///
  /// In en, this message translates to:
  /// **'Could not load your chats.'**
  String get chatCouldNotLoadYourChats;

  /// No description provided for @chatPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get chatPhotoLibrary;

  /// No description provided for @chatCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get chatCamera;

  /// No description provided for @chatMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessage;

  /// No description provided for @homeCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get homeCoordinates;

  /// No description provided for @homeDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get homeDraw;

  /// No description provided for @homeAddPoint.
  ///
  /// In en, this message translates to:
  /// **'Add point'**
  String get homeAddPoint;

  /// No description provided for @homeSearchByAreaRoadVillage.
  ///
  /// In en, this message translates to:
  /// **'Search by area, road, village...'**
  String get homeSearchByAreaRoadVillage;

  /// No description provided for @homeNoCoordinatesFoundPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'No coordinates found. Please try again.'**
  String get homeNoCoordinatesFoundPleaseTryAgain;

  /// No description provided for @homeCropDocument.
  ///
  /// In en, this message translates to:
  /// **'Crop Document'**
  String get homeCropDocument;

  /// No description provided for @homeNoCoordinatesFoundInTheImage.
  ///
  /// In en, this message translates to:
  /// **'No coordinates found in the image.'**
  String get homeNoCoordinatesFoundInTheImage;

  /// No description provided for @homePleaseFillBothXAndY.
  ///
  /// In en, this message translates to:
  /// **'Enter both X and Y, or leave both blank.'**
  String get homePleaseFillBothXAndY;

  /// No description provided for @homeCoordinatesMustBeValidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Coordinates must be valid numbers.'**
  String get homeCoordinatesMustBeValidNumbers;

  /// No description provided for @homePleaseEnterAtLeast3Coordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 coordinates.'**
  String get homePleaseEnterAtLeast3Coordinates;

  /// No description provided for @homePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get homePreview;

  /// No description provided for @homeLocateProperty.
  ///
  /// In en, this message translates to:
  /// **'Locate Property'**
  String get homeLocateProperty;

  /// No description provided for @homeEnterCoordinatesManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Coordinates Manually'**
  String get homeEnterCoordinatesManually;

  /// No description provided for @homeTypeUtmZoneEastingXAnd.
  ///
  /// In en, this message translates to:
  /// **'Type UTM Zone, Easting (X), and Northing (Y).'**
  String get homeTypeUtmZoneEastingXAnd;

  /// No description provided for @homeEnterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter Coordinates'**
  String get homeEnterCoordinates;

  /// No description provided for @homeUseUtmFromALandDocument.
  ///
  /// In en, this message translates to:
  /// **'Use UTM coordinates from your land document or enter them.'**
  String get homeUseUtmFromALandDocument;

  /// No description provided for @homeCrsWgs84UtmZone48p.
  ///
  /// In en, this message translates to:
  /// **'CRS: WGS84 / UTM Zone 48P'**
  String get homeCrsWgs84UtmZone48p;

  /// No description provided for @homeScanUtmFromDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan UTM from Document'**
  String get homeScanUtmFromDocument;

  /// No description provided for @homeUseCameraToDetectCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Use camera to detect coordinates'**
  String get homeUseCameraToDetectCoordinates;

  /// No description provided for @homeStartScanning.
  ///
  /// In en, this message translates to:
  /// **'Start Scanning'**
  String get homeStartScanning;

  /// No description provided for @propertySetPropertyLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Property Location'**
  String get propertySetPropertyLocation;

  /// No description provided for @propertyLocationBoundary.
  ///
  /// In en, this message translates to:
  /// **'Location & Boundary'**
  String get propertyLocationBoundary;

  /// No description provided for @propertyDrawingProperty.
  ///
  /// In en, this message translates to:
  /// **'Drawing Property'**
  String get propertyDrawingProperty;

  /// No description provided for @propertyMapPreview.
  ///
  /// In en, this message translates to:
  /// **'Map Preview'**
  String get propertyMapPreview;

  /// No description provided for @propertyViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get propertyViewOnMap;

  /// No description provided for @propertyAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get propertyAddProperty;

  /// No description provided for @propertyPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyPropertyType;

  /// No description provided for @propertyTitleHeadline.
  ///
  /// In en, this message translates to:
  /// **'Title/Headline'**
  String get propertyTitleHeadline;

  /// No description provided for @propertyExample10x30LandNearNationalRoad.
  ///
  /// In en, this message translates to:
  /// **'Example: 10x30 Land Near National Road 1'**
  String get propertyExample10x30LandNearNationalRoad;

  /// No description provided for @propertyDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get propertyDescription;

  /// No description provided for @propertyDescribeWhatMakesThisPropertySpecial.
  ///
  /// In en, this message translates to:
  /// **'Describe what makes this property special'**
  String get propertyDescribeWhatMakesThisPropertySpecial;

  /// No description provided for @propertyKeywordsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Keywords / Features'**
  String get propertyKeywordsFeatures;

  /// No description provided for @propertyUploadPropertyPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload property photos'**
  String get propertyUploadPropertyPhotos;

  /// No description provided for @propertyContactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get propertyContactInformation;

  /// No description provided for @propertyPhoneNumber0.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (0...)'**
  String get propertyPhoneNumber0;

  /// No description provided for @propertyValidateRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Validate required fields'**
  String get propertyValidateRequiredFields;

  /// No description provided for @propertyPleaseCompleteRequiredFieldsBeforePublis.
  ///
  /// In en, this message translates to:
  /// **'Please complete required fields before publishing.'**
  String get propertyPleaseCompleteRequiredFieldsBeforePublis;

  /// No description provided for @propertyClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get propertyClose;

  /// No description provided for @propertyYourListingIsNowVisibleTo.
  ///
  /// In en, this message translates to:
  /// **'Your listing is now visible to buyers.'**
  String get propertyYourListingIsNowVisibleTo;

  /// No description provided for @propertyYouAreOfflinePleaseConnectTo.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Please connect to internet for updates.'**
  String get propertyYouAreOfflinePleaseConnectTo;

  /// No description provided for @propertyCouldNotLoadProperties.
  ///
  /// In en, this message translates to:
  /// **'Could not load properties'**
  String get propertyCouldNotLoadProperties;

  /// No description provided for @propertySortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get propertySortBy;

  /// No description provided for @propertyFailedToLoadSavedProperties.
  ///
  /// In en, this message translates to:
  /// **'Failed to load saved properties'**
  String get propertyFailedToLoadSavedProperties;

  /// No description provided for @propertyYouHavenTSavedAnyProperties.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any properties yet.'**
  String get propertyYouHavenTSavedAnyProperties;

  /// No description provided for @propertyTapTheHeartIconOnListings.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart to save a listing.'**
  String get propertyTapTheHeartIconOnListings;

  /// No description provided for @propertySavedProperties.
  ///
  /// In en, this message translates to:
  /// **'Saved Properties'**
  String get propertySavedProperties;

  /// No description provided for @propertySortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get propertySortOrder;

  /// No description provided for @propertyAddAtLeast3ClearPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add at least 3 clear property photos.'**
  String get propertyAddAtLeast3ClearPhotos;

  /// No description provided for @propertyOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get propertyOpenCamera;

  /// No description provided for @propertyCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get propertyCallNow;

  /// No description provided for @propertyCallInApp.
  ///
  /// In en, this message translates to:
  /// **'Call in Tilomnov'**
  String get propertyCallInApp;

  /// No description provided for @propertyCallPhone.
  ///
  /// In en, this message translates to:
  /// **'Use phone dialer'**
  String get propertyCallPhone;

  /// No description provided for @callFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Full-screen incoming calls'**
  String get callFullScreenTitle;

  /// No description provided for @callFullScreenHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow incoming calls to appear over the lock screen. Android may show a call banner while your phone is unlocked.'**
  String get callFullScreenHelp;

  /// No description provided for @callFullScreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open full-screen call settings.'**
  String get callFullScreenFailed;

  /// No description provided for @propertyNoPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number. Message the owner instead.'**
  String get propertyNoPhoneNumber;

  /// No description provided for @propertyCallFailed.
  ///
  /// In en, this message translates to:
  /// **'The phone app could not be opened.'**
  String get propertyCallFailed;

  /// No description provided for @profileSignInForContact.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see their phone and email.'**
  String get profileSignInForContact;

  /// No description provided for @propertyCannotChatOwnerInformationMissing.
  ///
  /// In en, this message translates to:
  /// **'Cannot chat: owner information missing.'**
  String get propertyCannotChatOwnerInformationMissing;

  /// No description provided for @propertySimilarProperty.
  ///
  /// In en, this message translates to:
  /// **'Similar Property'**
  String get propertySimilarProperty;

  /// No description provided for @propertyPropertyForYou.
  ///
  /// In en, this message translates to:
  /// **'Property for you'**
  String get propertyPropertyForYou;

  /// No description provided for @propertyPropertyHighlights.
  ///
  /// In en, this message translates to:
  /// **'Property Highlights'**
  String get propertyPropertyHighlights;

  /// No description provided for @propertyTilomnov.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov'**
  String get propertyTilomnov;

  /// No description provided for @propertyViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get propertyViews;

  /// No description provided for @propertySaves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get propertySaves;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the insights. Check your connection.'**
  String get insightsLoadFailed;

  /// No description provided for @insightsTotalViews.
  ///
  /// In en, this message translates to:
  /// **'People viewed'**
  String get insightsTotalViews;

  /// No description provided for @insightsTotalSaves.
  ///
  /// In en, this message translates to:
  /// **'Saved it'**
  String get insightsTotalSaves;

  /// No description provided for @insightsTotalCalls.
  ///
  /// In en, this message translates to:
  /// **'Tapped Call'**
  String get insightsTotalCalls;

  /// No description provided for @insightsTotalChats.
  ///
  /// In en, this message translates to:
  /// **'Started a chat'**
  String get insightsTotalChats;

  /// No description provided for @insightsLast14Days.
  ///
  /// In en, this message translates to:
  /// **'Last 14 days'**
  String get insightsLast14Days;

  /// No description provided for @insightsMeasureViews.
  ///
  /// In en, this message translates to:
  /// **'Viewers'**
  String get insightsMeasureViews;

  /// No description provided for @insightsMeasureSaves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get insightsMeasureSaves;

  /// No description provided for @insightsMeasureLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get insightsMeasureLeads;

  /// No description provided for @insightsViewers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new viewer} other{{count} new viewers}}'**
  String insightsViewers(int count);

  /// No description provided for @insightsSaves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new save} other{{count} new saves}}'**
  String insightsSaves(int count);

  /// No description provided for @insightsLeads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new lead} other{{count} new leads}}'**
  String insightsLeads(int count);

  /// No description provided for @insightsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week: {thisWeek}. The week before: {lastWeek}.'**
  String insightsThisWeek(String thisWeek, int lastWeek);

  /// No description provided for @insightsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No views yet. Share your listing to reach more people.'**
  String get insightsEmptyHint;

  /// No description provided for @propertyShareThisProperty.
  ///
  /// In en, this message translates to:
  /// **'Share This Property'**
  String get propertyShareThisProperty;

  /// No description provided for @propertyScanThisQrCodeToView.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to view this property on your phone'**
  String get propertyScanThisQrCodeToView;

  /// No description provided for @propertyShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get propertyShare;

  /// No description provided for @propertyDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get propertyDownload;

  /// No description provided for @propertyShareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this listing'**
  String get propertyShareSheetTitle;

  /// No description provided for @propertyShareScanToView.
  ///
  /// In en, this message translates to:
  /// **'Scan to view this listing'**
  String get propertyShareScanToView;

  /// No description provided for @propertyShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get propertyShareCopyLink;

  /// No description provided for @propertyShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get propertyShareLinkCopied;

  /// No description provided for @propertyShareSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get propertyShareSaveImage;

  /// No description provided for @propertyShareImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your photos'**
  String get propertyShareImageSaved;

  /// No description provided for @propertyShareImageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the image'**
  String get propertyShareImageSaveFailed;

  /// No description provided for @propertySharePhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow Tilomnov to add photos in Settings to save the image.'**
  String get propertySharePhotosDenied;

  /// No description provided for @propertyShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share this listing'**
  String get propertyShareFailed;

  /// No description provided for @propertyShareMessageSeeOnMap.
  ///
  /// In en, this message translates to:
  /// **'See the photos and exact location on the map:'**
  String get propertyShareMessageSeeOnMap;

  /// No description provided for @propertyShareMessageFooter.
  ///
  /// In en, this message translates to:
  /// **'Shared from Tilomnov, land and homes on the map.'**
  String get propertyShareMessageFooter;

  /// No description provided for @propertyShareCaptionCopied.
  ///
  /// In en, this message translates to:
  /// **'Caption copied: paste it if the app leaves it out'**
  String get propertyShareCaptionCopied;

  /// No description provided for @propertyShareNotPublicDraft.
  ///
  /// In en, this message translates to:
  /// **'Publish this listing to share its link or QR code.'**
  String get propertyShareNotPublicDraft;

  /// No description provided for @propertyShareNotPublicPending.
  ///
  /// In en, this message translates to:
  /// **'Complete payment before sharing this listing.'**
  String get propertyShareNotPublicPending;

  /// No description provided for @propertyShareNotPublicEnded.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer public and can’t be shared.'**
  String get propertyShareNotPublicEnded;

  /// No description provided for @propertyTitleType.
  ///
  /// In en, this message translates to:
  /// **'Title Type'**
  String get propertyTitleType;

  /// No description provided for @propertyBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get propertyBedrooms;

  /// No description provided for @propertyNumberOfBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Number of bedrooms'**
  String get propertyNumberOfBedrooms;

  /// No description provided for @propertyBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get propertyBathrooms;

  /// No description provided for @propertyNumberOfBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Number of bathrooms'**
  String get propertyNumberOfBathrooms;

  /// No description provided for @propertyFloors.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get propertyFloors;

  /// No description provided for @propertyTotalFloorsEG2.
  ///
  /// In en, this message translates to:
  /// **'Total floors (e.g. 2)'**
  String get propertyTotalFloorsEG2;

  /// No description provided for @propertyNumberOfFloors.
  ///
  /// In en, this message translates to:
  /// **'Number of Floors'**
  String get propertyNumberOfFloors;

  /// No description provided for @propertyFloorNumber.
  ///
  /// In en, this message translates to:
  /// **'Floor Number'**
  String get propertyFloorNumber;

  /// No description provided for @propertyEnterFloorNumberEG12.
  ///
  /// In en, this message translates to:
  /// **'Enter floor number (e.g. 12)'**
  String get propertyEnterFloorNumberEG12;

  /// No description provided for @propertyTotalFloors.
  ///
  /// In en, this message translates to:
  /// **'Total Floors'**
  String get propertyTotalFloors;

  /// No description provided for @propertyTotalFloorsInBuilding.
  ///
  /// In en, this message translates to:
  /// **'Total floors in building'**
  String get propertyTotalFloorsInBuilding;

  /// No description provided for @propertyParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get propertyParking;

  /// No description provided for @propertySelectParking.
  ///
  /// In en, this message translates to:
  /// **'Select parking'**
  String get propertySelectParking;

  /// No description provided for @propertyFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get propertyFurnished;

  /// No description provided for @propertySelectFurnished.
  ///
  /// In en, this message translates to:
  /// **'Select furnished'**
  String get propertySelectFurnished;

  /// No description provided for @propertyBuildingType.
  ///
  /// In en, this message translates to:
  /// **'Building Type'**
  String get propertyBuildingType;

  /// No description provided for @propertySelectBuildingType.
  ///
  /// In en, this message translates to:
  /// **'Select building type'**
  String get propertySelectBuildingType;

  /// No description provided for @propertyTotalUnits.
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get propertyTotalUnits;

  /// No description provided for @propertyNumberOfUnits.
  ///
  /// In en, this message translates to:
  /// **'Number of units'**
  String get propertyNumberOfUnits;

  /// No description provided for @propertyBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get propertyBalcony;

  /// No description provided for @propertySelectBalcony.
  ///
  /// In en, this message translates to:
  /// **'Select balcony'**
  String get propertySelectBalcony;

  /// No description provided for @propertyCompletionStatus.
  ///
  /// In en, this message translates to:
  /// **'Completion Status'**
  String get propertyCompletionStatus;

  /// No description provided for @propertySelectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get propertySelectStatus;

  /// No description provided for @propertyViewType.
  ///
  /// In en, this message translates to:
  /// **'View Type'**
  String get propertyViewType;

  /// No description provided for @propertySelectViewType.
  ///
  /// In en, this message translates to:
  /// **'Select view type'**
  String get propertySelectViewType;

  /// No description provided for @propertyProjectType.
  ///
  /// In en, this message translates to:
  /// **'Project Type'**
  String get propertyProjectType;

  /// No description provided for @propertySelectProjectType.
  ///
  /// In en, this message translates to:
  /// **'Select project type'**
  String get propertySelectProjectType;

  /// No description provided for @propertySelectStatus2.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get propertySelectStatus2;

  /// No description provided for @propertyBuildingManagementFeePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Building management fee per month'**
  String get propertyBuildingManagementFeePerMonth;

  /// No description provided for @propertyRemainingContractDurationWithLandlord.
  ///
  /// In en, this message translates to:
  /// **'Remaining contract duration with landlord'**
  String get propertyRemainingContractDurationWithLandlord;

  /// No description provided for @propertyMaintenanceFee.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Fee'**
  String get propertyMaintenanceFee;

  /// No description provided for @propertyLeaseRemaining.
  ///
  /// In en, this message translates to:
  /// **'Lease Remaining'**
  String get propertyLeaseRemaining;

  /// No description provided for @propertyPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get propertyPrice;

  /// No description provided for @propertyEnterSellingPriceUsd.
  ///
  /// In en, this message translates to:
  /// **'Enter selling price (USD)'**
  String get propertyEnterSellingPriceUsd;

  /// No description provided for @propertyListingSettings.
  ///
  /// In en, this message translates to:
  /// **'Listing Settings'**
  String get propertyListingSettings;

  /// No description provided for @propertyAutoFromMap.
  ///
  /// In en, this message translates to:
  /// **'Auto from map'**
  String get propertyAutoFromMap;

  /// No description provided for @propertyTotalLandAreaOfTheProperty.
  ///
  /// In en, this message translates to:
  /// **'Total land area of the property'**
  String get propertyTotalLandAreaOfTheProperty;

  /// No description provided for @propertyTotalBuiltUpArea.
  ///
  /// In en, this message translates to:
  /// **'Total built-up area'**
  String get propertyTotalBuiltUpArea;

  /// No description provided for @propertyTotalUsableAreaOfTheUnit.
  ///
  /// In en, this message translates to:
  /// **'Total usable area of the unit'**
  String get propertyTotalUsableAreaOfTheUnit;

  /// No description provided for @propertyBuildingSize.
  ///
  /// In en, this message translates to:
  /// **'Building Size'**
  String get propertyBuildingSize;

  /// No description provided for @propertyUnitSize.
  ///
  /// In en, this message translates to:
  /// **'Unit Size'**
  String get propertyUnitSize;

  /// No description provided for @propertyDeveloperName.
  ///
  /// In en, this message translates to:
  /// **'Developer Name'**
  String get propertyDeveloperName;

  /// No description provided for @propertyExampleAbcDevelopmentCoLtd.
  ///
  /// In en, this message translates to:
  /// **'Example: ABC Development Co., Ltd'**
  String get propertyExampleAbcDevelopmentCoLtd;

  /// No description provided for @propertyProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get propertyProjectName;

  /// No description provided for @propertyProjectName2.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get propertyProjectName2;

  /// No description provided for @propertyTotalProjectArea.
  ///
  /// In en, this message translates to:
  /// **'Total Project Area'**
  String get propertyTotalProjectArea;

  /// No description provided for @propertyEnterTotalLandSize.
  ///
  /// In en, this message translates to:
  /// **'Enter total land size'**
  String get propertyEnterTotalLandSize;

  /// No description provided for @propertyTotalNumberOfUnitsInProject.
  ///
  /// In en, this message translates to:
  /// **'Total number of units in project'**
  String get propertyTotalNumberOfUnitsInProject;

  /// No description provided for @propertyStartingPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting Price'**
  String get propertyStartingPrice;

  /// No description provided for @propertyStartingPriceInUsd.
  ///
  /// In en, this message translates to:
  /// **'Starting price in USD'**
  String get propertyStartingPriceInUsd;

  /// No description provided for @propertyMonthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent'**
  String get propertyMonthlyRent;

  /// No description provided for @propertyEnterMonthlyShopRentUsd.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly shop rent (USD)'**
  String get propertyEnterMonthlyShopRentUsd;

  /// No description provided for @propertyEquipmentIncluded.
  ///
  /// In en, this message translates to:
  /// **'Equipment Included'**
  String get propertyEquipmentIncluded;

  /// No description provided for @propertyListFurnitureKitchenEquipmentMachinesPos.
  ///
  /// In en, this message translates to:
  /// **'List furniture, kitchen equipment, machines, POS system, etc.'**
  String get propertyListFurnitureKitchenEquipmentMachinesPos;

  /// No description provided for @propertyReasonForSelling.
  ///
  /// In en, this message translates to:
  /// **'Reason for Selling'**
  String get propertyReasonForSelling;

  /// No description provided for @propertyExampleOwnerRelocatingAbroad.
  ///
  /// In en, this message translates to:
  /// **'Example: Owner relocating abroad'**
  String get propertyExampleOwnerRelocatingAbroad;

  /// No description provided for @propertyEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get propertyEdit;

  /// No description provided for @propertyPublishToPublic.
  ///
  /// In en, this message translates to:
  /// **'Publish to Public'**
  String get propertyPublishToPublic;

  /// No description provided for @propertyMoveToDraft.
  ///
  /// In en, this message translates to:
  /// **'Move to Draft'**
  String get propertyMoveToDraft;

  /// No description provided for @propertyDeleteProperty.
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get propertyDeleteProperty;

  /// No description provided for @propertyPropertyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Property deleted'**
  String get propertyPropertyDeleted;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'You were signed out of this device.'**
  String get sessionEnded;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Update Tilomnov from your app store to keep using it.'**
  String get updateRequiredMessage;

  /// No description provided for @securityCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get securityCreatePassword;

  /// No description provided for @createPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Set a password and confirm with Google. You can still sign in with Google.'**
  String get createPasswordIntro;

  /// No description provided for @createPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Google and create'**
  String get createPasswordAction;

  /// No description provided for @createPasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password created.'**
  String get createPasswordDone;

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this chat. Check your connection.'**
  String get chatOpenFailed;

  /// No description provided for @devicesImmediateNote.
  ///
  /// In en, this message translates to:
  /// **'Devices are signed out right away.'**
  String get devicesImmediateNote;

  /// No description provided for @devicesTooNew.
  ///
  /// In en, this message translates to:
  /// **'Wait 24 hours after signing in to sign out other devices, or use an older device.'**
  String get devicesTooNew;

  /// No description provided for @devicesTooNewUntil.
  ///
  /// In en, this message translates to:
  /// **'You can sign out other devices from {when}. Until then, use a device signed in earlier.'**
  String devicesTooNewUntil(String when);

  /// No description provided for @newSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'New sign-in to your account'**
  String get newSignInTitle;

  /// No description provided for @newSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'New sign-in. Not you? Sign out that device and change your password.'**
  String get newSignInMessage;

  /// No description provided for @newSignInWasMe.
  ///
  /// In en, this message translates to:
  /// **'It was me'**
  String get newSignInWasMe;

  /// No description provided for @newSignInReview.
  ///
  /// In en, this message translates to:
  /// **'Review devices'**
  String get newSignInReview;

  /// No description provided for @avatarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get avatarRemove;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated.'**
  String get avatarUpdated;

  /// No description provided for @avatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the profile picture. Please try again.'**
  String get avatarFailed;

  /// No description provided for @avatarSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Use your Google account\'s photo and keep it up to date.'**
  String get avatarSyncHelp;

  /// No description provided for @avatarNoGooglePhoto.
  ///
  /// In en, this message translates to:
  /// **'Your Google account has no photo.'**
  String get avatarNoGooglePhoto;

  /// No description provided for @accountDeviceTooNew.
  ///
  /// In en, this message translates to:
  /// **'Wait 24 hours after signing in, or use a device signed in earlier.'**
  String get accountDeviceTooNew;

  /// No description provided for @personalInfoUsernameChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get personalInfoUsernameChecking;

  /// No description provided for @personalInfoUsernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'This username is available.'**
  String get personalInfoUsernameAvailable;

  /// No description provided for @mediaSourceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than {limitMb} MB and cannot be uploaded.'**
  String mediaSourceTooLarge(int limitMb);

  /// No description provided for @mediaStillTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Picture too large. Choose a smaller one.'**
  String get mediaStillTooLarge;

  /// No description provided for @mediaUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This picture could not be read. Please choose another one.'**
  String get mediaUnreadable;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search area, road, listing or person'**
  String get searchFieldHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchSectionPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get searchSectionPlaces;

  /// No description provided for @searchSectionListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get searchSectionListings;

  /// No description provided for @searchSectionPeople.
  ///
  /// In en, this message translates to:
  /// **'People & agencies'**
  String get searchSectionPeople;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a place, a listing or a person'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Search for a place, owner or agency.'**
  String get searchIdleBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResultsTitle(String query);

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try a nearby road or district.'**
  String get searchNoResultsBody;

  /// No description provided for @searchFailureOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection and try again.'**
  String get searchFailureOffline;

  /// No description provided for @searchFailureTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many searches. Please wait a moment and try again.'**
  String get searchFailureTooManyRequests;

  /// No description provided for @searchFailureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Place search is not available right now. Please try again later.'**
  String get searchFailureUnavailable;

  /// No description provided for @searchFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'This place could not be found. Try another result.'**
  String get searchFailureNotFound;

  /// No description provided for @searchFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get searchFailureUnknown;

  /// No description provided for @searchListingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No listings} =1{1 listing} other{{count} listings}}'**
  String searchListingCount(int count);

  /// No description provided for @searchPropertiesInArea.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No properties here yet} =1{1 property in this area} other{{count} properties in this area}}'**
  String searchPropertiesInArea(int count);

  /// No description provided for @searchPropertiesByPerson.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No published listings} =1{1 published listing} other{{count} published listings}}'**
  String searchPropertiesByPerson(int count);

  /// No description provided for @searchAreaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listings here. Try a wider area.'**
  String get searchAreaEmpty;

  /// No description provided for @searchPersonEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published listings yet.'**
  String get searchPersonEmpty;

  /// No description provided for @searchViewProperty.
  ///
  /// In en, this message translates to:
  /// **'View property'**
  String get searchViewProperty;

  /// No description provided for @searchCloseResults.
  ///
  /// In en, this message translates to:
  /// **'Close search results'**
  String get searchCloseResults;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// No description provided for @searchHistoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit this search'**
  String get searchHistoryEdit;

  /// No description provided for @searchHistoryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get searchHistoryRemove;

  /// No description provided for @searchHistoryRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'This search could not be removed. Please try again.'**
  String get searchHistoryRemoveFailed;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @profileListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileListingsTitle;

  /// No description provided for @profileViewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get profileViewOnMap;

  /// No description provided for @profileListingsStat.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileListingsStat;

  /// No description provided for @profileFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get profileFollow;

  /// No description provided for @profileFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowing;

  /// No description provided for @profileFollowersStat.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowersStat;

  /// No description provided for @profileFollowingStat.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowingStat;

  /// No description provided for @profileFollowLimit.
  ///
  /// In en, this message translates to:
  /// **'You can follow up to {count} people. Unfollow someone to follow more.'**
  String profileFollowLimit(int count);

  /// No description provided for @profileFollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Following could not be changed. Please try again.'**
  String get profileFollowFailed;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedTitle;

  /// No description provided for @feedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh finds from people you follow'**
  String get feedSubtitle;

  /// No description provided for @feedNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get feedNewestFirst;

  /// No description provided for @feedSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top (most saved)'**
  String get feedSortTop;

  /// No description provided for @feedListingDate.
  ///
  /// In en, this message translates to:
  /// **'Listing date'**
  String get feedListingDate;

  /// No description provided for @feedAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get feedAnyTime;

  /// No description provided for @feedLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get feedLast7Days;

  /// No description provided for @feedLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get feedLast30Days;

  /// No description provided for @feedChooseDates.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get feedChooseDates;

  /// No description provided for @feedPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a price between \$0 and \$9,999,999,999.99.'**
  String get feedPriceInvalid;

  /// No description provided for @feedNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching listings'**
  String get feedNoMatches;

  /// No description provided for @feedTryOtherFilters.
  ///
  /// In en, this message translates to:
  /// **'Try a different date, price or property type.'**
  String get feedTryOtherFilters;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your feed is empty'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Follow people to see their new listings.'**
  String get feedEmptyHint;

  /// No description provided for @feedExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore listings'**
  String get feedExplore;

  /// No description provided for @feedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your feed could not be loaded.'**
  String get feedLoadFailed;

  /// No description provided for @feedListedOn.
  ///
  /// In en, this message translates to:
  /// **'Listed {date}'**
  String feedListedOn(String date);

  /// No description provided for @profileContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get profileContactTitle;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String profileCopied(String label);

  /// No description provided for @profileCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get profileCopy;

  /// No description provided for @profileChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get profileChat;

  /// No description provided for @chatTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get chatTabProfile;

  /// No description provided for @chatViewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View full profile'**
  String get chatViewFullProfile;

  /// No description provided for @profileTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileTabAbout;

  /// No description provided for @profileNoContact.
  ///
  /// In en, this message translates to:
  /// **'No contact details shared.'**
  String get profileNoContact;

  /// No description provided for @propertySavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Save photo'**
  String get propertySavePhoto;

  /// No description provided for @propertyPhotoLimit.
  ///
  /// In en, this message translates to:
  /// **'A listing can have up to {count} photos.'**
  String propertyPhotoLimit(int count);

  /// No description provided for @propertyEditProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get propertyEditProperty;

  /// No description provided for @propertySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get propertySaveChanges;

  /// No description provided for @propertySavingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get propertySavingChanges;

  /// No description provided for @propertyChangesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get propertyChangesSaved;

  /// No description provided for @propertyCouldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes. Please try again.'**
  String get propertyCouldNotSaveChanges;

  /// No description provided for @propertyCurrentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Current photos ({count})'**
  String propertyCurrentPhotos(int count);

  /// No description provided for @propertyRestoreRemovedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Undo remove ({count})'**
  String propertyRestoreRemovedPhotos(int count);

  /// No description provided for @propertyRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get propertyRemovePhoto;

  /// No description provided for @propertyNearby.
  ///
  /// In en, this message translates to:
  /// **'What\'s nearby'**
  String get propertyNearby;

  /// No description provided for @propertyNearbyCaption.
  ///
  /// In en, this message translates to:
  /// **'Closest by road from this property'**
  String get propertyNearbyCaption;

  /// No description provided for @propertyNearbyMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get propertyNearbyMarkets;

  /// No description provided for @propertyNearbyHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get propertyNearbyHospitals;

  /// No description provided for @propertyNearbySchools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get propertyNearbySchools;

  /// No description provided for @propertyNearbyNoneWithin.
  ///
  /// In en, this message translates to:
  /// **'None found within {km} km'**
  String propertyNearbyNoneWithin(int km);

  /// No description provided for @propertyDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String propertyDistanceKm(String distance);

  /// No description provided for @propertyDistanceM.
  ///
  /// In en, this message translates to:
  /// **'{distance} m'**
  String propertyDistanceM(int distance);

  /// No description provided for @propertyStraightLine.
  ///
  /// In en, this message translates to:
  /// **'{distance} straight line'**
  String propertyStraightLine(String distance);

  /// No description provided for @propertyNearbyCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby places.'**
  String get propertyNearbyCouldNotLoad;

  /// No description provided for @propertyNearbyRouteCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the road to this place.'**
  String get propertyNearbyRouteCouldNotLoad;

  /// No description provided for @propertyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount (optional)'**
  String get propertyDiscount;

  /// No description provided for @propertyDiscountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get propertyDiscountHint;

  /// No description provided for @propertyDiscountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use more than 0 and less than 100%, or less than the price.'**
  String get propertyDiscountInvalid;

  /// No description provided for @propertyPriceCut.
  ///
  /// In en, this message translates to:
  /// **'Price cut: {amount}'**
  String propertyPriceCut(String amount);

  /// No description provided for @propertyVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get propertyVisibility;

  /// No description provided for @propertyVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get propertyVisibilityPublic;

  /// No description provided for @propertyVisibilityPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone can find it on the map.'**
  String get propertyVisibilityPublicHint;

  /// No description provided for @propertyVisibilityDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get propertyVisibilityDraft;

  /// No description provided for @propertyVisibilityDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden; only you can see it.'**
  String get propertyVisibilityDraftHint;

  /// No description provided for @propertyVisibilitySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get propertyVisibilitySold;

  /// No description provided for @propertyVisibilitySoldHint.
  ///
  /// In en, this message translates to:
  /// **'Marked sold and taken off the map.'**
  String get propertyVisibilitySoldHint;

  /// No description provided for @propertyVisibilitySoldNeedsPublic.
  ///
  /// In en, this message translates to:
  /// **'Publish it first to mark it sold.'**
  String get propertyVisibilitySoldNeedsPublic;

  /// No description provided for @propertyVisibilityChanged.
  ///
  /// In en, this message translates to:
  /// **'Visibility updated.'**
  String get propertyVisibilityChanged;

  /// No description provided for @propertyCouldNotChangeVisibility.
  ///
  /// In en, this message translates to:
  /// **'Could not change the visibility. Please try again.'**
  String get propertyCouldNotChangeVisibility;

  /// No description provided for @propertyCouldNotOpenEditor.
  ///
  /// In en, this message translates to:
  /// **'Could not open the listing for editing. Please try again.'**
  String get propertyCouldNotOpenEditor;

  /// No description provided for @propertyDrawBoundaryFirst.
  ///
  /// In en, this message translates to:
  /// **'Draw the property on the map first to measure it.'**
  String get propertyDrawBoundaryFirst;

  /// No description provided for @securityPinRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'Your chats are always end-to-end encrypted and protected by your 6-digit chat PIN. You need it to read your chats on a new phone.'**
  String get securityPinRequiredNote;

  /// No description provided for @chatPasswordChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your password...'**
  String get chatPasswordChecking;

  /// No description provided for @chatLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats are locked on this phone'**
  String get chatLockedTitle;

  /// No description provided for @chatEnterPinAction.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get chatEnterPinAction;

  /// No description provided for @authErrEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authErrEnterName;

  /// No description provided for @authErrEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid password'**
  String get authErrEnterPassword;

  /// No description provided for @authErrPasswordMin8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authErrPasswordMin8;

  /// No description provided for @authErrAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms of services to continue.'**
  String get authErrAgreeTerms;

  /// No description provided for @authErrEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authErrEnterEmail;

  /// No description provided for @authErrEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get authErrEnterNewPassword;

  /// No description provided for @authErrReEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter your password'**
  String get authErrReEnterPassword;

  /// No description provided for @authErrPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authErrPasswordsDontMatch;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service for Tilomnov'**
  String get termsTitle;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 14 February 2026'**
  String get termsLastUpdated;

  /// No description provided for @termsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tilomnov. By accessing or using the Tilomnov application and services, you agree to comply with and be bound by the following Terms of Service.'**
  String get termsWelcome;

  /// No description provided for @termsDisagree.
  ///
  /// In en, this message translates to:
  /// **'If you do not agree with these terms, please do not use the application.'**
  String get termsDisagree;

  /// No description provided for @termsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'1. About Tilomnov'**
  String get termsAboutTitle;

  /// No description provided for @termsAboutIntro.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov is a map-based property platform that allows users to:'**
  String get termsAboutIntro;

  /// No description provided for @termsAboutView.
  ///
  /// In en, this message translates to:
  /// **'View property listings with accurate map locations and boundaries'**
  String get termsAboutView;

  /// No description provided for @termsAboutManage.
  ///
  /// In en, this message translates to:
  /// **'Add, manage, and share property information'**
  String get termsAboutManage;

  /// No description provided for @termsAboutConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect buyers, sellers, agents, and developers'**
  String get termsAboutConnect;

  /// No description provided for @termsAboutTools.
  ///
  /// In en, this message translates to:
  /// **'Use coordinate tools such as UTM input and map measurement'**
  String get termsAboutTools;

  /// No description provided for @termsAboutPlatformOnly.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov acts only as a platform and does not own, sell, or broker any property.'**
  String get termsAboutPlatformOnly;

  /// No description provided for @termsAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'2. User Accounts'**
  String get termsAccountsTitle;

  /// No description provided for @termsAccountsIntro.
  ///
  /// In en, this message translates to:
  /// **'To use certain features, users must register using a valid phone number or email address.\nYou agree that:'**
  String get termsAccountsIntro;

  /// No description provided for @termsAccountsAccurate.
  ///
  /// In en, this message translates to:
  /// **'The information you provide is accurate'**
  String get termsAccountsAccurate;

  /// No description provided for @termsAccountsConfidential.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining the confidentiality of your account'**
  String get termsAccountsConfidential;

  /// No description provided for @termsAccountsNoImpersonation.
  ///
  /// In en, this message translates to:
  /// **'You will not impersonate another person'**
  String get termsAccountsNoImpersonation;

  /// No description provided for @termsAccountsSuspend.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov reserves the right to suspend accounts that provide false information.'**
  String get termsAccountsSuspend;

  /// No description provided for @termsListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Property Listings'**
  String get termsListingsTitle;

  /// No description provided for @termsListingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Users who post properties (owners, agents, developers) agree that:'**
  String get termsListingsIntro;

  /// No description provided for @termsListingsTruthful.
  ///
  /// In en, this message translates to:
  /// **'All information, boundaries, prices, and details are truthful'**
  String get termsListingsTruthful;

  /// No description provided for @termsListingsRight.
  ///
  /// In en, this message translates to:
  /// **'You have the legal right to share and advertise the property'**
  String get termsListingsRight;

  /// No description provided for @termsListingsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'The map boundary or UTM coordinates you provide are accurate to the best of your knowledge'**
  String get termsListingsCoordinates;

  /// No description provided for @termsListingsNotResponsible.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov is not responsible for incorrect property data submitted by users.'**
  String get termsListingsNotResponsible;

  /// No description provided for @termsMapTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Map and Coordinate Accuracy'**
  String get termsMapTitle;

  /// No description provided for @termsMapIntro.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov provides tools for map visualization, UTM conversion, and distance measurement.'**
  String get termsMapIntro;

  /// No description provided for @termsMapGuidanceOnly.
  ///
  /// In en, this message translates to:
  /// **'Map boundaries are for visual guidance only and do not replace official cadastral surveys or land titles.'**
  String get termsMapGuidanceOnly;

  /// No description provided for @termsMapVerify.
  ///
  /// In en, this message translates to:
  /// **'Users should verify all land borders and titles with relevant authorities before financial transactions.'**
  String get termsMapVerify;

  /// No description provided for @termsAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree terms of services'**
  String get termsAgree;

  /// No description provided for @authErrEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authErrEnterValidEmail;

  /// No description provided for @authErrEnterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get authErrEnterValidPhone;

  /// No description provided for @authErrPasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authErrPasswordMin6;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email, phone number or password.'**
  String get authErrorWrongCredentials;

  /// No description provided for @authErrorAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email or phone number already exists.'**
  String get authErrorAccountExists;

  /// No description provided for @authErrorCheckDetails.
  ///
  /// In en, this message translates to:
  /// **'Please check what you entered and try again.'**
  String get authErrorCheckDetails;

  /// No description provided for @authErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is wrong or has expired.'**
  String get authErrorInvalidCode;

  /// No description provided for @authErrorTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Please wait a few minutes and try again.'**
  String get authErrorTooManyTries;

  /// No description provided for @authErrorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get authErrorNoConnection;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authResendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String authResendOtpIn(int seconds);

  /// No description provided for @chatPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable. Tap to retry.'**
  String get chatPhotoUnavailable;

  /// No description provided for @chatPictureCannotBeShown.
  ///
  /// In en, this message translates to:
  /// **'This picture cannot be shown.'**
  String get chatPictureCannotBeShown;

  /// No description provided for @chatMessageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Tap to retry.'**
  String get chatMessageNotSent;

  /// No description provided for @chatMessageSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get chatMessageSending;

  /// No description provided for @chatMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatMessageSent;

  /// No description provided for @chatMessageTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String chatMessageTimeYesterday(String time);

  /// No description provided for @chatDeliveredJustNow.
  ///
  /// In en, this message translates to:
  /// **'Delivered just now'**
  String get chatDeliveredJustNow;

  /// No description provided for @chatDeliveredMinutes.
  ///
  /// In en, this message translates to:
  /// **'Delivered {minutes, plural, =1{1 minute ago} other{{minutes} minutes ago}}'**
  String chatDeliveredMinutes(int minutes);

  /// No description provided for @chatDeliveredHours.
  ///
  /// In en, this message translates to:
  /// **'Delivered {hours, plural, =1{1 hour ago} other{{hours} hours ago}}'**
  String chatDeliveredHours(int hours);

  /// No description provided for @chatDeliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered {day}'**
  String chatDeliveredOn(String day);

  /// No description provided for @chatAttachPicture.
  ///
  /// In en, this message translates to:
  /// **'Attach a picture'**
  String get chatAttachPicture;

  /// No description provided for @chatShowEmojis.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get chatShowEmojis;

  /// No description provided for @chatShowKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get chatShowKeyboard;

  /// No description provided for @chatSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSendMessage;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatEdit;

  /// No description provided for @chatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get chatCopied;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String chatReplyingTo(String name);

  /// No description provided for @chatEditingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get chatEditingMessage;

  /// No description provided for @chatEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get chatEdited;

  /// No description provided for @chatAskAboutListing.
  ///
  /// In en, this message translates to:
  /// **'Asking about this listing?'**
  String get chatAskAboutListing;

  /// No description provided for @chatSendListing.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSendListing;

  /// No description provided for @chatDismissListing.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get chatDismissListing;

  /// No description provided for @chatViewListing.
  ///
  /// In en, this message translates to:
  /// **'View listing'**
  String get chatViewListing;

  /// No description provided for @chatListingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available.'**
  String get chatListingUnavailable;

  /// No description provided for @chatDeleteMessageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get chatDeleteMessageQuestion;

  /// No description provided for @chatDeleteMessageForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteMessageForEveryone;

  /// No description provided for @chatDeleteMessageForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteMessageForMe;

  /// No description provided for @chatDeleteOwnMessageExplained.
  ///
  /// In en, this message translates to:
  /// **'Delete for you and {name}, or just for you.'**
  String chatDeleteOwnMessageExplained(String name);

  /// No description provided for @chatDeleteMessageForMeExplained.
  ///
  /// In en, this message translates to:
  /// **'Only deleted for you. {name} can still see it.'**
  String chatDeleteMessageForMeExplained(String name);

  /// No description provided for @chatEditTooLate.
  ///
  /// In en, this message translates to:
  /// **'You can edit messages for up to 1 hour.'**
  String get chatEditTooLate;

  /// No description provided for @chatPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatPresenceOnline;

  /// No description provided for @chatLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'Last seen just now'**
  String get chatLastSeenJustNow;

  /// No description provided for @chatLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes} min ago'**
  String chatLastSeenMinutes(int minutes);

  /// No description provided for @chatLastSeenToday.
  ///
  /// In en, this message translates to:
  /// **'Last seen today at {time}'**
  String chatLastSeenToday(String time);

  /// No description provided for @chatLastSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last seen yesterday at {time}'**
  String chatLastSeenYesterday(String time);

  /// No description provided for @chatLastSeenOn.
  ///
  /// In en, this message translates to:
  /// **'Last seen {date}'**
  String chatLastSeenOn(String date);

  /// No description provided for @chatEmojiSmileys.
  ///
  /// In en, this message translates to:
  /// **'Smileys'**
  String get chatEmojiSmileys;

  /// No description provided for @chatEmojiGestures.
  ///
  /// In en, this message translates to:
  /// **'Gestures'**
  String get chatEmojiGestures;

  /// No description provided for @chatEmojiHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get chatEmojiHearts;

  /// No description provided for @chatEmojiPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get chatEmojiPlaces;

  /// No description provided for @chatPreviewEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Message unavailable'**
  String get chatPreviewEncrypted;

  /// No description provided for @chatPreviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPreviewPhoto;

  /// No description provided for @chatUndecryptable.
  ///
  /// In en, this message translates to:
  /// **'This message cannot be read on this device.'**
  String get chatUndecryptable;

  /// No description provided for @ownerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Property Owner'**
  String get ownerFallbackName;

  /// No description provided for @chatSendSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You are signed out.'**
  String get chatSendSignedOut;

  /// No description provided for @chatSendNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get chatSendNoConnection;

  /// No description provided for @chatSendRejected.
  ///
  /// In en, this message translates to:
  /// **'Message not accepted. Try again.'**
  String get chatSendRejected;

  /// No description provided for @chatSendTooFast.
  ///
  /// In en, this message translates to:
  /// **'Sending too fast. Wait a moment.'**
  String get chatSendTooFast;

  /// No description provided for @chatSendBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can\'t message this person.'**
  String get chatSendBlocked;

  /// No description provided for @chatYouBlocked.
  ///
  /// In en, this message translates to:
  /// **'You blocked {name}. They can\'t message or call you.'**
  String chatYouBlocked(String name);

  /// No description provided for @chatCannotReply.
  ///
  /// In en, this message translates to:
  /// **'You can\'t reply to this conversation.'**
  String get chatCannotReply;

  /// No description provided for @safetyMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get safetyMore;

  /// No description provided for @blockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockConfirmTitle(String name);

  /// No description provided for @blockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They can’t message or call you. You’ll unfollow each other. They won’t be notified.'**
  String get blockConfirmMessage;

  /// No description provided for @unblockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String unblockConfirmTitle(String name);

  /// No description provided for @unblockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You can message each other again. Follow them again if you want to.'**
  String get unblockConfirmMessage;

  /// No description provided for @blockDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is blocked.'**
  String blockDone(String name);

  /// No description provided for @unblockDone.
  ///
  /// In en, this message translates to:
  /// **'{name} is unblocked.'**
  String unblockDone(String name);

  /// No description provided for @blockFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Check your connection and try again.'**
  String get blockFailed;

  /// No description provided for @blockedAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked accounts'**
  String get blockedAccountsTitle;

  /// No description provided for @blockedAccountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedAccountsEmpty;

  /// No description provided for @blockedAccountsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the accounts you blocked.'**
  String get blockedAccountsLoadFailed;

  /// No description provided for @reportListingAction.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListingAction;

  /// No description provided for @reportUserAction.
  ///
  /// In en, this message translates to:
  /// **'Report account'**
  String get reportUserAction;

  /// No description provided for @reportListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this listing'**
  String get reportListingTitle;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this account'**
  String get reportUserTitle;

  /// No description provided for @reportHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s wrong. The owner won\'t know who reported it.'**
  String get reportHelp;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get reportReasonScam;

  /// No description provided for @reportReasonMisleading.
  ///
  /// In en, this message translates to:
  /// **'Wrong price, photos or details'**
  String get reportReasonMisleading;

  /// No description provided for @reportReasonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Already sold or rented'**
  String get reportReasonUnavailable;

  /// No description provided for @reportReasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Posted more than once'**
  String get reportReasonDuplicate;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or threats'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Pretending to be someone else'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Offensive or inappropriate'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else we should know (optional)'**
  String get reportDetailsHint;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We\'ll review your report.'**
  String get reportSent;

  /// No description provided for @reportTooMany.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent a lot of reports. Try again later.'**
  String get reportTooMany;

  /// No description provided for @reportTargetGone.
  ///
  /// In en, this message translates to:
  /// **'This has already been removed.'**
  String get reportTargetGone;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'The report wasn\'t sent. Check your connection and try again.'**
  String get reportFailed;

  /// No description provided for @chatSendFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large (limit {megabytes} MB).'**
  String chatSendFileTooLarge(int megabytes);

  /// No description provided for @chatSendUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the file. Check your connection.'**
  String get chatSendUploadFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Please try again.'**
  String get chatSendFailed;

  /// No description provided for @mapNewListing.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get mapNewListing;

  /// No description provided for @homeExtractedCoordinates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 coordinate.} other{Found {count} coordinates.}}'**
  String homeExtractedCoordinates(int count);

  /// No description provided for @homeScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the document. Please try again.'**
  String get homeScanFailed;

  /// No description provided for @homeInvalidUtm.
  ///
  /// In en, this message translates to:
  /// **'These UTM coordinates are not valid. Please check them.'**
  String get homeInvalidUtm;

  /// No description provided for @homeScanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get homeScanProcessing;

  /// No description provided for @homeScanFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get homeScanFinished;

  /// No description provided for @homeLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get homeLocationServicesOff;

  /// No description provided for @homeLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get homeLocationDenied;

  /// No description provided for @homeLocationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. You can allow it in the phone\'s settings.'**
  String get homeLocationDeniedForever;

  /// No description provided for @homeLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please try again.'**
  String get homeLocationFailed;

  /// No description provided for @propertyMaintenanceFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Monthly maintenance fee (USD)'**
  String get propertyMaintenanceFeeHint;

  /// No description provided for @propertyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get propertyDuration;

  /// No description provided for @propertySelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit'**
  String get propertySelectUnit;

  /// No description provided for @propertySizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get propertySizeTitle;

  /// No description provided for @propertyLandSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Land Size'**
  String get propertyLandSizeTitle;

  /// No description provided for @propertySizeAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Size area (m²)'**
  String get propertySizeAreaHint;

  /// No description provided for @propertyEnterLandSize.
  ///
  /// In en, this message translates to:
  /// **'Enter land size (m²)'**
  String get propertyEnterLandSize;

  /// No description provided for @propertyEnterBuildingSize.
  ///
  /// In en, this message translates to:
  /// **'Enter building size'**
  String get propertyEnterBuildingSize;

  /// No description provided for @propertyEnterUnitSize.
  ///
  /// In en, this message translates to:
  /// **'Enter unit size'**
  String get propertyEnterUnitSize;

  /// No description provided for @propertyProjectNameInfo.
  ///
  /// In en, this message translates to:
  /// **'Official name of the development project'**
  String get propertyProjectNameInfo;

  /// No description provided for @propertyProjectAreaInfo.
  ///
  /// In en, this message translates to:
  /// **'Total land area of entire project'**
  String get propertyProjectAreaInfo;

  /// No description provided for @propertyStartingPriceInfo.
  ///
  /// In en, this message translates to:
  /// **'Lowest available unit price'**
  String get propertyStartingPriceInfo;

  /// No description provided for @propertyMonthlyRentInfo.
  ///
  /// In en, this message translates to:
  /// **'Lower rent = higher profit potential'**
  String get propertyMonthlyRentInfo;

  /// No description provided for @propertyEquipmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Describe assets included in sale'**
  String get propertyEquipmentInfo;

  /// No description provided for @propertySelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get propertySelectHint;

  /// No description provided for @propertyPublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Published\nSuccessfully!'**
  String get propertyPublishedTitle;

  /// No description provided for @propertyShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get propertyShowLess;

  /// No description provided for @propertyShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get propertyShowMore;

  /// No description provided for @propertyNoListingsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t listed any\nproperty yet'**
  String get propertyNoListingsYet;

  /// No description provided for @propertyPublishedToast.
  ///
  /// In en, this message translates to:
  /// **'Property published'**
  String get propertyPublishedToast;

  /// No description provided for @propertyMovedToDraft.
  ///
  /// In en, this message translates to:
  /// **'Property moved to draft'**
  String get propertyMovedToDraft;

  /// No description provided for @propertyPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get propertyPublish;

  /// No description provided for @propertyArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get propertyArchive;

  /// No description provided for @propertyArchivedPrivately.
  ///
  /// In en, this message translates to:
  /// **'Saved privately. Only you can see this listing.'**
  String get propertyArchivedPrivately;

  /// No description provided for @propertySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the property. Please try again.'**
  String get propertySaveFailed;

  /// No description provided for @propertyUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the property. Please try again.'**
  String get propertyUpdateFailed;

  /// No description provided for @propertyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the property. Please try again.'**
  String get propertyDeleteFailed;

  /// No description provided for @propertyListingBy.
  ///
  /// In en, this message translates to:
  /// **'Listing by: {name}'**
  String propertyListingBy(String name);

  /// No description provided for @propertyTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String propertyTabActive(int count);

  /// No description provided for @propertyTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String propertyTabPending(int count);

  /// No description provided for @propertyTabDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft ({count})'**
  String propertyTabDraft(int count);

  /// No description provided for @propertyTabSold.
  ///
  /// In en, this message translates to:
  /// **'Sold ({count})'**
  String propertyTabSold(int count);

  /// No description provided for @propertyContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get propertyContacts;

  /// No description provided for @propertySavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Saved'**
  String propertySavedCount(int count);

  /// No description provided for @propertySpecBeds.
  ///
  /// In en, this message translates to:
  /// **'{count} bds'**
  String propertySpecBeds(int count);

  /// No description provided for @propertySpecBaths.
  ///
  /// In en, this message translates to:
  /// **'{count} ba'**
  String propertySpecBaths(int count);

  /// No description provided for @propertyTypeForSale.
  ///
  /// In en, this message translates to:
  /// **'{type} for sale'**
  String propertyTypeForSale(String type);

  /// No description provided for @propertyTypeForRent.
  ///
  /// In en, this message translates to:
  /// **'{type} for rent'**
  String propertyTypeForRent(String type);

  /// No description provided for @propertyPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String propertyPriceFrom(String price);

  /// No description provided for @propertyBedroomCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Bed} other{{count} Beds}}'**
  String propertyBedroomCount(int count);

  /// No description provided for @propertyBathroomCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Bath} other{{count} Baths}}'**
  String propertyBathroomCount(int count);

  /// No description provided for @propertyDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String propertyDaysCount(int count);

  /// No description provided for @sortPropertyForYou.
  ///
  /// In en, this message translates to:
  /// **'Property for You'**
  String get sortPropertyForYou;

  /// No description provided for @sortRecentlyPosted.
  ///
  /// In en, this message translates to:
  /// **'Recently Posted'**
  String get sortRecentlyPosted;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortPriceHighToLow;

  /// No description provided for @sortPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortPriceLowToHigh;

  /// No description provided for @listingTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Type'**
  String get listingTypeTitle;

  /// No description provided for @listingTypeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get listingTypeSale;

  /// No description provided for @listingTypeRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get listingTypeRent;

  /// No description provided for @listingTypeToLet.
  ///
  /// In en, this message translates to:
  /// **'To Let'**
  String get listingTypeToLet;

  /// No description provided for @propertyTypeLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get propertyTypeLand;

  /// No description provided for @propertyTypeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get propertyTypeHouse;

  /// No description provided for @propertyTypeBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get propertyTypeBuilding;

  /// No description provided for @propertyTypeCondo.
  ///
  /// In en, this message translates to:
  /// **'Condo'**
  String get propertyTypeCondo;

  /// No description provided for @propertyTypeBorey.
  ///
  /// In en, this message translates to:
  /// **'Borey'**
  String get propertyTypeBorey;

  /// No description provided for @propertyTypeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business for Sale'**
  String get propertyTypeBusiness;

  /// No description provided for @propertyTypeBusinessShort.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get propertyTypeBusinessShort;

  /// No description provided for @propertyTypeWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get propertyTypeWarehouse;

  /// No description provided for @propertyStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get propertyStatusActive;

  /// No description provided for @propertyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get propertyStatusPending;

  /// No description provided for @propertyStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get propertyStatusDraft;

  /// No description provided for @propertyStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get propertyStatusSold;

  /// No description provided for @propertyStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get propertyStatusExpired;

  /// No description provided for @propertyOptionHardTitle.
  ///
  /// In en, this message translates to:
  /// **'Hard Title'**
  String get propertyOptionHardTitle;

  /// No description provided for @propertyOptionSoftTitle.
  ///
  /// In en, this message translates to:
  /// **'Soft Title'**
  String get propertyOptionSoftTitle;

  /// No description provided for @propertyOptionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get propertyOptionOther;

  /// No description provided for @propertyOptionStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get propertyOptionStudio;

  /// No description provided for @propertyOptionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get propertyOptionYes;

  /// No description provided for @propertyOptionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get propertyOptionNo;

  /// No description provided for @propertyOptionUnfurnished.
  ///
  /// In en, this message translates to:
  /// **'Unfurnished'**
  String get propertyOptionUnfurnished;

  /// No description provided for @propertyOptionFullyFurnished.
  ///
  /// In en, this message translates to:
  /// **'Fully Furnished'**
  String get propertyOptionFullyFurnished;

  /// No description provided for @propertyOptionElectricalAppliances.
  ///
  /// In en, this message translates to:
  /// **'Electrical appliances'**
  String get propertyOptionElectricalAppliances;

  /// No description provided for @propertyOptionCommercialBuilding.
  ///
  /// In en, this message translates to:
  /// **'Commercial Building'**
  String get propertyOptionCommercialBuilding;

  /// No description provided for @propertyOptionOfficeBuilding.
  ///
  /// In en, this message translates to:
  /// **'Office Building'**
  String get propertyOptionOfficeBuilding;

  /// No description provided for @propertyOptionMixedUse.
  ///
  /// In en, this message translates to:
  /// **'Mixed-use'**
  String get propertyOptionMixedUse;

  /// No description provided for @propertyOptionRetailBuilding.
  ///
  /// In en, this message translates to:
  /// **'Retail Building'**
  String get propertyOptionRetailBuilding;

  /// No description provided for @propertyOptionOffPlan.
  ///
  /// In en, this message translates to:
  /// **'Off-plan'**
  String get propertyOptionOffPlan;

  /// No description provided for @propertyOptionUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'Under Construction'**
  String get propertyOptionUnderConstruction;

  /// No description provided for @propertyOptionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get propertyOptionCompleted;

  /// No description provided for @propertyOptionCityView.
  ///
  /// In en, this message translates to:
  /// **'City View'**
  String get propertyOptionCityView;

  /// No description provided for @propertyOptionRiverView.
  ///
  /// In en, this message translates to:
  /// **'River View'**
  String get propertyOptionRiverView;

  /// No description provided for @propertyOptionGardenView.
  ///
  /// In en, this message translates to:
  /// **'Garden View'**
  String get propertyOptionGardenView;

  /// No description provided for @propertyOptionPoolView.
  ///
  /// In en, this message translates to:
  /// **'Pool View'**
  String get propertyOptionPoolView;

  /// No description provided for @propertyOptionNoView.
  ///
  /// In en, this message translates to:
  /// **'No View'**
  String get propertyOptionNoView;

  /// No description provided for @propertyOptionCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get propertyOptionCommercial;

  /// No description provided for @propertyOptionLandSubdivision.
  ///
  /// In en, this message translates to:
  /// **'Land Subdivision'**
  String get propertyOptionLandSubdivision;

  /// No description provided for @propertyOptionPreLaunch.
  ///
  /// In en, this message translates to:
  /// **'Pre-launch'**
  String get propertyOptionPreLaunch;

  /// No description provided for @propertyOptionCompleted50.
  ///
  /// In en, this message translates to:
  /// **'50% Completed'**
  String get propertyOptionCompleted50;

  /// No description provided for @propertyOptionCompleted80.
  ///
  /// In en, this message translates to:
  /// **'80% Completed'**
  String get propertyOptionCompleted80;

  /// No description provided for @propertyOptionMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get propertyOptionMonths;

  /// No description provided for @propertyOptionYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get propertyOptionYears;

  /// No description provided for @keywordRoadAccess.
  ///
  /// In en, this message translates to:
  /// **'Road Access'**
  String get keywordRoadAccess;

  /// No description provided for @keywordCornerLand.
  ///
  /// In en, this message translates to:
  /// **'Corner Land'**
  String get keywordCornerLand;

  /// No description provided for @keywordNearMarket.
  ///
  /// In en, this message translates to:
  /// **'Near Market'**
  String get keywordNearMarket;

  /// No description provided for @keywordNearSchool.
  ///
  /// In en, this message translates to:
  /// **'Near School'**
  String get keywordNearSchool;

  /// No description provided for @keywordNearHospital.
  ///
  /// In en, this message translates to:
  /// **'Near Hospital'**
  String get keywordNearHospital;

  /// No description provided for @keywordRiverLakeNearby.
  ///
  /// In en, this message translates to:
  /// **'River / Lake Nearby'**
  String get keywordRiverLakeNearby;

  /// No description provided for @keywordElectricityReady.
  ///
  /// In en, this message translates to:
  /// **'Electricity Ready'**
  String get keywordElectricityReady;

  /// No description provided for @keywordWaterSupply.
  ///
  /// In en, this message translates to:
  /// **'Water Supply'**
  String get keywordWaterSupply;

  /// No description provided for @keywordResidentialArea.
  ///
  /// In en, this message translates to:
  /// **'Residential Area'**
  String get keywordResidentialArea;

  /// No description provided for @keywordCommercialArea.
  ///
  /// In en, this message translates to:
  /// **'Commercial Area'**
  String get keywordCommercialArea;

  /// No description provided for @chatPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatPreviewVoice;

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record a voice message'**
  String get chatRecordVoice;

  /// No description provided for @chatRecordingVoice.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get chatRecordingVoice;

  /// No description provided for @chatSendVoice.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get chatSendVoice;

  /// No description provided for @chatDiscardVoice.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get chatDiscardVoice;

  /// No description provided for @chatSlideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get chatSlideToCancel;

  /// No description provided for @chatCallOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get chatCallOutgoing;

  /// No description provided for @chatCallIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get chatCallIncoming;

  /// No description provided for @chatCallLost.
  ///
  /// In en, this message translates to:
  /// **'Call lost'**
  String get chatCallLost;

  /// No description provided for @chatCallNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get chatCallNoAnswer;

  /// No description provided for @chatCallCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled call'**
  String get chatCallCancelled;

  /// No description provided for @chatCallDeclined.
  ///
  /// In en, this message translates to:
  /// **'Call declined'**
  String get chatCallDeclined;

  /// No description provided for @chatCallYouDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined the call'**
  String get chatCallYouDeclined;

  /// No description provided for @chatCallMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get chatCallMissed;

  /// No description provided for @chatVoiceTooShort.
  ///
  /// In en, this message translates to:
  /// **'Voice message too short.'**
  String get chatVoiceTooShort;

  /// No description provided for @chatVoiceRecordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not record. Try again.'**
  String get chatVoiceRecordFailed;

  /// No description provided for @chatVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice message unavailable. Tap to retry.'**
  String get chatVoiceUnavailable;

  /// No description provided for @chatPlayVoice.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get chatPlayVoice;

  /// No description provided for @chatPauseVoice.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get chatPauseVoice;

  /// No description provided for @chatVoiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get chatVoiceSpeed;

  /// No description provided for @microphoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to record your voice.'**
  String get microphoneDenied;

  /// No description provided for @microphoneBlocked.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is turned off. Turn it on in Settings.'**
  String get microphoneBlocked;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSystemSettings;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat messages'**
  String get notificationsChatTitle;

  /// No description provided for @notificationsChatHelp.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you a message.'**
  String get notificationsChatHelp;

  /// No description provided for @notificationsPromotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers and news'**
  String get notificationsPromotionsTitle;

  /// No description provided for @notificationsPromotionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Deals and updates from our team.'**
  String get notificationsPromotionsHelp;

  /// No description provided for @notificationsSavedSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved search alerts'**
  String get notificationsSavedSearchTitle;

  /// No description provided for @notificationsSavedSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'New listings that match a search you saved.'**
  String get notificationsSavedSearchHelp;

  /// No description provided for @notificationsFollowedTitle.
  ///
  /// In en, this message translates to:
  /// **'People you follow'**
  String get notificationsFollowedTitle;

  /// No description provided for @notificationsFollowedHelp.
  ///
  /// In en, this message translates to:
  /// **'When someone you follow posts a new listing.'**
  String get notificationsFollowedHelp;

  /// No description provided for @notificationsSavedUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved listings'**
  String get notificationsSavedUpdatesTitle;

  /// No description provided for @notificationsSavedUpdatesHelp.
  ///
  /// In en, this message translates to:
  /// **'Price drops, and when a listing you saved is sold.'**
  String get notificationsSavedUpdatesHelp;

  /// No description provided for @feedPriceDropped.
  ///
  /// In en, this message translates to:
  /// **'Price dropped'**
  String get feedPriceDropped;

  /// No description provided for @savedSearchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get savedSearchesTitle;

  /// No description provided for @savedSearchesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set map filters, then tap the bookmark to save your search.'**
  String get savedSearchesEmpty;

  /// No description provided for @savedSearchesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved searches.'**
  String get savedSearchesLoadFailed;

  /// No description provided for @savedSearchSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get savedSearchSaveTitle;

  /// No description provided for @savedSearchSaveHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tell you when a new listing in this map area matches your filter.'**
  String get savedSearchSaveHelp;

  /// No description provided for @savedSearchName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get savedSearchName;

  /// No description provided for @savedSearchSaved.
  ///
  /// In en, this message translates to:
  /// **'Search saved. We\'ll let you know about new listings.'**
  String get savedSearchSaved;

  /// No description provided for @savedSearchLimit.
  ///
  /// In en, this message translates to:
  /// **'You can save up to {count} searches. Delete one first.'**
  String savedSearchLimit(int count);

  /// No description provided for @savedSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Check your connection and try again.'**
  String get savedSearchFailed;

  /// No description provided for @savedSearchNoArea.
  ///
  /// In en, this message translates to:
  /// **'The map is still loading. Try again in a moment.'**
  String get savedSearchNoArea;

  /// No description provided for @savedSearchAnyListing.
  ///
  /// In en, this message translates to:
  /// **'Any listing in this area'**
  String get savedSearchAnyListing;

  /// No description provided for @savedSearchKeywords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 keyword} other{{count} keywords}}'**
  String savedSearchKeywords(int count);

  /// No description provided for @savedSearchAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get savedSearchAlerts;

  /// No description provided for @savedSearchRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedSearchRename;

  /// No description provided for @savedSearchDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savedSearchDelete;

  /// No description provided for @savedSearchDeleted.
  ///
  /// In en, this message translates to:
  /// **'Saved search deleted.'**
  String get savedSearchDeleted;

  /// No description provided for @notificationsAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Calls and sign-in alerts are always on.'**
  String get notificationsAlwaysOn;

  /// No description provided for @notificationsBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app'**
  String get notificationsBlockedTitle;

  /// No description provided for @notificationsBlockedHelp.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications in your phone’s settings.'**
  String get notificationsBlockedHelp;

  /// No description provided for @chatPreviewNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatPreviewNewMessage;

  /// No description provided for @notificationsShowTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Show message text'**
  String get notificationsShowTextTitle;

  /// No description provided for @notificationsShowTextHelp.
  ///
  /// In en, this message translates to:
  /// **'Show message text in notifications, including on your lock screen.'**
  String get notificationsShowTextHelp;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your notification settings.'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check your connection and try again.'**
  String get notificationsSaveFailed;

  /// No description provided for @callVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get callVoice;

  /// No description provided for @callCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get callCalling;

  /// No description provided for @callIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming voice call'**
  String get callIncoming;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Call declined'**
  String get callDeclined;

  /// No description provided for @callNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get callNoAnswer;

  /// No description provided for @callBusy.
  ///
  /// In en, this message translates to:
  /// **'On another call'**
  String get callBusy;

  /// No description provided for @callUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be called right now'**
  String get callUnavailable;

  /// No description provided for @callMicrophoneNeeded.
  ///
  /// In en, this message translates to:
  /// **'Calls need the microphone. Allow it in Settings.'**
  String get callMicrophoneNeeded;

  /// No description provided for @callConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get callConnectionLost;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Call failed'**
  String get callFailed;

  /// No description provided for @callAnsweredElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Answered on another device'**
  String get callAnsweredElsewhere;

  /// No description provided for @callAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callAccept;

  /// No description provided for @callDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// No description provided for @callHangUp.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callHangUp;

  /// No description provided for @callMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUnmute;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callIncomingFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} is calling'**
  String callIncomingFrom(String name);

  /// No description provided for @callMissedFrom.
  ///
  /// In en, this message translates to:
  /// **'Missed call from {name}'**
  String callMissedFrom(String name);

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterForSale.
  ///
  /// In en, this message translates to:
  /// **'For sale'**
  String get filterForSale;

  /// No description provided for @filterForRent.
  ///
  /// In en, this message translates to:
  /// **'For rent'**
  String get filterForRent;

  /// No description provided for @filterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get filterPriceRange;

  /// No description provided for @filterPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {range}'**
  String filterPriceLabel(String range);

  /// No description provided for @filterPriceAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterPriceAny;

  /// No description provided for @filterPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String filterPerMonth(String price);

  /// No description provided for @filterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get filterMinPrice;

  /// No description provided for @filterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get filterMaxPrice;

  /// No description provided for @filterNoMin.
  ///
  /// In en, this message translates to:
  /// **'No min'**
  String get filterNoMin;

  /// No description provided for @filterNoMax.
  ///
  /// In en, this message translates to:
  /// **'No max'**
  String get filterNoMax;

  /// No description provided for @filterDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get filterDownPayment;

  /// No description provided for @filterNoDownPayment.
  ///
  /// In en, this message translates to:
  /// **'No down payment'**
  String get filterNoDownPayment;

  /// No description provided for @filterLandSize.
  ///
  /// In en, this message translates to:
  /// **'Land size'**
  String get filterLandSize;

  /// No description provided for @filterPropertySize.
  ///
  /// In en, this message translates to:
  /// **'Property size'**
  String get filterPropertySize;

  /// No description provided for @filterMinArea.
  ///
  /// In en, this message translates to:
  /// **'Min m²'**
  String get filterMinArea;

  /// No description provided for @filterMaxArea.
  ///
  /// In en, this message translates to:
  /// **'Max m²'**
  String get filterMaxArea;

  /// No description provided for @filterMinAboveMax.
  ///
  /// In en, this message translates to:
  /// **'The minimum is above the maximum'**
  String get filterMinAboveMax;

  /// No description provided for @filterPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get filterPropertyType;

  /// No description provided for @filterKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords / Features'**
  String get filterKeywords;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterSeeResults.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get filterSeeResults;

  /// No description provided for @propertyFactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyFactsTitle;

  /// No description provided for @propertyFactsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get propertyFactsOverview;

  /// No description provided for @propertyFactsSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get propertyFactsSize;

  /// No description provided for @propertyFactsBuilding.
  ///
  /// In en, this message translates to:
  /// **'Rooms & Building'**
  String get propertyFactsBuilding;

  /// No description provided for @propertyFactsProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get propertyFactsProject;

  /// No description provided for @propertyFactsCosts.
  ///
  /// In en, this message translates to:
  /// **'Costs & Business'**
  String get propertyFactsCosts;

  /// No description provided for @propertyFactsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get propertyFactsFeatures;

  /// No description provided for @propertyFactPricePerSquareMetre.
  ///
  /// In en, this message translates to:
  /// **'Price per m²'**
  String get propertyFactPricePerSquareMetre;

  /// No description provided for @propertyFactPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String propertyFactPerMonth(String amount);

  /// No description provided for @propertyFactMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String propertyFactMonths(int count);

  /// No description provided for @propertyPublisherTitle.
  ///
  /// In en, this message translates to:
  /// **'Listed by'**
  String get propertyPublisherTitle;

  /// No description provided for @propertyPublisherViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get propertyPublisherViewProfile;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'012 345 678'**
  String get authPhoneHint;

  /// No description provided for @authEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get authEmailOptional;

  /// No description provided for @authAgreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreeToTermsPrefix;

  /// No description provided for @personalInfoAddEmail.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get personalInfoAddEmail;

  /// No description provided for @addEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmailTitle;

  /// No description provided for @addEmailIntro.
  ///
  /// In en, this message translates to:
  /// **'Add an email for password resets. Confirm with your password.'**
  String get addEmailIntro;

  /// No description provided for @addEmailDone.
  ///
  /// In en, this message translates to:
  /// **'Email added'**
  String get addEmailDone;

  /// No description provided for @addEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already used by another account.'**
  String get addEmailTaken;

  /// No description provided for @closestTitleNearYou.
  ///
  /// In en, this message translates to:
  /// **'Listings near you'**
  String get closestTitleNearYou;

  /// No description provided for @closestTitleNearMap.
  ///
  /// In en, this message translates to:
  /// **'Listings near the map centre'**
  String get closestTitleNearMap;

  /// No description provided for @closestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest first, then further away'**
  String get closestSubtitle;

  /// No description provided for @closestAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String closestAway(String distance);

  /// No description provided for @closestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get closestEmptyTitle;

  /// No description provided for @closestEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try clearing some filters.'**
  String get closestEmptyHint;

  /// No description provided for @closestLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Listings could not be loaded.'**
  String get closestLoadFailed;

  /// No description provided for @closestRefresh.
  ///
  /// In en, this message translates to:
  /// **'Measure from where I am now'**
  String get closestRefresh;

  /// No description provided for @closestShowList.
  ///
  /// In en, this message translates to:
  /// **'Show listings near you'**
  String get closestShowList;

  /// No description provided for @authEnterYourPhoneNumberToGet.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we will text you a code to reset your password.'**
  String get authEnterYourPhoneNumberToGet;

  /// No description provided for @authVerificationCodeSentToYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your phone'**
  String get authVerificationCodeSentToYourPhone;

  /// No description provided for @authEnterTheVerificationCodeWeTexted.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code we just texted to your phone.'**
  String get authEnterTheVerificationCodeWeTexted;

  /// No description provided for @authErrorNoAccountForPhone.
  ///
  /// In en, this message translates to:
  /// **'No account uses this phone number.'**
  String get authErrorNoAccountForPhone;

  /// No description provided for @authErrorSmsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Text messages cannot be sent right now. Reset with your email, or try again later.'**
  String get authErrorSmsUnavailable;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get planSilver;

  /// No description provided for @planGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get planGold;

  /// No description provided for @planDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get planDiamond;

  /// No description provided for @planMember.
  ///
  /// In en, this message translates to:
  /// **'{tier} member'**
  String planMember(String tier);

  /// No description provided for @planAccount.
  ///
  /// In en, this message translates to:
  /// **'{tier} Account'**
  String planAccount(String tier);

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get planPerMonth;

  /// No description provided for @planListingsUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} listings used'**
  String planListingsUsed(int used, int limit);

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get planCurrent;

  /// No description provided for @planUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {tier}'**
  String planUpgradeTo(String tier);

  /// No description provided for @planFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get planFeatures;

  /// No description provided for @planFeatureLimit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Publish 1 property at a time} other{Publish up to {count} properties}}'**
  String planFeatureLimit(int count);

  /// No description provided for @planFeatureFree.
  ///
  /// In en, this message translates to:
  /// **'Basic listing visibility'**
  String get planFeatureFree;

  /// No description provided for @planFeatureSilver.
  ///
  /// In en, this message translates to:
  /// **'Suits small agents'**
  String get planFeatureSilver;

  /// No description provided for @planFeatureGold.
  ///
  /// In en, this message translates to:
  /// **'Higher listing capacity'**
  String get planFeatureGold;

  /// No description provided for @planFeatureDiamond.
  ///
  /// In en, this message translates to:
  /// **'Highest listing capacity'**
  String get planFeatureDiamond;

  /// No description provided for @planChooseIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to publish more properties.'**
  String get planChooseIntro;

  /// No description provided for @planUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Subscription'**
  String get planUpgradeTitle;

  /// No description provided for @planUpgradeIntro.
  ///
  /// In en, this message translates to:
  /// **'New plans last one month. Upgrades charge only the price difference for your remaining time and keep your expiry date.'**
  String get planUpgradeIntro;

  /// No description provided for @planSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get planSubscribe;

  /// No description provided for @paymentSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get paymentSelectMethod;

  /// No description provided for @paymentTaxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Total price includes 10% tax.'**
  String get paymentTaxIncluded;

  /// No description provided for @paymentAbaPay.
  ///
  /// In en, this message translates to:
  /// **'ABA PAY'**
  String get paymentAbaPay;

  /// No description provided for @paymentAbaPayHint.
  ///
  /// In en, this message translates to:
  /// **'Pay with ABA Mobile'**
  String get paymentAbaPayHint;

  /// No description provided for @paymentAbaKhqr.
  ///
  /// In en, this message translates to:
  /// **'ABA KHQR'**
  String get paymentAbaKhqr;

  /// No description provided for @paymentAbaKhqrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to pay with any banking app'**
  String get paymentAbaKhqrHint;

  /// No description provided for @paymentAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for ABA to confirm your payment. This usually takes a minute.'**
  String get paymentAwaitingConfirmation;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment was not completed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @paymentRefundRequired.
  ///
  /// In en, this message translates to:
  /// **'Your payment arrived after the upgrade expired. Please contact support with your transaction reference for a refund.'**
  String get paymentRefundRequired;

  /// No description provided for @paymentAppNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Could not open ABA Mobile or the payment page.'**
  String get paymentAppNotOpened;

  /// No description provided for @paymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online payment is not available yet. Please try again later.'**
  String get paymentUnavailable;

  /// No description provided for @paymentCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the payment. Please try again.'**
  String get paymentCouldNotStart;

  /// No description provided for @paymentBillingSummary.
  ///
  /// In en, this message translates to:
  /// **'Billing Summary'**
  String get paymentBillingSummary;

  /// No description provided for @paymentPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get paymentPlan;

  /// No description provided for @paymentPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get paymentPrice;

  /// No description provided for @paymentBillingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get paymentBillingCycle;

  /// No description provided for @paymentMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paymentMonthly;

  /// No description provided for @paymentTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get paymentTotal;

  /// No description provided for @paymentOneTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'One-Time Payment'**
  String get paymentOneTimeTitle;

  /// No description provided for @paymentOneTimeIntro.
  ///
  /// In en, this message translates to:
  /// **'Your property is ready to be published.'**
  String get paymentOneTimeIntro;

  /// No description provided for @publishingRenewListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew property post'**
  String get publishingRenewListingTitle;

  /// No description provided for @publishingRenewListingMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep this property public for one month. Pay for this post, or use an active subscription with space available.'**
  String get publishingRenewListingMessage;

  /// No description provided for @publishingRenewSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew your subscription'**
  String get publishingRenewSubscriptionTitle;

  /// No description provided for @publishingRenewSubscriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has expired. Renew your plan to publish your properties again. Your original free listing stays available.'**
  String get publishingRenewSubscriptionMessage;

  /// No description provided for @paymentPropertyInformation.
  ///
  /// In en, this message translates to:
  /// **'Property information'**
  String get paymentPropertyInformation;

  /// No description provided for @paymentOneTime.
  ///
  /// In en, this message translates to:
  /// **'One month · one-time payment'**
  String get paymentOneTime;

  /// No description provided for @paymentPublishProperty.
  ///
  /// In en, this message translates to:
  /// **'Publish Property'**
  String get paymentPublishProperty;

  /// No description provided for @paymentProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get paymentProperty;

  /// No description provided for @paymentCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get paymentCategory;

  /// No description provided for @publishPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Publishing Plan'**
  String get publishPlanTitle;

  /// No description provided for @publishPlanOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-Time Publish'**
  String get publishPlanOneTime;

  /// No description provided for @publishPlanOneTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Pay {price} to publish this property for one month.'**
  String publishPlanOneTimeHint(String price);

  /// No description provided for @publishPlanSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get publishPlanSubscription;

  /// No description provided for @publishPlanSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Publish many properties every month.'**
  String get publishPlanSubscriptionHint;

  /// No description provided for @publishPlanChooseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan or one-time payment to publish.'**
  String get publishPlanChooseFirst;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: November 4, 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'What we collect, how we use it, and your choices.'**
  String get privacyIntro;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectAccount.
  ///
  /// In en, this message translates to:
  /// **'Your name, username, phone number, optional email and profile photo.'**
  String get privacyCollectAccount;

  /// No description provided for @privacyCollectListings.
  ///
  /// In en, this message translates to:
  /// **'Listing photos, descriptions, prices, map locations, boundaries and contact numbers.'**
  String get privacyCollectListings;

  /// No description provided for @privacyCollectLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location, only when you allow it, to show listings and routes near you.'**
  String get privacyCollectLocation;

  /// No description provided for @privacyCollectActivity.
  ///
  /// In en, this message translates to:
  /// **'Saved listings and searches, follows and listing views, used for insights.'**
  String get privacyCollectActivity;

  /// No description provided for @privacyCollectDevice.
  ///
  /// In en, this message translates to:
  /// **'App version, phone model, sign-in device key and notification token for security and notifications.'**
  String get privacyCollectDevice;

  /// No description provided for @privacyUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How we use it'**
  String get privacyUseTitle;

  /// No description provided for @privacyUseRun.
  ///
  /// In en, this message translates to:
  /// **'To run the marketplace: show listings, connect buyers with owners, and deliver chats and calls.'**
  String get privacyUseRun;

  /// No description provided for @privacyUseProtect.
  ///
  /// In en, this message translates to:
  /// **'To protect accounts: spot suspicious sign-ins, limit misuse and act on reports.'**
  String get privacyUseProtect;

  /// No description provided for @privacyUseFix.
  ///
  /// In en, this message translates to:
  /// **'To fix problems: crash and error reports help us find bugs.'**
  String get privacyUseFix;

  /// No description provided for @privacyUseNoSale.
  ///
  /// In en, this message translates to:
  /// **'We do not sell your personal information.'**
  String get privacyUseNoSale;

  /// No description provided for @privacyChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages and calls'**
  String get privacyChatTitle;

  /// No description provided for @privacyChatBody.
  ///
  /// In en, this message translates to:
  /// **'Messages are encrypted when sent and stored. Only chat participants can access them through the app. Tilomnov manages the encryption keys. No chat PIN is needed. Older encrypted messages are kept but can’t be opened.'**
  String get privacyChatBody;

  /// No description provided for @privacyPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get privacyPaymentsTitle;

  /// No description provided for @privacyPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'ABA PayWay handles payments. We never see or store card or bank details. We keep the transaction reference, amount, status and date with your account.'**
  String get privacyPaymentsBody;

  /// No description provided for @privacySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see your information'**
  String get privacySharingTitle;

  /// No description provided for @privacySharingIntro.
  ///
  /// In en, this message translates to:
  /// **'We share information only as far as the app needs it:'**
  String get privacySharingIntro;

  /// No description provided for @privacySharingUsers.
  ///
  /// In en, this message translates to:
  /// **'Others can see your listings, public profile and listing contact number.'**
  String get privacySharingUsers;

  /// No description provided for @privacySharingProviders.
  ///
  /// In en, this message translates to:
  /// **'Google handles maps, sign-in, phone verification and notifications; Sentry handles error reports; ABA Bank handles payments.'**
  String get privacySharingProviders;

  /// No description provided for @privacySharingLaw.
  ///
  /// In en, this message translates to:
  /// **'Authorities, when the law requires it.'**
  String get privacySharingLaw;

  /// No description provided for @privacyCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookies and storage on your phone'**
  String get privacyCookiesTitle;

  /// No description provided for @privacyCookiesIntro.
  ///
  /// In en, this message translates to:
  /// **'No advertising or tracking cookies. We store these on your phone:'**
  String get privacyCookiesIntro;

  /// No description provided for @privacyCookiesSignIn.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in, kept in your phone\'s secure storage.'**
  String get privacyCookiesSignIn;

  /// No description provided for @privacyCookiesSettings.
  ///
  /// In en, this message translates to:
  /// **'Your settings, such as theme and language.'**
  String get privacyCookiesSettings;

  /// No description provided for @privacyCookiesOffline.
  ///
  /// In en, this message translates to:
  /// **'Recent pages and photos for faster loading and offline use.'**
  String get privacyCookiesOffline;

  /// No description provided for @privacyCookiesClear.
  ///
  /// In en, this message translates to:
  /// **'Sign out to remove your login. Clear app storage in your phone’s settings to remove other stored data.'**
  String get privacyCookiesClear;

  /// No description provided for @privacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get privacyChoicesTitle;

  /// No description provided for @privacyChoicesEdit.
  ///
  /// In en, this message translates to:
  /// **'View and change your details at any time in Account > Personal information.'**
  String get privacyChoicesEdit;

  /// No description provided for @privacyChoicesLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn location access off in your phone\'s settings; the map still works without it.'**
  String get privacyChoicesLocation;

  /// No description provided for @privacyChoicesNotifications.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you get in Account > Notifications.'**
  String get privacyChoicesNotifications;

  /// No description provided for @privacyChoicesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete your listings at any time. To close your account, contact us.'**
  String get privacyChoicesDelete;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Contact the Tilomnov team with questions. The date above shows the latest update.'**
  String get privacyContactBody;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} USD'**
  String paymentSuccessAmount(String amount);

  /// No description provided for @paymentSuccessTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID  #{id}'**
  String paymentSuccessTransaction(String id);

  /// No description provided for @paymentSuccessEmailed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmation email:'**
  String get paymentSuccessEmailed;

  /// No description provided for @paymentSuccessNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Add an email in Personal information to get receipts by email.'**
  String get paymentSuccessNoEmail;

  /// No description provided for @paymentDownloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get paymentDownloadReceipt;

  /// No description provided for @paymentBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get paymentBackToHome;

  /// No description provided for @paymentReceiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved to your photos.'**
  String get paymentReceiptSaved;

  /// No description provided for @paymentReceiptSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the receipt. Please try again.'**
  String get paymentReceiptSaveFailed;

  /// No description provided for @paymentReceiptPhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your photos to save the receipt.'**
  String get paymentReceiptPhotosDenied;

  /// No description provided for @paymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get paymentReceiptTitle;

  /// No description provided for @paymentReceiptTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get paymentReceiptTransaction;

  /// No description provided for @paymentReceiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get paymentReceiptDate;

  /// No description provided for @paymentReceiptItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get paymentReceiptItem;

  /// No description provided for @paymentReceiptMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentReceiptMethod;

  /// No description provided for @paymentReceiptEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get paymentReceiptEmail;

  /// No description provided for @paymentReceiptStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get paymentReceiptStatus;

  /// No description provided for @paymentReceiptPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentReceiptPaid;

  /// No description provided for @paymentItemSubscription.
  ///
  /// In en, this message translates to:
  /// **'{tier} plan · Monthly'**
  String paymentItemSubscription(String tier);

  /// No description provided for @paymentItemOneTimePublish.
  ///
  /// In en, this message translates to:
  /// **'Property post · one month'**
  String get paymentItemOneTimePublish;

  /// No description provided for @planCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get planCancelAction;

  /// No description provided for @planCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your plan?'**
  String get planCancelTitle;

  /// No description provided for @planCancelExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your plan stays active until {date}. You keep your paid benefits until then.'**
  String planCancelExplanation(String date);

  /// No description provided for @planActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Plan active until {date}.'**
  String planActiveUntil(String date);

  /// No description provided for @planCancelledUntil.
  ///
  /// In en, this message translates to:
  /// **'Plan cancelled. Your access stays active until {date}.'**
  String planCancelledUntil(String date);

  /// No description provided for @planCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not cancel your plan. Please try again.'**
  String get planCancelFailed;

  /// No description provided for @planStatusRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load your plan. Tap to retry.'**
  String get planStatusRetry;

  /// No description provided for @listingTypeTakeover.
  ///
  /// In en, this message translates to:
  /// **'Takeover Payments'**
  String get listingTypeTakeover;

  /// No description provided for @takeoverIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the existing payment plan. Buyers pay you the seller amount, then take responsibility for the remaining balance, subject to provider approval.'**
  String get takeoverIntro;

  /// No description provided for @takeoverProviderType.
  ///
  /// In en, this message translates to:
  /// **'Payment provider type'**
  String get takeoverProviderType;

  /// No description provided for @takeoverProviderName.
  ///
  /// In en, this message translates to:
  /// **'Developer or bank name'**
  String get takeoverProviderName;

  /// No description provided for @takeoverProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get takeoverProjectName;

  /// No description provided for @takeoverSellerAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount payable to seller (USD)'**
  String get takeoverSellerAmount;

  /// No description provided for @takeoverBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance (USD)'**
  String get takeoverBalance;

  /// No description provided for @takeoverBalanceHelp.
  ///
  /// In en, this message translates to:
  /// **'Outstanding contract balance or loan principal, excluding future financing interest. Include any larger scheduled payments in this balance.'**
  String get takeoverBalanceHelp;

  /// No description provided for @takeoverBalanceDate.
  ///
  /// In en, this message translates to:
  /// **'Balance as of'**
  String get takeoverBalanceDate;

  /// No description provided for @takeoverPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Regular instalment (USD)'**
  String get takeoverPaymentAmount;

  /// No description provided for @takeoverFrequency.
  ///
  /// In en, this message translates to:
  /// **'Payment frequency'**
  String get takeoverFrequency;

  /// No description provided for @takeoverRemainingMonths.
  ///
  /// In en, this message translates to:
  /// **'Months remaining'**
  String get takeoverRemainingMonths;

  /// No description provided for @takeoverNextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment due'**
  String get takeoverNextPayment;

  /// No description provided for @takeoverInterestType.
  ///
  /// In en, this message translates to:
  /// **'Interest terms'**
  String get takeoverInterestType;

  /// No description provided for @takeoverAnnualRate.
  ///
  /// In en, this message translates to:
  /// **'Current annual interest rate (%)'**
  String get takeoverAnnualRate;

  /// No description provided for @takeoverTransferStatus.
  ///
  /// In en, this message translates to:
  /// **'Transfer permission (seller-reported)'**
  String get takeoverTransferStatus;

  /// No description provided for @takeoverTransferFee.
  ///
  /// In en, this message translates to:
  /// **'Transfer fee (USD, leave blank if unknown)'**
  String get takeoverTransferFee;

  /// No description provided for @takeoverFeePayer.
  ///
  /// In en, this message translates to:
  /// **'Who pays the transfer fee?'**
  String get takeoverFeePayer;

  /// No description provided for @takeoverArrears.
  ///
  /// In en, this message translates to:
  /// **'Overdue amount (USD, enter 0 if none)'**
  String get takeoverArrears;

  /// No description provided for @takeoverArrearsHelp.
  ///
  /// In en, this message translates to:
  /// **'Disclose unpaid instalments and penalties. Explain in the notes whether overdue principal is already included in the balance.'**
  String get takeoverArrearsHelp;

  /// No description provided for @takeoverArrearsPayer.
  ///
  /// In en, this message translates to:
  /// **'Who settles the overdue amount?'**
  String get takeoverArrearsPayer;

  /// No description provided for @takeoverHasAdditional.
  ///
  /// In en, this message translates to:
  /// **'Any additional large scheduled payments?'**
  String get takeoverHasAdditional;

  /// No description provided for @takeoverAdditionalAmount.
  ///
  /// In en, this message translates to:
  /// **'Scheduled payment amount (USD)'**
  String get takeoverAdditionalAmount;

  /// No description provided for @takeoverAdditionalDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled payment due'**
  String get takeoverAdditionalDate;

  /// No description provided for @takeoverAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add scheduled payment'**
  String get takeoverAddPayment;

  /// No description provided for @takeoverRemovePayment.
  ///
  /// In en, this message translates to:
  /// **'Remove scheduled payment'**
  String get takeoverRemovePayment;

  /// No description provided for @takeoverAdditionalHelp.
  ///
  /// In en, this message translates to:
  /// **'Include handover or balloon payments here. These amounts are already part of the remaining balance.'**
  String get takeoverAdditionalHelp;

  /// No description provided for @takeoverNotes.
  ///
  /// In en, this message translates to:
  /// **'Payment plan and transfer notes'**
  String get takeoverNotes;

  /// No description provided for @takeoverCombinedPrice.
  ///
  /// In en, this message translates to:
  /// **'Combined price before future interest and fees'**
  String get takeoverCombinedPrice;

  /// No description provided for @takeoverCombinedHelp.
  ///
  /// In en, this message translates to:
  /// **'Seller amount + remaining balance. Future interest, transfer fees and overdue charges may add to the buyer\'s cost.'**
  String get takeoverCombinedHelp;

  /// No description provided for @takeoverInvalid.
  ///
  /// In en, this message translates to:
  /// **'Complete or correct the highlighted takeover details before publishing.'**
  String get takeoverInvalid;

  /// No description provided for @takeoverFieldError.
  ///
  /// In en, this message translates to:
  /// **'Required or invalid value'**
  String get takeoverFieldError;

  /// No description provided for @takeoverNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This contract cannot be listed for takeover while transfers are not allowed.'**
  String get takeoverNotAllowed;

  /// No description provided for @takeoverBuyerNotice.
  ///
  /// In en, this message translates to:
  /// **'Terms and permission are reported by the seller, not verified by Tilomnov. Confirm the balance, fees and transfer process directly with the developer or bank. Listing a property does not transfer its contract or loan.'**
  String get takeoverBuyerNotice;

  /// No description provided for @takeoverDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get takeoverDateHint;

  /// No description provided for @takeoverProviderDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer instalments'**
  String get takeoverProviderDeveloper;

  /// No description provided for @takeoverProviderBank.
  ///
  /// In en, this message translates to:
  /// **'Bank loan'**
  String get takeoverProviderBank;

  /// No description provided for @takeoverMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get takeoverMonthly;

  /// No description provided for @takeoverQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get takeoverQuarterly;

  /// No description provided for @takeoverYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get takeoverYearly;

  /// No description provided for @takeoverInterestNone.
  ///
  /// In en, this message translates to:
  /// **'Interest-free'**
  String get takeoverInterestNone;

  /// No description provided for @takeoverInterestFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed rate'**
  String get takeoverInterestFixed;

  /// No description provided for @takeoverInterestVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable rate'**
  String get takeoverInterestVariable;

  /// No description provided for @takeoverUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown / to be confirmed'**
  String get takeoverUnknown;

  /// No description provided for @takeoverNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not yet checked with provider'**
  String get takeoverNotChecked;

  /// No description provided for @takeoverConditional.
  ///
  /// In en, this message translates to:
  /// **'Allowed subject to provider conditions'**
  String get takeoverConditional;

  /// No description provided for @takeoverWrittenApproval.
  ///
  /// In en, this message translates to:
  /// **'Written permission available'**
  String get takeoverWrittenApproval;

  /// No description provided for @takeoverNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'Transfer not allowed'**
  String get takeoverNotPermitted;

  /// No description provided for @takeoverBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get takeoverBuyer;

  /// No description provided for @takeoverSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get takeoverSeller;

  /// No description provided for @takeoverShared.
  ///
  /// In en, this message translates to:
  /// **'Shared by buyer and seller'**
  String get takeoverShared;

  /// No description provided for @takeoverMonthsValue.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String takeoverMonthsValue(int months);

  /// No description provided for @takeoverToSellerValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} to seller'**
  String takeoverToSellerValue(String amount);

  /// No description provided for @takeoverPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} combined'**
  String takeoverPriceLabel(String amount);

  /// No description provided for @takeoverPaymentValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {frequency}'**
  String takeoverPaymentValue(String amount, String frequency);

  /// No description provided for @takeoverBuyerTransferFee.
  ///
  /// In en, this message translates to:
  /// **'Transfer fee'**
  String get takeoverBuyerTransferFee;

  /// No description provided for @takeoverBuyerArrears.
  ///
  /// In en, this message translates to:
  /// **'Overdue payments and penalties'**
  String get takeoverBuyerArrears;

  /// No description provided for @adminEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your admin email'**
  String get adminEmailTitle;

  /// No description provided for @adminEmailWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your password was accepted. Open Gmail and tap Open Tilomnov in the sign-in email to finish signing in. The link expires in 10 minutes.'**
  String get adminEmailWaiting;

  /// No description provided for @adminEmailVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your sign-in link...'**
  String get adminEmailVerifying;

  /// No description provided for @adminEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'This sign-in link could not be verified. It may be expired or already used, or the connection failed. Please sign in again to request a new email.'**
  String get adminEmailInvalid;

  /// No description provided for @adminEmailBack.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get adminEmailBack;

  /// No description provided for @advertisementLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get advertisementLabel;

  /// No description provided for @themeLiquidGlass.
  ///
  /// In en, this message translates to:
  /// **'Liquid Glass'**
  String get themeLiquidGlass;

  /// No description provided for @themeMinimalistic.
  ///
  /// In en, this message translates to:
  /// **'Minimalistic'**
  String get themeMinimalistic;

  /// No description provided for @planAnnualOffer.
  ///
  /// In en, this message translates to:
  /// **'Annual · 2 months free'**
  String get planAnnualOffer;

  /// No description provided for @paymentAnnual.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get paymentAnnual;

  /// No description provided for @planPerYear.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get planPerYear;

  /// No description provided for @planExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Access until'**
  String get planExpiryDate;

  /// No description provided for @planManualRenewal.
  ///
  /// In en, this message translates to:
  /// **'One payment only. No automatic renewal. Renew manually at the displayed plan price when this period ends.'**
  String get planManualRenewal;

  /// No description provided for @paymentOneTimeDuration.
  ///
  /// In en, this message translates to:
  /// **'30 days · manual renewal'**
  String get paymentOneTimeDuration;

  /// No description provided for @authRecoveryEmailOnly.
  ///
  /// In en, this message translates to:
  /// **'Password recovery uses the email linked to your account. If you signed up with Google, sign in with Google. Add an email in Account Security so you can recover a forgotten password.'**
  String get authRecoveryEmailOnly;

  /// No description provided for @propertyAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add another phone number'**
  String get propertyAddPhone;

  /// No description provided for @propertyAdditionalPhone.
  ///
  /// In en, this message translates to:
  /// **'Additional phone number'**
  String get propertyAdditionalPhone;

  /// No description provided for @propertyRemovePhone.
  ///
  /// In en, this message translates to:
  /// **'Remove phone number'**
  String get propertyRemovePhone;

  /// No description provided for @searchApproximateArea.
  ///
  /// In en, this message translates to:
  /// **'Approximate search area'**
  String get searchApproximateArea;

  /// No description provided for @authRecoveryEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Add an email for password recovery. Your phone number is for contact only.'**
  String get authRecoveryEmailHint;

  /// No description provided for @paymentEstimatedExpiry.
  ///
  /// In en, this message translates to:
  /// **'Estimated expiry'**
  String get paymentEstimatedExpiry;

  /// No description provided for @paymentRenewalPrice.
  ///
  /// In en, this message translates to:
  /// **'Renewal for another 30 days'**
  String get paymentRenewalPrice;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
