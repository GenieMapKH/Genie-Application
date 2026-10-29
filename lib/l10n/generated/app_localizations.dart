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
  /// **'You are offline. Connect to the internet for updates.'**
  String get commonOffline;

  /// No description provided for @offlineDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineDialogTitle;

  /// No description provided for @offlineDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your Wi-Fi or mobile data. You can keep browsing what is saved on this phone.'**
  String get offlineDialogMessage;

  /// No description provided for @offlineKeepBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Keep browsing'**
  String get offlineKeepBrowsing;

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
  /// **'Please log in or sign up to access this feature.'**
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

  /// No description provided for @accountSubscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get accountSubscriptionFree;

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
  /// **'Glass navigation'**
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
  /// **'Your username is yours alone and is how people find you. Use 3 to 30 lowercase letters, numbers, \"_\" or \".\".'**
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
  /// **'The name other people see. It does not have to be unique, and you can change it any time.'**
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
  /// **'Used for signing in and so buyers can reach you.'**
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

  /// No description provided for @securitySectionEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption'**
  String get securitySectionEncryption;

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

  /// No description provided for @securityChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change chat PIN'**
  String get securityChangePin;

  /// No description provided for @securityResetKeys.
  ///
  /// In en, this message translates to:
  /// **'Reset encryption keys'**
  String get securityResetKeys;

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

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get pinHint;

  /// No description provided for @pinSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get pinSubmit;

  /// No description provided for @pinIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits.'**
  String get pinIncomplete;

  /// No description provided for @pinTooGuessable.
  ///
  /// In en, this message translates to:
  /// **'Too easy to guess. Choose another PIN.'**
  String get pinTooGuessable;

  /// No description provided for @pinEnterCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get pinEnterCurrentTitle;

  /// No description provided for @pinEnterCurrentHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your current 6-digit PIN to confirm it is you.'**
  String get pinEnterCurrentHelp;

  /// No description provided for @pinEnterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get pinEnterNewTitle;

  /// No description provided for @pinEnterNewHelp.
  ///
  /// In en, this message translates to:
  /// **'The new PIN will protect your existing keys.'**
  String get pinEnterNewHelp;

  /// No description provided for @pinForNewKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN for the new keys'**
  String get pinForNewKeysTitle;

  /// No description provided for @pinForNewKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'This PIN will protect your new keys. You need it to read your chats on another device.'**
  String get pinForNewKeysHelp;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'Chat PIN changed.'**
  String get pinChanged;

  /// No description provided for @pinNoBackup.
  ///
  /// In en, this message translates to:
  /// **'You have no chat PIN yet.'**
  String get pinNoBackup;

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Your PIN is locked for a while; try again later.'**
  String get pinLocked;

  /// No description provided for @pinFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the key backup. Check your connection.'**
  String get pinFetchFailed;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. After 5 wrong tries your PIN locks for a while.'**
  String get pinWrong;

  /// No description provided for @pinSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the new backup. Nothing was changed.'**
  String get pinSaveFailed;

  /// No description provided for @resetKeysConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset encryption keys?'**
  String get resetKeysConfirmTitle;

  /// No description provided for @resetKeysConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'New keys will be created and you will lose access to all earlier chat history. This cannot be undone.\n\nYou will be asked for your current chat PIN first.'**
  String get resetKeysConfirmMessage;

  /// No description provided for @resetKeysConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reset keys'**
  String get resetKeysConfirmAction;

  /// No description provided for @resetKeysDone.
  ///
  /// In en, this message translates to:
  /// **'Encryption keys reset.'**
  String get resetKeysDone;

  /// No description provided for @resetKeysFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the keys. Nothing was changed.'**
  String get resetKeysFailed;

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
  /// **'After the change, every other device signed in to your account will be signed out.'**
  String get passwordIntro;

  /// No description provided for @devicesIntro.
  ///
  /// In en, this message translates to:
  /// **'These devices are signed in to your account. Sign out any you do not recognise, then change your password.'**
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
  /// **'Your profile and listings are hidden and you are signed out everywhere. Nothing is deleted: sign in again to bring it all back.'**
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
  /// **'Your account, listings, saved properties and chats are permanently deleted. This cannot be undone.'**
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
  /// **'You sign in with Google. Confirm with your Google account to continue.'**
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
  /// **'Enter your email address to get the password reset link.'**
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

  /// No description provided for @authLoginFailedPleaseCheckYourCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials and try again.'**
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
  /// **'Enter the verification code we just sent to your email.'**
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
  /// **'Enter your new password twice below to reset a new password'**
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
  /// **'Password reset successfully! Please log in with your new password.'**
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
  /// **'An archived chat comes back to your list when a new message arrives.'**
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
  /// **'It is removed from your chats only. {name} still has it.'**
  String chatDeleteForMeExplained(String name);

  /// No description provided for @chatDeleteForBoth.
  ///
  /// In en, this message translates to:
  /// **'Also delete for {name}'**
  String chatDeleteForBoth(String name);

  /// No description provided for @chatDeleteForBothExplained.
  ///
  /// In en, this message translates to:
  /// **'Every message and photo is deleted for both of you. This cannot be undone.'**
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
  /// **'That did not work. Check your connection and try again.'**
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

  /// No description provided for @chatMessagesAreEndToEndEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Messages are end-to-end encrypted. Say hello!'**
  String get chatMessagesAreEndToEndEncrypted;

  /// No description provided for @chatNoChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet!'**
  String get chatNoChatsYet;

  /// No description provided for @chatMessageAPropertyOwnerToStart.
  ///
  /// In en, this message translates to:
  /// **'Message a property owner to start a conversation.'**
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

  /// No description provided for @chatThisIsNormalIfTheyReinstalled.
  ///
  /// In en, this message translates to:
  /// **'This is normal if they reinstalled the app or reset their keys. If you did not expect it, someone may be trying to read your messages: accept the new key, then compare the security code with them before sharing anything private.'**
  String get chatThisIsNormalIfTheyReinstalled;

  /// No description provided for @chatSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Security code'**
  String get chatSecurityCode;

  /// No description provided for @chatAcceptNewKey.
  ///
  /// In en, this message translates to:
  /// **'Accept new key'**
  String get chatAcceptNewKey;

  /// No description provided for @chatAvailableOnceYouHaveBothSet.
  ///
  /// In en, this message translates to:
  /// **'Available once you have both set up secure chat.'**
  String get chatAvailableOnceYouHaveBothSet;

  /// No description provided for @chatTheSecurityCodeIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The security code is unavailable.'**
  String get chatTheSecurityCodeIsUnavailable;

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
  /// **'Please fill both X and Y coordinates for a row, or leave both empty.'**
  String get homePleaseFillBothXAndY;

  /// No description provided for @homeCoordinatesMustBeValidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Coordinates must be valid numbers.'**
  String get homeCoordinatesMustBeValidNumbers;

  /// No description provided for @homePleaseEnterAtLeast3Coordinates.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 3 coordinates to form a property.'**
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
  /// **'Use UTM from a land document or enter coordinates manually'**
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
  /// **'Tap the heart icon on listings to save them for later.'**
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
  /// **'Add at least 3 clear photos of the property and surrounding area'**
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

  /// No description provided for @propertyNoPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number was shared for this listing. Try chatting with the owner instead.'**
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
  /// **'Nobody has opened this listing yet. Publishing it, good photos and sharing its link bring the first viewers.'**
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
  /// **'Only you can see this listing until it is published. Publish it to share its link and QR code.'**
  String get propertyShareNotPublicDraft;

  /// No description provided for @propertyShareNotPublicPending.
  ///
  /// In en, this message translates to:
  /// **'This listing goes public once its payment is complete. You can share it then.'**
  String get propertyShareNotPublicPending;

  /// No description provided for @propertyShareNotPublicEnded.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer public, so its link and QR code cannot be shared.'**
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

  /// No description provided for @chatSecurityCodeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Messages are end-to-end encrypted. To be sure nobody is in between, compare this code with {name} in person or on a call: it must be the same on both phones.'**
  String chatSecurityCodeExplanation(String name);

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
  /// **'This version of Tilomnov no longer works with our servers. Please update the app from your app store to keep using it.'**
  String get updateRequiredMessage;

  /// No description provided for @securityForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot chat PIN'**
  String get securityForgotPin;

  /// No description provided for @securityCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get securityCreatePassword;

  /// No description provided for @createPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google, so this account has no password yet. Choose one, then confirm with your Google account. You can keep signing in with Google.'**
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

  /// No description provided for @forgotPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your chat PIN?'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinKeepsHistory.
  ///
  /// In en, this message translates to:
  /// **'This phone still has your chat keys, so nothing is lost. Confirm it is you with your account password, then choose a new PIN.'**
  String get forgotPinKeepsHistory;

  /// No description provided for @forgotPinLosesHistory.
  ///
  /// In en, this message translates to:
  /// **'This phone does not have your chat keys, and without the PIN they cannot be recovered. After you confirm with your account password and choose a new PIN, new keys are made and your earlier chat history can no longer be read. This cannot be undone.\n\nIf another of your phones can still open your chats, do this there instead to keep your history.'**
  String get forgotPinLosesHistory;

  /// No description provided for @forgotPinNeedsPassword.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google, so create an account password first. It confirms it is you when you choose a new chat PIN.'**
  String get forgotPinNeedsPassword;

  /// No description provided for @pinForgotHint.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN? Go to User > Security > Forgot chat PIN.'**
  String get pinForgotHint;

  /// No description provided for @chatPinNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter your chat PIN to read and send messages on this phone.'**
  String get chatPinNeeded;

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this chat. Check your connection.'**
  String get chatOpenFailed;

  /// No description provided for @pinSetUpHelp.
  ///
  /// In en, this message translates to:
  /// **'You will need this PIN to read your chats on a new phone. Choose one you will remember.'**
  String get pinSetUpHelp;

  /// No description provided for @chatPinRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your chat PIN'**
  String get chatPinRestoreTitle;

  /// No description provided for @chatPinRestoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Your chats are protected by your 6-digit chat PIN. Enter it to read them on this phone.'**
  String get chatPinRestoreHelp;

  /// No description provided for @devicesImmediateNote.
  ///
  /// In en, this message translates to:
  /// **'A device you sign out is signed out immediately.'**
  String get devicesImmediateNote;

  /// No description provided for @devicesTooNew.
  ///
  /// In en, this message translates to:
  /// **'This device signed in less than a day ago, so it cannot sign other devices out yet. Use a device you have been signed in on for longer.'**
  String get devicesTooNew;

  /// No description provided for @devicesTooNewUntil.
  ///
  /// In en, this message translates to:
  /// **'For your protection, a device can sign other devices out only after it has been signed in for a day. This device can from {when}. Until then, use a device you have been signed in on for longer.'**
  String devicesTooNewUntil(String when);

  /// No description provided for @newSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'New sign-in to your account'**
  String get newSignInTitle;

  /// No description provided for @newSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Another device signed in to your account. If this was not you, sign it out now and change your password.'**
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
  /// **'This device signed in less than a day ago, so to protect your account it cannot do this yet. Use a device you have been signed in on for longer, or try again tomorrow.'**
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
  /// **'This picture is still too large after compression. Please choose a smaller one.'**
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
  /// **'Type a road, village or district to see what is for sale there, or the name of an owner or agency.'**
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
  /// **'Nothing is listed here yet. Move the map or search a wider area.'**
  String get searchAreaEmpty;

  /// No description provided for @searchPersonEmpty.
  ///
  /// In en, this message translates to:
  /// **'This person has no published listings right now.'**
  String get searchPersonEmpty;

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

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your feed is empty'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Follow people from their profile to see their new listings here.'**
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

  /// No description provided for @forgotPinPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your account password to confirm it is you. Then choose a new chat PIN.'**
  String get forgotPinPasswordHelp;

  /// No description provided for @forgotPinRecovered.
  ///
  /// In en, this message translates to:
  /// **'Done. Your new chat PIN protects your chats.'**
  String get forgotPinRecovered;

  /// No description provided for @securityPinRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'Your chats are always end-to-end encrypted and protected by your 6-digit chat PIN. You need it to read your chats on a new phone.'**
  String get securityPinRequiredNote;

  /// No description provided for @pinUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get pinUnlock;

  /// No description provided for @pinChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your PIN...'**
  String get pinChecking;

  /// No description provided for @pinWrongTriesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Incorrect PIN. 1 try left before your PIN locks for a while.} other{Incorrect PIN. {count} tries left.}}'**
  String pinWrongTriesLeft(int count);

  /// No description provided for @pinWrongNoCount.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get pinWrongNoCount;

  /// No description provided for @pinLockedFor.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Try again in {time}.'**
  String pinLockedFor(String time);

  /// No description provided for @pinLockedLater.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Please try again later.'**
  String get pinLockedLater;

  /// No description provided for @pinCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check your PIN. Check your connection and try again.'**
  String get pinCheckFailed;

  /// No description provided for @chatPinSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your PIN...'**
  String get chatPinSaving;

  /// No description provided for @chatPasswordChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your password...'**
  String get chatPasswordChecking;

  /// No description provided for @chatPinSetupSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get chatPinSetupSignOut;

  /// No description provided for @chatPinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your chat PIN'**
  String get chatPinCreateTitle;

  /// No description provided for @chatPinCreateHelp.
  ///
  /// In en, this message translates to:
  /// **'Your messages are end-to-end encrypted. This 6-digit PIN brings them back when you sign in on a new phone. Choose one you will remember: nobody, not even Tilomnov, can see it.'**
  String get chatPinCreateHelp;

  /// No description provided for @chatPinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your chat PIN'**
  String get chatPinConfirmTitle;

  /// No description provided for @chatPinConfirmHelp.
  ///
  /// In en, this message translates to:
  /// **'Type the same 6 digits again.'**
  String get chatPinConfirmHelp;

  /// No description provided for @chatPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs did not match. Choose your PIN again.'**
  String get chatPinMismatch;

  /// No description provided for @chatPinSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your PIN. Check your connection and try again.'**
  String get chatPinSaveFailed;

  /// No description provided for @chatPinChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose a different PIN'**
  String get chatPinChooseAnother;

  /// No description provided for @chatPinMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect your chats with a PIN'**
  String get chatPinMoveTitle;

  /// No description provided for @chatPinMoveHelp.
  ///
  /// In en, this message translates to:
  /// **'Your chats are now protected by a 6-digit chat PIN instead of your account password. Enter your account password once, then choose your PIN.'**
  String get chatPinMoveHelp;

  /// No description provided for @chatPinStartOverLink.
  ///
  /// In en, this message translates to:
  /// **'Can\'t unlock? Start over'**
  String get chatPinStartOverLink;

  /// No description provided for @chatPinStartOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Start over with new chat keys?'**
  String get chatPinStartOverTitle;

  /// No description provided for @chatPinStartOverMessage.
  ///
  /// In en, this message translates to:
  /// **'If your password was reset, your old chats cannot be unlocked. Starting over keeps your account, but your earlier messages can no longer be read. This cannot be undone.'**
  String get chatPinStartOverMessage;

  /// No description provided for @chatPinStartOverAction.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get chatPinStartOverAction;

  /// No description provided for @chatPinRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your messages are end-to-end encrypted. Create a 6-digit chat PIN to protect them before you start chatting.'**
  String get chatPinRequiredMessage;

  /// No description provided for @chatPinCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get chatPinCreateAction;

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

  /// No description provided for @chatPinLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs'**
  String get chatPinLockedTitle;

  /// No description provided for @chatPinLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'For your security, entering your chat PIN is paused for a while. Please try again later.'**
  String get chatPinLockedMessage;

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

  /// No description provided for @authErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again later.'**
  String get authErrorServer;

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
  /// **'For everyone: it is removed for you and {name}, with nothing left in its place. For me: only you stop seeing it.'**
  String chatDeleteOwnMessageExplained(String name);

  /// No description provided for @chatDeleteMessageForMeExplained.
  ///
  /// In en, this message translates to:
  /// **'It is removed for you only. {name} still sees it.'**
  String chatDeleteMessageForMeExplained(String name);

  /// No description provided for @chatEditTooLate.
  ///
  /// In en, this message translates to:
  /// **'A message can only be edited within an hour of sending it.'**
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

  /// No description provided for @chatKeyChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s security key has changed'**
  String chatKeyChangedTitle(String name);

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
  /// **'Encrypted message'**
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
  /// **'The server did not accept this message. Please try again.'**
  String get chatSendRejected;

  /// No description provided for @chatSendTooFast.
  ///
  /// In en, this message translates to:
  /// **'You are sending messages too quickly. Wait a moment.'**
  String get chatSendTooFast;

  /// No description provided for @chatSendPinRequired.
  ///
  /// In en, this message translates to:
  /// **'Create your chat PIN before sending messages.'**
  String get chatSendPinRequired;

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
  /// **'They won\'t be able to message or call you, and you\'ll stop following each other. They won\'t be told.'**
  String get blockConfirmMessage;

  /// No description provided for @unblockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String unblockConfirmTitle(String name);

  /// No description provided for @unblockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to message each other again. Follows removed by the block don\'t come back.'**
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

  /// No description provided for @chatSendKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'Their security key has changed. Accept the new key to continue.'**
  String get chatSendKeyChanged;

  /// No description provided for @chatSendNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Secure chat is not set up on this device.'**
  String get chatSendNotSetUp;

  /// No description provided for @chatSendPeerNotReady.
  ///
  /// In en, this message translates to:
  /// **'This person has not set up secure chat yet. They can receive messages once they open the app again.'**
  String get chatSendPeerNotReady;

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
  /// **'No saved searches yet. Set a filter on the map and tap the bookmark to save it.'**
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
  /// **'Security alerts and calls are always on, so you never miss a new sign-in to your account or someone calling you.'**
  String get notificationsAlwaysOn;

  /// No description provided for @notificationsBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app'**
  String get notificationsBlockedTitle;

  /// No description provided for @notificationsBlockedHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn them on in your phone\'s settings to hear about new messages, calls and sign-ins.'**
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
  /// **'Show what a message says in its notification. Anyone who can see your lock screen can read it.'**
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
  /// **'Add an email so you can reset your password if you forget it. Enter your password to confirm it is you.'**
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
