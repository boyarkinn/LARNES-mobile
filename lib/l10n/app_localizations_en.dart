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
}
