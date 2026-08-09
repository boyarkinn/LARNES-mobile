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

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get passwordResetTitle;

  /// No description provided for @passwordResetStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3 — contact'**
  String get passwordResetStep1Subtitle;

  /// No description provided for @passwordResetStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3 — verification code'**
  String get passwordResetStep2Subtitle;

  /// No description provided for @passwordResetStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 — new password'**
  String get passwordResetStep3Subtitle;

  /// No description provided for @passwordResetContactHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone or email linked to your account. We will send a verification code.'**
  String get passwordResetContactHint;

  /// No description provided for @passwordResetContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get passwordResetContactLabel;

  /// No description provided for @passwordResetOtpHintSms.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {contact}. Enter it below.'**
  String passwordResetOtpHintSms(String contact);

  /// No description provided for @passwordResetOtpHintEmail.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {contact}. Check your inbox (and spam folder) and enter it below.'**
  String passwordResetOtpHintEmail(String contact);

  /// No description provided for @passwordResetOtpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent.'**
  String get passwordResetOtpResent;

  /// No description provided for @passwordResetOtpNotReceivedHint.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code? Check that the contact is correct — your account may be linked to a different phone or email.'**
  String get passwordResetOtpNotReceivedHint;

  /// No description provided for @passwordResetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password. After saving you will be signed in automatically and other sessions will end.'**
  String get passwordResetPasswordHint;

  /// No description provided for @passwordResetNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordResetNewPasswordLabel;

  /// No description provided for @passwordResetConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get passwordResetConfirmPasswordLabel;

  /// No description provided for @passwordResetSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save and sign in'**
  String get passwordResetSubmit;

  /// No description provided for @passwordResetBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'← Back to sign in'**
  String get passwordResetBackToLogin;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset password.'**
  String get passwordResetFailed;

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

  /// No description provided for @registerTypeParentHint.
  ///
  /// In en, this message translates to:
  /// **'For your child\'s home learning'**
  String get registerTypeParentHint;

  /// No description provided for @registerTypeTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'For tutors and instructors'**
  String get registerTypeTeacherHint;

  /// No description provided for @registerTypeNetworkOwnerHint.
  ///
  /// In en, this message translates to:
  /// **'For schools and learning centers'**
  String get registerTypeNetworkOwnerHint;

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

  /// No description provided for @registerParentRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role in the family'**
  String get registerParentRelationshipLabel;

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

  /// No description provided for @dateOfBirthPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD.MM.YYYY'**
  String get dateOfBirthPlaceholder;

  /// No description provided for @invalidDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date of birth'**
  String get invalidDateOfBirth;

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

  /// No description provided for @parentStudyProfileCard.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get parentStudyProfileCard;

  /// No description provided for @parentStudyCoursesCard.
  ///
  /// In en, this message translates to:
  /// **'LARNES courses'**
  String get parentStudyCoursesCard;

  /// No description provided for @parentCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get parentCoursesTitle;

  /// No description provided for @parentCoursesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published courses yet.'**
  String get parentCoursesEmpty;

  /// No description provided for @parentActivityAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get parentActivityAttendance;

  /// No description provided for @parentActivitySchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get parentActivitySchedule;

  /// No description provided for @parentActivityScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lessons on this day.'**
  String get parentActivityScheduleEmpty;

  /// No description provided for @parentActivitySchedulePrevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get parentActivitySchedulePrevDay;

  /// No description provided for @parentActivityScheduleNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get parentActivityScheduleNextDay;

  /// No description provided for @parentActivityScheduleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Schedule is not available for this day.'**
  String get parentActivityScheduleNotFound;

  /// No description provided for @parentActivityPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get parentActivityPayments;

  /// No description provided for @parentActivityPaymentsTabAccruals.
  ///
  /// In en, this message translates to:
  /// **'Accruals'**
  String get parentActivityPaymentsTabAccruals;

  /// No description provided for @parentActivityPaymentsTabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get parentActivityPaymentsTabReceipts;

  /// No description provided for @parentActivityPaymentsTabsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment mode'**
  String get parentActivityPaymentsTabsLabel;

  /// No description provided for @parentActivityPaymentsEmptyAccruals.
  ///
  /// In en, this message translates to:
  /// **'No accruals yet.'**
  String get parentActivityPaymentsEmptyAccruals;

  /// No description provided for @parentActivityPaymentsEmptyReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet.'**
  String get parentActivityPaymentsEmptyReceipts;

  /// No description provided for @parentActivityPaymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get parentActivityPaymentReceiptTitle;

  /// No description provided for @parentActivityPaymentReceiptAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get parentActivityPaymentReceiptAccepted;

  /// No description provided for @parentActivityPaymentReceiptGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get parentActivityPaymentReceiptGift;

  /// No description provided for @parentActivityPaymentReceiptRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund for missed lessons'**
  String get parentActivityPaymentReceiptRefund;

  /// No description provided for @parentActivityPaymentReceiptTotalOnAccount.
  ///
  /// In en, this message translates to:
  /// **'Total on account'**
  String get parentActivityPaymentReceiptTotalOnAccount;

  /// No description provided for @parentActivityPaymentAccrualTitle.
  ///
  /// In en, this message translates to:
  /// **'Accrual'**
  String get parentActivityPaymentAccrualTitle;

  /// No description provided for @parentActivityPaymentAccrualHeadSuffix.
  ///
  /// In en, this message translates to:
  /// **'allocated to:'**
  String get parentActivityPaymentAccrualHeadSuffix;

  /// No description provided for @parentActivityPaymentAccrualColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get parentActivityPaymentAccrualColAmount;

  /// No description provided for @parentActivityPaymentAccrualColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get parentActivityPaymentAccrualColDate;

  /// No description provided for @parentActivityPaymentAccrualColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get parentActivityPaymentAccrualColTime;

  /// No description provided for @parentActivityPaymentAccrualColCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get parentActivityPaymentAccrualColCenter;

  /// No description provided for @parentActivityPaymentAccrualColClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get parentActivityPaymentAccrualColClass;

  /// No description provided for @parentActivityPaymentDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payment details are not available.'**
  String get parentActivityPaymentDetailNotFound;

  /// No description provided for @parentActivityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section is coming soon in the app.'**
  String get parentActivityComingSoon;

  /// No description provided for @parentActivityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity diary.'**
  String get parentActivityLoadFailed;

  /// No description provided for @parentActivityPlaceSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get parentActivityPlaceSummary;

  /// No description provided for @parentActivityPlaceDockLabel.
  ///
  /// In en, this message translates to:
  /// **'Place filter'**
  String get parentActivityPlaceDockLabel;

  /// No description provided for @parentActivityAttendanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No classes in the selected place yet.'**
  String get parentActivityAttendanceEmpty;

  /// No description provided for @parentActivityCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'“{name}”'**
  String parentActivityCalendarTitle(Object name);

  /// No description provided for @parentActivityCalendarNotFound.
  ///
  /// In en, this message translates to:
  /// **'Calendar is not available for this class.'**
  String get parentActivityCalendarNotFound;

  /// No description provided for @parentActivityCalendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get parentActivityCalendarPrevMonth;

  /// No description provided for @parentActivityCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get parentActivityCalendarNextMonth;

  /// No description provided for @parentActivityCalendarLegendPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get parentActivityCalendarLegendPaid;

  /// No description provided for @parentActivityCalendarLegendFirstUnpaid.
  ///
  /// In en, this message translates to:
  /// **'First unpaid'**
  String get parentActivityCalendarLegendFirstUnpaid;

  /// No description provided for @parentActivityCalendarLegendUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get parentActivityCalendarLegendUnpaid;

  /// No description provided for @parentActivityCalendarLegendMakeup.
  ///
  /// In en, this message translates to:
  /// **'Make-up'**
  String get parentActivityCalendarLegendMakeup;

  /// No description provided for @parentActivityCalendarCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance codes'**
  String get parentActivityCalendarCodesTitle;

  /// No description provided for @parentActivityCalendarCodePresent.
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get parentActivityCalendarCodePresent;

  /// No description provided for @parentActivityCalendarCodeAbsent.
  ///
  /// In en, this message translates to:
  /// **'absent'**
  String get parentActivityCalendarCodeAbsent;

  /// No description provided for @parentActivityCalendarCodeSick.
  ///
  /// In en, this message translates to:
  /// **'sick'**
  String get parentActivityCalendarCodeSick;

  /// No description provided for @parentActivityCalendarCodeExcused.
  ///
  /// In en, this message translates to:
  /// **'excused'**
  String get parentActivityCalendarCodeExcused;

  /// No description provided for @parentActivityCalendarCodeAdvanceNotice.
  ///
  /// In en, this message translates to:
  /// **'advance notice'**
  String get parentActivityCalendarCodeAdvanceNotice;

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

  /// No description provided for @parentChildFormCardColor.
  ///
  /// In en, this message translates to:
  /// **'Favorite color'**
  String get parentChildFormCardColor;

  /// No description provided for @parentChildFormAvatar.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get parentChildFormAvatar;

  /// No description provided for @parentChildFormCardColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get parentChildFormCardColorOrange;

  /// No description provided for @parentChildFormCardColorEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get parentChildFormCardColorEmerald;

  /// No description provided for @parentChildFormCardColorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get parentChildFormCardColorViolet;

  /// No description provided for @parentChildFormCardColorSky.
  ///
  /// In en, this message translates to:
  /// **'Sky blue'**
  String get parentChildFormCardColorSky;

  /// No description provided for @parentChildFormCardColorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get parentChildFormCardColorRose;

  /// No description provided for @parentChildFormCardColorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get parentChildFormCardColorAmber;

  /// No description provided for @parentChildFormAvatarFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get parentChildFormAvatarFox;

  /// No description provided for @parentChildFormAvatarBear.
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get parentChildFormAvatarBear;

  /// No description provided for @parentChildFormAvatarOwl.
  ///
  /// In en, this message translates to:
  /// **'Owl'**
  String get parentChildFormAvatarOwl;

  /// No description provided for @parentChildLegalBasisLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal authority basis'**
  String get parentChildLegalBasisLabel;

  /// No description provided for @parentChildLegalBasisParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentChildLegalBasisParent;

  /// No description provided for @parentChildLegalBasisAdoptiveParent.
  ///
  /// In en, this message translates to:
  /// **'Adoptive parent'**
  String get parentChildLegalBasisAdoptiveParent;

  /// No description provided for @parentChildLegalBasisGuardian.
  ///
  /// In en, this message translates to:
  /// **'Appointed guardian'**
  String get parentChildLegalBasisGuardian;

  /// No description provided for @parentChildLegalAuthority.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I am the selected legal representative of this child, my authority has not ended or been restricted, and no conflict of interest has been established. I will notify LARNES if my authority changes.'**
  String get parentChildLegalAuthority;

  /// No description provided for @parentChildLegalConsent.
  ///
  /// In en, this message translates to:
  /// **'I consent to the processing of this child\'s personal data.'**
  String get parentChildLegalConsent;

  /// No description provided for @parentChildLegalDocumentLink.
  ///
  /// In en, this message translates to:
  /// **'Child Data Processing Consent'**
  String get parentChildLegalDocumentLink;

  /// No description provided for @parentChildLegalRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your authority and accept the child data consent.'**
  String get parentChildLegalRequired;

  /// No description provided for @parentChildFormSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get parentChildFormSubmit;

  /// No description provided for @parentChildFormAutosaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get parentChildFormAutosaveSaved;

  /// No description provided for @parentChildFormAutosaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get parentChildFormAutosaveFailed;

  /// No description provided for @parentClassroomQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Classroom QR'**
  String get parentClassroomQrTitle;

  /// No description provided for @parentClassroomQrAlt.
  ///
  /// In en, this message translates to:
  /// **'Child classroom QR code'**
  String get parentClassroomQrAlt;

  /// No description provided for @parentClassroomQrVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String parentClassroomQrVersion(int version);

  /// No description provided for @parentClassroomQrPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get parentClassroomQrPrint;

  /// No description provided for @parentClassroomQrRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Reissue'**
  String get parentClassroomQrRegenerate;

  /// No description provided for @parentClassroomQrRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get parentClassroomQrRevoke;

  /// No description provided for @parentClassroomQrIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue QR'**
  String get parentClassroomQrIssue;

  /// No description provided for @parentClassroomQrRevokedHint.
  ///
  /// In en, this message translates to:
  /// **'QR revoked. Printed cards no longer work.'**
  String get parentClassroomQrRevokedHint;

  /// No description provided for @parentClassroomQrCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parentClassroomQrCancel;

  /// No description provided for @parentClassroomQrConfirmRegenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reissue QR?'**
  String get parentClassroomQrConfirmRegenerateTitle;

  /// No description provided for @parentClassroomQrConfirmRegenerateMessage.
  ///
  /// In en, this message translates to:
  /// **'The old QR will stop working. You will need to print a new one.'**
  String get parentClassroomQrConfirmRegenerateMessage;

  /// No description provided for @parentClassroomQrConfirmRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke QR?'**
  String get parentClassroomQrConfirmRevokeTitle;

  /// No description provided for @parentClassroomQrConfirmRevokeMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign-in with the current QR will be blocked until you issue a new one.'**
  String get parentClassroomQrConfirmRevokeMessage;

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

  /// No description provided for @parentHomeworkLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load homework.'**
  String get parentHomeworkLoadFailed;

  /// No description provided for @parentHomeworkListTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework — {name}'**
  String parentHomeworkListTitle(String name);

  /// No description provided for @parentHomeworkBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get parentHomeworkBack;

  /// No description provided for @parentHomeworkSentAt.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get parentHomeworkSentAt;

  /// No description provided for @parentHomeworkDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get parentHomeworkDeadline;

  /// No description provided for @parentHomeworkNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get parentHomeworkNoDeadline;

  /// No description provided for @parentHomeworkProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get parentHomeworkProgress;

  /// No description provided for @parentHomeworkProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String parentHomeworkProgressValue(int current, int total);

  /// No description provided for @parentHomeworkPlaySoon.
  ///
  /// In en, this message translates to:
  /// **'Assignment player — coming in the next step.'**
  String get parentHomeworkPlaySoon;

  /// No description provided for @parentHomeworkPlayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load assignment.'**
  String get parentHomeworkPlayLoadFailed;

  /// No description provided for @parentHomeworkPlayAdvanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save progress.'**
  String get parentHomeworkPlayAdvanceFailed;

  /// No description provided for @parentHomeworkPlayProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String parentHomeworkPlayProgress(int current, int total);

  /// No description provided for @parentHomeworkPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get parentHomeworkPlayNext;

  /// No description provided for @parentHomeworkPlayFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get parentHomeworkPlayFinish;

  /// No description provided for @parentHomeworkPlayCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework completed'**
  String get parentHomeworkPlayCompletedTitle;

  /// No description provided for @parentHomeworkPlayBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to homework list'**
  String get parentHomeworkPlayBackToList;

  /// No description provided for @parentHomeworkPlayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get parentHomeworkPlayExit;

  /// No description provided for @parentHomeworkPlayMenuContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue lesson'**
  String get parentHomeworkPlayMenuContinue;

  /// No description provided for @parentHomeworkPlayEmpty.
  ///
  /// In en, this message translates to:
  /// **'This assignment has no trainers yet.'**
  String get parentHomeworkPlayEmpty;

  /// No description provided for @parentHomeworkPlayStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String parentHomeworkPlayStepLabel(int step);

  /// No description provided for @parentHomeworkPlayTrainerSoon.
  ///
  /// In en, this message translates to:
  /// **'Trainer — coming in the next update.'**
  String get parentHomeworkPlayTrainerSoon;

  /// No description provided for @parentHomeworkPlayInteractiveHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the task on screen'**
  String get parentHomeworkPlayInteractiveHint;

  /// No description provided for @parentHomeworkEmptyDue.
  ///
  /// In en, this message translates to:
  /// **'No assignments to do right now.'**
  String get parentHomeworkEmptyDue;

  /// No description provided for @parentHomeworkEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed assignments yet.'**
  String get parentHomeworkEmptyCompleted;

  /// No description provided for @parentHomeworkEmptyOverdue.
  ///
  /// In en, this message translates to:
  /// **'No overdue assignments.'**
  String get parentHomeworkEmptyOverdue;

  /// No description provided for @parentHomeworkEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming assignments.'**
  String get parentHomeworkEmptyUpcoming;

  /// No description provided for @parentHomeworkTabDue.
  ///
  /// In en, this message translates to:
  /// **'Due ({count})'**
  String parentHomeworkTabDue(int count);

  /// No description provided for @parentHomeworkTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String parentHomeworkTabCompleted(int count);

  /// No description provided for @parentHomeworkTabOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue ({count})'**
  String parentHomeworkTabOverdue(int count);

  /// No description provided for @parentHomeworkTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String parentHomeworkTabUpcoming(int count);

  /// No description provided for @parentHomeworkStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get parentHomeworkStatusAssigned;

  /// No description provided for @parentHomeworkStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get parentHomeworkStatusInProgress;

  /// No description provided for @parentHomeworkStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get parentHomeworkStatusCompleted;

  /// No description provided for @parentHomeworkStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get parentHomeworkStatusOverdue;

  /// No description provided for @parentAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get parentAccountTitle;

  /// No description provided for @adminNavTrainers.
  ///
  /// In en, this message translates to:
  /// **'Trainers'**
  String get adminNavTrainers;

  /// No description provided for @adminNavAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminNavAccount;

  /// No description provided for @adminTrainersTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainers'**
  String get adminTrainersTitle;

  /// No description provided for @adminTrainersHint.
  ///
  /// In en, this message translates to:
  /// **'Catalog for manual trainer checks before programs and homework.'**
  String get adminTrainersHint;

  /// No description provided for @adminTrainersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load catalog.'**
  String get adminTrainersLoadFailed;

  /// No description provided for @adminTrainersOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminTrainersOpen;

  /// No description provided for @adminTrainersDirectionMental.
  ///
  /// In en, this message translates to:
  /// **'Mental arithmetic'**
  String get adminTrainersDirectionMental;

  /// No description provided for @adminTrainersDirectionMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get adminTrainersDirectionMath;

  /// No description provided for @adminTrainersDirectionReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get adminTrainersDirectionReading;

  /// No description provided for @adminTrainersPlatformWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get adminTrainersPlatformWeb;

  /// No description provided for @adminTrainersPlatformMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get adminTrainersPlatformMobile;

  /// No description provided for @adminTrainersStatusInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'In development'**
  String get adminTrainersStatusInDevelopment;

  /// No description provided for @adminTrainersStatusReadyForRelease.
  ///
  /// In en, this message translates to:
  /// **'Ready for release'**
  String get adminTrainersStatusReadyForRelease;

  /// No description provided for @adminTrainersGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# trainer} other{# trainers}}'**
  String adminTrainersGroupCount(int count);

  /// No description provided for @adminTrainersCatalogInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# in progress} other{# in progress}}'**
  String adminTrainersCatalogInProgress(int count);

  /// No description provided for @adminTrainersDetailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Trainer screen (Play and Workflow) will appear in the next phases.'**
  String get adminTrainersDetailPlaceholder;

  /// No description provided for @adminTrainerWorkflowTabWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get adminTrainerWorkflowTabWorkflow;

  /// No description provided for @adminTrainerWorkflowTabPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get adminTrainerWorkflowTabPlay;

  /// No description provided for @adminTrainerWorkflowPlayPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Trainer play mode will appear in the next phase.'**
  String get adminTrainerWorkflowPlayPlaceholder;

  /// No description provided for @adminTrainerWorkflowLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load trainer.'**
  String get adminTrainerWorkflowLoadFailed;

  /// No description provided for @adminTrainerWorkflowSectionFunnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get adminTrainerWorkflowSectionFunnel;

  /// No description provided for @adminTrainerWorkflowSectionTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get adminTrainerWorkflowSectionTeam;

  /// No description provided for @adminTrainerWorkflowSectionFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get adminTrainerWorkflowSectionFeed;

  /// No description provided for @adminTrainerWorkflowInProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# comment in progress} other{# comments in progress}}'**
  String adminTrainerWorkflowInProgressCount(int count);

  /// No description provided for @adminTrainerWorkflowFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get adminTrainerWorkflowFeedEmpty;

  /// No description provided for @adminTrainerWorkflowCommentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get adminTrainerWorkflowCommentAddTitle;

  /// No description provided for @adminTrainerWorkflowCommentBodyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe an issue or task'**
  String get adminTrainerWorkflowCommentBodyPlaceholder;

  /// No description provided for @adminTrainerWorkflowCommentAddSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminTrainerWorkflowCommentAddSubmit;

  /// No description provided for @adminTrainerWorkflowCommentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get adminTrainerWorkflowCommentStatusInProgress;

  /// No description provided for @adminTrainerWorkflowCommentStatusImplemented.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminTrainerWorkflowCommentStatusImplemented;

  /// No description provided for @adminTrainerWorkflowCommentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminTrainerWorkflowCommentStatusRejected;

  /// No description provided for @adminTrainerWorkflowCommentActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get adminTrainerWorkflowCommentActionInProgress;

  /// No description provided for @adminTrainerWorkflowCommentActionImplemented.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminTrainerWorkflowCommentActionImplemented;

  /// No description provided for @adminTrainerWorkflowCommentActionRejected.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminTrainerWorkflowCommentActionRejected;

  /// No description provided for @adminTrainerWorkflowSignoffStatusUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminTrainerWorkflowSignoffStatusUnset;

  /// No description provided for @adminTrainerWorkflowSignoffStatusNeedsFixes.
  ///
  /// In en, this message translates to:
  /// **'Needs fixes'**
  String get adminTrainerWorkflowSignoffStatusNeedsFixes;

  /// No description provided for @adminTrainerWorkflowSignoffStatusReadyForRelease.
  ///
  /// In en, this message translates to:
  /// **'Ready for release'**
  String get adminTrainerWorkflowSignoffStatusReadyForRelease;

  /// No description provided for @adminTrainerWorkflowSignoffActionNeedsFixes.
  ///
  /// In en, this message translates to:
  /// **'Needs fixes'**
  String get adminTrainerWorkflowSignoffActionNeedsFixes;

  /// No description provided for @adminTrainerWorkflowSignoffActionReadyForRelease.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get adminTrainerWorkflowSignoffActionReadyForRelease;

  /// No description provided for @adminTrainerPlayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load parameters.'**
  String get adminTrainerPlayLoadFailed;

  /// No description provided for @adminTrainerPlayLaunch.
  ///
  /// In en, this message translates to:
  /// **'LAUNCH'**
  String get adminTrainerPlayLaunch;

  /// No description provided for @adminTrainerPlayInteractiveHint.
  ///
  /// In en, this message translates to:
  /// **'Interactive trainers finish when the child completes the task.'**
  String get adminTrainerPlayInteractiveHint;

  /// No description provided for @adminTrainerPlayLetterCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Letter case'**
  String get adminTrainerPlayLetterCaseLabel;

  /// No description provided for @adminTrainerPlayWordCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Word case'**
  String get adminTrainerPlayWordCaseLabel;

  /// No description provided for @adminTrainerPlayLetterLabel.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get adminTrainerPlayLetterLabel;

  /// No description provided for @adminTrainerPlayPracticeLettersLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice letters'**
  String get adminTrainerPlayPracticeLettersLabel;

  /// No description provided for @adminTrainerPlayShopItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get adminTrainerPlayShopItemLabel;

  /// No description provided for @adminTrainerPlayPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get adminTrainerPlayPriceLabel;

  /// No description provided for @adminTrainerPlayCoinCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Coins in register'**
  String get adminTrainerPlayCoinCountLabel;

  /// No description provided for @adminTrainerPlayWholeLabel.
  ///
  /// In en, this message translates to:
  /// **'Whole'**
  String get adminTrainerPlayWholeLabel;

  /// No description provided for @adminTrainerPlayKnownPartLabel.
  ///
  /// In en, this message translates to:
  /// **'Known part'**
  String get adminTrainerPlayKnownPartLabel;

  /// No description provided for @adminTrainerPlayAnswerRangeStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer range start'**
  String get adminTrainerPlayAnswerRangeStartLabel;

  /// No description provided for @adminTrainerPlayTargetFruitLabel.
  ///
  /// In en, this message translates to:
  /// **'Target fruit'**
  String get adminTrainerPlayTargetFruitLabel;

  /// No description provided for @adminTrainerPlayFruitTargetCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target count'**
  String get adminTrainerPlayFruitTargetCountLabel;

  /// No description provided for @adminTrainerPlayFruitTypeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Fruit types'**
  String get adminTrainerPlayFruitTypeCountLabel;

  /// No description provided for @adminTrainerPlayTotalFruitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total fruits'**
  String get adminTrainerPlayTotalFruitsLabel;

  /// No description provided for @adminTrainerPlayDigitLabel.
  ///
  /// In en, this message translates to:
  /// **'Digit'**
  String get adminTrainerPlayDigitLabel;

  /// No description provided for @adminTrainerPlayTargetCountLabel.
  ///
  /// In en, this message translates to:
  /// **'How many to find'**
  String get adminTrainerPlayTargetCountLabel;

  /// No description provided for @adminTrainerPlayDistractorCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Distractors'**
  String get adminTrainerPlayDistractorCountLabel;

  /// No description provided for @adminTrainerPlayMissingSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing segment'**
  String get adminTrainerPlayMissingSegmentLabel;

  /// No description provided for @adminTrainerPlayLetterCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Letter count'**
  String get adminTrainerPlayLetterCountLabel;

  /// No description provided for @adminTrainerPlayOddLetterLabel.
  ///
  /// In en, this message translates to:
  /// **'Odd letter (random or letter)'**
  String get adminTrainerPlayOddLetterLabel;

  /// No description provided for @adminTrainerPlayOptionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Option count'**
  String get adminTrainerPlayOptionCountLabel;

  /// No description provided for @adminTrainerPlayDotModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dot mode'**
  String get adminTrainerPlayDotModeLabel;

  /// No description provided for @adminTrainerPlayRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get adminTrainerPlayRoundsLabel;

  /// No description provided for @adminTrainerPlayDisplaySecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Display seconds'**
  String get adminTrainerPlayDisplaySecondsLabel;

  /// No description provided for @adminTrainerPlayGridSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grid size'**
  String get adminTrainerPlayGridSizeLabel;

  /// No description provided for @adminTrainerPlayFilledCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Filled cells'**
  String get adminTrainerPlayFilledCountLabel;

  /// No description provided for @adminTrainerPlayWordSlugLabel.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get adminTrainerPlayWordSlugLabel;

  /// No description provided for @adminTrainerPlayEntityCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Word count'**
  String get adminTrainerPlayEntityCountLabel;

  /// No description provided for @adminTrainerPlayPairCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get adminTrainerPlayPairCountLabel;

  /// No description provided for @adminTrainerPlayCatchCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Catch count'**
  String get adminTrainerPlayCatchCountLabel;

  /// No description provided for @adminTrainerPlaySpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get adminTrainerPlaySpeedLabel;

  /// No description provided for @adminTrainerPlayWordItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Words in task'**
  String get adminTrainerPlayWordItemCountLabel;

  /// No description provided for @adminTrainerPlayTotalRodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rods'**
  String get adminTrainerPlayTotalRodsLabel;

  /// No description provided for @adminTrainerPlayStepPauseSecLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause (sec)'**
  String get adminTrainerPlayStepPauseSecLabel;

  /// No description provided for @adminTrainerPlayExampleStringLabel.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get adminTrainerPlayExampleStringLabel;

  /// No description provided for @adminTrainerPlayChainTopicIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain topic'**
  String get adminTrainerPlayChainTopicIdLabel;

  /// No description provided for @adminTrainerPlayActionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of actions'**
  String get adminTrainerPlayActionCountLabel;

  /// No description provided for @adminTrainerPlayExampleCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of examples'**
  String get adminTrainerPlayExampleCountLabel;

  /// No description provided for @adminTrainerPlaySignModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Signs'**
  String get adminTrainerPlaySignModeLabel;

  /// No description provided for @adminTrainerPlayAmountScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Operands'**
  String get adminTrainerPlayAmountScopeLabel;

  /// No description provided for @adminTrainerPlayValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get adminTrainerPlayValueLabel;

  /// No description provided for @adminTrainerPlayMatchValue1Label.
  ///
  /// In en, this message translates to:
  /// **'Value 1'**
  String get adminTrainerPlayMatchValue1Label;

  /// No description provided for @adminTrainerPlayMatchValue2Label.
  ///
  /// In en, this message translates to:
  /// **'Value 2'**
  String get adminTrainerPlayMatchValue2Label;

  /// No description provided for @adminTrainerPlayMatchValue3Label.
  ///
  /// In en, this message translates to:
  /// **'Value 3'**
  String get adminTrainerPlayMatchValue3Label;

  /// No description provided for @adminTrainerPlayMatchValue4Label.
  ///
  /// In en, this message translates to:
  /// **'Value 4'**
  String get adminTrainerPlayMatchValue4Label;

  /// No description provided for @adminTrainerPlayLetterCaseUpper.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get adminTrainerPlayLetterCaseUpper;

  /// No description provided for @adminTrainerPlayLetterCaseLower.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get adminTrainerPlayLetterCaseLower;

  /// No description provided for @adminTrainerPlayMissingSegmentRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get adminTrainerPlayMissingSegmentRandom;

  /// No description provided for @adminTrainerPlayMissingSegmentIndex1.
  ///
  /// In en, this message translates to:
  /// **'Segment 1'**
  String get adminTrainerPlayMissingSegmentIndex1;

  /// No description provided for @adminTrainerPlayMissingSegmentIndex2.
  ///
  /// In en, this message translates to:
  /// **'Segment 2'**
  String get adminTrainerPlayMissingSegmentIndex2;

  /// No description provided for @adminTrainerPlayMissingSegmentIndex3.
  ///
  /// In en, this message translates to:
  /// **'Segment 3'**
  String get adminTrainerPlayMissingSegmentIndex3;

  /// No description provided for @adminTrainerPlayMissingSegmentIndex4.
  ///
  /// In en, this message translates to:
  /// **'Segment 4'**
  String get adminTrainerPlayMissingSegmentIndex4;

  /// No description provided for @adminTrainerPlayDotModeNumbered.
  ///
  /// In en, this message translates to:
  /// **'Numbered'**
  String get adminTrainerPlayDotModeNumbered;

  /// No description provided for @adminTrainerPlayDotModeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get adminTrainerPlayDotModeFree;

  /// No description provided for @adminTrainerPlaySpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get adminTrainerPlaySpeedSlow;

  /// No description provided for @adminTrainerPlaySpeedMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get adminTrainerPlaySpeedMedium;

  /// No description provided for @adminTrainerPlaySpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get adminTrainerPlaySpeedFast;

  /// No description provided for @adminTrainerPlayMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Runs in the mobile runtime (Flutter). Check the web version on desktop.'**
  String get adminTrainerPlayMobileHint;

  /// No description provided for @adminTrainerPlayWebOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'No mobile implementation'**
  String get adminTrainerPlayWebOnlyTitle;

  /// No description provided for @adminTrainerPlayWebOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'This trainer is web-only for now. Run and test play at larnes.ru under Trainers.'**
  String get adminTrainerPlayWebOnlyMessage;

  /// No description provided for @adminTrainerPlayExit.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get adminTrainerPlayExit;

  /// No description provided for @adminTrainerPlayMenuContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue check'**
  String get adminTrainerPlayMenuContinue;

  /// No description provided for @adminTrainerPlayFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminTrainerPlayFinish;

  /// No description provided for @adminTrainerPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get adminTrainerPlayNext;

  /// No description provided for @adminTrainerPlayContinueCheck.
  ///
  /// In en, this message translates to:
  /// **'Continue check'**
  String get adminTrainerPlayContinueCheck;

  /// No description provided for @adminAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminAccountTitle;

  /// No description provided for @adminAccountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load account.'**
  String get adminAccountLoadFailed;

  /// No description provided for @adminAccountSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes.'**
  String get adminAccountSaveFailed;

  /// No description provided for @adminAccountNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminAccountNotSet;

  /// No description provided for @adminAccountSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get adminAccountSectionProfile;

  /// No description provided for @adminAccountSectionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get adminAccountSectionContacts;

  /// No description provided for @adminAccountSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get adminAccountSectionSecurity;

  /// No description provided for @adminAccountSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get adminAccountSectionLanguage;

  /// No description provided for @adminAccountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get adminAccountProfileTitle;

  /// No description provided for @adminAccountLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Change login'**
  String get adminAccountLoginTitle;

  /// No description provided for @adminAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get adminAccountPasswordTitle;

  /// No description provided for @adminAccountPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change phone'**
  String get adminAccountPhoneTitle;

  /// No description provided for @adminAccountEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get adminAccountEmailTitle;

  /// No description provided for @adminAccountSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminAccountSave;

  /// No description provided for @adminAccountSaveLogin.
  ///
  /// In en, this message translates to:
  /// **'Save login'**
  String get adminAccountSaveLogin;

  /// No description provided for @adminAccountSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get adminAccountSavePassword;

  /// No description provided for @adminAccountActionLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices'**
  String get adminAccountActionLogoutAll;

  /// No description provided for @parentAccountBackToPicker.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get parentAccountBackToPicker;

  /// No description provided for @parentAccountBackToAccount.
  ///
  /// In en, this message translates to:
  /// **'Back to account'**
  String get parentAccountBackToAccount;

  /// No description provided for @parentAccountNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get parentAccountNotSet;

  /// No description provided for @parentAccountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load account.'**
  String get parentAccountLoadFailed;

  /// No description provided for @parentAccountSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes.'**
  String get parentAccountSaveFailed;

  /// No description provided for @parentAccountSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get parentAccountSave;

  /// No description provided for @parentAccountSaveCity.
  ///
  /// In en, this message translates to:
  /// **'Save city'**
  String get parentAccountSaveCity;

  /// No description provided for @parentAccountSaveLogin.
  ///
  /// In en, this message translates to:
  /// **'Save login'**
  String get parentAccountSaveLogin;

  /// No description provided for @parentAccountSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get parentAccountSavePassword;

  /// No description provided for @parentAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parentAccountCancel;

  /// No description provided for @parentAccountSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Parent profile'**
  String get parentAccountSectionProfile;

  /// No description provided for @parentAccountSectionChildren.
  ///
  /// In en, this message translates to:
  /// **'Your children'**
  String get parentAccountSectionChildren;

  /// No description provided for @parentAccountSectionCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get parentAccountSectionCity;

  /// No description provided for @parentAccountSectionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get parentAccountSectionContacts;

  /// No description provided for @parentAccountSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get parentAccountSectionSecurity;

  /// No description provided for @parentAccountSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get parentAccountSectionLanguage;

  /// No description provided for @parentAccountSectionFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get parentAccountSectionFamily;

  /// No description provided for @parentAccountFieldGuardians.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get parentAccountFieldGuardians;

  /// No description provided for @parentAccountActionManageGuardians.
  ///
  /// In en, this message translates to:
  /// **'Manage guardians'**
  String get parentAccountActionManageGuardians;

  /// No description provided for @parentFamilySetupGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Is your family already on LARNES?'**
  String get parentFamilySetupGateTitle;

  /// No description provided for @parentFamilySetupContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Set up family'**
  String get parentFamilySetupContinueAction;

  /// No description provided for @parentFamilySetupGateLead.
  ///
  /// In en, this message translates to:
  /// **'If someone in your family already uses the platform, ask them to accept you. Otherwise create your own family and add children.'**
  String get parentFamilySetupGateLead;

  /// No description provided for @parentFamilySetupAnswerNo.
  ///
  /// In en, this message translates to:
  /// **'No, create my family'**
  String get parentFamilySetupAnswerNo;

  /// No description provided for @parentFamilySetupAnswerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, our family is here'**
  String get parentFamilySetupAnswerYes;

  /// No description provided for @parentFamilySetupWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get parentFamilySetupWaitingTitle;

  /// No description provided for @parentFamilySetupWaitingLead.
  ///
  /// In en, this message translates to:
  /// **'Send the link to a relative — any guardian of your family on LARNES can accept the request.'**
  String get parentFamilySetupWaitingLead;

  /// No description provided for @parentFamilySetupShareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link for your relative'**
  String get parentFamilySetupShareLinkLabel;

  /// No description provided for @parentFamilySetupCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get parentFamilySetupCopyLink;

  /// No description provided for @parentFamilySetupCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get parentFamilySetupCopySuccess;

  /// No description provided for @parentFamilySetupCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy'**
  String get parentFamilySetupCopyFailed;

  /// No description provided for @parentFamilySetupShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get parentFamilySetupShare;

  /// No description provided for @parentFamilySetupCancelJoin.
  ///
  /// In en, this message translates to:
  /// **'I made a mistake — create my family'**
  String get parentFamilySetupCancelJoin;

  /// No description provided for @parentFamilySetupResolveProfiles.
  ///
  /// In en, this message translates to:
  /// **'Resolve child profiles'**
  String get parentFamilySetupResolveProfiles;

  /// No description provided for @parentFamilyJoinDedupChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Children named “{name}”'**
  String parentFamilyJoinDedupChoiceTitle(String name);

  /// No description provided for @parentFamilyJoinDedupChoiceLead.
  ///
  /// In en, this message translates to:
  /// **'If this is one child, pick the profile to keep. The other will be removed from the family account.'**
  String get parentFamilyJoinDedupChoiceLead;

  /// No description provided for @parentFamilyJoinDedupDifferentChildren.
  ///
  /// In en, this message translates to:
  /// **'Different children'**
  String get parentFamilyJoinDedupDifferentChildren;

  /// No description provided for @parentFamilyJoinDedupSameChild.
  ///
  /// In en, this message translates to:
  /// **'Same child'**
  String get parentFamilyJoinDedupSameChild;

  /// No description provided for @parentFamilyJoinDedupPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Same child — pick a profile'**
  String get parentFamilyJoinDedupPickTitle;

  /// No description provided for @parentFamilyJoinDedupPickLead.
  ///
  /// In en, this message translates to:
  /// **'Which profile should we keep? The other will be removed from the family account.'**
  String get parentFamilyJoinDedupPickLead;

  /// No description provided for @parentFamilyJoinDedupRegisteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get parentFamilyJoinDedupRegisteredLabel;

  /// No description provided for @parentFamilyJoinDedupNetworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network / group'**
  String get parentFamilyJoinDedupNetworkLabel;

  /// No description provided for @parentFamilyJoinDedupProgramLabel.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get parentFamilyJoinDedupProgramLabel;

  /// No description provided for @parentFamilyJoinDedupKeepProfile.
  ///
  /// In en, this message translates to:
  /// **'Keep this profile'**
  String get parentFamilyJoinDedupKeepProfile;

  /// No description provided for @parentFamilyJoinDedupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get parentFamilyJoinDedupBack;

  /// No description provided for @parentFamilyJoinDedupInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to resolve'**
  String get parentFamilyJoinDedupInvalidTitle;

  /// No description provided for @parentFamilyJoinDedupInvalidLead.
  ///
  /// In en, this message translates to:
  /// **'This link is outdated or profiles are already aligned.'**
  String get parentFamilyJoinDedupInvalidLead;

  /// No description provided for @parentGuardiansTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get parentGuardiansTitle;

  /// No description provided for @parentGuardiansSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get parentGuardiansSectionTitle;

  /// No description provided for @parentGuardiansEmpty.
  ///
  /// In en, this message translates to:
  /// **'Just you for now.'**
  String get parentGuardiansEmpty;

  /// No description provided for @parentGuardiansYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get parentGuardiansYou;

  /// No description provided for @parentGuardiansInviteGuardian.
  ///
  /// In en, this message translates to:
  /// **'Invite guardian'**
  String get parentGuardiansInviteGuardian;

  /// No description provided for @parentGuardiansInviteFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Invite a family member'**
  String get parentGuardiansInviteFamilyMember;

  /// No description provided for @parentGuardiansInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get parentGuardiansInviteCopied;

  /// No description provided for @parentGuardiansInviteCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get parentGuardiansInviteCreated;

  /// No description provided for @parentGuardiansPendingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get parentGuardiansPendingInvitesTitle;

  /// No description provided for @parentGuardiansPendingInviteLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get parentGuardiansPendingInviteLabel;

  /// No description provided for @parentGuardiansPendingInviteStatus.
  ///
  /// In en, this message translates to:
  /// **'Awaiting acceptance'**
  String get parentGuardiansPendingInviteStatus;

  /// No description provided for @parentGuardiansConfirmRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke invitation?'**
  String get parentGuardiansConfirmRevokeTitle;

  /// No description provided for @parentGuardiansConfirmRevokeMessage.
  ///
  /// In en, this message translates to:
  /// **'The link will stop working.'**
  String get parentGuardiansConfirmRevokeMessage;

  /// No description provided for @parentGuardiansRevokeInvite.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get parentGuardiansRevokeInvite;

  /// No description provided for @parentGuardiansRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get parentGuardiansRemove;

  /// No description provided for @parentGuardiansLeaveFamily.
  ///
  /// In en, this message translates to:
  /// **'Leave family'**
  String get parentGuardiansLeaveFamily;

  /// No description provided for @parentGuardiansConfirmRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove guardian?'**
  String get parentGuardiansConfirmRemoveTitle;

  /// No description provided for @parentGuardiansConfirmRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this family\'s children and get a separate account.'**
  String get parentGuardiansConfirmRemoveMessage;

  /// No description provided for @parentGuardiansConfirmLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave family?'**
  String get parentGuardiansConfirmLeaveTitle;

  /// No description provided for @parentGuardiansConfirmLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to this family\'s children and get a separate account.'**
  String get parentGuardiansConfirmLeaveMessage;

  /// No description provided for @parentGuardiansRelationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get parentGuardiansRelationshipMother;

  /// No description provided for @parentGuardiansRelationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get parentGuardiansRelationshipFather;

  /// No description provided for @parentGuardiansRelationshipGrandmother.
  ///
  /// In en, this message translates to:
  /// **'Grandmother'**
  String get parentGuardiansRelationshipGrandmother;

  /// No description provided for @parentGuardiansRelationshipGrandfather.
  ///
  /// In en, this message translates to:
  /// **'Grandfather'**
  String get parentGuardiansRelationshipGrandfather;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invitation not found or expired.'**
  String get inviteInvalid;

  /// No description provided for @inviteInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid invitation'**
  String get inviteInvalidTitle;

  /// No description provided for @inviteFamilyJoinRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Family join request'**
  String get inviteFamilyJoinRequestTitle;

  /// No description provided for @inviteFamilyJoinRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this guardian into your family — they will see shared children.'**
  String get inviteFamilyJoinRequestSubtitle;

  /// No description provided for @inviteFamilyJoinRequestRequesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get inviteFamilyJoinRequestRequesterLabel;

  /// No description provided for @inviteFamilyJoinRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get inviteFamilyJoinRequestAccept;

  /// No description provided for @inviteFamilyJoinRequestDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get inviteFamilyJoinRequestDecline;

  /// No description provided for @inviteFamilyJoinRequestLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get inviteFamilyJoinRequestLoginTitle;

  /// No description provided for @inviteFamilyJoinRequestLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in as a guardian to accept the family join request.'**
  String get inviteFamilyJoinRequestLoginSubtitle;

  /// No description provided for @inviteFamilyJoinRequestRegister.
  ///
  /// In en, this message translates to:
  /// **'Guardian registration'**
  String get inviteFamilyJoinRequestRegister;

  /// No description provided for @inviteFamilyJoinRequestWrongAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong account type'**
  String get inviteFamilyJoinRequestWrongAccountTitle;

  /// No description provided for @inviteFamilyJoinRequestWrongAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only a guardian can accept this request.'**
  String get inviteFamilyJoinRequestWrongAccountSubtitle;

  /// No description provided for @inviteFamilyJoinRequestOwnRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'This is your request'**
  String get inviteFamilyJoinRequestOwnRequestTitle;

  /// No description provided for @inviteFamilyJoinRequestOwnRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this link with another guardian in your family on LARNES.'**
  String get inviteFamilyJoinRequestOwnRequestSubtitle;

  /// No description provided for @inviteFamilyGuardianTitle.
  ///
  /// In en, this message translates to:
  /// **'Family invitation'**
  String get inviteFamilyGuardianTitle;

  /// No description provided for @inviteFamilyGuardianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept the invitation to access the family\'s children.'**
  String get inviteFamilyGuardianSubtitle;

  /// No description provided for @inviteFamilyGuardianInviterLabel.
  ///
  /// In en, this message translates to:
  /// **'Invited by'**
  String get inviteFamilyGuardianInviterLabel;

  /// No description provided for @inviteFamilyGuardianAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get inviteFamilyGuardianAccept;

  /// No description provided for @inviteFamilyGuardianDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get inviteFamilyGuardianDecline;

  /// No description provided for @inviteFamilyGuardianLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get inviteFamilyGuardianLoginTitle;

  /// No description provided for @inviteFamilyGuardianLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or register as a guardian to accept the invitation.'**
  String get inviteFamilyGuardianLoginSubtitle;

  /// No description provided for @inviteFamilyGuardianRegister.
  ///
  /// In en, this message translates to:
  /// **'Guardian registration'**
  String get inviteFamilyGuardianRegister;

  /// No description provided for @inviteFamilyGuardianWrongAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong account type'**
  String get inviteFamilyGuardianWrongAccountTitle;

  /// No description provided for @inviteFamilyGuardianWrongAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only a guardian can accept this invitation.'**
  String get inviteFamilyGuardianWrongAccountSubtitle;

  /// No description provided for @parentAccountFieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get parentAccountFieldFullName;

  /// No description provided for @parentAccountFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get parentAccountFieldDateOfBirth;

  /// No description provided for @parentAccountFieldRelationship.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get parentAccountFieldRelationship;

  /// No description provided for @parentAccountFieldChildren.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get parentAccountFieldChildren;

  /// No description provided for @parentAccountFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get parentAccountFieldCity;

  /// No description provided for @parentAccountFieldLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get parentAccountFieldLogin;

  /// No description provided for @parentAccountActionChangeProfile.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get parentAccountActionChangeProfile;

  /// No description provided for @parentAccountActionChangeDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Change date of birth'**
  String get parentAccountActionChangeDateOfBirth;

  /// No description provided for @parentAccountActionManageChildren.
  ///
  /// In en, this message translates to:
  /// **'Manage children'**
  String get parentAccountActionManageChildren;

  /// No description provided for @parentAccountActionChangeCity.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get parentAccountActionChangeCity;

  /// No description provided for @parentAccountActionChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone'**
  String get parentAccountActionChangePhone;

  /// No description provided for @parentAccountActionChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get parentAccountActionChangeEmail;

  /// No description provided for @parentAccountActionChangeLogin.
  ///
  /// In en, this message translates to:
  /// **'Change login'**
  String get parentAccountActionChangeLogin;

  /// No description provided for @parentAccountActionChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get parentAccountActionChangePassword;

  /// No description provided for @parentAccountActionLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices'**
  String get parentAccountActionLogoutAll;

  /// No description provided for @parentAccountChildrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile} other{{count} profiles}}'**
  String parentAccountChildrenCount(int count);

  /// No description provided for @parentAccountCityNotSet.
  ///
  /// In en, this message translates to:
  /// **'City not set'**
  String get parentAccountCityNotSet;

  /// No description provided for @parentAccountDateOfBirthNotSet.
  ///
  /// In en, this message translates to:
  /// **'Date of birth not set'**
  String get parentAccountDateOfBirthNotSet;

  /// No description provided for @parentAccountContactVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get parentAccountContactVerified;

  /// No description provided for @parentAccountContactNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get parentAccountContactNotVerified;

  /// No description provided for @parentAccountContactChangeSoon.
  ///
  /// In en, this message translates to:
  /// **'Contact change — coming in the next step.'**
  String get parentAccountContactChangeSoon;

  /// No description provided for @parentAccountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get parentAccountProfileTitle;

  /// No description provided for @parentAccountDateOfBirthTitle.
  ///
  /// In en, this message translates to:
  /// **'Change date of birth'**
  String get parentAccountDateOfBirthTitle;

  /// No description provided for @parentAccountCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get parentAccountCityTitle;

  /// No description provided for @parentAccountRelationshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get parentAccountRelationshipTitle;

  /// No description provided for @parentAccountSaveRelationship.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get parentAccountSaveRelationship;

  /// No description provided for @parentAccountLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Change login'**
  String get parentAccountLoginTitle;

  /// No description provided for @parentAccountPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change phone'**
  String get parentAccountPhoneTitle;

  /// No description provided for @parentAccountEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get parentAccountEmailTitle;

  /// No description provided for @parentAccountNewPhone.
  ///
  /// In en, this message translates to:
  /// **'New phone'**
  String get parentAccountNewPhone;

  /// No description provided for @parentAccountNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get parentAccountNewEmail;

  /// No description provided for @parentAccountSendCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get parentAccountSendCode;

  /// No description provided for @parentAccountVerifyContact.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get parentAccountVerifyContact;

  /// No description provided for @parentAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get parentAccountPasswordTitle;

  /// No description provided for @parentAccountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get parentAccountCurrentPassword;

  /// No description provided for @parentAccountNewLogin.
  ///
  /// In en, this message translates to:
  /// **'New login'**
  String get parentAccountNewLogin;

  /// No description provided for @parentAccountConfirmNewLogin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new login'**
  String get parentAccountConfirmNewLogin;

  /// No description provided for @parentAccountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get parentAccountNewPassword;

  /// No description provided for @parentAccountConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get parentAccountConfirmNewPassword;

  /// No description provided for @parentAccountLogoutAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices?'**
  String get parentAccountLogoutAllTitle;

  /// No description provided for @parentAccountLogoutAllMessage.
  ///
  /// In en, this message translates to:
  /// **'All active sessions will end. You will need to sign in again.'**
  String get parentAccountLogoutAllMessage;

  /// No description provided for @parentAccountLogoutAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere'**
  String get parentAccountLogoutAllConfirm;

  /// No description provided for @parentAccountChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get parentAccountChildrenTitle;

  /// No description provided for @parentAccountChildrenProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get parentAccountChildrenProfiles;

  /// No description provided for @parentAccountChildrenArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived children'**
  String get parentAccountChildrenArchiveTitle;

  /// No description provided for @parentAccountChildrenArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Connections are closed. School and teacher access must be granted again after restoration.'**
  String get parentAccountChildrenArchiveHint;

  /// No description provided for @parentAccountChildrenRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore profile'**
  String get parentAccountChildrenRestore;

  /// No description provided for @parentAccountChildrenActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get parentAccountChildrenActions;

  /// No description provided for @parentAccountChildrenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No children added yet.'**
  String get parentAccountChildrenEmpty;

  /// No description provided for @parentAccountChildrenBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get parentAccountChildrenBackToList;

  /// No description provided for @parentAccountChildSummary.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get parentAccountChildSummary;

  /// No description provided for @parentAccountChildAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get parentAccountChildAge;

  /// No description provided for @parentAccountEditChildProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get parentAccountEditChildProfile;

  /// No description provided for @parentChildEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get parentChildEducationTitle;

  /// No description provided for @parentChildEducationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teachers or networks linked yet.'**
  String get parentChildEducationEmpty;

  /// No description provided for @parentChildTutorSection.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get parentChildTutorSection;

  /// No description provided for @parentChildTeacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get parentChildTeacherLabel;

  /// No description provided for @parentChildGroupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get parentChildGroupsLabel;

  /// No description provided for @parentChildGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get parentChildGroupLabel;

  /// No description provided for @parentChildTutorNoGroups.
  ///
  /// In en, this message translates to:
  /// **'Not added to any groups yet.'**
  String get parentChildTutorNoGroups;

  /// No description provided for @parentChildNetworkSection.
  ///
  /// In en, this message translates to:
  /// **'Network \"{name}\"'**
  String parentChildNetworkSection(String name);

  /// No description provided for @parentChildNetworkNoGroups.
  ///
  /// In en, this message translates to:
  /// **'Enrolled in network; no group assigned yet.'**
  String get parentChildNetworkNoGroups;

  /// No description provided for @parentChildResponsibleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String parentChildResponsibleTeacher(String name);

  /// No description provided for @parentChildTeacherNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'No responsible teacher assigned.'**
  String get parentChildTeacherNotAssigned;

  /// No description provided for @parentAccountEditChild.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get parentAccountEditChild;

  /// No description provided for @parentAccountEditChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get parentAccountEditChildTitle;

  /// No description provided for @parentAccountChildBackToProfile.
  ///
  /// In en, this message translates to:
  /// **'Back to profile'**
  String get parentAccountChildBackToProfile;

  /// No description provided for @parentAccountDeleteChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this child profile?'**
  String get parentAccountDeleteChildTitle;

  /// No description provided for @parentAccountDeleteChildMessage.
  ///
  /// In en, this message translates to:
  /// **'The profile will leave the active list and can be restored later.'**
  String get parentAccountDeleteChildMessage;

  /// No description provided for @parentAccountDeleteChildMessageActiveNetwork.
  ///
  /// In en, this message translates to:
  /// **'The profile will leave the active list; connections will end; learning and payment history will be kept. The profile can be restored later.'**
  String get parentAccountDeleteChildMessageActiveNetwork;

  /// No description provided for @parentAccountDeleteChildConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive profile'**
  String get parentAccountDeleteChildConfirm;

  /// No description provided for @parentUpdateChildFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update child profile.'**
  String get parentUpdateChildFailed;

  /// No description provided for @parentDeleteChildFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete child profile.'**
  String get parentDeleteChildFailed;

  /// No description provided for @parentProgramLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load programs.'**
  String get parentProgramLoadFailed;

  /// No description provided for @parentDirectionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load directions.'**
  String get parentDirectionLoadFailed;

  /// No description provided for @parentLearningDirectionProgramCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# program} other {# programs}}'**
  String parentLearningDirectionProgramCount(int count);

  /// No description provided for @parentDirectionProgramsBack.
  ///
  /// In en, this message translates to:
  /// **'Back to study'**
  String get parentDirectionProgramsBack;

  /// No description provided for @parentDirectionProgramsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published programs in this direction yet.'**
  String get parentDirectionProgramsEmpty;

  /// No description provided for @parentProgramTrackCompleted.
  ///
  /// In en, this message translates to:
  /// **'Direction completed'**
  String get parentProgramTrackCompleted;

  /// No description provided for @parentProgramDirectionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get parentProgramDirectionStart;

  /// No description provided for @parentProgramDirectionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get parentProgramDirectionContinue;

  /// No description provided for @parentProgramDirectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get parentProgramDirectionCompleted;

  /// No description provided for @parentProgramStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get parentProgramStatusInProgress;

  /// No description provided for @parentProgramStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get parentProgramStatusCompleted;

  /// No description provided for @parentProgramPlayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load program.'**
  String get parentProgramPlayLoadFailed;

  /// No description provided for @parentProgramPlayCompleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save progress.'**
  String get parentProgramPlayCompleteFailed;

  /// No description provided for @parentProgramPlayLessonProgress.
  ///
  /// In en, this message translates to:
  /// **'Topic {topic} · Lesson {lesson} · step {current} of {total}'**
  String parentProgramPlayLessonProgress(
    int topic,
    int lesson,
    int current,
    int total,
  );

  /// No description provided for @parentProgramPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get parentProgramPlayNext;

  /// No description provided for @parentProgramPlayFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get parentProgramPlayFinish;

  /// No description provided for @parentProgramPlayCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Program completed'**
  String get parentProgramPlayCompletedTitle;

  /// No description provided for @parentProgramPlayBackToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to study'**
  String get parentProgramPlayBackToHub;

  /// No description provided for @parentProgramPlayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get parentProgramPlayExit;

  /// No description provided for @parentProgramPlayMenuContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue lesson'**
  String get parentProgramPlayMenuContinue;

  /// No description provided for @parentProgramPlayEmptyProgram.
  ///
  /// In en, this message translates to:
  /// **'This program has no trainers to play yet.'**
  String get parentProgramPlayEmptyProgram;

  /// No description provided for @parentProgramPlayEmptyLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson} in topic {topic} has no trainers yet. Ask your teacher to add tasks.'**
  String parentProgramPlayEmptyLesson(int topic, int lesson);

  /// No description provided for @parentProgramPlayInteractiveHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the task on screen'**
  String get parentProgramPlayInteractiveHint;

  /// No description provided for @networkCentersTitle.
  ///
  /// In en, this message translates to:
  /// **'My centers'**
  String get networkCentersTitle;

  /// No description provided for @networkCentersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your centers'**
  String get networkCentersSectionTitle;

  /// No description provided for @networkDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Network devices'**
  String get networkDevicesTitle;

  /// No description provided for @networkDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tablets and other clients in your network. Classroom and slot show current placement.'**
  String get networkDevicesHint;

  /// No description provided for @networkCentersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You do not have any centers yet'**
  String get networkCentersEmptyTitle;

  /// No description provided for @networkCentersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create centers in the web network panel.'**
  String get networkCentersEmptyDescription;

  /// No description provided for @networkDevicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices yet. They appear after enrolling a tablet.'**
  String get networkDevicesEmpty;

  /// No description provided for @networkLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load network data.'**
  String get networkLoadFailed;

  /// No description provided for @networkDeviceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get networkDeviceOnline;

  /// No description provided for @networkDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get networkDeviceOffline;

  /// No description provided for @networkDeviceUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get networkDeviceUnassigned;

  /// No description provided for @networkDeviceKindTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get networkDeviceKindTablet;

  /// No description provided for @networkDeviceKindLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get networkDeviceKindLaptop;

  /// No description provided for @networkDeviceKindPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get networkDeviceKindPhone;

  /// No description provided for @networkDeviceSlotValue.
  ///
  /// In en, this message translates to:
  /// **'Slot {slot}'**
  String networkDeviceSlotValue(String slot);

  /// No description provided for @kioskIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson not started'**
  String get kioskIdleTitle;

  /// No description provided for @kioskIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The teacher will start the lesson. Then hold the child\'s QR code up to this device.'**
  String get kioskIdleSubtitle;

  /// No description provided for @kioskIdleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get kioskIdleSettings;

  /// No description provided for @kioskScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Show your QR code'**
  String get kioskScanTitle;

  /// No description provided for @kioskScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold the code up to this device.'**
  String get kioskScanSubtitle;

  /// No description provided for @kioskScanEnableCamera.
  ///
  /// In en, this message translates to:
  /// **'Enable camera'**
  String get kioskScanEnableCamera;

  /// No description provided for @kioskScanEnableCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button and allow camera access when prompted.'**
  String get kioskScanEnableCameraHint;

  /// No description provided for @kioskScanRetryCamera.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get kioskScanRetryCamera;

  /// No description provided for @kioskScanSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get kioskScanSwitchCamera;

  /// No description provided for @kioskScanStartingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get kioskScanStartingCamera;

  /// No description provided for @kioskScanProcessing.
  ///
  /// In en, this message translates to:
  /// **'Checking the code…'**
  String get kioskScanProcessing;

  /// No description provided for @kioskScanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied.'**
  String get kioskScanCameraDenied;

  /// No description provided for @kioskScanCameraDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in system settings, or tap Try again.'**
  String get kioskScanCameraDeniedHint;

  /// No description provided for @kioskScanErrorCamera.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera. Please try again.'**
  String get kioskScanErrorCamera;

  /// No description provided for @kioskScanErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not process the QR code. Please try again.'**
  String get kioskScanErrorGeneric;

  /// No description provided for @kioskScanErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Scanning is not available on this device.'**
  String get kioskScanErrorForbidden;

  /// No description provided for @kioskScanErrorInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'The QR code is invalid or expired.'**
  String get kioskScanErrorInvalidToken;

  /// No description provided for @kioskScanErrorLessonInactive.
  ///
  /// In en, this message translates to:
  /// **'The lesson has not started yet or has already ended.'**
  String get kioskScanErrorLessonInactive;

  /// No description provided for @kioskScanErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server. Check your internet.'**
  String get kioskScanErrorNetwork;

  /// No description provided for @kioskScanErrorNotInGroup.
  ///
  /// In en, this message translates to:
  /// **'This child is not enrolled in the lesson group.'**
  String get kioskScanErrorNotInGroup;

  /// No description provided for @kioskScanErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute.'**
  String get kioskScanErrorRateLimited;

  /// No description provided for @kioskScanErrorRevoked.
  ///
  /// In en, this message translates to:
  /// **'The QR code was revoked. Ask the parent to refresh it.'**
  String get kioskScanErrorRevoked;

  /// No description provided for @kioskScanCameraSoon.
  ///
  /// In en, this message translates to:
  /// **'Camera support is coming in the next update.'**
  String get kioskScanCameraSoon;

  /// No description provided for @kioskResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Child checked in'**
  String get kioskResultTitle;

  /// No description provided for @kioskResultProgramAssigned.
  ///
  /// In en, this message translates to:
  /// **'Program assigned'**
  String get kioskResultProgramAssigned;

  /// No description provided for @kioskResultNoProgram.
  ///
  /// In en, this message translates to:
  /// **'No program is available for this child yet.'**
  String get kioskResultNoProgram;

  /// No description provided for @kioskSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Device settings'**
  String get kioskSettingsTitle;

  /// No description provided for @kioskSettingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get kioskSettingsBack;

  /// No description provided for @kioskSettingsPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get kioskSettingsPlacement;

  /// No description provided for @kioskSettingsDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get kioskSettingsDeviceId;

  /// No description provided for @kioskSettingsUnbindTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbind device'**
  String get kioskSettingsUnbindTitle;

  /// No description provided for @kioskSettingsUnbindHint.
  ///
  /// In en, this message translates to:
  /// **'The device will disappear from the network list. To use kiosk again, enroll it once more.'**
  String get kioskSettingsUnbindHint;

  /// No description provided for @kioskSettingsUnbindSubmit.
  ///
  /// In en, this message translates to:
  /// **'Unbind and leave kiosk'**
  String get kioskSettingsUnbindSubmit;

  /// No description provided for @kioskSettingsUnbinding.
  ///
  /// In en, this message translates to:
  /// **'Unbinding…'**
  String get kioskSettingsUnbinding;

  /// No description provided for @kioskSettingsUnbindConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbind this device?'**
  String get kioskSettingsUnbindConfirmTitle;

  /// No description provided for @kioskSettingsUnbindConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode on this phone will be turned off.'**
  String get kioskSettingsUnbindConfirmMessage;

  /// No description provided for @kioskSettingsUnbindCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get kioskSettingsUnbindCancel;

  /// No description provided for @kioskSettingsUnbindConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get kioskSettingsUnbindConfirm;

  /// No description provided for @kioskSettingsLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to unbind this device.'**
  String get kioskSettingsLoginRequired;

  /// No description provided for @networkAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get networkAddDevice;

  /// No description provided for @kioskEnrollTitle.
  ///
  /// In en, this message translates to:
  /// **'Device setup'**
  String get kioskEnrollTitle;

  /// No description provided for @kioskEnrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where this device belongs in your network.'**
  String get kioskEnrollSubtitle;

  /// No description provided for @kioskEnrollCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get kioskEnrollCenter;

  /// No description provided for @kioskEnrollClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get kioskEnrollClassroom;

  /// No description provided for @kioskEnrollClassroomPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select a classroom'**
  String get kioskEnrollClassroomPlaceholder;

  /// No description provided for @kioskEnrollSlot.
  ///
  /// In en, this message translates to:
  /// **'Desk / slot'**
  String get kioskEnrollSlot;

  /// No description provided for @kioskEnrollSlotPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example, 1'**
  String get kioskEnrollSlotPlaceholder;

  /// No description provided for @kioskEnrollSlotRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a slot label'**
  String get kioskEnrollSlotRequired;

  /// No description provided for @kioskEnrollKind.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get kioskEnrollKind;

  /// No description provided for @kioskEnrollSubmit.
  ///
  /// In en, this message translates to:
  /// **'Enroll device'**
  String get kioskEnrollSubmit;

  /// No description provided for @kioskEnrollSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Enrolling…'**
  String get kioskEnrollSubmitting;

  /// No description provided for @kioskEnrollNoCenters.
  ///
  /// In en, this message translates to:
  /// **'Create a center in the network panel first.'**
  String get kioskEnrollNoCenters;

  /// No description provided for @kioskEnrollNoClassrooms.
  ///
  /// In en, this message translates to:
  /// **'Add classrooms in the center first.'**
  String get kioskEnrollNoClassrooms;

  /// No description provided for @kioskEnrollNoClassroomsForCenter.
  ///
  /// In en, this message translates to:
  /// **'This center has no classrooms yet.'**
  String get kioskEnrollNoClassroomsForCenter;

  /// No description provided for @optionalPatronymicLabel.
  ///
  /// In en, this message translates to:
  /// **'Patronymic (optional)'**
  String get optionalPatronymicLabel;

  /// No description provided for @registrationOwnerEmailUnverifiedHint.
  ///
  /// In en, this message translates to:
  /// **'The email will be saved as unverified. Verify it in account settings after registration.'**
  String get registrationOwnerEmailUnverifiedHint;

  /// No description provided for @optionalDateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get optionalDateOfBirthLabel;

  /// No description provided for @optionalCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get optionalCityLabel;

  /// No description provided for @placesAutocompleteUnavailable.
  String get placesAutocompleteUnavailable;

  /// No description provided for @placesAutocompleteInvalidSelection.
  String get placesAutocompleteInvalidSelection;

  /// No description provided for @notSpecifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecifiedLabel;

  /// No description provided for @registrationTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept the current Terms to create an account.'**
  String get registrationTermsRequired;

  /// No description provided for @registrationTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get registrationTermsLink;

  /// No description provided for @registrationPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Personal Data Policy'**
  String get registrationPrivacyLink;

  /// No description provided for @registrationTermsParent.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service.'**
  String get registrationTermsParent;

  /// No description provided for @registrationTermsTeacher.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service.'**
  String get registrationTermsTeacher;

  /// No description provided for @registrationTermsNetworkOwner.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Service.'**
  String get registrationTermsNetworkOwner;

  /// No description provided for @voluntaryConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Separate consent for optional data'**
  String get voluntaryConsentTitle;

  /// No description provided for @voluntaryConsentParentFields.
  ///
  /// In en, this message translates to:
  /// **'Covers only patronymic, city, and date of birth. Core account functions do not depend on it.'**
  String get voluntaryConsentParentFields;

  /// No description provided for @voluntaryConsentParentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I consent to processing my patronymic, city, and date of birth for maintaining my private extended profile.'**
  String get voluntaryConsentParentCheckbox;

  /// No description provided for @voluntaryConsentOpenVersion.
  ///
  /// In en, this message translates to:
  /// **'Open version {version}'**
  String voluntaryConsentOpenVersion(String version);

  /// No description provided for @voluntaryConsentVersionMissing.
  ///
  /// In en, this message translates to:
  /// **'The published consent version is unavailable.'**
  String get voluntaryConsentVersionMissing;

  /// No description provided for @voluntaryConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm the separate consent to save a non-empty optional field.'**
  String get voluntaryConsentRequired;

  /// No description provided for @voluntaryConsentRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw profile data consent'**
  String get voluntaryConsentRevokeTitle;

  /// No description provided for @voluntaryConsentRevokeDescription.
  ///
  /// In en, this message translates to:
  /// **'Patronymic, city, and date of birth will be permanently erased. The core account will continue to work.'**
  String get voluntaryConsentRevokeDescription;

  /// No description provided for @voluntaryConsentRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm withdrawal and data erasure'**
  String get voluntaryConsentRevokeConfirm;

  /// No description provided for @voluntaryConsentRevokeButton.
  ///
  /// In en, this message translates to:
  /// **'Withdraw and erase'**
  String get voluntaryConsentRevokeButton;

  /// No description provided for @voluntaryConsentRevokeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Consent was withdrawn and the data was erased.'**
  String get voluntaryConsentRevokeSuccess;

  /// No description provided for @voluntaryConsentRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Consent could not be withdrawn. No data was erased.'**
  String get voluntaryConsentRevokeFailed;
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
