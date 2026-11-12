// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get callInProgress => 'Call in progress';

  @override
  String get chatManagedSecurity =>
      'Messages are encrypted when sent and stored.';

  @override
  String get callMinimize => 'Minimize call';

  @override
  String get callReturn => 'Return to call';

  @override
  String get propertyUnavailable => 'Unavailable';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get commonTooManyAttempts =>
      'Too many attempts. Please try again later.';

  @override
  String get commonOffline => 'You’re offline. Connect for updates.';

  @override
  String get connectionOffline => 'No internet connection';

  @override
  String get connectionWaiting => 'Waiting for network…';

  @override
  String get connectionWeak => 'Slow connection';

  @override
  String get connectionWeakDetail => 'Loading may take longer';

  @override
  String get connectionRestored => 'Back online';

  @override
  String get loadFailureOfflineTitle => 'No internet connection';

  @override
  String get loadFailureOfflineBody =>
      'Check your internet. This page will reload when you reconnect.';

  @override
  String get loadFailureSlowTitle => 'Your connection is too slow';

  @override
  String get loadFailureSlowBody =>
      'Loading took too long. Check your connection and retry.';

  @override
  String get loadFailureServerBody =>
      'Something went wrong. Try again shortly.';

  @override
  String get failureOffline =>
      'No internet connection. Check your Wi-Fi or mobile data and try again.';

  @override
  String get failureSlow =>
      'Your connection is too slow. Move to a better spot and try again.';

  @override
  String get failureServer => 'Something went wrong. Try again shortly.';

  @override
  String get navExplore => 'Explore';

  @override
  String get navSaved => 'Saved';

  @override
  String get navChat => 'Chat';

  @override
  String get navMyProperties => 'My Properties';

  @override
  String get navListings => 'Listings';

  @override
  String get navUser => 'User';

  @override
  String get loginRequiredTitle => 'Account Required';

  @override
  String get loginRequiredMessage => 'Log in or sign up to continue.';

  @override
  String get loginRequiredAction => 'Login / Sign Up';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountLoadFailed => 'Could not load profile';

  @override
  String get accountSectionAccount => 'Account';

  @override
  String get accountSectionPreferences => 'Preferences';

  @override
  String get accountSectionMore => 'More';

  @override
  String get accountPersonalInfo => 'Personal information';

  @override
  String get accountSecurity => 'Security';

  @override
  String get accountAppearance => 'Appearance';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountPrivacy => 'Privacy & cookies';

  @override
  String get accountSubscription => 'Subscription Plan';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountDefaultName => 'User';

  @override
  String get avatarTakePhoto => 'Take photo';

  @override
  String get avatarChooseFromStorage => 'Choose from storage';

  @override
  String get avatarSyncFromGoogle => 'Sync from Google Account';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get glassNavigationTitle => 'Navigation theme';

  @override
  String get glassNavigationSubtitle => 'Matches your device\'s system bars.';

  @override
  String get personalInfoTitle => 'Personal information';

  @override
  String get personalInfoSectionProfile => 'Profile';

  @override
  String get personalInfoSectionDetails => 'Personal details';

  @override
  String get personalInfoSectionContact => 'Contact';

  @override
  String get personalInfoUsername => 'Username';

  @override
  String get personalInfoUsernameHelp =>
      '3 to 30 lowercase letters, numbers, periods or underscores.';

  @override
  String get personalInfoUsernameInvalid =>
      'Use 3 to 30 lowercase letters, numbers, \"_\" or \".\".';

  @override
  String get personalInfoUsernameTaken => 'This username is already taken.';

  @override
  String get personalInfoName => 'Name';

  @override
  String get personalInfoNameHelp => 'Visible to other users.';

  @override
  String get personalInfoFirstName => 'First name';

  @override
  String get personalInfoLastName => 'Last name';

  @override
  String get personalInfoSex => 'Sex';

  @override
  String get personalInfoSexMale => 'Male';

  @override
  String get personalInfoSexFemale => 'Female';

  @override
  String get personalInfoSexOther => 'Other';

  @override
  String get personalInfoPhone => 'Phone number';

  @override
  String get personalInfoPhoneHelp => 'Used for sign-in and buyer calls.';

  @override
  String get personalInfoPhoneTaken =>
      'This phone number is already used by another account.';

  @override
  String get personalInfoPhoneInvalid =>
      'Enter a valid phone number, for example 012 345 678.';

  @override
  String get personalInfoEmail => 'Email';

  @override
  String get personalInfoTooLong => 'This is too long.';

  @override
  String personalInfoEdit(String field) {
    return 'Edit $field';
  }

  @override
  String get securityTitle => 'Security';

  @override
  String get securitySectionSignIn => 'Sign-in';

  @override
  String get securitySectionAccount => 'Account';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityDevices => 'Logged-in devices';

  @override
  String get securityRemoveAccount => 'Deactivate or delete account';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordConfirm => 'Confirm new password';

  @override
  String get passwordCurrentRequired => 'Enter your current password.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get passwordMismatch => 'The two passwords do not match.';

  @override
  String get passwordSameAsCurrent =>
      'Choose a password different from the current one.';

  @override
  String get passwordIncorrect => 'The current password is incorrect.';

  @override
  String get passwordChanged =>
      'Password changed. Your other devices were signed out.';

  @override
  String get passwordIntro =>
      'Changing your password signs out all other devices.';

  @override
  String get devicesIntro =>
      'Review signed-in devices and sign out any you do not recognize.';

  @override
  String get devicesLoadFailed => 'Could not load your devices';

  @override
  String get devicesEmpty => 'No other devices are signed in.';

  @override
  String get devicesThisDevice => 'This device';

  @override
  String get devicesUnknownDevice => 'Unknown device';

  @override
  String get devicesUnknownLocation => 'Unknown location';

  @override
  String get devicesActiveNow => 'Active now';

  @override
  String devicesLastUsedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last used $count minutes ago',
      one: 'Last used 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String devicesLastUsedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last used $count hours ago',
      one: 'Last used 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String devicesLastUsedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last used $count days ago',
      one: 'Last used yesterday',
    );
    return '$_temp0';
  }

  @override
  String devicesSignedInOn(String date) {
    return 'Signed in $date';
  }

  @override
  String get devicesSignOut => 'Sign out';

  @override
  String get devicesSignOutAll => 'Sign out of all devices';

  @override
  String get devicesSignOutConfirmTitle => 'Sign out this device?';

  @override
  String devicesSignOutConfirmMessage(String device) {
    return '$device will have to sign in again.';
  }

  @override
  String get devicesSignOutAllConfirmTitle => 'Sign out of all devices?';

  @override
  String get devicesSignOutAllConfirmMessage =>
      'Every device, including this one, will have to sign in again.';

  @override
  String get devicesSignedOut => 'Device signed out.';

  @override
  String get devicesSignOutFailed =>
      'Could not sign the device out. Please try again.';

  @override
  String get removeAccountDeactivateTitle => 'Deactivate account';

  @override
  String get removeAccountDeactivateBody =>
      'Hide your profile and listings, and sign out everywhere. Sign in to restore them.';

  @override
  String get removeAccountDeactivateAction => 'Deactivate account';

  @override
  String get removeAccountDeleteTitle => 'Delete account';

  @override
  String get removeAccountDeleteBody =>
      'Permanently delete your account, listings, saved properties and chats. This cannot be undone.';

  @override
  String get removeAccountDeleteAction => 'Delete account';

  @override
  String get removeAccountDeleteConfirmAction => 'Delete forever';

  @override
  String get removeAccountDeactivated => 'Your account was deactivated.';

  @override
  String get removeAccountDeleted => 'Your account was deleted.';

  @override
  String get identityConfirmPasswordHelp => 'Enter your password to continue.';

  @override
  String get identityConfirmPassword => 'Password';

  @override
  String get identityConfirmPasswordRequired => 'Enter your password.';

  @override
  String get identityConfirmPasswordWrong => 'The password is incorrect.';

  @override
  String get identityConfirmWithGoogle => 'Confirm with Google';

  @override
  String get identityConfirmGoogleHelp =>
      'Confirm with your Google account to continue.';

  @override
  String get identityConfirmGoogleFailed =>
      'Could not confirm your Google account. Please try again.';

  @override
  String get identityConfirmOr => 'or';

  @override
  String get authCreateAnAccount => 'Create an account';

  @override
  String get authAccountCreatedSuccessfullyPleaseLogin =>
      'Account created successfully! Please login.';

  @override
  String get authSuccessfullyAuthenticated => 'Successfully authenticated!';

  @override
  String get authForgotPassword => 'Forgot Password';

  @override
  String get authEnterYourEmailAddressToGet =>
      'Enter your email to reset your password.';

  @override
  String get authPasswordReset => 'Password Reset';

  @override
  String get authCreateAAccount => 'Create a Account';

  @override
  String get authEmailAddress => 'Email Address';

  @override
  String get authExampleGmailCom => 'example@gmail.com';

  @override
  String get authVerificationCodeSentToYourEmail =>
      'Verification code sent to your email';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get authGetCode => 'Get code';

  @override
  String get authPhoneVerified => 'Phone number verified';

  @override
  String get authPhoneVerificationExpired =>
      'Phone verification expired. Get a new code.';

  @override
  String get authPhoneVerificationUnavailable =>
      'We couldn\'t send the SMS code. Please try again later.';

  @override
  String get authVerifyPhoneFirst =>
      'Verify your phone number before signing up.';

  @override
  String get authLoginFailedPleaseCheckYourCredentials =>
      'Could not sign in. Check your details and retry.';

  @override
  String get authSuccessfullyLoggedIn => 'Successfully logged in!';

  @override
  String get authOtpVerification => 'OTP Verification';

  @override
  String get authEnterTheVerificationCodeWeJust =>
      'Enter the code sent to your email.';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResendOtp => 'Resend OTP';

  @override
  String get authPleaseEnterAll6Digits => 'Please enter all 6 digits';

  @override
  String get authNewVerificationCodeSent => 'New verification code sent';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authEnterYourNewPasswordTwiceBelow =>
      'Enter your new password twice.';

  @override
  String get authEnterNewPassword => 'Enter new password';

  @override
  String get authReEnterNewPassword => 'Re-enter new password';

  @override
  String get authPasswordResetSuccessfullyPleaseLogIn =>
      'Password reset. Sign in with your new password.';

  @override
  String get authWelcomeToTheApp => 'Welcome to the app';

  @override
  String get authFindAndSharePropertiesWithExact =>
      'Find and share properties with exact map location';

  @override
  String get authLogin => 'Login';

  @override
  String get authExploreWithoutAccount => 'Explore without account';

  @override
  String get authOrSignInWith => 'or sign in with';

  @override
  String get authAlreadyHaveAnAccount => 'Already have an account? ';

  @override
  String get authSignInHere => 'Sign in here';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authTermsOfServices => 'terms of service';

  @override
  String get authForgetPassword => 'Forget Password?';

  @override
  String get authKeepMeSignedIn => 'Keep me signed in';

  @override
  String get authWelcomeBackToTheApp => 'Welcome back to the app';

  @override
  String get chatCouldNotOpenYourPhotos => 'Could not open your photos.';

  @override
  String get chatTryAgain => 'Try again';

  @override
  String get chatPasswordTitle => 'Enter your account password';

  @override
  String get chatPasswordLabel => 'Account password';

  @override
  String get chatPasswordWrong => 'That is not your account password.';

  @override
  String get chatPasswordTooManyTries =>
      'Too many tries. Wait a few minutes and try again.';

  @override
  String get chatMoreOptions => 'More options';

  @override
  String get chatArchivedChats => 'Archived chats';

  @override
  String get chatNoArchivedChats => 'No archived chats';

  @override
  String get chatArchivedChatsHint =>
      'New messages move chats back to your inbox.';

  @override
  String get chatArchive => 'Archive';

  @override
  String get chatUnarchive => 'Unarchive';

  @override
  String get chatDelete => 'Delete';

  @override
  String get chatArchiveChat => 'Archive chat';

  @override
  String get chatUnarchiveChat => 'Move back to chats';

  @override
  String get chatDeleteChat => 'Delete chat';

  @override
  String get chatDeleteChatQuestion => 'Delete this chat?';

  @override
  String chatDeleteForMeExplained(String name) {
    return 'Only deleted for you. $name keeps the chat.';
  }

  @override
  String chatDeleteForBoth(String name) {
    return 'Also delete for $name';
  }

  @override
  String get chatDeleteForBothExplained =>
      'Delete all messages and photos for both of you. This cannot be undone.';

  @override
  String get chatArchivedDone => 'Chat archived';

  @override
  String get chatUnarchivedDone => 'Chat moved back to your chats';

  @override
  String get chatDeletedDone => 'Chat deleted';

  @override
  String get chatUndo => 'Undo';

  @override
  String get chatActionFailed =>
      'Could not do that. Check your connection and retry.';

  @override
  String get chatThisIsYourOwnAccount => 'This is your own account.';

  @override
  String get chatSignInToChatOrCheck =>
      'Sign in to chat, or check your connection.';

  @override
  String get chatNoChatsYet => 'No chats yet!';

  @override
  String get chatMessageAPropertyOwnerToStart =>
      'Message an owner to start chatting.';

  @override
  String get chatCouldNotLoadYourChats => 'Could not load your chats.';

  @override
  String get chatPhotoLibrary => 'Photo library';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatMessage => 'Message';

  @override
  String get homeCoordinates => 'Coordinates';

  @override
  String get homeDraw => 'Draw';

  @override
  String get homeAddPoint => 'Add point';

  @override
  String get homeSearchByAreaRoadVillage => 'Search by area, road, village...';

  @override
  String get homeNoCoordinatesFoundPleaseTryAgain =>
      'No coordinates found. Please try again.';

  @override
  String get homeCropDocument => 'Crop Document';

  @override
  String get homeNoCoordinatesFoundInTheImage =>
      'No coordinates found in the image.';

  @override
  String get homePleaseFillBothXAndY =>
      'Enter both X and Y, or leave both blank.';

  @override
  String get homeCoordinatesMustBeValidNumbers =>
      'Coordinates must be valid numbers.';

  @override
  String get homePleaseEnterAtLeast3Coordinates =>
      'Enter at least 3 coordinates.';

  @override
  String get homePreview => 'Preview';

  @override
  String get homeLocateProperty => 'Locate Property';

  @override
  String get homeEnterCoordinatesManually => 'Enter Coordinates Manually';

  @override
  String get homeTypeUtmZoneEastingXAnd =>
      'Type UTM Zone, Easting (X), and Northing (Y).';

  @override
  String get homeEnterCoordinates => 'Enter Coordinates';

  @override
  String get homeUseUtmFromALandDocument =>
      'Use UTM coordinates from your land document or enter them.';

  @override
  String get homeCrsWgs84UtmZone48p => 'CRS: WGS84 / UTM Zone 48P';

  @override
  String get homeScanUtmFromDocument => 'Scan UTM from Document';

  @override
  String get homeUseCameraToDetectCoordinates =>
      'Use camera to detect coordinates';

  @override
  String get homeStartScanning => 'Start Scanning';

  @override
  String get propertySetPropertyLocation => 'Set Property Location';

  @override
  String get propertyLocationBoundary => 'Location & Boundary';

  @override
  String get propertyDrawingProperty => 'Drawing Property';

  @override
  String get propertyMapPreview => 'Map Preview';

  @override
  String get propertyViewOnMap => 'View on map';

  @override
  String get propertyAddProperty => 'Add Property';

  @override
  String get propertyPropertyType => 'Property Type';

  @override
  String get propertyTitleHeadline => 'Title/Headline';

  @override
  String get propertyExample10x30LandNearNationalRoad =>
      'Example: 10x30 Land Near National Road 1';

  @override
  String get propertyDescription => 'Description';

  @override
  String get propertyDescribeWhatMakesThisPropertySpecial =>
      'Describe what makes this property special';

  @override
  String get propertyKeywordsFeatures => 'Keywords / Features';

  @override
  String get propertyUploadPropertyPhotos => 'Upload property photos';

  @override
  String get propertyContactInformation => 'Contact Information';

  @override
  String get propertyPhoneNumber0 => 'Phone Number (0...)';

  @override
  String get propertyValidateRequiredFields => 'Validate required fields';

  @override
  String get propertyPleaseCompleteRequiredFieldsBeforePublis =>
      'Please complete required fields before publishing.';

  @override
  String get propertyClose => 'Close';

  @override
  String get propertyYourListingIsNowVisibleTo =>
      'Your listing is now visible to buyers.';

  @override
  String get propertyYouAreOfflinePleaseConnectTo =>
      'You are offline. Please connect to internet for updates.';

  @override
  String get propertyCouldNotLoadProperties => 'Could not load properties';

  @override
  String get propertySortBy => 'Sort by';

  @override
  String get propertyFailedToLoadSavedProperties =>
      'Failed to load saved properties';

  @override
  String get propertyYouHavenTSavedAnyProperties =>
      'You haven\'t saved any properties yet.';

  @override
  String get propertyTapTheHeartIconOnListings =>
      'Tap the heart to save a listing.';

  @override
  String get propertySavedProperties => 'Saved Properties';

  @override
  String get propertySortOrder => 'Sort Order';

  @override
  String get propertyAddAtLeast3ClearPhotos =>
      'Add at least 3 clear property photos.';

  @override
  String get propertyOpenCamera => 'Open camera';

  @override
  String get propertyCallNow => 'Call Now';

  @override
  String get propertyCallInApp => 'Call in Tilomnov';

  @override
  String get propertyCallPhone => 'Use phone dialer';

  @override
  String get callFullScreenTitle => 'Full-screen incoming calls';

  @override
  String get callFullScreenHelp =>
      'Allow incoming calls to appear over the lock screen.';

  @override
  String get callFullScreenFailed =>
      'Could not open full-screen call settings.';

  @override
  String get propertyNoPhoneNumber =>
      'No phone number. Message the owner instead.';

  @override
  String get propertyCallFailed => 'The phone app could not be opened.';

  @override
  String get profileSignInForContact => 'Sign in to see their phone and email.';

  @override
  String get propertyCannotChatOwnerInformationMissing =>
      'Cannot chat: owner information missing.';

  @override
  String get propertySimilarProperty => 'Similar Property';

  @override
  String get propertyPropertyForYou => 'Property for you';

  @override
  String get propertyPropertyHighlights => 'Property Highlights';

  @override
  String get propertyTilomnov => 'Tilomnov';

  @override
  String get propertyViews => 'Views';

  @override
  String get propertySaves => 'Saves';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsLoadFailed =>
      'Couldn\'t load the insights. Check your connection.';

  @override
  String get insightsTotalViews => 'People viewed';

  @override
  String get insightsTotalSaves => 'Saved it';

  @override
  String get insightsTotalCalls => 'Tapped Call';

  @override
  String get insightsTotalChats => 'Started a chat';

  @override
  String get insightsLast14Days => 'Last 14 days';

  @override
  String get insightsMeasureViews => 'Viewers';

  @override
  String get insightsMeasureSaves => 'Saves';

  @override
  String get insightsMeasureLeads => 'Leads';

  @override
  String insightsViewers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new viewers',
      one: '1 new viewer',
    );
    return '$_temp0';
  }

  @override
  String insightsSaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new saves',
      one: '1 new save',
    );
    return '$_temp0';
  }

  @override
  String insightsLeads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new leads',
      one: '1 new lead',
    );
    return '$_temp0';
  }

  @override
  String insightsThisWeek(String thisWeek, int lastWeek) {
    return 'This week: $thisWeek. The week before: $lastWeek.';
  }

  @override
  String get insightsEmptyHint =>
      'No views yet. Share your listing to reach more people.';

  @override
  String get propertyShareThisProperty => 'Share This Property';

  @override
  String get propertyScanThisQrCodeToView =>
      'Scan this QR code to view this property on your phone';

  @override
  String get propertyShare => 'Share';

  @override
  String get propertyDownload => 'Download';

  @override
  String get propertyShareSheetTitle => 'Share this listing';

  @override
  String get propertyShareScanToView => 'Scan to view this listing';

  @override
  String get propertyShareCopyLink => 'Copy link';

  @override
  String get propertyShareLinkCopied => 'Link copied';

  @override
  String get propertyShareSaveImage => 'Save image';

  @override
  String get propertyShareImageSaved => 'Saved to your photos';

  @override
  String get propertyShareImageSaveFailed => 'Couldn\'t save the image';

  @override
  String get propertySharePhotosDenied =>
      'Allow Tilomnov to add photos in Settings to save the image.';

  @override
  String get propertyShareFailed => 'Couldn\'t share this listing';

  @override
  String get propertyShareMessageSeeOnMap =>
      'See the photos and exact location on the map:';

  @override
  String get propertyShareMessageFooter =>
      'Shared from Tilomnov, land and homes on the map.';

  @override
  String get propertyShareCaptionCopied =>
      'Caption copied: paste it if the app leaves it out';

  @override
  String get propertyShareNotPublicDraft =>
      'Publish this listing to share its link or QR code.';

  @override
  String get propertyShareNotPublicPending =>
      'Complete payment before sharing this listing.';

  @override
  String get propertyShareNotPublicEnded =>
      'This listing is no longer public and can’t be shared.';

  @override
  String get propertyTitleType => 'Title Type';

  @override
  String get propertyBedrooms => 'Bedrooms';

  @override
  String get propertyNumberOfBedrooms => 'Number of bedrooms';

  @override
  String get propertyBathrooms => 'Bathrooms';

  @override
  String get propertyNumberOfBathrooms => 'Number of bathrooms';

  @override
  String get propertyFloors => 'Floors';

  @override
  String get propertyTotalFloorsEG2 => 'Total floors (e.g. 2)';

  @override
  String get propertyNumberOfFloors => 'Number of Floors';

  @override
  String get propertyFloorNumber => 'Floor Number';

  @override
  String get propertyEnterFloorNumberEG12 => 'Enter floor number (e.g. 12)';

  @override
  String get propertyTotalFloors => 'Total Floors';

  @override
  String get propertyTotalFloorsInBuilding => 'Total floors in building';

  @override
  String get propertyParking => 'Parking';

  @override
  String get propertySelectParking => 'Select parking';

  @override
  String get propertyFurnished => 'Furnished';

  @override
  String get propertySelectFurnished => 'Select furnished';

  @override
  String get propertyBuildingType => 'Building Type';

  @override
  String get propertySelectBuildingType => 'Select building type';

  @override
  String get propertyTotalUnits => 'Total Units';

  @override
  String get propertyNumberOfUnits => 'Number of units';

  @override
  String get propertyBalcony => 'Balcony';

  @override
  String get propertySelectBalcony => 'Select balcony';

  @override
  String get propertyCompletionStatus => 'Completion Status';

  @override
  String get propertySelectStatus => 'Select Status';

  @override
  String get propertyViewType => 'View Type';

  @override
  String get propertySelectViewType => 'Select view type';

  @override
  String get propertyProjectType => 'Project Type';

  @override
  String get propertySelectProjectType => 'Select project type';

  @override
  String get propertySelectStatus2 => 'Select status';

  @override
  String get propertyBuildingManagementFeePerMonth =>
      'Building management fee per month';

  @override
  String get propertyRemainingContractDurationWithLandlord =>
      'Remaining contract duration with landlord';

  @override
  String get propertyMaintenanceFee => 'Maintenance Fee';

  @override
  String get propertyLeaseRemaining => 'Lease Remaining';

  @override
  String get propertyPrice => 'Price';

  @override
  String get propertyEnterSellingPriceUsd => 'Enter selling price (USD)';

  @override
  String get propertyListingSettings => 'Listing Settings';

  @override
  String get propertyAutoFromMap => 'Auto from map';

  @override
  String get propertyTotalLandAreaOfTheProperty =>
      'Total land area of the property';

  @override
  String get propertyTotalBuiltUpArea => 'Total built-up area';

  @override
  String get propertyTotalUsableAreaOfTheUnit =>
      'Total usable area of the unit';

  @override
  String get propertyBuildingSize => 'Building Size';

  @override
  String get propertyUnitSize => 'Unit Size';

  @override
  String get propertyDeveloperName => 'Developer Name';

  @override
  String get propertyExampleAbcDevelopmentCoLtd =>
      'Example: ABC Development Co., Ltd';

  @override
  String get propertyProjectName => 'Project Name';

  @override
  String get propertyProjectName2 => 'Project name';

  @override
  String get propertyTotalProjectArea => 'Total Project Area';

  @override
  String get propertyEnterTotalLandSize => 'Enter total land size';

  @override
  String get propertyTotalNumberOfUnitsInProject =>
      'Total number of units in project';

  @override
  String get propertyStartingPrice => 'Starting Price';

  @override
  String get propertyStartingPriceInUsd => 'Starting price in USD';

  @override
  String get propertyMonthlyRent => 'Monthly Rent';

  @override
  String get propertyEnterMonthlyShopRentUsd => 'Enter monthly shop rent (USD)';

  @override
  String get propertyEquipmentIncluded => 'Equipment Included';

  @override
  String get propertyListFurnitureKitchenEquipmentMachinesPos =>
      'List furniture, kitchen equipment, machines, POS system, etc.';

  @override
  String get propertyReasonForSelling => 'Reason for Selling';

  @override
  String get propertyExampleOwnerRelocatingAbroad =>
      'Example: Owner relocating abroad';

  @override
  String get propertyEdit => 'Edit';

  @override
  String get propertyPublishToPublic => 'Publish to Public';

  @override
  String get propertyMoveToDraft => 'Move to Draft';

  @override
  String get propertyDeleteProperty => 'Delete Property';

  @override
  String get propertyPropertyDeleted => 'Property deleted';

  @override
  String get commonContinue => 'Continue';

  @override
  String get sessionEnded => 'You were signed out of this device.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredMessage =>
      'Update Tilomnov from your app store to keep using it.';

  @override
  String get securityCreatePassword => 'Create password';

  @override
  String get createPasswordIntro =>
      'Set a password and confirm with Google. You can still sign in with Google.';

  @override
  String get createPasswordAction => 'Confirm with Google and create';

  @override
  String get createPasswordDone => 'Password created.';

  @override
  String get chatOpenFailed =>
      'Could not open this chat. Check your connection.';

  @override
  String get devicesImmediateNote => 'Devices are signed out right away.';

  @override
  String get devicesTooNew =>
      'Wait 24 hours after signing in to sign out other devices, or use an older device.';

  @override
  String devicesTooNewUntil(String when) {
    return 'You can sign out other devices from $when. Until then, use a device signed in earlier.';
  }

  @override
  String get newSignInTitle => 'New sign-in to your account';

  @override
  String get newSignInMessage =>
      'New sign-in. Not you? Sign out that device and change your password.';

  @override
  String get newSignInWasMe => 'It was me';

  @override
  String get newSignInReview => 'Review devices';

  @override
  String get avatarRemove => 'Remove photo';

  @override
  String get avatarUpdated => 'Profile picture updated.';

  @override
  String get avatarFailed =>
      'Could not change the profile picture. Please try again.';

  @override
  String get avatarSyncHelp =>
      'Use your Google account\'s photo and keep it up to date.';

  @override
  String get avatarNoGooglePhoto => 'Your Google account has no photo.';

  @override
  String get accountDeviceTooNew =>
      'Wait 24 hours after signing in, or use a device signed in earlier.';

  @override
  String get personalInfoUsernameChecking => 'Checking…';

  @override
  String get personalInfoUsernameAvailable => 'This username is available.';

  @override
  String mediaSourceTooLarge(int limitMb) {
    return 'This file is larger than $limitMb MB and cannot be uploaded.';
  }

  @override
  String get mediaStillTooLarge => 'Picture too large. Choose a smaller one.';

  @override
  String get mediaUnreadable =>
      'This picture could not be read. Please choose another one.';

  @override
  String get searchFieldHint => 'Search area, road, listing or person';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchSectionPlaces => 'Places';

  @override
  String get searchSectionListings => 'Listings';

  @override
  String get searchSectionPeople => 'People & agencies';

  @override
  String get searchIdleTitle => 'Find a place, a listing or a person';

  @override
  String get searchIdleBody => 'Search for a place, owner or agency.';

  @override
  String searchNoResultsTitle(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsBody =>
      'Check the spelling, or try a nearby road or district.';

  @override
  String get searchFailureOffline =>
      'You are offline. Check your connection and try again.';

  @override
  String get searchFailureTooManyRequests =>
      'Too many searches. Please wait a moment and try again.';

  @override
  String get searchFailureUnavailable =>
      'Place search is not available right now. Please try again later.';

  @override
  String get searchFailureNotFound =>
      'This place could not be found. Try another result.';

  @override
  String get searchFailureUnknown => 'Something went wrong. Please try again.';

  @override
  String searchListingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
      zero: 'No listings',
    );
    return '$_temp0';
  }

  @override
  String searchPropertiesInArea(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties in this area',
      one: '1 property in this area',
      zero: 'No properties here yet',
    );
    return '$_temp0';
  }

  @override
  String searchPropertiesByPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count published listings',
      one: '1 published listing',
      zero: 'No published listings',
    );
    return '$_temp0';
  }

  @override
  String get searchAreaEmpty => 'No listings here. Try a wider area.';

  @override
  String get searchPersonEmpty => 'No published listings yet.';

  @override
  String get searchViewProperty => 'View property';

  @override
  String get searchCloseResults => 'Close search results';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchHistoryEdit => 'Edit this search';

  @override
  String get searchHistoryRemove => 'Remove from history';

  @override
  String get searchHistoryRemoveFailed =>
      'This search could not be removed. Please try again.';

  @override
  String profileMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get profileListingsTitle => 'Listings';

  @override
  String get profileViewOnMap => 'View on map';

  @override
  String get profileListingsStat => 'Listings';

  @override
  String get profileFollow => 'Follow';

  @override
  String get profileFollowing => 'Following';

  @override
  String get profileFollowersStat => 'Followers';

  @override
  String get profileFollowingStat => 'Following';

  @override
  String profileFollowLimit(int count) {
    return 'You can follow up to $count people. Unfollow someone to follow more.';
  }

  @override
  String get profileFollowFailed =>
      'Following could not be changed. Please try again.';

  @override
  String get navFeed => 'Feed';

  @override
  String get feedTitle => 'Feed';

  @override
  String get feedSubtitle => 'Listings from people you follow.';

  @override
  String get feedNewestFirst => 'Newest first';

  @override
  String get feedSortTop => 'Top (most saved)';

  @override
  String get feedListingDate => 'Listing date';

  @override
  String get feedAnyTime => 'Any time';

  @override
  String get feedLast7Days => 'Last 7 days';

  @override
  String get feedLast30Days => 'Last 30 days';

  @override
  String get feedChooseDates => 'Choose dates';

  @override
  String get feedPriceInvalid =>
      'Enter a price between \$0 and \$9,999,999,999.99.';

  @override
  String get feedNoMatches => 'No matching listings';

  @override
  String get feedTryOtherFilters =>
      'Try a different date, price or property type.';

  @override
  String get feedEmptyTitle => 'Your feed is empty';

  @override
  String get feedEmptyHint => 'Follow people to see their new listings.';

  @override
  String get feedExplore => 'Explore listings';

  @override
  String get feedLoadFailed => 'Your feed could not be loaded.';

  @override
  String feedListedOn(String date) {
    return 'Listed $date';
  }

  @override
  String get profileContactTitle => 'Contact';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileEmail => 'Email';

  @override
  String profileCopied(String label) {
    return '$label copied';
  }

  @override
  String get profileCopy => 'Copy';

  @override
  String get profileChat => 'Chat';

  @override
  String get chatTabProfile => 'Profile';

  @override
  String get chatViewFullProfile => 'View full profile';

  @override
  String get profileTabAbout => 'About';

  @override
  String get profileNoContact => 'No contact details shared.';

  @override
  String get propertySavePhoto => 'Save photo';

  @override
  String propertyPhotoLimit(int count) {
    return 'A listing can have up to $count photos.';
  }

  @override
  String get propertyEditProperty => 'Edit Property';

  @override
  String get propertySaveChanges => 'Save Changes';

  @override
  String get propertySavingChanges => 'Saving changes...';

  @override
  String get propertyChangesSaved => 'Changes saved.';

  @override
  String get propertyCouldNotSaveChanges =>
      'Could not save your changes. Please try again.';

  @override
  String propertyCurrentPhotos(int count) {
    return 'Current photos ($count)';
  }

  @override
  String propertyRestoreRemovedPhotos(int count) {
    return 'Undo remove ($count)';
  }

  @override
  String get propertyRemovePhoto => 'Remove photo';

  @override
  String get propertyNearby => 'What\'s nearby';

  @override
  String get propertyNearbyCaption => 'Closest by road from this property';

  @override
  String get propertyNearbyMarkets => 'Markets';

  @override
  String get propertyNearbyHospitals => 'Hospitals';

  @override
  String get propertyNearbySchools => 'Schools';

  @override
  String propertyNearbyNoneWithin(int km) {
    return 'None found within $km km';
  }

  @override
  String propertyDistanceKm(String distance) {
    return '$distance km';
  }

  @override
  String propertyDistanceM(int distance) {
    return '$distance m';
  }

  @override
  String propertyStraightLine(String distance) {
    return '$distance straight line';
  }

  @override
  String get propertyNearbyCouldNotLoad => 'Couldn\'t load nearby places.';

  @override
  String get propertyNearbyRouteCouldNotLoad =>
      'Couldn\'t load the road to this place.';

  @override
  String get propertyDiscount => 'Discount (optional)';

  @override
  String get propertyDiscountHint => 'e.g. 10';

  @override
  String get propertyDiscountInvalid =>
      'Use more than 0 and less than 100%, or less than the price.';

  @override
  String propertyPriceCut(String amount) {
    return 'Price cut: $amount';
  }

  @override
  String get propertyVisibility => 'Visibility';

  @override
  String get propertyVisibilityPublic => 'Public';

  @override
  String get propertyVisibilityPublicHint => 'Anyone can find it on the map.';

  @override
  String get propertyVisibilityDraft => 'Draft';

  @override
  String get propertyVisibilityDraftHint => 'Hidden; only you can see it.';

  @override
  String get propertyVisibilitySold => 'Sold';

  @override
  String get propertyVisibilitySoldHint => 'Marked sold and taken off the map.';

  @override
  String get propertyVisibilitySoldNeedsPublic =>
      'Publish it first to mark it sold.';

  @override
  String get propertyVisibilityChanged => 'Visibility updated.';

  @override
  String get propertyCouldNotChangeVisibility =>
      'Could not change the visibility. Please try again.';

  @override
  String get propertyCouldNotOpenEditor =>
      'Could not open the listing for editing. Please try again.';

  @override
  String get propertyDrawBoundaryFirst =>
      'Draw the property on the map first to measure it.';

  @override
  String get securityPinRequiredNote =>
      'Your chats are always end-to-end encrypted and protected by your 6-digit chat PIN. You need it to read your chats on a new phone.';

  @override
  String get chatPasswordChecking => 'Checking your password...';

  @override
  String get chatLockedTitle => 'Chats are locked on this phone';

  @override
  String get chatEnterPinAction => 'Enter PIN';

  @override
  String get authErrEnterName => 'Please enter your name';

  @override
  String get authErrEnterPassword => 'Enter a valid password';

  @override
  String get authErrPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get authErrAgreeTerms =>
      'Please agree to the terms of services to continue.';

  @override
  String get authErrEnterEmail => 'Please enter a valid email address';

  @override
  String get authErrEnterNewPassword => 'Please enter a new password';

  @override
  String get authErrReEnterPassword => 'Please re-enter your password';

  @override
  String get authErrPasswordsDontMatch => 'Passwords do not match';

  @override
  String get termsTitle => 'Terms of Service for Tilomnov';

  @override
  String get termsLastUpdated => 'Last updated: 14 February 2026';

  @override
  String get termsWelcome =>
      'Welcome to Tilomnov. By accessing or using the Tilomnov application and services, you agree to comply with and be bound by the following Terms of Service.';

  @override
  String get termsDisagree =>
      'If you do not agree with these terms, please do not use the application.';

  @override
  String get termsAboutTitle => '1. About Tilomnov';

  @override
  String get termsAboutIntro =>
      'Tilomnov is a map-based property platform that allows users to:';

  @override
  String get termsAboutView =>
      'View property listings with accurate map locations and boundaries';

  @override
  String get termsAboutManage => 'Add, manage, and share property information';

  @override
  String get termsAboutConnect =>
      'Connect buyers, sellers, agents, and developers';

  @override
  String get termsAboutTools =>
      'Use coordinate tools such as UTM input and map measurement';

  @override
  String get termsAboutPlatformOnly =>
      'Tilomnov acts only as a platform and does not own, sell, or broker any property.';

  @override
  String get termsAccountsTitle => '2. User Accounts';

  @override
  String get termsAccountsIntro =>
      'To use certain features, users must register using a valid phone number or email address.\nYou agree that:';

  @override
  String get termsAccountsAccurate => 'The information you provide is accurate';

  @override
  String get termsAccountsConfidential =>
      'You are responsible for maintaining the confidentiality of your account';

  @override
  String get termsAccountsNoImpersonation =>
      'You will not impersonate another person';

  @override
  String get termsAccountsSuspend =>
      'Tilomnov reserves the right to suspend accounts that provide false information.';

  @override
  String get termsListingsTitle => '3. Property Listings';

  @override
  String get termsListingsIntro =>
      'Users who post properties (owners, agents, developers) agree that:';

  @override
  String get termsListingsTruthful =>
      'All information, boundaries, prices, and details are truthful';

  @override
  String get termsListingsRight =>
      'You have the legal right to share and advertise the property';

  @override
  String get termsListingsCoordinates =>
      'The map boundary or UTM coordinates you provide are accurate to the best of your knowledge';

  @override
  String get termsListingsNotResponsible =>
      'Tilomnov is not responsible for incorrect property data submitted by users.';

  @override
  String get termsMapTitle => '4. Map and Coordinate Accuracy';

  @override
  String get termsMapIntro =>
      'Tilomnov provides tools for map visualization, UTM conversion, and distance measurement.';

  @override
  String get termsMapGuidanceOnly =>
      'Map boundaries are for visual guidance only and do not replace official cadastral surveys or land titles.';

  @override
  String get termsMapVerify =>
      'Users should verify all land borders and titles with relevant authorities before financial transactions.';

  @override
  String get termsAgree => 'Agree terms of services';

  @override
  String get authErrEnterValidEmail => 'Enter a valid email address';

  @override
  String get authErrEnterValidPhone => 'Enter a valid phone number';

  @override
  String get authErrPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get authErrorWrongCredentials =>
      'Incorrect email, phone number or password.';

  @override
  String get authErrorAccountExists =>
      'An account with this email or phone number already exists.';

  @override
  String get authErrorCheckDetails =>
      'Please check what you entered and try again.';

  @override
  String get authErrorInvalidCode => 'The code is wrong or has expired.';

  @override
  String get authErrorTooManyTries =>
      'Too many tries. Please wait a few minutes and try again.';

  @override
  String get authErrorNoConnection =>
      'Could not reach the server. Check your connection.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String authResendOtpIn(int seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get chatPhotoUnavailable => 'Photo unavailable. Tap to retry.';

  @override
  String get chatPictureCannotBeShown => 'This picture cannot be shown.';

  @override
  String get chatMessageNotSent => 'Not sent. Tap to retry.';

  @override
  String get chatMessageSending => 'Sending…';

  @override
  String get chatMessageSent => 'Sent';

  @override
  String chatMessageTimeYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get chatDeliveredJustNow => 'Delivered just now';

  @override
  String chatDeliveredMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return 'Delivered $_temp0';
  }

  @override
  String chatDeliveredHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return 'Delivered $_temp0';
  }

  @override
  String chatDeliveredOn(String day) {
    return 'Delivered $day';
  }

  @override
  String get chatAttachPicture => 'Attach a picture';

  @override
  String get chatShowEmojis => 'Emoji';

  @override
  String get chatShowKeyboard => 'Keyboard';

  @override
  String get chatSendMessage => 'Send message';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatCopy => 'Copy';

  @override
  String get chatEdit => 'Edit';

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatYou => 'You';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatEditingMessage => 'Editing message';

  @override
  String get chatEdited => 'Edited';

  @override
  String get chatAskAboutListing => 'Asking about this listing?';

  @override
  String get chatSendListing => 'Send';

  @override
  String get chatDismissListing => 'Not now';

  @override
  String get chatViewListing => 'View listing';

  @override
  String get chatListingUnavailable => 'This listing is no longer available.';

  @override
  String get chatDeleteMessageQuestion => 'Delete this message?';

  @override
  String get chatDeleteMessageForEveryone => 'Delete for everyone';

  @override
  String get chatDeleteMessageForMe => 'Delete for me';

  @override
  String chatDeleteOwnMessageExplained(String name) {
    return 'Delete for you and $name, or just for you.';
  }

  @override
  String chatDeleteMessageForMeExplained(String name) {
    return 'Only deleted for you. $name can still see it.';
  }

  @override
  String get chatEditTooLate => 'You can edit messages for up to 1 hour.';

  @override
  String get chatPresenceOnline => 'Online';

  @override
  String get chatLastSeenJustNow => 'Last seen just now';

  @override
  String chatLastSeenMinutes(int minutes) {
    return 'Last seen $minutes min ago';
  }

  @override
  String chatLastSeenToday(String time) {
    return 'Last seen today at $time';
  }

  @override
  String chatLastSeenYesterday(String time) {
    return 'Last seen yesterday at $time';
  }

  @override
  String chatLastSeenOn(String date) {
    return 'Last seen $date';
  }

  @override
  String get chatEmojiSmileys => 'Smileys';

  @override
  String get chatEmojiGestures => 'Gestures';

  @override
  String get chatEmojiHearts => 'Hearts';

  @override
  String get chatEmojiPlaces => 'Places';

  @override
  String get chatPreviewEncrypted => 'Message unavailable';

  @override
  String get chatPreviewPhoto => 'Photo';

  @override
  String get chatUndecryptable => 'This message cannot be read on this device.';

  @override
  String get ownerFallbackName => 'Property Owner';

  @override
  String get chatSendSignedOut => 'You are signed out.';

  @override
  String get chatSendNoConnection =>
      'Could not reach the server. Check your connection.';

  @override
  String get chatSendRejected => 'Message not accepted. Try again.';

  @override
  String get chatSendTooFast => 'Sending too fast. Wait a moment.';

  @override
  String get chatSendBlocked => 'You can\'t message this person.';

  @override
  String chatYouBlocked(String name) {
    return 'You blocked $name. They can\'t message or call you.';
  }

  @override
  String get chatCannotReply => 'You can\'t reply to this conversation.';

  @override
  String get safetyMore => 'More';

  @override
  String get blockAction => 'Block';

  @override
  String get unblockAction => 'Unblock';

  @override
  String blockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockConfirmMessage =>
      'They can’t message or call you. You’ll unfollow each other. They won’t be notified.';

  @override
  String unblockConfirmTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get unblockConfirmMessage =>
      'You can message each other again. Follow them again if you want to.';

  @override
  String blockDone(String name) {
    return '$name is blocked.';
  }

  @override
  String unblockDone(String name) {
    return '$name is unblocked.';
  }

  @override
  String get blockFailed =>
      'That didn\'t work. Check your connection and try again.';

  @override
  String get blockedAccountsTitle => 'Blocked accounts';

  @override
  String get blockedAccountsEmpty => 'You haven\'t blocked anyone.';

  @override
  String get blockedAccountsLoadFailed =>
      'Couldn\'t load the accounts you blocked.';

  @override
  String get reportListingAction => 'Report listing';

  @override
  String get reportUserAction => 'Report account';

  @override
  String get reportListingTitle => 'Report this listing';

  @override
  String get reportUserTitle => 'Report this account';

  @override
  String get reportHelp =>
      'Tell us what\'s wrong. The owner won\'t know who reported it.';

  @override
  String get reportReasonScam => 'Scam or fraud';

  @override
  String get reportReasonMisleading => 'Wrong price, photos or details';

  @override
  String get reportReasonUnavailable => 'Already sold or rented';

  @override
  String get reportReasonDuplicate => 'Posted more than once';

  @override
  String get reportReasonHarassment => 'Harassment or threats';

  @override
  String get reportReasonImpersonation => 'Pretending to be someone else';

  @override
  String get reportReasonInappropriate => 'Offensive or inappropriate';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDetailsHint => 'Anything else we should know (optional)';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Thanks. We\'ll review your report.';

  @override
  String get reportTooMany => 'You\'ve sent a lot of reports. Try again later.';

  @override
  String get reportTargetGone => 'This has already been removed.';

  @override
  String get reportFailed =>
      'The report wasn\'t sent. Check your connection and try again.';

  @override
  String chatSendFileTooLarge(int megabytes) {
    return 'This file is too large (limit $megabytes MB).';
  }

  @override
  String get chatSendUploadFailed =>
      'Could not upload the file. Check your connection.';

  @override
  String get chatSendFailed => 'Message not sent. Please try again.';

  @override
  String get mapNewListing => 'New';

  @override
  String homeExtractedCoordinates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count coordinates.',
      one: 'Found 1 coordinate.',
    );
    return '$_temp0';
  }

  @override
  String get homeScanFailed => 'Could not read the document. Please try again.';

  @override
  String get homeInvalidUtm =>
      'These UTM coordinates are not valid. Please check them.';

  @override
  String get homeScanProcessing => 'Processing...';

  @override
  String get homeScanFinished => 'Finished';

  @override
  String get homeLocationServicesOff =>
      'Location services are disabled. Please enable them.';

  @override
  String get homeLocationDenied => 'Location permission was denied.';

  @override
  String get homeLocationDeniedForever =>
      'Location permission is permanently denied. You can allow it in the phone\'s settings.';

  @override
  String get homeLocationFailed =>
      'Could not get your location. Please try again.';

  @override
  String get propertyMaintenanceFeeHint => 'Monthly maintenance fee (USD)';

  @override
  String get propertyDuration => 'Duration';

  @override
  String get propertySelectUnit => 'Select unit';

  @override
  String get propertySizeTitle => 'Size';

  @override
  String get propertyLandSizeTitle => 'Land Size';

  @override
  String get propertySizeAreaHint => 'Size area (m²)';

  @override
  String get propertyEnterLandSize => 'Enter land size (m²)';

  @override
  String get propertyEnterBuildingSize => 'Enter building size';

  @override
  String get propertyEnterUnitSize => 'Enter unit size';

  @override
  String get propertyProjectNameInfo =>
      'Official name of the development project';

  @override
  String get propertyProjectAreaInfo => 'Total land area of entire project';

  @override
  String get propertyStartingPriceInfo => 'Lowest available unit price';

  @override
  String get propertyMonthlyRentInfo => 'Lower rent = higher profit potential';

  @override
  String get propertyEquipmentInfo => 'Describe assets included in sale';

  @override
  String get propertySelectHint => 'Select';

  @override
  String get propertyPublishedTitle => 'Property Published\nSuccessfully!';

  @override
  String get propertyShowLess => 'Show less';

  @override
  String get propertyShowMore => 'Show more';

  @override
  String get propertyNoListingsYet => 'You haven\'t listed any\nproperty yet';

  @override
  String get propertyPublishedToast => 'Property published';

  @override
  String get propertyMovedToDraft => 'Property moved to draft';

  @override
  String get propertyPublish => 'Publish';

  @override
  String get propertyArchive => 'Archive';

  @override
  String get propertyArchivedPrivately =>
      'Saved privately. Only you can see this listing.';

  @override
  String get propertySaveFailed =>
      'Could not save the property. Please try again.';

  @override
  String get propertyUpdateFailed =>
      'Could not update the property. Please try again.';

  @override
  String get propertyDeleteFailed =>
      'Could not delete the property. Please try again.';

  @override
  String propertyListingBy(String name) {
    return 'Listing by: $name';
  }

  @override
  String propertyTabActive(int count) {
    return 'Active ($count)';
  }

  @override
  String propertyTabPending(int count) {
    return 'Pending ($count)';
  }

  @override
  String propertyTabDraft(int count) {
    return 'Draft ($count)';
  }

  @override
  String propertyTabSold(int count) {
    return 'Sold ($count)';
  }

  @override
  String get propertyContacts => 'Contacts';

  @override
  String propertySavedCount(int count) {
    return '$count Saved';
  }

  @override
  String propertySpecBeds(int count) {
    return '$count bds';
  }

  @override
  String propertySpecBaths(int count) {
    return '$count ba';
  }

  @override
  String propertyTypeForSale(String type) {
    return '$type for sale';
  }

  @override
  String propertyTypeForRent(String type) {
    return '$type for rent';
  }

  @override
  String propertyPriceFrom(String price) {
    return 'From $price';
  }

  @override
  String propertyBedroomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Beds',
      one: '1 Bed',
    );
    return '$_temp0';
  }

  @override
  String propertyBathroomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Baths',
      one: '1 Bath',
    );
    return '$_temp0';
  }

  @override
  String propertyDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get sortPropertyForYou => 'Property for You';

  @override
  String get sortRecentlyPosted => 'Recently Posted';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPriceHighToLow => 'Price: High to Low';

  @override
  String get sortPriceLowToHigh => 'Price: Low to High';

  @override
  String get listingTypeTitle => 'Listing Type';

  @override
  String get listingTypeSale => 'Sale';

  @override
  String get listingTypeRent => 'Rent';

  @override
  String get listingTypeToLet => 'To Let';

  @override
  String get propertyTypeLand => 'Land';

  @override
  String get propertyTypeHouse => 'House';

  @override
  String get propertyTypeBuilding => 'Building';

  @override
  String get propertyTypeCondo => 'Condo';

  @override
  String get propertyTypeBorey => 'Borey';

  @override
  String get propertyTypeBusiness => 'Business for Sale';

  @override
  String get propertyTypeBusinessShort => 'Business';

  @override
  String get propertyTypeWarehouse => 'Warehouse';

  @override
  String get propertyStatusActive => 'Active';

  @override
  String get propertyStatusPending => 'Pending';

  @override
  String get propertyStatusDraft => 'Draft';

  @override
  String get propertyStatusSold => 'Sold';

  @override
  String get propertyStatusExpired => 'Expired';

  @override
  String get propertyOptionHardTitle => 'Hard Title';

  @override
  String get propertyOptionSoftTitle => 'Soft Title';

  @override
  String get propertyOptionOther => 'Other';

  @override
  String get propertyOptionStudio => 'Studio';

  @override
  String get propertyOptionYes => 'Yes';

  @override
  String get propertyOptionNo => 'No';

  @override
  String get propertyOptionUnfurnished => 'Unfurnished';

  @override
  String get propertyOptionFullyFurnished => 'Fully Furnished';

  @override
  String get propertyOptionElectricalAppliances => 'Electrical appliances';

  @override
  String get propertyOptionCommercialBuilding => 'Commercial Building';

  @override
  String get propertyOptionOfficeBuilding => 'Office Building';

  @override
  String get propertyOptionMixedUse => 'Mixed-use';

  @override
  String get propertyOptionRetailBuilding => 'Retail Building';

  @override
  String get propertyOptionOffPlan => 'Off-plan';

  @override
  String get propertyOptionUnderConstruction => 'Under Construction';

  @override
  String get propertyOptionCompleted => 'Completed';

  @override
  String get propertyOptionCityView => 'City View';

  @override
  String get propertyOptionRiverView => 'River View';

  @override
  String get propertyOptionGardenView => 'Garden View';

  @override
  String get propertyOptionPoolView => 'Pool View';

  @override
  String get propertyOptionNoView => 'No View';

  @override
  String get propertyOptionCommercial => 'Commercial';

  @override
  String get propertyOptionLandSubdivision => 'Land Subdivision';

  @override
  String get propertyOptionPreLaunch => 'Pre-launch';

  @override
  String get propertyOptionCompleted50 => '50% Completed';

  @override
  String get propertyOptionCompleted80 => '80% Completed';

  @override
  String get propertyOptionMonths => 'Months';

  @override
  String get propertyOptionYears => 'Years';

  @override
  String get keywordRoadAccess => 'Road Access';

  @override
  String get keywordCornerLand => 'Corner Land';

  @override
  String get keywordNearMarket => 'Near Market';

  @override
  String get keywordNearSchool => 'Near School';

  @override
  String get keywordNearHospital => 'Near Hospital';

  @override
  String get keywordRiverLakeNearby => 'River / Lake Nearby';

  @override
  String get keywordElectricityReady => 'Electricity Ready';

  @override
  String get keywordWaterSupply => 'Water Supply';

  @override
  String get keywordResidentialArea => 'Residential Area';

  @override
  String get keywordCommercialArea => 'Commercial Area';

  @override
  String get chatPreviewVoice => 'Voice message';

  @override
  String get chatVoiceMessage => 'Voice message';

  @override
  String get chatRecordVoice => 'Record a voice message';

  @override
  String get chatRecordingVoice => 'Recording';

  @override
  String get chatSendVoice => 'Send voice message';

  @override
  String get chatDiscardVoice => 'Delete recording';

  @override
  String get chatSlideToCancel => 'Slide to cancel';

  @override
  String get chatCallOutgoing => 'Outgoing call';

  @override
  String get chatCallIncoming => 'Incoming call';

  @override
  String get chatCallLost => 'Call lost';

  @override
  String get chatCallNoAnswer => 'No answer';

  @override
  String get chatCallCancelled => 'Cancelled call';

  @override
  String get chatCallDeclined => 'Call declined';

  @override
  String get chatCallYouDeclined => 'You declined the call';

  @override
  String get chatCallMissed => 'Missed call';

  @override
  String get chatVoiceTooShort => 'Voice message too short.';

  @override
  String get chatVoiceRecordFailed => 'Could not record. Try again.';

  @override
  String get chatVoiceUnavailable => 'Voice message unavailable. Tap to retry.';

  @override
  String get chatPlayVoice => 'Play';

  @override
  String get chatPauseVoice => 'Pause';

  @override
  String get chatVoiceSpeed => 'Playback speed';

  @override
  String get microphoneDenied =>
      'Allow microphone access to record your voice.';

  @override
  String get microphoneBlocked =>
      'Microphone access is turned off. Turn it on in Settings.';

  @override
  String get openSystemSettings => 'Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsChatTitle => 'Chat messages';

  @override
  String get notificationsChatHelp => 'Message alerts.';

  @override
  String get notificationsPromotionsTitle => 'Offers and news';

  @override
  String get notificationsPromotionsHelp => 'Promotions and product updates.';

  @override
  String get notificationsSavedSearchTitle => 'Saved search alerts';

  @override
  String get notificationsSavedSearchHelp =>
      'New listings matching saved searches.';

  @override
  String get notificationsFollowedTitle => 'People you follow';

  @override
  String get notificationsFollowedHelp => 'New listings from followed users.';

  @override
  String get notificationsSavedUpdatesTitle => 'Saved listings';

  @override
  String get notificationsSavedUpdatesHelp =>
      'Price changes and sale updates for saved listings.';

  @override
  String get feedPriceDropped => 'Price dropped';

  @override
  String get savedSearchesTitle => 'Saved searches';

  @override
  String get savedSearchesEmpty =>
      'Set map filters, then tap the bookmark to save your search.';

  @override
  String get savedSearchesLoadFailed => 'Couldn\'t load your saved searches.';

  @override
  String get savedSearchSaveTitle => 'Save this search';

  @override
  String get savedSearchSaveHelp =>
      'Alerts for new listings matching this search.';

  @override
  String get savedSearchName => 'Name';

  @override
  String get savedSearchSaved =>
      'Search saved. We\'ll let you know about new listings.';

  @override
  String savedSearchLimit(int count) {
    return 'You can save up to $count searches. Delete one first.';
  }

  @override
  String get savedSearchFailed =>
      'That didn\'t work. Check your connection and try again.';

  @override
  String get savedSearchNoArea =>
      'The map is still loading. Try again in a moment.';

  @override
  String get savedSearchAnyListing => 'Any listing in this area';

  @override
  String savedSearchKeywords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keywords',
      one: '1 keyword',
    );
    return '$_temp0';
  }

  @override
  String get savedSearchAlerts => 'Alerts';

  @override
  String get savedSearchRename => 'Rename';

  @override
  String get savedSearchDelete => 'Delete';

  @override
  String get savedSearchDeleted => 'Saved search deleted.';

  @override
  String get notificationsAlwaysOn => 'Calls and sign-in alerts are always on.';

  @override
  String get notificationsBlockedTitle => 'Notifications are off for this app';

  @override
  String get notificationsBlockedHelp =>
      'Enable notifications in device settings.';

  @override
  String get chatPreviewNewMessage => 'New message';

  @override
  String get notificationsShowTextTitle => 'Show message text';

  @override
  String get notificationsShowTextHelp =>
      'Display message previews in notifications.';

  @override
  String get notificationsLoadFailed =>
      'Could not load your notification settings.';

  @override
  String get notificationsSaveFailed =>
      'Could not save. Check your connection and try again.';

  @override
  String get callVoice => 'Voice call';

  @override
  String get callCalling => 'Calling…';

  @override
  String get callIncoming => 'Incoming voice call';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callDeclined => 'Call declined';

  @override
  String get callNoAnswer => 'No answer';

  @override
  String get callBusy => 'On another call';

  @override
  String get callUnavailable => 'Can\'t be called right now';

  @override
  String get callMicrophoneNeeded =>
      'Calls need the microphone. Allow it in Settings.';

  @override
  String get callConnectionLost => 'Connection lost';

  @override
  String get callFailed => 'Call failed';

  @override
  String get callAnsweredElsewhere => 'Answered on another device';

  @override
  String get callAccept => 'Accept';

  @override
  String get callDecline => 'Decline';

  @override
  String get callHangUp => 'End call';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String callIncomingFrom(String name) {
    return '$name is calling';
  }

  @override
  String callMissedFrom(String name) {
    return 'Missed call from $name';
  }

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterForSale => 'For sale';

  @override
  String get filterForRent => 'For rent';

  @override
  String get filterPriceRange => 'Price range';

  @override
  String filterPriceLabel(String range) {
    return 'Price: $range';
  }

  @override
  String get filterPriceAny => 'Any';

  @override
  String filterPerMonth(String price) {
    return '$price/month';
  }

  @override
  String get filterMinPrice => 'Min Price';

  @override
  String get filterMaxPrice => 'Max Price';

  @override
  String get filterNoMin => 'No min';

  @override
  String get filterNoMax => 'No max';

  @override
  String get filterDownPayment => 'Down payment';

  @override
  String get filterNoDownPayment => 'No down payment';

  @override
  String get filterLandSize => 'Land size';

  @override
  String get filterPropertySize => 'Property size';

  @override
  String get filterMinArea => 'Min m²';

  @override
  String get filterMaxArea => 'Max m²';

  @override
  String get filterMinAboveMax => 'The minimum is above the maximum';

  @override
  String get filterPropertyType => 'Property Type';

  @override
  String get filterKeywords => 'Keywords / Features';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterSeeResults => 'See results';

  @override
  String get propertyFactsTitle => 'Property Details';

  @override
  String get propertyFactsOverview => 'Overview';

  @override
  String get propertyFactsSize => 'Size';

  @override
  String get propertyFactsBuilding => 'Rooms & Building';

  @override
  String get propertyFactsProject => 'Project';

  @override
  String get propertyFactsCosts => 'Costs & Business';

  @override
  String get propertyFactsFeatures => 'Features';

  @override
  String get propertyFactPricePerSquareMetre => 'Price per m²';

  @override
  String propertyFactPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String propertyFactMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get propertyPublisherTitle => 'Listed by';

  @override
  String get propertyPublisherViewProfile => 'View Profile';

  @override
  String get authPhoneHint => '012 345 678';

  @override
  String get authEmailOptional => 'Email (optional)';

  @override
  String get authAgreeToTermsPrefix => 'I agree to the ';

  @override
  String get personalInfoAddEmail => 'Add email';

  @override
  String get addEmailTitle => 'Add email';

  @override
  String get addEmailIntro =>
      'Confirm your password to add an email for password recovery.';

  @override
  String get addEmailDone => 'Email added';

  @override
  String get addEmailTaken => 'This email is already used by another account.';

  @override
  String get closestTitleNearYou => 'Listings near you';

  @override
  String get closestTitleNearMap => 'Listings near the map centre';

  @override
  String get closestSubtitle => 'Nearest first, then further away';

  @override
  String closestAway(String distance) {
    return '$distance away';
  }

  @override
  String get closestEmptyTitle => 'No listings found';

  @override
  String get closestEmptyHint => 'Try clearing some filters.';

  @override
  String get closestLoadFailed => 'Listings could not be loaded.';

  @override
  String get closestRefresh => 'Measure from where I am now';

  @override
  String get closestShowList => 'Show listings near you';

  @override
  String get authEnterYourPhoneNumberToGet =>
      'Enter your phone number and we will text you a code to reset your password.';

  @override
  String get authVerificationCodeSentToYourPhone =>
      'Verification code sent to your phone';

  @override
  String get authEnterTheVerificationCodeWeTexted =>
      'Enter the verification code we just texted to your phone.';

  @override
  String get authErrorNoAccountForPhone => 'No account uses this phone number.';

  @override
  String get authErrorSmsUnavailable =>
      'Text messages cannot be sent right now. Reset with your email, or try again later.';

  @override
  String get planFree => 'Free';

  @override
  String get planSilver => 'Silver';

  @override
  String get planGold => 'Gold';

  @override
  String get planDiamond => 'Diamond';

  @override
  String planMember(String tier) {
    return '$tier member';
  }

  @override
  String planAccount(String tier) {
    return '$tier Account';
  }

  @override
  String get planPerMonth => '/ month';

  @override
  String planListingsUsed(int used, int limit) {
    return '$used / $limit listings used';
  }

  @override
  String get planCurrent => 'Current Plan';

  @override
  String planUpgradeTo(String tier) {
    return 'Upgrade to $tier';
  }

  @override
  String get planFeatures => 'Features';

  @override
  String planFeatureLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Publish up to $count properties',
      one: 'Publish 1 property at a time',
    );
    return '$_temp0';
  }

  @override
  String get planFeatureFree => 'Basic listing visibility';

  @override
  String get planFeatureSilver => 'Suits small agents';

  @override
  String get planFeatureGold => 'Higher listing capacity';

  @override
  String get planFeatureDiamond => 'Highest listing capacity';

  @override
  String get planChooseIntro => 'Choose a plan to publish more listings.';

  @override
  String get planUpgradeTitle => 'Upgrade Subscription';

  @override
  String get planUpgradeIntro =>
      'Plans last one month. Upgrades charge the price difference and keep your current expiry date.';

  @override
  String get planSubscribe => 'Subscribe';

  @override
  String get paymentSelectMethod => 'Select Payment Method';

  @override
  String get paymentTaxIncluded => 'Total price includes 10% tax.';

  @override
  String get paymentAbaPay => 'ABA PAY';

  @override
  String get paymentAbaPayHint => 'Pay with ABA Mobile';

  @override
  String get paymentAbaKhqr => 'ABA KHQR';

  @override
  String get paymentAbaKhqrHint => 'Scan to pay with any banking app';

  @override
  String get paymentAwaitingConfirmation =>
      'Waiting for ABA to confirm your payment. This usually takes a minute.';

  @override
  String get paymentFailed =>
      'The payment was not completed. Please try again.';

  @override
  String get paymentRefundRequired =>
      'Your payment arrived after the upgrade expired. Please contact support with your transaction reference for a refund.';

  @override
  String get paymentAppNotOpened =>
      'Could not open ABA Mobile or the payment page.';

  @override
  String get paymentUnavailable =>
      'Online payment is not available yet. Please try again later.';

  @override
  String get paymentCouldNotStart =>
      'Could not start the payment. Please try again.';

  @override
  String get paymentBillingSummary => 'Billing Summary';

  @override
  String get paymentPlan => 'Plan';

  @override
  String get paymentPrice => 'Price';

  @override
  String get paymentBillingCycle => 'Billing Cycle';

  @override
  String get paymentMonthly => 'Monthly';

  @override
  String get paymentTotal => 'Total';

  @override
  String get paymentOneTimeTitle => 'One-Time Payment';

  @override
  String get paymentOneTimeIntro => 'Your property is ready to publish.';

  @override
  String get publishingRenewListingTitle => 'Renew property post';

  @override
  String get publishingRenewListingMessage =>
      'Keep this property public for one month. Pay for this post, or use an active subscription with space available.';

  @override
  String get publishingRenewSubscriptionTitle => 'Renew your subscription';

  @override
  String get publishingRenewSubscriptionMessage =>
      'Your subscription has expired. Renew your plan to publish your properties again. Your original free listing stays available.';

  @override
  String get paymentPropertyInformation => 'Property information';

  @override
  String get paymentOneTime => 'One month · one-time payment';

  @override
  String get paymentPublishProperty => 'Publish Property';

  @override
  String get paymentProperty => 'Property';

  @override
  String get paymentCategory => 'Category';

  @override
  String get publishPlanTitle => 'Choose Publishing Plan';

  @override
  String get publishPlanOneTime => 'One-Time Publish';

  @override
  String publishPlanOneTimeHint(String price) {
    return 'Pay $price to publish this property for one month.';
  }

  @override
  String get publishPlanSubscription => 'Subscription Plan';

  @override
  String get publishPlanSubscriptionHint =>
      'Publish many properties every month.';

  @override
  String get publishPlanChooseFirst =>
      'Choose a plan or one-time payment to publish.';

  @override
  String get privacyLastUpdated => 'Last updated: November 4, 2026';

  @override
  String get privacyIntro =>
      'What we collect, how we use it, and your choices.';

  @override
  String get privacyCollectTitle => 'What we collect';

  @override
  String get privacyCollectAccount =>
      'Your name, username, phone number, optional email and profile photo.';

  @override
  String get privacyCollectListings =>
      'Listing photos, descriptions, prices, map locations, boundaries and contact numbers.';

  @override
  String get privacyCollectLocation =>
      'Your location, only when you allow it, to show listings and routes near you.';

  @override
  String get privacyCollectActivity =>
      'Saved listings and searches, follows and listing views, used for insights.';

  @override
  String get privacyCollectDevice =>
      'App version, phone model, sign-in device key and notification token for security and notifications.';

  @override
  String get privacyUseTitle => 'How we use it';

  @override
  String get privacyUseRun =>
      'To run the marketplace: show listings, connect buyers with owners, and deliver chats and calls.';

  @override
  String get privacyUseProtect =>
      'To protect accounts: spot suspicious sign-ins, limit misuse and act on reports.';

  @override
  String get privacyUseFix =>
      'To fix problems: crash and error reports help us find bugs.';

  @override
  String get privacyUseNoSale => 'We do not sell your personal information.';

  @override
  String get privacyChatTitle => 'Messages and calls';

  @override
  String get privacyChatBody =>
      'Messages are encrypted when sent and stored. Only chat participants can access them through the app. Tilomnov manages the encryption keys. No chat PIN is needed. Older encrypted messages are kept but can’t be opened.';

  @override
  String get privacyPaymentsTitle => 'Payments';

  @override
  String get privacyPaymentsBody =>
      'ABA PayWay handles payments. We never see or store card or bank details. We keep the transaction reference, amount, status and date with your account.';

  @override
  String get privacySharingTitle => 'Who can see your information';

  @override
  String get privacySharingIntro =>
      'We share information only as far as the app needs it:';

  @override
  String get privacySharingUsers =>
      'Others can see your listings, public profile and listing contact number.';

  @override
  String get privacySharingProviders =>
      'Google handles maps, sign-in, phone verification and notifications; Sentry handles error reports; ABA Bank handles payments.';

  @override
  String get privacySharingLaw => 'Authorities, when the law requires it.';

  @override
  String get privacyCookiesTitle => 'Cookies and storage on your phone';

  @override
  String get privacyCookiesIntro =>
      'No advertising or tracking cookies. We store these on your phone:';

  @override
  String get privacyCookiesSignIn =>
      'Your sign-in, kept in your phone\'s secure storage.';

  @override
  String get privacyCookiesSettings =>
      'Your settings, such as theme and language.';

  @override
  String get privacyCookiesOffline =>
      'Recent pages and photos for faster loading and offline use.';

  @override
  String get privacyCookiesClear =>
      'Sign out to remove your login. Clear app storage in your phone’s settings to remove other stored data.';

  @override
  String get privacyChoicesTitle => 'Your choices';

  @override
  String get privacyChoicesEdit =>
      'View and change your details at any time in Account > Personal information.';

  @override
  String get privacyChoicesLocation =>
      'Turn location access off in your phone\'s settings; the map still works without it.';

  @override
  String get privacyChoicesNotifications =>
      'Choose which notifications you get in Account > Notifications.';

  @override
  String get privacyChoicesDelete =>
      'Delete your listings at any time. To close your account, contact us.';

  @override
  String get privacyContactTitle => 'Contact us';

  @override
  String get privacyContactBody =>
      'Contact the Tilomnov team with questions. The date above shows the latest update.';

  @override
  String get paymentSuccessTitle => 'Success';

  @override
  String paymentSuccessAmount(String amount) {
    return '$amount USD';
  }

  @override
  String paymentSuccessTransaction(String id) {
    return 'Transaction ID  #$id';
  }

  @override
  String get paymentSuccessEmailed => 'Order confirmation email:';

  @override
  String get paymentSuccessNoEmail =>
      'Add an email in Personal information to get receipts by email.';

  @override
  String get paymentDownloadReceipt => 'Download Receipt';

  @override
  String get paymentBackToHome => 'Back to Home';

  @override
  String get paymentReceiptSaved => 'Receipt saved to your photos.';

  @override
  String get paymentReceiptSaveFailed =>
      'Could not save the receipt. Please try again.';

  @override
  String get paymentReceiptPhotosDenied =>
      'Allow access to your photos to save the receipt.';

  @override
  String get paymentReceiptTitle => 'Payment receipt';

  @override
  String get paymentReceiptTransaction => 'Transaction ID';

  @override
  String get paymentReceiptDate => 'Date';

  @override
  String get paymentReceiptItem => 'Item';

  @override
  String get paymentReceiptMethod => 'Payment method';

  @override
  String get paymentReceiptEmail => 'Email';

  @override
  String get paymentReceiptStatus => 'Status';

  @override
  String get paymentReceiptPaid => 'Paid';

  @override
  String paymentItemSubscription(String tier) {
    return '$tier plan · Monthly';
  }

  @override
  String get paymentItemOneTimePublish => 'Property post · one month';

  @override
  String get planCancelAction => 'Cancel plan';

  @override
  String get planCancelTitle => 'Cancel your plan?';

  @override
  String planCancelExplanation(String date) {
    return 'Your plan stays active until $date. You keep your paid benefits until then.';
  }

  @override
  String planActiveUntil(String date) {
    return 'Plan active until $date.';
  }

  @override
  String planCancelledUntil(String date) {
    return 'Plan cancelled. Your access stays active until $date.';
  }

  @override
  String get planCancelFailed =>
      'We could not cancel your plan. Please try again.';

  @override
  String get planStatusRetry => 'Could not load your plan. Tap to retry.';

  @override
  String get listingTypeTakeover => 'Takeover Payments';

  @override
  String get takeoverIntro =>
      'Enter the existing payment plan. Buyers pay you the seller amount, then take responsibility for the remaining balance, subject to provider approval.';

  @override
  String get takeoverProviderType => 'Payment provider type';

  @override
  String get takeoverProviderName => 'Developer or bank name';

  @override
  String get takeoverProjectName => 'Project name';

  @override
  String get takeoverSellerAmount => 'Amount payable to seller (USD)';

  @override
  String get takeoverBalance => 'Remaining balance (USD)';

  @override
  String get takeoverBalanceHelp =>
      'Outstanding contract balance or loan principal, excluding future financing interest. Include any larger scheduled payments in this balance.';

  @override
  String get takeoverBalanceDate => 'Balance as of';

  @override
  String get takeoverPaymentAmount => 'Regular instalment (USD)';

  @override
  String get takeoverFrequency => 'Payment frequency';

  @override
  String get takeoverRemainingMonths => 'Months remaining';

  @override
  String get takeoverNextPayment => 'Next payment due';

  @override
  String get takeoverInterestType => 'Interest terms';

  @override
  String get takeoverAnnualRate => 'Current annual interest rate (%)';

  @override
  String get takeoverTransferStatus => 'Transfer permission (seller-reported)';

  @override
  String get takeoverTransferFee =>
      'Transfer fee (USD, leave blank if unknown)';

  @override
  String get takeoverFeePayer => 'Who pays the transfer fee?';

  @override
  String get takeoverArrears => 'Overdue amount (USD, enter 0 if none)';

  @override
  String get takeoverArrearsHelp =>
      'Disclose unpaid instalments and penalties. Explain in the notes whether overdue principal is already included in the balance.';

  @override
  String get takeoverArrearsPayer => 'Who settles the overdue amount?';

  @override
  String get takeoverHasAdditional =>
      'Any additional large scheduled payments?';

  @override
  String get takeoverAdditionalAmount => 'Scheduled payment amount (USD)';

  @override
  String get takeoverAdditionalDate => 'Scheduled payment due';

  @override
  String get takeoverAddPayment => 'Add scheduled payment';

  @override
  String get takeoverRemovePayment => 'Remove scheduled payment';

  @override
  String get takeoverAdditionalHelp =>
      'Include handover or balloon payments here. These amounts are already part of the remaining balance.';

  @override
  String get takeoverNotes => 'Payment plan and transfer notes';

  @override
  String get takeoverCombinedPrice =>
      'Combined price before future interest and fees';

  @override
  String get takeoverCombinedHelp =>
      'Seller amount + remaining balance. Future interest, transfer fees and overdue charges may add to the buyer\'s cost.';

  @override
  String get takeoverInvalid =>
      'Complete or correct the highlighted takeover details before publishing.';

  @override
  String get takeoverFieldError => 'Required or invalid value';

  @override
  String get takeoverNotAllowed =>
      'This contract cannot be listed for takeover while transfers are not allowed.';

  @override
  String get takeoverBuyerNotice =>
      'Terms and permission are reported by the seller, not verified by Tilomnov. Confirm the balance, fees and transfer process directly with the developer or bank. Listing a property does not transfer its contract or loan.';

  @override
  String get takeoverDateHint => 'YYYY-MM-DD';

  @override
  String get takeoverProviderDeveloper => 'Developer instalments';

  @override
  String get takeoverProviderBank => 'Bank loan';

  @override
  String get takeoverMonthly => 'Monthly';

  @override
  String get takeoverQuarterly => 'Every 3 months';

  @override
  String get takeoverYearly => 'Yearly';

  @override
  String get takeoverInterestNone => 'Interest-free';

  @override
  String get takeoverInterestFixed => 'Fixed rate';

  @override
  String get takeoverInterestVariable => 'Variable rate';

  @override
  String get takeoverUnknown => 'Unknown / to be confirmed';

  @override
  String get takeoverNotChecked => 'Not yet checked with provider';

  @override
  String get takeoverConditional => 'Allowed subject to provider conditions';

  @override
  String get takeoverWrittenApproval => 'Written permission available';

  @override
  String get takeoverNotPermitted => 'Transfer not allowed';

  @override
  String get takeoverBuyer => 'Buyer';

  @override
  String get takeoverSeller => 'Seller';

  @override
  String get takeoverShared => 'Shared by buyer and seller';

  @override
  String takeoverMonthsValue(int months) {
    return '$months months';
  }

  @override
  String takeoverToSellerValue(String amount) {
    return '$amount to seller';
  }

  @override
  String takeoverPriceLabel(String amount) {
    return '$amount combined';
  }

  @override
  String takeoverPaymentValue(String amount, String frequency) {
    return '$amount · $frequency';
  }

  @override
  String get takeoverBuyerTransferFee => 'Transfer fee';

  @override
  String get takeoverBuyerArrears => 'Overdue payments and penalties';

  @override
  String get adminEmailTitle => 'Check your admin email';

  @override
  String get adminEmailWaiting =>
      'Your password was accepted. Open Gmail and tap Open Tilomnov in the sign-in email to finish signing in. The link expires in 10 minutes.';

  @override
  String get adminEmailVerifying => 'Verifying your sign-in link...';

  @override
  String get adminEmailInvalid =>
      'This sign-in link could not be verified. It may be expired or already used, or the connection failed. Please sign in again to request a new email.';

  @override
  String get adminEmailBack => 'Back to login';

  @override
  String get advertisementLabel => 'Advertisement';

  @override
  String get themeLiquidGlass => 'Liquid Glass';

  @override
  String get themeMinimalistic => 'Minimalistic';

  @override
  String get planAnnualOffer => 'Annual · 2 months free';

  @override
  String get paymentAnnual => '12 months';

  @override
  String get planPerYear => '/ year';

  @override
  String get planExpiryDate => 'Access until';

  @override
  String get planManualRenewal =>
      'One payment only. No automatic renewal. Renew manually at the displayed plan price when this period ends.';

  @override
  String get paymentOneTimeDuration => '30 days · manual renewal';

  @override
  String get authRecoveryEmailOnly =>
      'Use the email linked to your account for recovery. For Google accounts, continue with Google.';

  @override
  String get propertyAddPhone => 'Add another phone number';

  @override
  String get propertyAdditionalPhone => 'Additional phone number';

  @override
  String get propertyRemovePhone => 'Remove phone number';

  @override
  String get searchApproximateArea => 'Approximate search area';

  @override
  String get paymentEstimatedExpiry => 'Estimated expiry';

  @override
  String get paymentRenewalPrice => 'Renewal for another 30 days';
}
