// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get commonOffline =>
      'You are offline. Connect to the internet for updates.';

  @override
  String get navExplore => 'Explore';

  @override
  String get navSaved => 'Saved';

  @override
  String get navChat => 'Chat';

  @override
  String get navMyProperties => 'My Properties';

  @override
  String get navUser => 'User';

  @override
  String get loginRequiredTitle => 'Account Required';

  @override
  String get loginRequiredMessage =>
      'Please log in or sign up to access this feature.';

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
  String get accountSubscriptionFree => 'Free';

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
      'Your username is yours alone and is how people find you. Use 3 to 30 lowercase letters, numbers, \"_\" or \".\".';

  @override
  String get personalInfoUsernameInvalid =>
      'Use 3 to 30 lowercase letters, numbers, \"_\" or \".\".';

  @override
  String get personalInfoUsernameTaken => 'This username is already taken.';

  @override
  String get personalInfoName => 'Name';

  @override
  String get personalInfoNameHelp =>
      'The name other people see. It does not have to be unique, and you can change it any time.';

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
  String get personalInfoPhoneHelp =>
      'Used for signing in and so buyers can reach you.';

  @override
  String get personalInfoPhoneTaken =>
      'This phone number is already used by another account.';

  @override
  String get personalInfoPhoneInvalid =>
      'Enter a phone number of at most 20 characters.';

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
  String get securitySectionEncryption => 'End-to-end encryption';

  @override
  String get securitySectionSignIn => 'Sign-in';

  @override
  String get securitySectionAccount => 'Account';

  @override
  String get securityChangePin => 'Change backup PIN';

  @override
  String get securityResetKeys => 'Reset encryption keys';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityDevices => 'Logged-in devices';

  @override
  String get securityRemoveAccount => 'Deactivate or delete account';

  @override
  String get pinHint => '6-digit PIN';

  @override
  String get pinSubmit => 'Submit';

  @override
  String get pinIncomplete => 'Enter all 6 digits.';

  @override
  String get pinTooGuessable => 'Too easy to guess. Choose another PIN.';

  @override
  String get pinEnterCurrentTitle => 'Enter current PIN';

  @override
  String get pinEnterCurrentHelp =>
      'Enter your current 6-digit PIN to confirm it is you.';

  @override
  String get pinEnterNewTitle => 'Enter new PIN';

  @override
  String get pinEnterNewHelp => 'The new PIN will protect your existing keys.';

  @override
  String get pinForNewKeysTitle => 'PIN for the new keys';

  @override
  String get pinForNewKeysHelp =>
      'This PIN will protect your new keys. You need it to read your chats on another device.';

  @override
  String get pinChanged => 'Backup PIN changed.';

  @override
  String get pinNoBackup =>
      'No backup found. Open Chat first to set up your keys.';

  @override
  String get pinLocked =>
      'Too many wrong PINs. The backup is locked; try again later.';

  @override
  String get pinFetchFailed =>
      'Could not reach the key backup. Check your connection.';

  @override
  String get pinWrong =>
      'Incorrect PIN. After 5 wrong tries the backup locks for a while.';

  @override
  String get pinSaveFailed =>
      'Could not save the new backup. Nothing was changed.';

  @override
  String get resetKeysConfirmTitle => 'Reset encryption keys?';

  @override
  String get resetKeysConfirmMessage =>
      'New keys will be created and you will lose access to all earlier chat history. This cannot be undone.\n\nYou will be asked for your current PIN first.';

  @override
  String get resetKeysConfirmAction => 'Reset keys';

  @override
  String get resetKeysDone => 'Encryption keys reset.';

  @override
  String get resetKeysFailed =>
      'Could not reset the keys. Nothing was changed.';

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
      'After the change, every other device signed in to your account will be signed out.';

  @override
  String get devicesIntro =>
      'These devices are signed in to your account. Sign out any you do not recognise, then change your password.';

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
      'Your profile and listings are hidden and you are signed out everywhere. Nothing is deleted: sign in again to bring it all back.';

  @override
  String get removeAccountDeactivateAction => 'Deactivate account';

  @override
  String get removeAccountDeleteTitle => 'Delete account';

  @override
  String get removeAccountDeleteBody =>
      'Your account, listings, saved properties and chats are permanently deleted. This cannot be undone.';

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
      'You sign in with Google. Confirm with your Google account to continue.';

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
      'Enter your email address to get the password reset link.';

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
  String get authLoginFailedPleaseCheckYourCredentials =>
      'Login failed. Please check your credentials and try again.';

  @override
  String get authSuccessfullyLoggedIn => 'Successfully logged in!';

  @override
  String get authOtpVerification => 'OTP Verification';

  @override
  String get authEnterTheVerificationCodeWeJust =>
      'Enter the verification code we just sent to your email.';

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
      'Enter your new password twice below to reset a new password';

  @override
  String get authEnterNewPassword => 'Enter new password';

  @override
  String get authReEnterNewPassword => 'Re-enter new password';

  @override
  String get authPasswordResetSuccessfullyPleaseLogIn =>
      'Password reset successfully! Please log in with your new password.';

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
  String get authByContinuingYouAgreeToOut =>
      'By continuing, you agree to out ';

  @override
  String get authTermsOfServices => 'terms of services.';

  @override
  String get authEmailAddressOrPhoneNumber => 'Email Address or Phone number';

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
  String get chatThisIsYourOwnAccount => 'This is your own account.';

  @override
  String get chatSignInToChatOrCheck =>
      'Sign in to chat, or check your connection.';

  @override
  String get chatMessagesAreEndToEndEncrypted =>
      'Messages are end-to-end encrypted. Say hello!';

  @override
  String get chatNoChatsYet => 'No chats yet!';

  @override
  String get chatMessageAPropertyOwnerToStart =>
      'Message a property owner to start a conversation.';

  @override
  String get chatCouldNotLoadYourChats => 'Could not load your chats.';

  @override
  String get chatPhotoLibrary => 'Photo library';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatMessage => 'Message';

  @override
  String get chatThisIsNormalIfTheyReinstalled =>
      'This is normal if they reinstalled the app or reset their keys. If you did not expect it, someone may be trying to read your messages: accept the new key, then compare the security code with them before sharing anything private.';

  @override
  String get chatSecurityCode => 'Security code';

  @override
  String get chatAcceptNewKey => 'Accept new key';

  @override
  String get chatAvailableOnceYouHaveBothSet =>
      'Available once you have both set up secure chat.';

  @override
  String get chatTheSecurityCodeIsUnavailable =>
      'The security code is unavailable.';

  @override
  String get homeCoordinates => 'Coordinates';

  @override
  String get homeDraw => 'Draw';

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
      'Please fill both X and Y coordinates for a row, or leave both empty.';

  @override
  String get homeCoordinatesMustBeValidNumbers =>
      'Coordinates must be valid numbers.';

  @override
  String get homePleaseEnterAtLeast3Coordinates =>
      'Please enter at least 3 coordinates to form a property.';

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
      'Use UTM from a land document or enter coordinates manually';

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
      'Tap the heart icon on listings to save them for later.';

  @override
  String get propertySavedProperties => 'Saved Properties';

  @override
  String get propertySortOrder => 'Sort Order';

  @override
  String get propertyAddAtLeast3ClearPhotos =>
      'Add at least 3 clear photos of the property and surrounding area';

  @override
  String get propertyOpenCamera => 'Open camera';

  @override
  String get propertyCallNow => 'Call Now';

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
  String get propertyGenie => 'Genie';

  @override
  String get propertyViews => 'Views';

  @override
  String get propertySaves => 'Saves';

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
  String chatSecurityCodeExplanation(String name) {
    return 'Messages are end-to-end encrypted. To be sure nobody is in between, compare this code with $name in person or on a call: it must be the same on both phones.';
  }

  @override
  String get commonContinue => 'Continue';

  @override
  String get sessionEnded => 'You were signed out of this device.';

  @override
  String get securityForgotPin => 'Forgot backup PIN';

  @override
  String get securityCreatePassword => 'Create password';

  @override
  String get createPasswordIntro =>
      'You sign in with Google, so this account has no password yet. Choose one, then confirm with your Google account. You can keep signing in with Google.';

  @override
  String get createPasswordAction => 'Confirm with Google and create';

  @override
  String get createPasswordDone => 'Password created.';

  @override
  String get forgotPinTitle => 'Forgot your backup PIN?';

  @override
  String get forgotPinKeepsHistory =>
      'This device still has your chat keys, so nothing is lost. Confirm your account password, then choose a new PIN.';

  @override
  String get forgotPinLosesHistory =>
      'This device does not have your chat keys, and without the PIN they cannot be recovered. After you confirm your account password, new keys are created and your earlier chat history can no longer be read. This cannot be undone.\n\nIf another of your devices can still open your chats, do this there instead to keep your history.';

  @override
  String get forgotPinNeedsPassword =>
      'Recovering your PIN needs your account password. You sign in with Google, so create a password first.';

  @override
  String get forgotPinPasswordTitle => 'Confirm your password';

  @override
  String get forgotPinNewPinHelp =>
      'This new PIN will protect your chat keys from now on.';

  @override
  String get forgotPinDone =>
      'New backup PIN set. Your chat history is intact.';

  @override
  String get forgotPinProofExpired =>
      'That took too long. Please confirm your password again.';

  @override
  String get pinForgotHint =>
      'Forgot your PIN? Go to User > Security > Forgot backup PIN.';

  @override
  String get chatPinNeeded =>
      'Your backup PIN is needed to read and send messages.';

  @override
  String get chatOpenFailed =>
      'Could not open this chat. Check your connection.';

  @override
  String get devicesImmediateNote =>
      'A device you sign out is signed out immediately.';

  @override
  String get devicesTooNew =>
      'This device signed in less than a day ago, so it cannot sign other devices out yet. Use a device you have been signed in on for longer.';

  @override
  String devicesTooNewUntil(String when) {
    return 'For your protection, a device can sign other devices out only after it has been signed in for a day. This device can from $when. Until then, use a device you have been signed in on for longer.';
  }

  @override
  String get newSignInTitle => 'New sign-in to your account';

  @override
  String get newSignInMessage =>
      'Another device signed in to your account. If this was not you, sign it out now and change your password.';

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
}
