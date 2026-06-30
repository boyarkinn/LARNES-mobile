import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LARNES'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Phone, email or username and password'**
  String get loginSubtitle;

  /// No description provided for @loginFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone, email or username'**
  String get loginFieldLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Password reset — coming soon'**
  String get forgotPasswordComingSoon;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Register'**
  String get noAccountRegister;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Try again later.'**
  String get loginFailed;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose account type'**
  String get registerSubtitle;

  /// No description provided for @accountTypeParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get accountTypeParent;

  /// No description provided for @accountTypeTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get accountTypeTeacher;

  /// No description provided for @accountTypeNetworkOwner.
  ///
  /// In en, this message translates to:
  /// **'Network owner'**
  String get accountTypeNetworkOwner;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @registerStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3 — contact verification'**
  String get registerStep1Subtitle;

  /// No description provided for @phoneChannel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneChannel;

  /// No description provided for @emailChannel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailChannel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @getCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get getCodeButton;

  /// No description provided for @enterContact.
  ///
  /// In en, this message translates to:
  /// **'Enter contact'**
  String get enterContact;

  /// No description provided for @confirmNotRobot.
  ///
  /// In en, this message translates to:
  /// **'Confirm you are not a robot'**
  String get confirmNotRobot;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {contact}'**
  String otpSentTo(String contact);

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String resendCooldown(int seconds);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'Code sent again'**
  String get codeResent;

  /// No description provided for @verifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify code.'**
  String get verifyCodeFailed;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resend code.'**
  String get resendFailed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @registerStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 — {accountType}'**
  String registerStep3Subtitle(String accountType);

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @verifyContactFirst.
  ///
  /// In en, this message translates to:
  /// **'Verify your contact with a code first'**
  String get verifyContactFirst;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create account.'**
  String get createAccountFailed;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @patronymicLabel.
  ///
  /// In en, this message translates to:
  /// **'Patronymic'**
  String get patronymicLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirthLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @networkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Network name'**
  String get networkNameLabel;

  /// No description provided for @repeatPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPasswordLabel;

  /// No description provided for @loggedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in'**
  String get loggedInTitle;

  /// No description provided for @nameValue.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String nameValue(String name);

  /// No description provided for @roleValue.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleValue(String role);

  /// No description provided for @homePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Role dashboard (parent / teacher / network) will appear here.'**
  String get homePlaceholder;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutButton;

  /// No description provided for @emptyValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get emptyValue;

  /// No description provided for @turnstileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verification passed'**
  String get turnstileVerified;

  /// No description provided for @turnstileCanContinue.
  ///
  /// In en, this message translates to:
  /// **'You can continue registration'**
  String get turnstileCanContinue;

  /// No description provided for @turnstileBotProtection.
  ///
  /// In en, this message translates to:
  /// **'Bot protection'**
  String get turnstileBotProtection;

  /// No description provided for @turnstilePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get turnstilePreparing;

  /// No description provided for @turnstileVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get turnstileVerifying;

  /// No description provided for @turnstileTapToVerify.
  ///
  /// In en, this message translates to:
  /// **'Tap to verify'**
  String get turnstileTapToVerify;

  /// No description provided for @turnstileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load verification'**
  String get turnstileLoadFailed;

  /// No description provided for @turnstileLoadFailedPull.
  ///
  /// In en, this message translates to:
  /// **'Could not load verification. Pull down and try again.'**
  String get turnstileLoadFailedPull;

  /// No description provided for @turnstileExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification expired. Tap again.'**
  String get turnstileExpired;

  /// No description provided for @turnstileLoadFailedTap.
  ///
  /// In en, this message translates to:
  /// **'Could not load verification. Tap again.'**
  String get turnstileLoadFailedTap;

  /// No description provided for @turnstileFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Tap again.'**
  String get turnstileFailed;

  /// No description provided for @turnstileStillLoading.
  ///
  /// In en, this message translates to:
  /// **'Verification is still loading. Wait a few seconds.'**
  String get turnstileStillLoading;

  /// No description provided for @turnstileStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start verification'**
  String get turnstileStartFailed;

  /// No description provided for @turnstileNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Verification did not complete. Tap again.'**
  String get turnstileNotCompleted;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No server connection. Check your internet.'**
  String get noConnection;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get requestFailed;

  /// No description provided for @requestError.
  ///
  /// In en, this message translates to:
  /// **'Request error.'**
  String get requestError;

  /// No description provided for @sendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send code.'**
  String get sendCodeFailed;

  /// No description provided for @verifyContactFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify contact.'**
  String get verifyContactFailed;

  /// No description provided for @tokenFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get token.'**
  String get tokenFetchFailed;

  /// No description provided for @parentChildPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is studying today?'**
  String get parentChildPickerTitle;

  /// No description provided for @parentAddChild.
  ///
  /// In en, this message translates to:
  /// **'Add a child'**
  String get parentAddChild;

  /// No description provided for @parentAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get parentAccount;

  /// No description provided for @parentBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get parentBack;

  /// No description provided for @parentStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'What are we studying today?'**
  String get parentStudyTitle;

  /// No description provided for @parentHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get parentHomeworkTitle;

  /// No description provided for @parentHomeworkEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet'**
  String get parentHomeworkEmptyHint;

  /// No description provided for @parentHomeworkAssignmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 assignment} other{{count} assignments}}'**
  String parentHomeworkAssignmentCount(int count);

  /// No description provided for @parentChildFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New child profile'**
  String get parentChildFormTitle;

  /// No description provided for @parentChildFormLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get parentChildFormLastName;

  /// No description provided for @parentChildFormFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get parentChildFormFirstName;

  /// No description provided for @parentChildFormPatronymic.
  ///
  /// In en, this message translates to:
  /// **'Patronymic (optional)'**
  String get parentChildFormPatronymic;

  /// No description provided for @parentChildFormDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get parentChildFormDateOfBirth;

  /// No description provided for @parentChildFormGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get parentChildFormGender;

  /// No description provided for @parentChildFormGenderMale.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get parentChildFormGenderMale;

  /// No description provided for @parentChildFormGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get parentChildFormGenderFemale;

  /// No description provided for @parentChildFormGenderRequired.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get parentChildFormGenderRequired;

  /// No description provided for @parentChildFormSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get parentChildFormSubmit;

  /// No description provided for @parentLoadChildrenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load children.'**
  String get parentLoadChildrenFailed;

  /// No description provided for @parentCreateChildFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create profile.'**
  String get parentCreateChildFailed;

  /// No description provided for @parentHomeworkSoon.
  ///
  /// In en, this message translates to:
  /// **'Homework list — coming in the next step.'**
  String get parentHomeworkSoon;

  /// No description provided for @parentAccountSoon.
  ///
  /// In en, this message translates to:
  /// **'Account settings — coming soon.'**
  String get parentAccountSoon;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
