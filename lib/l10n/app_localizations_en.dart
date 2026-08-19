// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LARNES';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginEyebrow => 'Sign in';

  @override
  String get loginPending => 'Signing in…';

  @override
  String get loginNoAccount => 'No account?';

  @override
  String get loginRegisterLink => 'Register';

  @override
  String get authHeaderRegister => 'Register';

  @override
  String get authHeaderLogin => 'Sign in';

  @override
  String get authLegalLink => 'Legal information';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get passwordCapsLock => 'Caps Lock is on';

  @override
  String get loginSubtitle => 'Phone, email or username and password';

  @override
  String get loginFieldLabel => 'Email or phone';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetTitle => 'Password reset';

  @override
  String get passwordResetStep1Subtitle => 'Step 1 of 3 — contact';

  @override
  String get passwordResetStep2Subtitle => 'Step 2 of 3 — verification code';

  @override
  String get passwordResetStep3Subtitle => 'Step 3 of 3 — new password';

  @override
  String get passwordResetContactHint =>
      'Enter the phone or email linked to your account. We will send a verification code.';

  @override
  String get passwordResetContactLabel => 'Phone or email';

  @override
  String passwordResetOtpHintSms(String contact) {
    return 'Code sent to $contact. Enter it below.';
  }

  @override
  String passwordResetOtpHintEmail(String contact) {
    return 'Code sent to $contact. Check your inbox (and spam folder) and enter it below.';
  }

  @override
  String get passwordResetOtpResent => 'A new code was sent.';

  @override
  String get passwordResetOtpNotReceivedHint =>
      'Didn\'t get the code? Check that the contact is correct — your account may be linked to a different phone or email.';

  @override
  String get passwordResetPasswordHint =>
      'Choose a new password. After saving you will be signed in automatically and other sessions will end.';

  @override
  String get passwordResetNewPasswordLabel => 'New password';

  @override
  String get passwordResetConfirmPasswordLabel => 'Confirm password';

  @override
  String get passwordResetSubmit => 'Save and sign in';

  @override
  String get passwordResetBackToLogin => '← Back to sign in';

  @override
  String get passwordResetFailed => 'Could not reset password.';

  @override
  String get signInButton => 'Sign in';

  @override
  String get noAccountRegister => 'No account? Register';

  @override
  String get loginFailed => 'Sign in failed. Try again later.';

  @override
  String get registerTitle => 'Register';

  @override
  String get registerHubEyebrow => 'Sign up';

  @override
  String get registerHubParent => 'I\'m a parent / guardian';

  @override
  String get registerHubTeacher => 'I\'m a teacher / tutor';

  @override
  String get registerHubNetworkOwner => 'I represent a school / center network';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get registerLoginLink => 'Log in';

  @override
  String get registerWizardStepContact => 'Contact';

  @override
  String get registerWizardStepOtp => 'Code';

  @override
  String get registerWizardStepProfile => 'Profile';

  @override
  String get registerContactStepTitle => 'Contact';

  @override
  String get registerOtpStepTitle => 'Code';

  @override
  String get registerProfileParentTitle => 'Parent registration';

  @override
  String get registerProfileTeacherTitle => 'Teacher registration';

  @override
  String get registerProfileNetworkTitle => 'Network owner registration';

  @override
  String get registerWizardContactChannelLabel => 'Verification method';

  @override
  String get registerWizardOtpSubmit => 'Confirm';

  @override
  String get registerWizardOtpBack => 'Change contact';

  @override
  String get passwordResetWizardStepContact => 'Contact';

  @override
  String get passwordResetWizardStepOtp => 'Code';

  @override
  String get passwordResetWizardStepPassword => 'New password';

  @override
  String get passwordResetContactStepTitle => 'Contact';

  @override
  String get passwordResetOtpStepTitle => 'Code';

  @override
  String get passwordResetPasswordStepTitle => 'New password';

  @override
  String get registerSubtitle => 'Choose account type';

  @override
  String get accountTypeParent => 'Parent';

  @override
  String get accountTypeTeacher => 'Teacher';

  @override
  String get accountTypeNetworkOwner => 'Network owner';

  @override
  String get registerTypeParentHint => 'For your child\'s home learning';

  @override
  String get registerTypeTeacherHint => 'For tutors and instructors';

  @override
  String get registerTypeNetworkOwnerHint => 'For schools and learning centers';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get registerStep1Subtitle => 'Step 1 of 3 — contact verification';

  @override
  String get phoneChannel => 'Phone';

  @override
  String get emailChannel => 'Email';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get getCodeButton => 'Get code';

  @override
  String get enterContact => 'Enter contact';

  @override
  String get otpTitle => 'Verification code';

  @override
  String otpSentTo(String contact) {
    return 'Sent to $contact';
  }

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCooldown(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get codeResent => 'Code sent again';

  @override
  String get verifyCodeFailed => 'Could not verify code.';

  @override
  String get resendFailed => 'Could not resend code.';

  @override
  String get profileTitle => 'Profile';

  @override
  String registerStep3Subtitle(String accountType) {
    return 'Step 3 of 3 — $accountType';
  }

  @override
  String get createAccountButton => 'Create account';

  @override
  String get verifyContactFirst => 'Verify your contact with a code first';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createAccountFailed => 'Could not create account.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get registerParentRelationshipLabel => 'Your role in the family';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get patronymicLabel => 'Patronymic';

  @override
  String get dateOfBirthLabel => 'Date of birth';

  @override
  String get dateOfBirthPlaceholder => 'DD.MM.YYYY';

  @override
  String get invalidDateOfBirth => 'Enter a valid date of birth';

  @override
  String get cityLabel => 'City';

  @override
  String get networkNameLabel => 'Network name';

  @override
  String get repeatPasswordLabel => 'Repeat password';

  @override
  String get loggedInTitle => 'You\'re signed in';

  @override
  String nameValue(String name) {
    return 'Name: $name';
  }

  @override
  String roleValue(String role) {
    return 'Role: $role';
  }

  @override
  String get homePlaceholder =>
      'Role dashboard (parent / teacher / network) will appear here.';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get emptyValue => '—';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get noConnection => 'No server connection. Check your internet.';

  @override
  String get requestFailed => 'Request failed.';

  @override
  String get requestError => 'Request error.';

  @override
  String get sendCodeFailed => 'Could not send code.';

  @override
  String get verifyContactFailed => 'Could not verify contact.';

  @override
  String get tokenFetchFailed => 'Could not get token.';

  @override
  String get parentChildPickerTitle => 'Who is studying today?';

  @override
  String get parentAddChild => 'Add a child';

  @override
  String get parentAccount => 'Account';

  @override
  String get parentBack => 'Back';

  @override
  String get parentStudyTitle => 'What are we studying today?';

  @override
  String get parentStudyProfileCard => 'Profile';

  @override
  String get parentStudyCoursesCard => 'LARNES courses';

  @override
  String get parentStudyRewardsCard => 'Rewards';

  @override
  String get parentRewardsTitle => 'Rewards';

  @override
  String get parentRewardsEmptyShops => 'No live shelves yet.';

  @override
  String get parentRewardsEmptyItems =>
      'Nothing to get on this shelf right now.';

  @override
  String parentRewardsBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count larcoins',
      one: '$count larcoin',
    );
    return '$_temp0';
  }

  @override
  String get parentRewardsCost => 'larcoins';

  @override
  String get parentRewardsGet => 'Get';

  @override
  String get parentRewardsGetting => 'Sending…';

  @override
  String get parentRewardsNotEnough => 'Not enough yet';

  @override
  String get parentRewardsPending => 'Waiting to be handed over';

  @override
  String get parentRewardsHandedOver => 'Handed over';

  @override
  String get parentRewardsCancelled => 'Cancelled';

  @override
  String get parentRewardsClaimsTitle => 'Requests';

  @override
  String get parentRewardsClaimed =>
      'Request sent — they will hand it over at class.';

  @override
  String get parentRewardsNoPhoto => 'No photo';

  @override
  String get parentRewardsLoadFailed => 'Could not load rewards.';

  @override
  String get parentCoursesTitle => 'Courses';

  @override
  String get parentCoursesEmpty => 'No published courses yet.';

  @override
  String get parentActivityAttendance => 'Attendance';

  @override
  String get parentActivitySchedule => 'Schedule';

  @override
  String get parentActivityScheduleEmpty => 'No lessons on this day.';

  @override
  String get parentActivitySchedulePrevDay => 'Previous day';

  @override
  String get parentActivityScheduleNextDay => 'Next day';

  @override
  String get parentActivityScheduleNotFound =>
      'Schedule is not available for this day.';

  @override
  String get parentActivityPayments => 'Payments';

  @override
  String get parentActivityPaymentsTabAccruals => 'Accruals';

  @override
  String get parentActivityPaymentsTabReceipts => 'Receipts';

  @override
  String get parentActivityPaymentsTabsLabel => 'Payment mode';

  @override
  String get parentActivityPaymentsEmptyAccruals => 'No accruals yet.';

  @override
  String get parentActivityPaymentsEmptyReceipts => 'No receipts yet.';

  @override
  String get parentActivityPaymentReceiptTitle => 'Receipt';

  @override
  String get parentActivityPaymentReceiptAccepted => 'Accepted';

  @override
  String get parentActivityPaymentReceiptGift => 'Gift';

  @override
  String get parentActivityPaymentReceiptRefund => 'Refund for missed lessons';

  @override
  String get parentActivityPaymentReceiptTotalOnAccount => 'Total on account';

  @override
  String get parentActivityPaymentAccrualTitle => 'Accrual';

  @override
  String get parentActivityPaymentAccrualHeadSuffix => 'allocated to:';

  @override
  String get parentActivityPaymentAccrualColAmount => 'Amount';

  @override
  String get parentActivityPaymentAccrualColDate => 'Date';

  @override
  String get parentActivityPaymentAccrualColTime => 'Time';

  @override
  String get parentActivityPaymentAccrualColCenter => 'Center';

  @override
  String get parentActivityPaymentAccrualColClass => 'Class';

  @override
  String get parentActivityPaymentDetailNotFound =>
      'Payment details are not available.';

  @override
  String get parentActivityComingSoon =>
      'This section is coming soon in the app.';

  @override
  String get parentActivityLoadFailed => 'Could not load activity diary.';

  @override
  String get parentActivityPlaceSummary => 'Summary';

  @override
  String get parentActivityPlaceDockLabel => 'Place filter';

  @override
  String get parentActivityAttendanceEmpty =>
      'No classes in the selected place yet.';

  @override
  String parentActivityCalendarTitle(Object name) {
    return '“$name”';
  }

  @override
  String get parentActivityCalendarNotFound =>
      'Calendar is not available for this class.';

  @override
  String get parentActivityCalendarPrevMonth => 'Previous month';

  @override
  String get parentActivityCalendarNextMonth => 'Next month';

  @override
  String get parentActivityCalendarLegendPaid => 'Paid';

  @override
  String get parentActivityCalendarLegendFirstUnpaid => 'First unpaid';

  @override
  String get parentActivityCalendarLegendUnpaid => 'Unpaid';

  @override
  String get parentActivityCalendarLegendMakeup => 'Make-up';

  @override
  String get parentActivityCalendarCodesTitle => 'Attendance codes';

  @override
  String get parentActivityCalendarCodePresent => 'present';

  @override
  String get parentActivityCalendarCodeAbsent => 'absent';

  @override
  String get parentActivityCalendarCodeSick => 'sick';

  @override
  String get parentActivityCalendarCodeExcused => 'excused';

  @override
  String get parentActivityCalendarCodeAdvanceNotice => 'advance notice';

  @override
  String get parentHomeworkTitle => 'Homework';

  @override
  String get parentHomeworkEmptyHint => 'No assignments yet';

  @override
  String parentHomeworkAssignmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments',
      one: '1 assignment',
    );
    return '$_temp0';
  }

  @override
  String get parentChildFormTitle => 'New child profile';

  @override
  String get parentChildFormLastName => 'Last name';

  @override
  String get parentChildFormFirstName => 'First name';

  @override
  String get parentChildFormPatronymic => 'Patronymic (optional)';

  @override
  String get parentChildFormDateOfBirth => 'Date of birth';

  @override
  String get parentChildFormGender => 'Gender';

  @override
  String get parentChildFormGenderMale => 'M';

  @override
  String get parentChildFormGenderFemale => 'F';

  @override
  String get parentChildFormGenderRequired => 'Select gender';

  @override
  String get parentChildFormCardColor => 'Favorite color';

  @override
  String get parentChildFormAvatar => 'Character';

  @override
  String get parentChildFormCardColorOrange => 'Orange';

  @override
  String get parentChildFormCardColorEmerald => 'Emerald';

  @override
  String get parentChildFormCardColorViolet => 'Violet';

  @override
  String get parentChildFormCardColorSky => 'Sky blue';

  @override
  String get parentChildFormCardColorRose => 'Rose';

  @override
  String get parentChildFormCardColorAmber => 'Amber';

  @override
  String get parentChildFormAvatarFox => 'Fox';

  @override
  String get parentChildFormAvatarBear => 'Bear';

  @override
  String get parentChildFormAvatarOwl => 'Owl';

  @override
  String get parentChildLegalBasisLabel => 'Legal authority basis';

  @override
  String get parentChildLegalBasisParent => 'Parent';

  @override
  String get parentChildLegalBasisAdoptiveParent => 'Adoptive parent';

  @override
  String get parentChildLegalBasisGuardian => 'Appointed guardian';

  @override
  String get parentChildLegalAuthority =>
      'I am the child\'s legal representative';

  @override
  String get parentChildLegalConsent =>
      'I consent to the processing of the child\'s data';

  @override
  String get parentChildLegalDocumentLink => 'Child Data Processing Consent';

  @override
  String get parentChildLegalRequired =>
      'Confirm your authority and accept the child data consent.';

  @override
  String get parentChildFormSubmit => 'Create child';

  @override
  String get parentChildFormAutosaveSaved => 'Saved';

  @override
  String get parentChildFormAutosaveFailed => 'Could not save';

  @override
  String get parentClassroomQrTitle => 'Classroom QR';

  @override
  String get parentClassroomQrAlt => 'Child classroom QR code';

  @override
  String parentClassroomQrVersion(int version) {
    return 'Version $version';
  }

  @override
  String get parentClassroomQrPrint => 'Print';

  @override
  String get parentClassroomQrRegenerate => 'Reissue';

  @override
  String get parentClassroomQrRevoke => 'Revoke';

  @override
  String get parentClassroomQrIssue => 'Issue QR';

  @override
  String get parentClassroomQrRevokedHint =>
      'QR revoked. Printed cards no longer work.';

  @override
  String get parentClassroomQrCancel => 'Cancel';

  @override
  String get parentClassroomQrConfirmRegenerateTitle => 'Reissue QR?';

  @override
  String get parentClassroomQrConfirmRegenerateMessage =>
      'The old QR will stop working. You will need to print a new one.';

  @override
  String get parentClassroomQrConfirmRevokeTitle => 'Revoke QR?';

  @override
  String get parentClassroomQrConfirmRevokeMessage =>
      'Sign-in with the current QR will be blocked until you issue a new one.';

  @override
  String get parentLoadChildrenFailed => 'Could not load children.';

  @override
  String get parentCreateChildFailed => 'Could not create profile.';

  @override
  String get parentHomeworkSoon => 'Homework list — coming in the next step.';

  @override
  String get parentHomeworkLoadFailed => 'Could not load homework.';

  @override
  String parentHomeworkListTitle(String name) {
    return 'Homework $name';
  }

  @override
  String get parentHomeworkBack => 'Back';

  @override
  String get parentHomeworkSentAt => 'Sent';

  @override
  String get parentHomeworkDeadline => 'Deadline';

  @override
  String get parentHomeworkNoDeadline => 'Not set';

  @override
  String get parentHomeworkProgress => 'Progress';

  @override
  String parentHomeworkProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String get parentHomeworkPlaySoon =>
      'Assignment player — coming in the next step.';

  @override
  String get parentHomeworkPlayLoadFailed => 'Could not load assignment.';

  @override
  String get parentHomeworkPlayAdvanceFailed => 'Could not save progress.';

  @override
  String parentHomeworkPlayProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get parentHomeworkPlayNext => 'Next';

  @override
  String get parentHomeworkPlayFinish => 'Finish';

  @override
  String get parentHomeworkPlayCompletedTitle => 'Homework completed';

  @override
  String get parentHomeworkPlayBackToList => 'Back to homework list';

  @override
  String get parentHomeworkPlayExit => 'Exit';

  @override
  String get parentHomeworkPlayMenuContinue => 'Continue lesson';

  @override
  String get parentHomeworkPlayEmpty => 'This assignment has no trainers yet.';

  @override
  String parentHomeworkPlayStepLabel(int step) {
    return 'Step $step';
  }

  @override
  String get parentHomeworkPlayTrainerSoon =>
      'Trainer — coming in the next update.';

  @override
  String get parentHomeworkPlayInteractiveHint => 'Complete the task on screen';

  @override
  String get parentHomeworkEmptyDue => 'No assignments to do right now.';

  @override
  String get parentHomeworkEmptyCompleted => 'No completed assignments yet.';

  @override
  String get parentHomeworkEmptyOverdue => 'No overdue assignments.';

  @override
  String get parentHomeworkEmptyUpcoming => 'No upcoming assignments.';

  @override
  String parentHomeworkTabDue(int count) {
    return 'Due ($count)';
  }

  @override
  String parentHomeworkTabCompleted(int count) {
    return 'Completed ($count)';
  }

  @override
  String parentHomeworkTabOverdue(int count) {
    return 'Overdue ($count)';
  }

  @override
  String parentHomeworkTabUpcoming(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String get parentHomeworkStatusAssigned => 'Not started';

  @override
  String get parentHomeworkStatusInProgress => 'In progress';

  @override
  String get parentHomeworkStatusCompleted => 'Completed';

  @override
  String get parentHomeworkStatusOverdue => 'Overdue';

  @override
  String get parentAccountTitle => 'Account';

  @override
  String get adminNavTrainers => 'Trainers';

  @override
  String get adminNavAccount => 'Account';

  @override
  String get adminTrainersTitle => 'Trainers';

  @override
  String get adminTrainersHint =>
      'Catalog for manual trainer checks before programs and homework.';

  @override
  String get adminTrainersLoadFailed => 'Could not load catalog.';

  @override
  String get adminTrainersOpen => 'Open';

  @override
  String get adminTrainersDirectionMental => 'Mental arithmetic';

  @override
  String get adminTrainersDirectionMath => 'Math';

  @override
  String get adminTrainersDirectionReading => 'Reading';

  @override
  String get adminTrainersPublicationInDevelopment => 'In development';

  @override
  String get adminTrainersPublicationReadyToPublish => 'Ready to publish';

  @override
  String get adminTrainersPublicationPublished => 'Published';

  @override
  String adminTrainersGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# trainers',
      one: '# trainer',
    );
    return '$_temp0';
  }

  @override
  String get adminTrainerPlayLoadFailed => 'Could not load parameters.';

  @override
  String get adminTrainerPlayLaunch => 'LAUNCH';

  @override
  String get adminTrainerPlayInteractiveHint =>
      'Interactive trainers finish when the child completes the task.';

  @override
  String get adminTrainerPlayLetterCaseLabel => 'Letter case';

  @override
  String get adminTrainerPlayWordCaseLabel => 'Word case';

  @override
  String get adminTrainerPlayLetterLabel => 'Letter';

  @override
  String get adminTrainerPlayPracticeLettersLabel => 'Practice letters';

  @override
  String get adminTrainerPlayShopItemLabel => 'Item';

  @override
  String get adminTrainerPlayPriceLabel => 'Price';

  @override
  String get adminTrainerPlayCoinCountLabel => 'Coins in register';

  @override
  String get adminTrainerPlayWholeLabel => 'Whole';

  @override
  String get adminTrainerPlayKnownPartLabel => 'Known part';

  @override
  String get adminTrainerPlayAnswerRangeStartLabel => 'Answer range start';

  @override
  String get adminTrainerPlayTargetFruitLabel => 'Target fruit';

  @override
  String get adminTrainerPlayFruitTargetCountLabel => 'Target count';

  @override
  String get adminTrainerPlayFruitTypeCountLabel => 'Fruit types';

  @override
  String get adminTrainerPlayTotalFruitsLabel => 'Total fruits';

  @override
  String get adminTrainerPlayDigitLabel => 'Digit';

  @override
  String get adminTrainerPlayTargetCountLabel => 'How many to find';

  @override
  String get adminTrainerPlayDistractorCountLabel => 'Distractors';

  @override
  String get adminTrainerPlayMissingSegmentLabel => 'Missing segment';

  @override
  String get adminTrainerPlayLetterCountLabel => 'Letter count';

  @override
  String get adminTrainerPlayOddLetterLabel => 'Odd letter (random or letter)';

  @override
  String get adminTrainerPlayOptionCountLabel => 'Option count';

  @override
  String get adminTrainerPlayDotModeLabel => 'Dot mode';

  @override
  String get adminTrainerPlayRoundsLabel => 'Rounds';

  @override
  String get adminTrainerPlayDisplaySecondsLabel => 'Display seconds';

  @override
  String get adminTrainerPlayGridSizeLabel => 'Grid size';

  @override
  String get adminTrainerPlayStepCountLabel => 'Number of steps';

  @override
  String get adminTrainerPlayFilledCountLabel => 'Filled cells';

  @override
  String get adminTrainerPlayWordSlugLabel => 'Word';

  @override
  String get adminTrainerPlayEntityCountLabel => 'Word count';

  @override
  String get adminTrainerPlayPairCountLabel => 'Pairs';

  @override
  String get adminTrainerPlayCatchCountLabel => 'Catch count';

  @override
  String get adminTrainerPlaySpeedLabel => 'Speed';

  @override
  String get adminTrainerPlayWordItemCountLabel => 'Words in task';

  @override
  String get adminTrainerPlayTotalRodsLabel => 'Rods';

  @override
  String get adminTrainerPlayStepPauseSecLabel => 'Pause (sec)';

  @override
  String get adminTrainerPlayExampleStringLabel => 'Example';

  @override
  String get adminTrainerPlayChainTopicIdLabel => 'Chain topic';

  @override
  String get adminTrainerPlaySolveModeLabel => 'Solve mode';

  @override
  String get adminTrainerPlaySolveModeAbacus => 'On abacus';

  @override
  String get adminTrainerPlaySolveModeMental => 'Mentally';

  @override
  String get adminTrainerPlayActionCountLabel => 'Number of actions';

  @override
  String get adminTrainerPlayExampleCountLabel => 'Number of examples';

  @override
  String get adminTrainerPlaySignModeLabel => 'Signs';

  @override
  String get adminTrainerPlayAmountScopeLabel => 'Operands';

  @override
  String get adminTrainerPlayValueLabel => 'Value';

  @override
  String get adminTrainerPlayMatchValue1Label => 'Value 1';

  @override
  String get adminTrainerPlayMatchValue2Label => 'Value 2';

  @override
  String get adminTrainerPlayMatchValue3Label => 'Value 3';

  @override
  String get adminTrainerPlayMatchValue4Label => 'Value 4';

  @override
  String get adminTrainerPlayLetterCaseUpper => 'Uppercase';

  @override
  String get adminTrainerPlayLetterCaseLower => 'Lowercase';

  @override
  String get adminTrainerPlayMissingSegmentRandom => 'Random';

  @override
  String get adminTrainerPlayMissingSegmentIndex1 => 'Segment 1';

  @override
  String get adminTrainerPlayMissingSegmentIndex2 => 'Segment 2';

  @override
  String get adminTrainerPlayMissingSegmentIndex3 => 'Segment 3';

  @override
  String get adminTrainerPlayMissingSegmentIndex4 => 'Segment 4';

  @override
  String get adminTrainerPlayDotModeNumbered => 'Numbered';

  @override
  String get adminTrainerPlayDotModeFree => 'Free';

  @override
  String get adminTrainerPlaySpeedSlow => 'Slow';

  @override
  String get adminTrainerPlaySpeedMedium => 'Medium';

  @override
  String get adminTrainerPlaySpeedFast => 'Fast';

  @override
  String get adminTrainerPlayMobileHint =>
      'Runs in the mobile runtime (Flutter). Check the web version on desktop.';

  @override
  String get adminTrainerPlayWebOnlyTitle => 'No mobile implementation';

  @override
  String get adminTrainerPlayWebOnlyMessage =>
      'This trainer is web-only for now. Run and test play at larnes.ru under Trainers.';

  @override
  String get adminTrainerPlayExit => 'Back';

  @override
  String get adminTrainerPlayMenuContinue => 'Continue check';

  @override
  String get adminTrainerPlayFinish => 'Done';

  @override
  String get adminTrainerPlayNext => 'Next';

  @override
  String get adminTrainerPlayContinueCheck => 'Continue check';

  @override
  String get adminAccountTitle => 'Account';

  @override
  String get adminAccountLoadFailed => 'Could not load account.';

  @override
  String get adminAccountSaveFailed => 'Could not save changes.';

  @override
  String get adminAccountNotSet => 'Not set';

  @override
  String get adminAccountSectionProfile => 'Profile';

  @override
  String get adminAccountSectionContacts => 'Contacts';

  @override
  String get adminAccountSectionSecurity => 'Security';

  @override
  String get adminAccountSectionLanguage => 'Language';

  @override
  String get adminAccountProfileTitle => 'Change name';

  @override
  String get adminAccountLoginTitle => 'Change login';

  @override
  String get adminAccountPasswordTitle => 'Change password';

  @override
  String get adminAccountPhoneTitle => 'Change phone';

  @override
  String get adminAccountEmailTitle => 'Change email';

  @override
  String get adminAccountSave => 'Save';

  @override
  String get adminAccountSaveLogin => 'Save login';

  @override
  String get adminAccountSavePassword => 'Save password';

  @override
  String get adminAccountActionLogoutAll => 'Sign out on all devices';

  @override
  String get parentAccountBackToPicker => 'Back';

  @override
  String get parentAccountBackToAccount => 'Back to account';

  @override
  String get parentAccountNotSet => 'Not set';

  @override
  String get parentAccountLoadFailed => 'Could not load account.';

  @override
  String get parentAccountSaveFailed => 'Could not save changes.';

  @override
  String get parentAccountSave => 'Save';

  @override
  String get parentAccountSaveCity => 'Save city';

  @override
  String get parentAccountSaveLogin => 'Save login';

  @override
  String get parentAccountSavePassword => 'Save password';

  @override
  String get parentAccountCancel => 'Cancel';

  @override
  String get parentAccountSectionProfile => 'Parent profile';

  @override
  String get parentAccountSectionChildren => 'Your children';

  @override
  String get parentAccountSectionCity => 'City';

  @override
  String get parentAccountSectionContacts => 'Contacts';

  @override
  String get parentAccountSectionSecurity => 'Security';

  @override
  String get parentAccountSectionLanguage => 'Language';

  @override
  String get parentAccountSectionFamily => 'Family';

  @override
  String get parentAccountFieldGuardians => 'Guardians';

  @override
  String get parentAccountActionManageGuardians => 'Manage guardians';

  @override
  String get parentFamilySetupGateTitle => 'Is your family already on LARNES?';

  @override
  String get parentFamilySetupContinueAction => 'Set up family';

  @override
  String get parentFamilySetupGateLead =>
      'If a family member already uses the platform, ask them to accept you. Or create your family and add children.';

  @override
  String get parentFamilySetupAnswerNo => 'No, create my family';

  @override
  String get parentFamilySetupAnswerYes => 'Yes, family is already here';

  @override
  String get parentFamilySetupWaitingTitle => 'Waiting for confirmation';

  @override
  String get parentFamilySetupWaitingLead =>
      'Send the link to a family member who already uses LARNES.';

  @override
  String get parentFamilySetupShareLinkLabel => 'Link for your relative';

  @override
  String get parentFamilySetupCopyLink => 'Copy link';

  @override
  String get parentFamilySetupShowLink => 'Show link';

  @override
  String get parentFamilySetupHideLink => 'Hide link';

  @override
  String get parentFamilySetupCopySuccess => 'Link copied';

  @override
  String get parentFamilySetupCopyFailed => 'Could not copy';

  @override
  String get parentFamilySetupShare => 'Share';

  @override
  String get parentFamilySetupCancelJoin => 'I was wrong — create my family';

  @override
  String get parentFamilySetupDisplayNameLabel => 'Family name';

  @override
  String get parentFamilySetupDisplayNameHint =>
      'Schools will see this name. Example: The Ivanovs.';

  @override
  String get parentFamilySetupDisplayNamePlaceholder => 'The Ivanovs';

  @override
  String get parentFamilySetupDisplayNameRequired => 'Enter a family name';

  @override
  String get parentFamilySetupSoloNameTitle =>
      'What should we call your family?';

  @override
  String get parentFamilySetupCreateSolo => 'Create family';

  @override
  String get parentFamilySetupBack => 'Back';

  @override
  String get parentFamilySetupResolveProfiles => 'Resolve child profiles';

  @override
  String parentFamilyJoinDedupChoiceTitle(String name) {
    return 'Children named «$name»';
  }

  @override
  String get parentFamilyJoinDedupChoiceLead =>
      'If this is the same child, pick one profile to keep. The other will be removed from the family cabinet.';

  @override
  String get parentFamilyJoinDedupDifferentChildren => 'Different children';

  @override
  String get parentFamilyJoinDedupSameChild => 'Same child';

  @override
  String get parentFamilyJoinDedupPickTitle => 'Same child — pick a profile';

  @override
  String get parentFamilyJoinDedupPickLead =>
      'Which profile should stay? The other will be removed from the cabinet.';

  @override
  String get parentFamilyJoinDedupRegisteredLabel => 'Registered';

  @override
  String get parentFamilyJoinDedupNetworkLabel => 'Network / group';

  @override
  String get parentFamilyJoinDedupProgramLabel => 'Program';

  @override
  String get parentFamilyJoinDedupKeepProfile => 'Keep this profile';

  @override
  String get parentFamilyJoinDedupBack => 'Back';

  @override
  String get parentFamilyJoinDedupInvalidTitle => 'Nothing to resolve';

  @override
  String get parentFamilyJoinDedupInvalidLead =>
      'The link expired or profiles were already reconciled.';

  @override
  String get parentGuardiansTitle => 'Guardians';

  @override
  String get parentGuardiansSectionTitle => 'Family';

  @override
  String get parentGuardiansEmpty => 'Just you for now.';

  @override
  String get parentGuardiansYou => 'you';

  @override
  String get parentGuardiansInviteGuardian => 'Invite guardian';

  @override
  String get parentGuardiansInviteFamilyMember => 'Invite a family member';

  @override
  String get parentGuardiansInviteCopied => 'Link copied';

  @override
  String get parentGuardiansInviteCreated => 'Invitation created';

  @override
  String get parentGuardiansPendingInvitesTitle => 'Pending invitations';

  @override
  String get parentGuardiansPendingInviteLabel => 'Invitation';

  @override
  String get parentGuardiansPendingInviteStatus => 'Awaiting acceptance';

  @override
  String get parentGuardiansConfirmRevokeTitle => 'Revoke invitation?';

  @override
  String get parentGuardiansConfirmRevokeMessage =>
      'The link will stop working.';

  @override
  String get parentGuardiansRevokeInvite => 'Revoke';

  @override
  String get parentGuardiansRemove => 'Remove';

  @override
  String get parentGuardiansLeaveFamily => 'Leave family';

  @override
  String get parentGuardiansConfirmRemoveTitle => 'Remove guardian?';

  @override
  String get parentGuardiansConfirmRemoveMessage =>
      'They will lose access to this family\'s children and get a separate account.';

  @override
  String get parentGuardiansConfirmLeaveTitle => 'Leave family?';

  @override
  String get parentGuardiansConfirmLeaveMessage =>
      'You will lose access to this family\'s children and get a separate account.';

  @override
  String get parentGuardiansRelationshipMother => 'Mother';

  @override
  String get parentGuardiansRelationshipFather => 'Father';

  @override
  String get parentGuardiansRelationshipGrandmother => 'Grandmother';

  @override
  String get parentGuardiansRelationshipGrandfather => 'Grandfather';

  @override
  String get inviteInvalid => 'Invitation not found or expired.';

  @override
  String get inviteInvalidTitle => 'Invalid invitation';

  @override
  String get inviteFamilyJoinRequestTitle => 'Family join request';

  @override
  String get inviteFamilyJoinRequestSubtitle =>
      'Accept this guardian into your family — they will see shared children.';

  @override
  String get inviteFamilyJoinRequestRequesterLabel => 'Requested by';

  @override
  String get inviteFamilyJoinRequestAccept => 'Accept';

  @override
  String get inviteFamilyJoinRequestDecline => 'Decline';

  @override
  String get inviteFamilyJoinRequestLoginTitle => 'Sign in required';

  @override
  String get inviteFamilyJoinRequestLoginSubtitle =>
      'Sign in as a guardian to accept the family join request.';

  @override
  String get inviteFamilyJoinRequestRegister => 'Guardian registration';

  @override
  String get inviteFamilyJoinRequestWrongAccountTitle => 'Wrong account type';

  @override
  String get inviteFamilyJoinRequestWrongAccountSubtitle =>
      'Only a guardian can accept this request.';

  @override
  String get inviteFamilyJoinRequestOwnRequestTitle => 'This is your request';

  @override
  String get inviteFamilyJoinRequestOwnRequestSubtitle =>
      'Share this link with another guardian in your family on LARNES.';

  @override
  String get inviteFamilyGuardianTitle => 'Family invitation';

  @override
  String get inviteFamilyGuardianSubtitle =>
      'Accept the invitation to access the family\'s children.';

  @override
  String get inviteFamilyGuardianInviterLabel => 'Invited by';

  @override
  String get inviteFamilyGuardianAccept => 'Accept';

  @override
  String get inviteFamilyGuardianDecline => 'Decline';

  @override
  String get inviteFamilyGuardianLoginTitle => 'Sign in required';

  @override
  String get inviteFamilyGuardianLoginSubtitle =>
      'Sign in or register as a guardian to accept the invitation.';

  @override
  String get inviteFamilyGuardianRegister => 'Guardian registration';

  @override
  String get inviteFamilyGuardianWrongAccountTitle => 'Wrong account type';

  @override
  String get inviteFamilyGuardianWrongAccountSubtitle =>
      'Only a guardian can accept this invitation.';

  @override
  String get parentAccountFieldFullName => 'Full name';

  @override
  String get parentAccountFieldDateOfBirth => 'Date of birth';

  @override
  String get parentAccountFieldRelationship => 'Role';

  @override
  String get parentAccountFieldChildren => 'Profiles';

  @override
  String get parentAccountFieldCity => 'City';

  @override
  String get parentAccountFieldLogin => 'Login';

  @override
  String get parentAccountActionChangeProfile => 'Change name';

  @override
  String get parentAccountActionChangeDateOfBirth => 'Change date of birth';

  @override
  String get parentAccountActionManageChildren => 'Manage children';

  @override
  String get parentAccountActionChangeCity => 'Change city';

  @override
  String get parentAccountActionChangePhone => 'Change phone';

  @override
  String get parentAccountActionChangeEmail => 'Change email';

  @override
  String get parentAccountActionChangeLogin => 'Change login';

  @override
  String get parentAccountActionChangePassword => 'Change password';

  @override
  String get parentAccountActionLogoutAll => 'Sign out on all devices';

  @override
  String parentAccountChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get parentAccountCityNotSet => 'City not set';

  @override
  String get parentAccountDateOfBirthNotSet => 'Date of birth not set';

  @override
  String get parentAccountContactVerified => 'Verified';

  @override
  String get parentAccountContactNotVerified => 'Not verified';

  @override
  String get parentAccountContactChangeSoon =>
      'Contact change — coming in the next step.';

  @override
  String get parentAccountProfileTitle => 'Change name';

  @override
  String get parentAccountDateOfBirthTitle => 'Change date of birth';

  @override
  String get parentAccountCityTitle => 'Change city';

  @override
  String get parentAccountRelationshipTitle => 'Change role';

  @override
  String get parentAccountSaveRelationship => 'Save';

  @override
  String get parentAccountLoginTitle => 'Change login';

  @override
  String get parentAccountPhoneTitle => 'Change phone';

  @override
  String get parentAccountEmailTitle => 'Change email';

  @override
  String get parentAccountNewPhone => 'New phone';

  @override
  String get parentAccountNewEmail => 'New email';

  @override
  String get parentAccountSendCode => 'Get code';

  @override
  String get parentAccountVerifyContact => 'Confirm';

  @override
  String get parentAccountPasswordTitle => 'Change password';

  @override
  String get parentAccountCurrentPassword => 'Current password';

  @override
  String get parentAccountNewLogin => 'New login';

  @override
  String get parentAccountConfirmNewLogin => 'Confirm new login';

  @override
  String get parentAccountNewPassword => 'New password';

  @override
  String get parentAccountConfirmNewPassword => 'Confirm new password';

  @override
  String get parentAccountLogoutAllTitle => 'Sign out on all devices?';

  @override
  String get parentAccountLogoutAllMessage =>
      'All active sessions will end. You will need to sign in again.';

  @override
  String get parentAccountLogoutAllConfirm => 'Sign out everywhere';

  @override
  String get parentAccountChildrenTitle => 'Children';

  @override
  String get parentAccountChildrenProfiles => 'Profiles';

  @override
  String get parentAccountChildrenArchiveTitle => 'Archived children';

  @override
  String get parentAccountChildrenArchiveHint =>
      'Connections are closed. School and teacher access must be granted again after restoration.';

  @override
  String get parentAccountChildrenRestore => 'Restore profile';

  @override
  String get parentAccountChildrenActions => 'Actions';

  @override
  String get parentAccountChildrenEmpty => 'No children added yet.';

  @override
  String get parentAccountChildrenBackToList => 'Back to list';

  @override
  String get parentAccountChildSummary => 'Profile';

  @override
  String get parentAccountChildAge => 'Age';

  @override
  String get parentAccountEditChildProfile => 'Edit profile';

  @override
  String get parentChildEducationTitle => 'Learning';

  @override
  String get parentChildEducationEmpty => 'No teachers or networks linked yet.';

  @override
  String get parentChildTutorSection => 'Tutor';

  @override
  String get parentChildTeacherLabel => 'Teacher';

  @override
  String get parentChildGroupsLabel => 'Groups';

  @override
  String get parentChildGroupLabel => 'Group';

  @override
  String get parentChildTutorNoGroups => 'Not added to any groups yet.';

  @override
  String parentChildNetworkSection(String name) {
    return 'Network \"$name\"';
  }

  @override
  String get parentChildNetworkNoGroups =>
      'Enrolled in network; no group assigned yet.';

  @override
  String parentChildResponsibleTeacher(String name) {
    return 'Teacher: $name';
  }

  @override
  String get parentChildTeacherNotAssigned =>
      'No responsible teacher assigned.';

  @override
  String get parentAccountEditChild => 'Edit profile';

  @override
  String get parentAccountEditChildTitle => 'Edit profile';

  @override
  String get parentAccountChildBackToProfile => 'Back to profile';

  @override
  String get parentAccountDeleteChildTitle => 'Archive this child profile?';

  @override
  String get parentAccountDeleteChildMessage =>
      'The profile will leave the active list and can be restored later.';

  @override
  String get parentAccountDeleteChildMessageActiveNetwork =>
      'The profile will leave the active list; connections will end; learning and payment history will be kept. The profile can be restored later.';

  @override
  String get parentAccountDeleteChildConfirm => 'Archive profile';

  @override
  String get parentUpdateChildFailed => 'Could not update child profile.';

  @override
  String get parentDeleteChildFailed => 'Could not delete child profile.';

  @override
  String get parentProgramLoadFailed => 'Could not load programs.';

  @override
  String get parentDirectionLoadFailed => 'Could not load directions.';

  @override
  String parentLearningDirectionProgramCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# programs',
      one: '# program',
    );
    return '$_temp0';
  }

  @override
  String get parentDirectionProgramsBack => 'Back to study';

  @override
  String get parentDirectionProgramsEmpty =>
      'No published programs in this direction yet.';

  @override
  String get parentProgramTrackCompleted => 'Direction completed';

  @override
  String get parentProgramDirectionStart => 'Start';

  @override
  String get parentProgramDirectionContinue => 'Continue';

  @override
  String get parentProgramDirectionCompleted => 'Completed';

  @override
  String get parentProgramStatusInProgress => 'In progress';

  @override
  String get parentProgramStatusCompleted => 'Completed';

  @override
  String get parentProgramPlayLoadFailed => 'Could not load program.';

  @override
  String get parentProgramPlayCompleteFailed => 'Could not save progress.';

  @override
  String parentProgramPlayLessonProgress(
    int topic,
    int lesson,
    int current,
    int total,
  ) {
    return 'Topic $topic · Lesson $lesson · step $current of $total';
  }

  @override
  String get parentProgramPlayNext => 'Next';

  @override
  String get parentProgramPlayFinish => 'Finish';

  @override
  String get parentProgramPlayCompletedTitle => 'Program completed';

  @override
  String get parentProgramPlayBackToHub => 'Back to study';

  @override
  String get parentProgramPlayExit => 'Exit';

  @override
  String get parentProgramPlayMenuContinue => 'Continue lesson';

  @override
  String get parentProgramPlayEmptyProgram =>
      'This program has no trainers to play yet.';

  @override
  String parentProgramPlayEmptyLesson(int topic, int lesson) {
    return 'Lesson $lesson in topic $topic has no trainers yet. Ask your teacher to add tasks.';
  }

  @override
  String get parentProgramPlayInteractiveHint => 'Complete the task on screen';

  @override
  String get networkCentersTitle => 'My centers';

  @override
  String get networkCentersSectionTitle => 'Your centers';

  @override
  String get networkDevicesTitle => 'Network devices';

  @override
  String get networkDevicesHint =>
      'Network devices. Classroom and slot show current placement.';

  @override
  String get networkCentersEmptyTitle => 'You do not have any centers yet';

  @override
  String get networkCentersEmptyDescription =>
      'Create centers in the web network panel.';

  @override
  String get networkDevicesEmpty =>
      'No devices yet. They appear after enrolling a device.';

  @override
  String get networkLoadFailed => 'Could not load network data.';

  @override
  String get networkDeviceOnline => 'Online';

  @override
  String get networkDeviceOffline => 'Offline';

  @override
  String get networkDeviceUnassigned => 'Unassigned';

  @override
  String get networkDeviceKindTablet => 'Tablet';

  @override
  String get networkDeviceKindLaptop => 'Laptop';

  @override
  String get networkDeviceKindPhone => 'Phone';

  @override
  String networkDeviceSlotValue(String slot) {
    return 'Slot $slot';
  }

  @override
  String get kioskRegistrationTitle => 'Device not registered';

  @override
  String get kioskRegistrationEyebrow => 'Connect this device';

  @override
  String get kioskRegistrationSubtitle =>
      'Sign in with the one-time access from the network panel.';

  @override
  String get kioskRegistrationSignIn => 'Sign in';

  @override
  String get kioskRegistrationStep1 =>
      'In the network panel → Devices, issue one-time access.';

  @override
  String get kioskRegistrationStep2 =>
      'On the sign-in screen, enter the dev-* login and password from the panel.';

  @override
  String get kioskIdleTitle => 'Lesson not started';

  @override
  String get kioskIdleEyebrow => 'Device ready';

  @override
  String get kioskIdleSubtitle =>
      'The teacher will start the lesson. Then hold the child\'s QR code up to this device.';

  @override
  String get kioskIdleSettings => 'Settings';

  @override
  String get kioskIdlePlacementLabel => 'Placement';

  @override
  String get kioskIdleWaiting => 'Waiting for the lesson to start';

  @override
  String get kioskUnplacedTitle => 'No seat assigned';

  @override
  String get kioskUnplacedEyebrow => 'Device setup';

  @override
  String get kioskUnplacedSubtitle =>
      'Assign this device to a seat in a classroom — then QR scanning will unlock.';

  @override
  String get kioskUnplacedStep1 => 'Open the network panel → Devices.';

  @override
  String get kioskUnplacedStep2 =>
      'Select this device and choose a classroom seat.';

  @override
  String get kioskUnplacedStep3 =>
      'This screen refreshes automatically — QR and lessons will unlock.';

  @override
  String get kioskUnplacedWaiting => 'Waiting for assignment';

  @override
  String get kioskUnplacedSettings => 'Settings';

  @override
  String get kioskScanTitle => 'Show your QR code';

  @override
  String get kioskScanSubtitle => 'Hold the code up to this device.';

  @override
  String get kioskScanEnableCamera => 'Enable camera';

  @override
  String get kioskScanEnableCameraHint =>
      'Tap the button and allow camera access when prompted.';

  @override
  String get kioskScanRetryCamera => 'Try again';

  @override
  String get kioskScanSwitchCamera => 'Switch camera';

  @override
  String get kioskScanStartingCamera => 'Starting camera…';

  @override
  String get kioskScanProcessing => 'Checking the code…';

  @override
  String get kioskScanCameraDenied => 'Camera access was denied.';

  @override
  String get kioskScanCameraDeniedHint =>
      'Allow camera access in system settings, or tap Try again.';

  @override
  String get kioskScanErrorCamera =>
      'Could not start the camera. Please try again.';

  @override
  String get kioskScanErrorGeneric =>
      'Could not process the QR code. Please try again.';

  @override
  String get kioskScanErrorForbidden =>
      'Scanning is not available on this device.';

  @override
  String get kioskScanErrorInvalidToken => 'The QR code is invalid or expired.';

  @override
  String get kioskScanErrorLessonInactive =>
      'The lesson has not started yet or has already ended.';

  @override
  String get kioskScanErrorNetwork =>
      'No connection to the server. Check your internet.';

  @override
  String get kioskScanErrorNotInGroup =>
      'This child is not enrolled in the lesson group.';

  @override
  String get kioskScanErrorRateLimited => 'Too many attempts. Wait a minute.';

  @override
  String get kioskScanErrorRevoked =>
      'The QR code was revoked. Ask the parent to refresh it.';

  @override
  String get kioskScanCameraSoon =>
      'Camera support is coming in the next update.';

  @override
  String get kioskResultTitle => 'Child checked in';

  @override
  String get kioskResultProgramAssigned => 'Program assigned';

  @override
  String get kioskResultNoProgram =>
      'No program is available for this child yet.';

  @override
  String get kioskTrainerCompletedTitle => 'Activity complete';

  @override
  String get kioskTrainerCompletedBack => 'Back to lesson';

  @override
  String get kioskTrainerProcessing => 'Starting trainer…';

  @override
  String get kioskSettingsTitle => 'Device settings';

  @override
  String get kioskSettingsBack => 'Back';

  @override
  String get kioskSettingsPlacement => 'Placement';

  @override
  String get kioskSettingsDeviceId => 'Device ID';

  @override
  String get kioskSettingsUnbindTitle => 'Sign out device';

  @override
  String get kioskSettingsUnbindHint =>
      'The device will be removed from the network. To use it again, register with a new access code from the network panel.';

  @override
  String get kioskSettingsUnbindSubmit => 'Sign out';

  @override
  String get kioskSettingsUnbinding => 'Signing out…';

  @override
  String get kioskSettingsUnbindConfirmTitle =>
      'Sign out and remove this device from the network?';

  @override
  String get kioskSettingsUnbindConfirmMessage =>
      'The device will disappear from the network list. Get a new access code in the network panel to use kiosk again.';

  @override
  String get kioskSettingsUnbindCancel => 'Cancel';

  @override
  String get kioskSettingsUnbindConfirm => 'Sign out';

  @override
  String get kioskSettingsLoginRequired =>
      'Sign in again to unbind this device.';

  @override
  String get networkAddDevice => 'Add device';

  @override
  String get kioskEnrollTitle => 'Device enrollment';

  @override
  String get kioskEnrollSubtitle =>
      'Enter the access code and password from the network panel.';

  @override
  String get kioskEnrollAccessCodeLabel => 'Access code';

  @override
  String get kioskEnrollFailed =>
      'Could not enroll this device. Check the access code and password.';

  @override
  String get kioskEnrollSubmit => 'Enroll device';

  @override
  String get kioskEnrollSubmitting => 'Enrolling…';

  @override
  String get optionalPatronymicLabel => 'Patronymic (optional)';

  @override
  String get registrationOwnerEmailUnverifiedHint =>
      'The email will be saved as unverified. Verify it in account settings after registration.';

  @override
  String get optionalDateOfBirthLabel => 'Date of birth (optional)';

  @override
  String get optionalCityLabel => 'City (optional)';

  @override
  String get placesAutocompleteUnavailable =>
      'Location search is temporarily unavailable.';

  @override
  String get placesAutocompleteInvalidSelection =>
      'Could not confirm the place. Choose an item from the list again.';

  @override
  String get notSpecifiedLabel => 'Not specified';

  @override
  String get registrationTermsRequired =>
      'Accept the current Terms to create an account.';

  @override
  String get registrationTermsLink => 'Terms of Service';

  @override
  String get registrationPrivacyLink => 'Personal Data Policy';

  @override
  String get registrationTermsParent => 'I accept the Terms of Service.';

  @override
  String get registrationTermsTeacher => 'I accept the Terms of Service.';

  @override
  String get registrationTermsNetworkOwner => 'I accept the Terms of Service.';

  @override
  String get voluntaryConsentTitle => 'Separate consent for optional data';

  @override
  String get voluntaryConsentParentFields =>
      'Covers only patronymic, city, and date of birth. Core account functions do not depend on it.';

  @override
  String get voluntaryConsentParentCheckbox =>
      'I consent to processing my patronymic, city, and date of birth for maintaining my private extended profile.';

  @override
  String voluntaryConsentOpenVersion(String version) {
    return 'Open version $version';
  }

  @override
  String get voluntaryConsentVersionMissing =>
      'The published consent version is unavailable.';

  @override
  String get voluntaryConsentRequired =>
      'Confirm the separate consent to save a non-empty optional field.';

  @override
  String get voluntaryConsentRevokeTitle => 'Withdraw profile data consent';

  @override
  String get voluntaryConsentRevokeDescription =>
      'Patronymic, city, and date of birth will be permanently erased. The core account will continue to work.';

  @override
  String get voluntaryConsentRevokeConfirm =>
      'I confirm withdrawal and data erasure';

  @override
  String get voluntaryConsentRevokeButton => 'Withdraw and erase';

  @override
  String get voluntaryConsentRevokeSuccess =>
      'Consent was withdrawn and the data was erased.';

  @override
  String get voluntaryConsentRevokeFailed =>
      'Consent could not be withdrawn. No data was erased.';

  @override
  String inviteFamilyAdultClaimTitle(String school) {
    return 'School «$school» invites you to the LARNES ecosystem';
  }

  @override
  String get inviteFamilyAdultClaimTitleShort => 'School invitation';

  @override
  String get inviteFamilyAdultClaimSubtitle =>
      'Accept the invitation, confirm your identity, then fill in the required details';

  @override
  String get inviteFamilyAdultClaimAccept => 'Accept invitation';

  @override
  String get inviteFamilyAdultClaimDecline => 'Decline';

  @override
  String get inviteFamilyAdultClaimWrongAccountTitle => 'Wrong account';

  @override
  String get inviteFamilyAdultClaimWrongAccountSubtitle =>
      'Sign in with the same phone or email as in the invitation, or sign out and register.';

  @override
  String get inviteFamilyAdultClaimContactLabel => 'Contact';

  @override
  String get inviteFamilyAdultClaimContactNotVerified =>
      'Confirm the contact with the code first';

  @override
  String get inviteFamilyAdultClaimOtpTitle => 'Confirm your identity';

  @override
  String get inviteFamilyAdultClaimOtpSentTo => 'Enter the code we sent to';

  @override
  String get inviteFamilyAdultClaimOtpSubmit => 'Confirm';

  @override
  String get inviteFamilyAdultClaimOtpResend => 'Send code again';

  @override
  String inviteFamilyAdultClaimOtpResendIn(int seconds) {
    return 'Resend available in ${seconds}s';
  }

  @override
  String get inviteFamilyAdultClaimProfileTitle => 'Parent details';

  @override
  String get inviteFamilyAdultClaimProfileHint =>
      'Check the details and set a password. You will confirm children on the next step.';

  @override
  String get inviteFamilyAdultClaimProfileSubmit => 'Create account';

  @override
  String get inviteFamilyAdultClaimLoggedInTitle => 'Accept with this account';

  @override
  String get inviteFamilyAdultClaimLoggedInSubtitle =>
      'The contact matches your account. After accepting you will confirm the children’s details.';

  @override
  String get inviteFamilyAdultClaimLoggedInSubmit => 'Accept family';

  @override
  String get parentConfirmFamilyChildrenTitle => 'Confirm children';

  @override
  String parentConfirmFamilyChildrenSubtitle(String family) {
    return 'Family «$family». The school shared profiles — confirm the details.';
  }

  @override
  String get parentConfirmFamilyChildrenNoChildren =>
      'There are no children in the family yet. You can finish confirmation.';

  @override
  String get parentConfirmFamilyChildrenSubmit => 'Confirm';

  @override
  String get parentConfirmFamilyChildrenGender => 'Gender';

  @override
  String get parentConfirmFamilyChildrenGenderMale => 'Boy';

  @override
  String get parentConfirmFamilyChildrenGenderFemale => 'Girl';

  @override
  String get parentConfirmFamilyChildrenAuthority => 'Authority basis';

  @override
  String get parentConfirmFamilyChildrenAuthorityParent => 'Parent';

  @override
  String get parentConfirmFamilyChildrenAuthorityAdoptive => 'Adoptive parent';

  @override
  String get parentConfirmFamilyChildrenAuthorityGuardian => 'Guardian';

  @override
  String get parentConfirmFamilyChildrenAuthorityDeclared =>
      'I confirm my authority as representative';

  @override
  String get parentConfirmFamilyChildrenConsentAccepted =>
      'I consent to processing children’s data';

  @override
  String get parentConfirmFamilyChildrenConsentRequired =>
      'Confirm authority and consent for the children';

  @override
  String get registerSchoolOffersTitle => 'School invitations';

  @override
  String get registerSchoolOffersLead =>
      'We found school families for your contact. Select whom to accept, or skip.';

  @override
  String get registerSchoolOffersContinue => 'Continue with selected';

  @override
  String get registerSchoolOffersSkip => 'Skip';

  @override
  String get registerSchoolOffersSelectOne => 'Select at least one child';
}
