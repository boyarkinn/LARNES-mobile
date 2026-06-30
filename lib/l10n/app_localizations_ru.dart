// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'LARNES';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Телефон, email или логин и пароль';

  @override
  String get loginFieldLabel => 'Телефон, email или логин';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get forgotPasswordComingSoon => 'Сброс пароля — в следующем этапе';

  @override
  String get signInButton => 'Войти';

  @override
  String get noAccountRegister => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get loginFailed => 'Не удалось войти. Попробуйте позже.';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerSubtitle => 'Выберите тип аккаунта';

  @override
  String get accountTypeParent => 'Родитель';

  @override
  String get accountTypeTeacher => 'Учитель';

  @override
  String get accountTypeNetworkOwner => 'Владелец сети';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get registerStep1Subtitle => 'Шаг 1 из 3 — подтверждение контакта';

  @override
  String get phoneChannel => 'Телефон';

  @override
  String get emailChannel => 'Почта';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get emailLabel => 'Email';

  @override
  String get getCodeButton => 'Получить код';

  @override
  String get enterContact => 'Введите контакт';

  @override
  String get confirmNotRobot => 'Подтвердите, что вы не робот';

  @override
  String get otpTitle => 'Код подтверждения';

  @override
  String otpSentTo(String contact) {
    return 'Отправили на $contact';
  }

  @override
  String get enterSixDigitCode => 'Введите 6-значный код';

  @override
  String get resendCode => 'Отправить код снова';

  @override
  String resendCooldown(int seconds) {
    return 'Повторная отправка через $seconds с';
  }

  @override
  String get continueButton => 'Продолжить';

  @override
  String get codeResent => 'Код отправлен снова';

  @override
  String get verifyCodeFailed => 'Не удалось проверить код.';

  @override
  String get resendFailed => 'Не удалось отправить код снова.';

  @override
  String get profileTitle => 'Профиль';

  @override
  String registerStep3Subtitle(String accountType) {
    return 'Шаг 3 из 3 — $accountType';
  }

  @override
  String get createAccountButton => 'Создать аккаунт';

  @override
  String get verifyContactFirst => 'Сначала подтвердите контакт кодом';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get createAccountFailed => 'Не удалось создать аккаунт.';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get patronymicLabel => 'Отчество';

  @override
  String get dateOfBirthLabel => 'Дата рождения';

  @override
  String get cityLabel => 'Город';

  @override
  String get networkNameLabel => 'Название сети';

  @override
  String get repeatPasswordLabel => 'Повторите пароль';

  @override
  String get loggedInTitle => 'Вы вошли';

  @override
  String nameValue(String name) {
    return 'Имя: $name';
  }

  @override
  String roleValue(String role) {
    return 'Роль: $role';
  }

  @override
  String get homePlaceholder =>
      'Здесь будет панель по роли (родитель / учитель / сеть).';

  @override
  String get logoutButton => 'Выйти';

  @override
  String get emptyValue => '—';

  @override
  String get turnstileVerified => 'Проверка пройдена';

  @override
  String get turnstileCanContinue => 'Можно продолжить регистрацию';

  @override
  String get turnstileBotProtection => 'Защита от ботов';

  @override
  String get turnstilePreparing => 'Подготовка...';

  @override
  String get turnstileVerifying => 'Проверка...';

  @override
  String get turnstileTapToVerify => 'Нажмите для проверки';

  @override
  String get turnstileLoadFailed => 'Не удалось загрузить проверку';

  @override
  String get turnstileLoadFailedPull =>
      'Не удалось загрузить проверку. Потяните экран вниз и попробуйте снова.';

  @override
  String get turnstileExpired => 'Проверка истекла. Нажмите ещё раз.';

  @override
  String get turnstileLoadFailedTap =>
      'Не удалось загрузить проверку. Нажмите ещё раз.';

  @override
  String get turnstileFailed => 'Проверка не пройдена. Нажмите ещё раз.';

  @override
  String get turnstileStillLoading =>
      'Проверка ещё загружается. Подождите пару секунд.';

  @override
  String get turnstileStartFailed => 'Не удалось запустить проверку';

  @override
  String get turnstileNotCompleted =>
      'Проверка не завершилась. Нажмите ещё раз.';

  @override
  String get languageLabel => 'Язык';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String get noConnection => 'Нет связи с сервером. Проверьте интернет.';

  @override
  String get requestFailed => 'Не удалось выполнить запрос.';

  @override
  String get requestError => 'Ошибка запроса.';

  @override
  String get sendCodeFailed => 'Не удалось отправить код.';

  @override
  String get verifyContactFailed => 'Не удалось подтвердить контакт.';

  @override
  String get tokenFetchFailed => 'Не удалось получить токен.';
}
