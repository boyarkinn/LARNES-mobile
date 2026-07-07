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
  String get loginSubtitle => 'Phone, email or username and password';

  @override
  String get loginFieldLabel => 'Phone, email or username';

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
  String get registerSubtitle => 'Choose account type';

  @override
  String get accountTypeParent => 'Parent';

  @override
  String get accountTypeTeacher => 'Teacher';

  @override
  String get accountTypeNetworkOwner => 'Network owner';

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
  String get parentChildFormSubmit => 'Create profile';

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
    return 'Homework — $name';
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
  String get parentAccountFieldFullName => 'Full name';

  @override
  String get parentAccountFieldDateOfBirth => 'Date of birth';

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
  String get parentAccountDeleteChildTitle => 'Delete child?';

  @override
  String get parentAccountDeleteChildMessage =>
      'This profile will be permanently deleted.';

  @override
  String get parentAccountDeleteChildConfirm => 'Delete child';

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
      'Tablets and other clients in your network. Classroom and slot show current placement.';

  @override
  String get networkCentersEmptyTitle => 'You do not have any centers yet';

  @override
  String get networkCentersEmptyDescription =>
      'Create centers in the web network panel.';

  @override
  String get networkDevicesEmpty =>
      'No devices yet. They appear after enrolling a tablet.';

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
  String get kioskIdleTitle => 'Lesson not started';

  @override
  String get kioskIdleSubtitle =>
      'The teacher will start the lesson. Then hold the child\'s QR code up to this device.';

  @override
  String get kioskIdleSettings => 'Settings';

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
  String get kioskSettingsTitle => 'Device settings';

  @override
  String get kioskSettingsBack => 'Back';

  @override
  String get kioskSettingsPlacement => 'Placement';

  @override
  String get kioskSettingsDeviceId => 'Device ID';

  @override
  String get kioskSettingsUnbindTitle => 'Unbind device';

  @override
  String get kioskSettingsUnbindHint =>
      'The device will disappear from the network list. To use kiosk again, enroll it once more.';

  @override
  String get kioskSettingsUnbindSubmit => 'Unbind and leave kiosk';

  @override
  String get kioskSettingsUnbinding => 'Unbinding…';

  @override
  String get kioskSettingsUnbindConfirmTitle => 'Unbind this device?';

  @override
  String get kioskSettingsUnbindConfirmMessage =>
      'Kiosk mode on this phone will be turned off.';

  @override
  String get kioskSettingsUnbindCancel => 'Cancel';

  @override
  String get kioskSettingsUnbindConfirm => 'Unbind';

  @override
  String get kioskSettingsLoginRequired =>
      'Sign in again to unbind this device.';

  @override
  String get networkAddDevice => 'Add device';

  @override
  String get kioskEnrollTitle => 'Device setup';

  @override
  String get kioskEnrollSubtitle =>
      'Choose where this device belongs in your network.';

  @override
  String get kioskEnrollCenter => 'Center';

  @override
  String get kioskEnrollClassroom => 'Classroom';

  @override
  String get kioskEnrollClassroomPlaceholder => 'Select a classroom';

  @override
  String get kioskEnrollSlot => 'Desk / slot';

  @override
  String get kioskEnrollSlotPlaceholder => 'For example, 1';

  @override
  String get kioskEnrollSlotRequired => 'Enter a slot label';

  @override
  String get kioskEnrollKind => 'Device type';

  @override
  String get kioskEnrollSubmit => 'Enroll device';

  @override
  String get kioskEnrollSubmitting => 'Enrolling…';

  @override
  String get kioskEnrollNoCenters =>
      'Create a center in the network panel first.';

  @override
  String get kioskEnrollNoClassrooms => 'Add classrooms in the center first.';

  @override
  String get kioskEnrollNoClassroomsForCenter =>
      'This center has no classrooms yet.';
}
