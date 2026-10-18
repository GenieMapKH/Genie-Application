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
  /// **'Enter a phone number of at most 20 characters.'**
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
  /// **'Change backup PIN'**
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
  /// **'Backup PIN changed.'**
  String get pinChanged;

  /// No description provided for @pinNoBackup.
  ///
  /// In en, this message translates to:
  /// **'You have no backup PIN.'**
  String get pinNoBackup;

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. The backup is locked; try again later.'**
  String get pinLocked;

  /// No description provided for @pinFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the key backup. Check your connection.'**
  String get pinFetchFailed;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. After 5 wrong tries the backup locks for a while.'**
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
  /// **'New keys will be created and you will lose access to all earlier chat history. This cannot be undone.\n\nIf you have a backup PIN, you will be asked for it first.'**
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

  /// No description provided for @authByContinuingYouAgreeToOut.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to out '**
  String get authByContinuingYouAgreeToOut;

  /// No description provided for @authTermsOfServices.
  ///
  /// In en, this message translates to:
  /// **'terms of services.'**
  String get authTermsOfServices;

  /// No description provided for @authEmailAddressOrPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Email Address or Phone number'**
  String get authEmailAddressOrPhoneNumber;

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

  /// No description provided for @resetKeysPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Your new chat keys will be locked with your account password.'**
  String get resetKeysPasswordHelp;

  /// No description provided for @chatPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account password'**
  String get chatPasswordTitle;

  /// No description provided for @chatPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Your chats are locked with your account password. Enter it to read and send messages on this device.'**
  String get chatPasswordHelp;

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

  /// No description provided for @chatPasswordChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Your chats are locked with an earlier password. Sign in once on a phone you used before to keep your earlier messages, or use chat here now: earlier messages cannot be read on this phone.'**
  String get chatPasswordChangedElsewhere;

  /// No description provided for @chatPinLastTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your chat PIN one last time'**
  String get chatPinLastTimeTitle;

  /// No description provided for @chatPinLastTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'From now on your account password protects your chats, so you will not need this PIN again.'**
  String get chatPinLastTimeHelp;

  /// No description provided for @securityChatsUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Your chats are always end-to-end encrypted and locked with your account password, so signing in on any device brings them back. No PIN is needed.'**
  String get securityChatsUsePassword;

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

  /// No description provided for @propertyGenie.
  ///
  /// In en, this message translates to:
  /// **'Tilomnov'**
  String get propertyGenie;

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

  /// No description provided for @securityForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot backup PIN'**
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
  /// **'Forgot your backup PIN?'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinKeepsHistory.
  ///
  /// In en, this message translates to:
  /// **'This device still has your chat keys, so nothing is lost. Create an account password: from then on it protects your chats instead of a PIN.'**
  String get forgotPinKeepsHistory;

  /// No description provided for @forgotPinLosesHistory.
  ///
  /// In en, this message translates to:
  /// **'This device does not have your chat keys, and without the PIN they cannot be recovered. After you create an account password, new keys are made and your earlier chat history can no longer be read. This cannot be undone.\n\nIf another of your devices can still open your chats, do this there instead to keep your history.'**
  String get forgotPinLosesHistory;

  /// No description provided for @forgotPinNeedsPassword.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google, so create an account password. It protects your chats from now on, instead of a PIN.'**
  String get forgotPinNeedsPassword;

  /// No description provided for @forgotPinNowPassword.
  ///
  /// In en, this message translates to:
  /// **'Done. Your chats are now protected by your account password.'**
  String get forgotPinNowPassword;

  /// No description provided for @pinForgotHint.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN? Go to User > Security > Forgot backup PIN to choose a new one or turn it off.'**
  String get pinForgotHint;

  /// No description provided for @chatPinNeeded.
  ///
  /// In en, this message translates to:
  /// **'Your chats are protected with a backup PIN. Enter it to read and send messages on this phone.'**
  String get chatPinNeeded;

  /// No description provided for @chatOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this chat. Check your connection.'**
  String get chatOpenFailed;

  /// No description provided for @securitySetUpPin.
  ///
  /// In en, this message translates to:
  /// **'Set up backup PIN'**
  String get securitySetUpPin;

  /// No description provided for @securityTurnOffPin.
  ///
  /// In en, this message translates to:
  /// **'Turn off backup PIN'**
  String get securityTurnOffPin;

  /// No description provided for @securityPinOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Your chats are always end-to-end encrypted. A backup PIN is optional: with one, you can read your earlier chats on a new phone, and nobody can replace your chat keys without it.'**
  String get securityPinOptionalNote;

  /// No description provided for @pinSetUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a backup PIN'**
  String get pinSetUpTitle;

  /// No description provided for @pinSetUpHelp.
  ///
  /// In en, this message translates to:
  /// **'You will need this PIN to read your chats on a new phone. Choose one you will remember.'**
  String get pinSetUpHelp;

  /// No description provided for @pinSetUpDone.
  ///
  /// In en, this message translates to:
  /// **'Backup PIN set.'**
  String get pinSetUpDone;

  /// No description provided for @pinAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'You already have a backup PIN.'**
  String get pinAlreadySet;

  /// No description provided for @pinKeysNotReady.
  ///
  /// In en, this message translates to:
  /// **'Open a chat on this phone first, then set up the PIN.'**
  String get pinKeysNotReady;

  /// No description provided for @pinTurnOffConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off backup PIN?'**
  String get pinTurnOffConfirmTitle;

  /// No description provided for @pinTurnOffConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your chats stay end-to-end encrypted. Without a PIN, a new phone cannot read your earlier messages.\n\nYou will be asked for your current PIN first.'**
  String get pinTurnOffConfirmMessage;

  /// No description provided for @pinTurnOffAction.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get pinTurnOffAction;

  /// No description provided for @pinTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Backup PIN turned off.'**
  String get pinTurnedOff;

  /// No description provided for @pinTurnOffFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not turn off the PIN. Nothing was changed.'**
  String get pinTurnOffFailed;

  /// No description provided for @chatPinRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your backup PIN'**
  String get chatPinRestoreTitle;

  /// No description provided for @chatPinRestoreHelp.
  ///
  /// In en, this message translates to:
  /// **'You protected your chats with a backup PIN. Enter it to read them on this phone.'**
  String get chatPinRestoreHelp;

  /// No description provided for @chatUsedOnAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'Your chat is now set up on another device. Use it on this phone instead? Earlier messages cannot be read here, and the other device will need to switch back the same way.\n\nTo use chat on several devices, set up a backup PIN in User > Security.'**
  String get chatUsedOnAnotherDevice;

  /// No description provided for @chatUseOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Use chat on this phone'**
  String get chatUseOnThisDevice;

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

  /// No description provided for @propertyDriveMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min drive'**
  String propertyDriveMinutes(int minutes);

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
