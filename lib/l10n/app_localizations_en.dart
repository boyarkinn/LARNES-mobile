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
  String get forgotPasswordComingSoon => 'Password reset — coming soon';

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
  String get confirmNotRobot => 'Confirm you are not a robot';

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
  String get turnstileVerified => 'Verification passed';

  @override
  String get turnstileCanContinue => 'You can continue registration';

  @override
  String get turnstileBotProtection => 'Bot protection';

  @override
  String get turnstilePreparing => 'Preparing...';

  @override
  String get turnstileVerifying => 'Verifying...';

  @override
  String get turnstileTapToVerify => 'Tap to verify';

  @override
  String get turnstileLoadFailed => 'Could not load verification';

  @override
  String get turnstileLoadFailedPull =>
      'Could not load verification. Pull down and try again.';

  @override
  String get turnstileExpired => 'Verification expired. Tap again.';

  @override
  String get turnstileLoadFailedTap =>
      'Could not load verification. Tap again.';

  @override
  String get turnstileFailed => 'Verification failed. Tap again.';

  @override
  String get turnstileStillLoading =>
      'Verification is still loading. Wait a few seconds.';

  @override
  String get turnstileStartFailed => 'Could not start verification';

  @override
  String get turnstileNotCompleted =>
      'Verification did not complete. Tap again.';

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
  String get parentChildFormSubmit => 'Create profile';

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
  String get parentAccountSectionProfile => 'Profile';

  @override
  String get parentAccountSectionChildren => 'Children';

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
}
