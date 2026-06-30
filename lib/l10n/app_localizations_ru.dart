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

  @override
  String get parentChildPickerTitle => 'Кто сегодня занимается?';

  @override
  String get parentAddChild => 'Добавить ребёнка';

  @override
  String get parentAccount => 'Аккаунт';

  @override
  String get parentBack => 'Назад';

  @override
  String get parentStudyTitle => 'Что изучаем сегодня?';

  @override
  String get parentHomeworkTitle => 'Домашние задания';

  @override
  String get parentHomeworkEmptyHint => 'Пока нет заданий';

  @override
  String parentHomeworkAssignmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# заданий',
      many: '# заданий',
      few: '# задания',
      one: '# задание',
    );
    return '$_temp0';
  }

  @override
  String get parentChildFormTitle => 'Новый профиль ребёнка';

  @override
  String get parentChildFormLastName => 'Фамилия';

  @override
  String get parentChildFormFirstName => 'Имя';

  @override
  String get parentChildFormPatronymic => 'Отчество (необязательно)';

  @override
  String get parentChildFormDateOfBirth => 'Дата рождения';

  @override
  String get parentChildFormGender => 'Пол';

  @override
  String get parentChildFormGenderMale => 'М';

  @override
  String get parentChildFormGenderFemale => 'Ж';

  @override
  String get parentChildFormGenderRequired => 'Укажите пол';

  @override
  String get parentChildFormSubmit => 'Создать профиль';

  @override
  String get parentLoadChildrenFailed => 'Не удалось загрузить список детей.';

  @override
  String get parentCreateChildFailed => 'Не удалось создать профиль.';

  @override
  String get parentHomeworkSoon => 'Список ДЗ — в следующем шаге.';

  @override
  String get parentHomeworkLoadFailed =>
      'Не удалось загрузить домашние задания.';

  @override
  String parentHomeworkListTitle(String name) {
    return 'ДЗ — $name';
  }

  @override
  String get parentHomeworkBack => 'Назад';

  @override
  String get parentHomeworkSentAt => 'Отправлено';

  @override
  String get parentHomeworkDeadline => 'Дедлайн';

  @override
  String get parentHomeworkNoDeadline => 'Не указан';

  @override
  String get parentHomeworkProgress => 'Прогресс';

  @override
  String parentHomeworkProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String get parentHomeworkPlaySoon =>
      'Прохождение задания — в следующем шаге.';

  @override
  String get parentHomeworkPlayLoadFailed => 'Не удалось загрузить задание.';

  @override
  String get parentHomeworkPlayAdvanceFailed =>
      'Не удалось сохранить прогресс.';

  @override
  String parentHomeworkPlayProgress(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get parentHomeworkPlayNext => 'Далее';

  @override
  String get parentHomeworkPlayFinish => 'Завершить';

  @override
  String get parentHomeworkPlayCompletedTitle => 'Домашнее задание выполнено';

  @override
  String get parentHomeworkPlayBackToList => 'К списку ДЗ';

  @override
  String get parentHomeworkPlayExit => 'Выйти';

  @override
  String get parentHomeworkPlayEmpty => 'В задании пока нет тренажёров.';

  @override
  String parentHomeworkPlayStepLabel(int step) {
    return 'Шаг $step';
  }

  @override
  String get parentHomeworkPlayTrainerSoon =>
      'Тренажёр — в следующем обновлении.';

  @override
  String get parentHomeworkPlayInteractiveHint => 'Выполните задание на экране';

  @override
  String get parentHomeworkEmptyDue =>
      'Нет заданий, которые нужно сделать сейчас.';

  @override
  String get parentHomeworkEmptyCompleted => 'Пока нет выполненных заданий.';

  @override
  String get parentHomeworkEmptyOverdue => 'Нет просроченных заданий.';

  @override
  String get parentHomeworkEmptyUpcoming => 'Нет предстоящих заданий.';

  @override
  String parentHomeworkTabDue(int count) {
    return 'Сделать ($count)';
  }

  @override
  String parentHomeworkTabCompleted(int count) {
    return 'Выполненные ($count)';
  }

  @override
  String parentHomeworkTabOverdue(int count) {
    return 'Просроченные ($count)';
  }

  @override
  String parentHomeworkTabUpcoming(int count) {
    return 'Предстоящие ($count)';
  }

  @override
  String get parentHomeworkStatusAssigned => 'Не начато';

  @override
  String get parentHomeworkStatusInProgress => 'В процессе';

  @override
  String get parentHomeworkStatusCompleted => 'Выполнено';

  @override
  String get parentHomeworkStatusOverdue => 'Просрочено';

  @override
  String get parentAccountTitle => 'Аккаунт';

  @override
  String get parentAccountBackToPicker => 'Назад';

  @override
  String get parentAccountBackToAccount => 'К аккаунту';

  @override
  String get parentAccountNotSet => 'Не указано';

  @override
  String get parentAccountLoadFailed => 'Не удалось загрузить аккаунт.';

  @override
  String get parentAccountSaveFailed => 'Не удалось сохранить изменения.';

  @override
  String get parentAccountSave => 'Сохранить';

  @override
  String get parentAccountSaveCity => 'Сохранить город';

  @override
  String get parentAccountSaveLogin => 'Сохранить логин';

  @override
  String get parentAccountSavePassword => 'Сохранить пароль';

  @override
  String get parentAccountCancel => 'Отмена';

  @override
  String get parentAccountSectionProfile => 'Профиль';

  @override
  String get parentAccountSectionChildren => 'Дети';

  @override
  String get parentAccountSectionCity => 'Город';

  @override
  String get parentAccountSectionContacts => 'Контакты';

  @override
  String get parentAccountSectionSecurity => 'Безопасность';

  @override
  String get parentAccountSectionLanguage => 'Язык';

  @override
  String get parentAccountFieldFullName => 'ФИО';

  @override
  String get parentAccountFieldDateOfBirth => 'Дата рождения';

  @override
  String get parentAccountFieldChildren => 'Профили';

  @override
  String get parentAccountFieldCity => 'Город';

  @override
  String get parentAccountFieldLogin => 'Логин';

  @override
  String get parentAccountActionChangeProfile => 'Сменить ФИО';

  @override
  String get parentAccountActionChangeDateOfBirth => 'Сменить дату рождения';

  @override
  String get parentAccountActionManageChildren => 'Управление детьми';

  @override
  String get parentAccountActionChangeCity => 'Сменить город';

  @override
  String get parentAccountActionChangePhone => 'Сменить телефон';

  @override
  String get parentAccountActionChangeEmail => 'Сменить email';

  @override
  String get parentAccountActionChangeLogin => 'Сменить логин';

  @override
  String get parentAccountActionChangePassword => 'Сменить пароль';

  @override
  String get parentAccountActionLogoutAll => 'Выйти на всех устройствах';

  @override
  String parentAccountChildrenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# профилей',
      many: '# профилей',
      few: '# профиля',
      one: '# профиль',
    );
    return '$_temp0';
  }

  @override
  String get parentAccountCityNotSet => 'Город не указан';

  @override
  String get parentAccountDateOfBirthNotSet => 'Дата рождения не указана';

  @override
  String get parentAccountContactVerified => 'Подтверждён';

  @override
  String get parentAccountContactNotVerified => 'Не подтверждён';

  @override
  String get parentAccountContactChangeSoon =>
      'Смена контакта — в следующем этапе.';

  @override
  String get parentAccountProfileTitle => 'Сменить ФИО';

  @override
  String get parentAccountDateOfBirthTitle => 'Сменить дату рождения';

  @override
  String get parentAccountCityTitle => 'Сменить город';

  @override
  String get parentAccountLoginTitle => 'Сменить логин';

  @override
  String get parentAccountPhoneTitle => 'Сменить телефон';

  @override
  String get parentAccountEmailTitle => 'Сменить email';

  @override
  String get parentAccountNewPhone => 'Новый телефон';

  @override
  String get parentAccountNewEmail => 'Новый email';

  @override
  String get parentAccountSendCode => 'Получить код';

  @override
  String get parentAccountVerifyContact => 'Подтвердить';

  @override
  String get parentAccountPasswordTitle => 'Сменить пароль';

  @override
  String get parentAccountCurrentPassword => 'Текущий пароль';

  @override
  String get parentAccountNewLogin => 'Новый логин';

  @override
  String get parentAccountConfirmNewLogin => 'Подтвердите новый логин';

  @override
  String get parentAccountNewPassword => 'Новый пароль';

  @override
  String get parentAccountConfirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get parentAccountLogoutAllTitle => 'Выйти на всех устройствах?';

  @override
  String get parentAccountLogoutAllMessage =>
      'Все активные сессии будут завершены. Потребуется войти снова.';

  @override
  String get parentAccountLogoutAllConfirm => 'Выйти везде';

  @override
  String get parentAccountChildrenTitle => 'Дети';

  @override
  String get parentAccountChildrenProfiles => 'Профили';

  @override
  String get parentAccountChildrenActions => 'Действия';

  @override
  String get parentAccountChildrenEmpty => 'Пока нет добавленных детей.';

  @override
  String get parentAccountChildrenBackToList => 'К списку';

  @override
  String get parentAccountChildSummary => 'Профиль';

  @override
  String get parentAccountChildAge => 'Возраст';

  @override
  String get parentAccountEditChild => 'Редактировать профиль';

  @override
  String get parentAccountEditChildTitle => 'Редактирование';

  @override
  String get parentAccountChildBackToProfile => 'К профилю';

  @override
  String get parentAccountDeleteChildTitle => 'Удалить ребёнка?';

  @override
  String get parentAccountDeleteChildMessage =>
      'Профиль будет удалён без возможности восстановления.';

  @override
  String get parentAccountDeleteChildConfirm => 'Удалить ребёнка';

  @override
  String get parentUpdateChildFailed => 'Не удалось обновить профиль ребёнка.';

  @override
  String get parentDeleteChildFailed => 'Не удалось удалить профиль ребёнка.';
}
