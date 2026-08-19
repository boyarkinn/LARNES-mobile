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
  String get loginEyebrow => 'Вход';

  @override
  String get loginPending => 'Входим…';

  @override
  String get loginNoAccount => 'Нет аккаунта?';

  @override
  String get loginRegisterLink => 'Регистрация';

  @override
  String get authHeaderRegister => 'Регистрация';

  @override
  String get authHeaderLogin => 'Войти';

  @override
  String get authLegalLink => 'Правовая информация';

  @override
  String get passwordShow => 'Показать пароль';

  @override
  String get passwordHide => 'Скрыть пароль';

  @override
  String get passwordCapsLock => 'Включён Caps Lock';

  @override
  String get loginSubtitle => 'Телефон, email или логин и пароль';

  @override
  String get loginFieldLabel => 'Email или телефон';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get passwordResetTitle => 'Восстановление пароля';

  @override
  String get passwordResetStep1Subtitle => 'Шаг 1 из 3 — контакт';

  @override
  String get passwordResetStep2Subtitle => 'Шаг 2 из 3 — код подтверждения';

  @override
  String get passwordResetStep3Subtitle => 'Шаг 3 из 3 — новый пароль';

  @override
  String get passwordResetContactHint =>
      'Укажите телефон или почту, привязанные к аккаунту. Мы отправим код подтверждения.';

  @override
  String get passwordResetContactLabel => 'Телефон или email';

  @override
  String passwordResetOtpHintSms(String contact) {
    return 'Код отправлен на $contact. Введите его ниже.';
  }

  @override
  String passwordResetOtpHintEmail(String contact) {
    return 'Код отправлен на $contact. Проверьте почту (и папку «Спам») и введите его ниже.';
  }

  @override
  String get passwordResetOtpResent => 'Новый код отправлен.';

  @override
  String get passwordResetOtpNotReceivedHint =>
      'Не пришёл код? Проверьте, верно ли указан контакт — возможно, аккаунт привязан к другому телефону или почте.';

  @override
  String get passwordResetPasswordHint =>
      'Придумайте новый пароль. После сохранения вы войдёте автоматически, а старые сессии будут завершены.';

  @override
  String get passwordResetNewPasswordLabel => 'Новый пароль';

  @override
  String get passwordResetConfirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get passwordResetSubmit => 'Сохранить и войти';

  @override
  String get passwordResetBackToLogin => '← Ко входу';

  @override
  String get passwordResetFailed => 'Не удалось сменить пароль.';

  @override
  String get signInButton => 'Войти';

  @override
  String get noAccountRegister => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get loginFailed => 'Не удалось войти. Попробуйте позже.';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerHubEyebrow => 'Регистрация';

  @override
  String get registerHubParent => 'Я родитель / опекун';

  @override
  String get registerHubTeacher => 'Я учитель / репетитор';

  @override
  String get registerHubNetworkOwner => 'Я представляю школу / сеть центров';

  @override
  String get registerHasAccount => 'Уже есть аккаунт?';

  @override
  String get registerLoginLink => 'Войти';

  @override
  String get registerWizardStepContact => 'Контакт';

  @override
  String get registerWizardStepOtp => 'Код';

  @override
  String get registerWizardStepProfile => 'Профиль';

  @override
  String get registerContactStepTitle => 'Контакт';

  @override
  String get registerOtpStepTitle => 'Код';

  @override
  String get registerProfileParentTitle => 'Регистрация родителя';

  @override
  String get registerProfileTeacherTitle => 'Регистрация учителя';

  @override
  String get registerProfileNetworkTitle => 'Регистрация владельца сети';

  @override
  String get registerWizardContactChannelLabel => 'Способ подтверждения';

  @override
  String get registerWizardOtpSubmit => 'Подтвердить';

  @override
  String get registerWizardOtpBack => 'Изменить контакт';

  @override
  String get passwordResetWizardStepContact => 'Контакт';

  @override
  String get passwordResetWizardStepOtp => 'Код';

  @override
  String get passwordResetWizardStepPassword => 'Новый пароль';

  @override
  String get passwordResetContactStepTitle => 'Контакт';

  @override
  String get passwordResetOtpStepTitle => 'Код';

  @override
  String get passwordResetPasswordStepTitle => 'Новый пароль';

  @override
  String get registerSubtitle => 'Выберите тип аккаунта';

  @override
  String get accountTypeParent => 'Родитель';

  @override
  String get accountTypeTeacher => 'Учитель';

  @override
  String get accountTypeNetworkOwner => 'Владелец сети';

  @override
  String get registerTypeParentHint => 'Для домашних занятий с ребёнком';

  @override
  String get registerTypeTeacherHint => 'Для репетиторов и преподавателей';

  @override
  String get registerTypeNetworkOwnerHint =>
      'Для школ и образовательных центров';

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
  String get registerParentRelationshipLabel => 'Кто вы для ребёнка?';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get patronymicLabel => 'Отчество';

  @override
  String get dateOfBirthLabel => 'Дата рождения';

  @override
  String get dateOfBirthPlaceholder => 'ДД.ММ.ГГГГ';

  @override
  String get invalidDateOfBirth => 'Укажите корректную дату рождения';

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
  String get parentStudyProfileCard => 'Профиль';

  @override
  String get parentStudyCoursesCard => 'Курсы LARNES';

  @override
  String get parentStudyRewardsCard => 'Награды';

  @override
  String get parentRewardsTitle => 'Награды';

  @override
  String get parentRewardsEmptyShops => 'Пока нет живых витрин.';

  @override
  String get parentRewardsEmptyItems =>
      'На этой витрине сейчас нечего получить.';

  @override
  String parentRewardsBalance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ларкоинов',
      many: '$count ларкоинов',
      few: '$count ларкоина',
      one: '$count ларкоин',
    );
    return '$_temp0';
  }

  @override
  String get parentRewardsCost => 'ларкоинов';

  @override
  String get parentRewardsGet => 'Получить';

  @override
  String get parentRewardsGetting => 'Отправляем…';

  @override
  String get parentRewardsNotEnough => 'Пока не хватает';

  @override
  String get parentRewardsPending => 'Ждёт выдачи';

  @override
  String get parentRewardsHandedOver => 'Выдано';

  @override
  String get parentRewardsCancelled => 'Отменено';

  @override
  String get parentRewardsClaimsTitle => 'Заявки';

  @override
  String get parentRewardsClaimed => 'Заявка отправлена — выдадут на занятии.';

  @override
  String get parentRewardsNoPhoto => 'Без фото';

  @override
  String get parentRewardsLoadFailed => 'Не удалось загрузить награды.';

  @override
  String get parentCoursesTitle => 'Курсы';

  @override
  String get parentCoursesEmpty => 'Пока нет опубликованных курсов.';

  @override
  String get parentActivityAttendance => 'Посещаемость';

  @override
  String get parentActivitySchedule => 'График';

  @override
  String get parentActivityScheduleEmpty => 'На этот день занятий нет.';

  @override
  String get parentActivitySchedulePrevDay => 'Предыдущий день';

  @override
  String get parentActivityScheduleNextDay => 'Следующий день';

  @override
  String get parentActivityScheduleNotFound =>
      'График для этого дня недоступен.';

  @override
  String get parentActivityPayments => 'Оплаты';

  @override
  String get parentActivityPaymentsTabAccruals => 'Начисления';

  @override
  String get parentActivityPaymentsTabReceipts => 'Чеки';

  @override
  String get parentActivityPaymentsTabsLabel => 'Режим оплат';

  @override
  String get parentActivityPaymentsEmptyAccruals => 'Пока нет начислений.';

  @override
  String get parentActivityPaymentsEmptyReceipts => 'Пока нет чеков.';

  @override
  String get parentActivityPaymentReceiptTitle => 'Чек';

  @override
  String get parentActivityPaymentReceiptAccepted => 'Принято';

  @override
  String get parentActivityPaymentReceiptGift => 'Подарочных';

  @override
  String get parentActivityPaymentReceiptRefund => 'Возврат за пропуски';

  @override
  String get parentActivityPaymentReceiptTotalOnAccount => 'Всего на счёт';

  @override
  String get parentActivityPaymentAccrualTitle => 'Начисление';

  @override
  String get parentActivityPaymentAccrualHeadSuffix => 'распределено на:';

  @override
  String get parentActivityPaymentAccrualColAmount => 'Сумма';

  @override
  String get parentActivityPaymentAccrualColDate => 'Дата';

  @override
  String get parentActivityPaymentAccrualColTime => 'Время';

  @override
  String get parentActivityPaymentAccrualColCenter => 'Центр';

  @override
  String get parentActivityPaymentAccrualColClass => 'Класс';

  @override
  String get parentActivityPaymentDetailNotFound => 'Детали оплаты недоступны.';

  @override
  String get parentActivityComingSoon => 'Раздел скоро появится в приложении.';

  @override
  String get parentActivityLoadFailed =>
      'Не удалось загрузить дневник занятий.';

  @override
  String get parentActivityPlaceSummary => 'Сводная';

  @override
  String get parentActivityPlaceDockLabel => 'Фильтр мест';

  @override
  String get parentActivityAttendanceEmpty =>
      'Пока нет классов в выбранном месте.';

  @override
  String parentActivityCalendarTitle(Object name) {
    return '«$name»';
  }

  @override
  String get parentActivityCalendarNotFound =>
      'Календарь для этого класса недоступен.';

  @override
  String get parentActivityCalendarPrevMonth => 'Предыдущий месяц';

  @override
  String get parentActivityCalendarNextMonth => 'Следующий месяц';

  @override
  String get parentActivityCalendarLegendPaid => 'Оплачено';

  @override
  String get parentActivityCalendarLegendFirstUnpaid => 'Первое неоплаченное';

  @override
  String get parentActivityCalendarLegendUnpaid => 'Неоплачено';

  @override
  String get parentActivityCalendarLegendMakeup => 'Отработка';

  @override
  String get parentActivityCalendarCodesTitle => 'Коды посещаемости';

  @override
  String get parentActivityCalendarCodePresent => 'был';

  @override
  String get parentActivityCalendarCodeAbsent => 'не пришёл';

  @override
  String get parentActivityCalendarCodeSick => 'заболел';

  @override
  String get parentActivityCalendarCodeExcused => 'отпросился';

  @override
  String get parentActivityCalendarCodeAdvanceNotice => 'тайм-аут';

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
  String get parentChildFormCardColor => 'Любимый цвет';

  @override
  String get parentChildFormAvatar => 'Персонаж';

  @override
  String get parentChildFormCardColorOrange => 'Оранжевый';

  @override
  String get parentChildFormCardColorEmerald => 'Изумрудный';

  @override
  String get parentChildFormCardColorViolet => 'Фиолетовый';

  @override
  String get parentChildFormCardColorSky => 'Голубой';

  @override
  String get parentChildFormCardColorRose => 'Розовый';

  @override
  String get parentChildFormCardColorAmber => 'Янтарный';

  @override
  String get parentChildFormAvatarFox => 'Лисичка';

  @override
  String get parentChildFormAvatarBear => 'Мишка';

  @override
  String get parentChildFormAvatarOwl => 'Сова';

  @override
  String get parentChildLegalBasisLabel => 'Основание представительства';

  @override
  String get parentChildLegalBasisParent => 'Родитель';

  @override
  String get parentChildLegalBasisAdoptiveParent => 'Усыновитель';

  @override
  String get parentChildLegalBasisGuardian => 'Назначенный опекун';

  @override
  String get parentChildLegalAuthority => 'Я законный представитель ребёнка';

  @override
  String get parentChildLegalConsent =>
      'Даю согласие на обработку данных ребёнка';

  @override
  String get parentChildLegalDocumentLink =>
      'Согласие на обработку данных ребёнка';

  @override
  String get parentChildLegalRequired =>
      'Подтвердите полномочия и примите согласие на обработку данных ребёнка.';

  @override
  String get parentChildFormSubmit => 'Создать ребёнка';

  @override
  String get parentChildFormAutosaveSaved => 'Сохранено';

  @override
  String get parentChildFormAutosaveFailed => 'Не удалось сохранить';

  @override
  String get parentClassroomQrTitle => 'QR для класса';

  @override
  String get parentClassroomQrAlt => 'QR-код ребёнка для занятий в классе';

  @override
  String parentClassroomQrVersion(int version) {
    return 'Версия $version';
  }

  @override
  String get parentClassroomQrPrint => 'Печать';

  @override
  String get parentClassroomQrRegenerate => 'Перевыпустить';

  @override
  String get parentClassroomQrRevoke => 'Отозвать';

  @override
  String get parentClassroomQrIssue => 'Выпустить QR';

  @override
  String get parentClassroomQrRevokedHint =>
      'QR отозван. Старые распечатки больше не работают.';

  @override
  String get parentClassroomQrCancel => 'Отмена';

  @override
  String get parentClassroomQrConfirmRegenerateTitle => 'Перевыпустить QR?';

  @override
  String get parentClassroomQrConfirmRegenerateMessage =>
      'Старый QR перестанет работать. Нужно распечатать новый.';

  @override
  String get parentClassroomQrConfirmRevokeTitle => 'Отозвать QR?';

  @override
  String get parentClassroomQrConfirmRevokeMessage =>
      'Вход по текущему QR будет заблокирован до выпуска нового.';

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
    return 'ДЗ $name';
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
  String get parentHomeworkPlayMenuContinue => 'Продолжить занятие';

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
  String get adminNavTrainers => 'Тренажёры';

  @override
  String get adminNavAccount => 'Аккаунт';

  @override
  String get adminTrainersTitle => 'Тренажёры';

  @override
  String get adminTrainersHint =>
      'Каталог для ручной проверки тренажёров перед подключением в программы и ДЗ.';

  @override
  String get adminTrainersLoadFailed => 'Не удалось загрузить каталог.';

  @override
  String get adminTrainersOpen => 'Открыть';

  @override
  String get adminTrainersDirectionMental => 'Ментальная арифметика';

  @override
  String get adminTrainersDirectionMath => 'Математика';

  @override
  String get adminTrainersDirectionReading => 'Чтение';

  @override
  String get adminTrainersPublicationInDevelopment => 'В разработке';

  @override
  String get adminTrainersPublicationReadyToPublish => 'Готов к публикации';

  @override
  String get adminTrainersPublicationPublished => 'Опубликован';

  @override
  String adminTrainersGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# тренажёра',
      many: '# тренажёров',
      few: '# тренажёра',
      one: '# тренажёр',
    );
    return '$_temp0';
  }

  @override
  String get adminTrainerPlayLoadFailed => 'Не удалось загрузить параметры.';

  @override
  String get adminTrainerPlayLaunch => 'ЗАПУСТИТЬ';

  @override
  String get adminTrainerPlayInteractiveHint =>
      'Интерактивный тренажёр завершится действием ребёнка.';

  @override
  String get adminTrainerPlayLetterCaseLabel => 'Регистр';

  @override
  String get adminTrainerPlayWordCaseLabel => 'Регистр слова';

  @override
  String get adminTrainerPlayLetterLabel => 'Буква';

  @override
  String get adminTrainerPlayPracticeLettersLabel => 'Буквы для тренировки';

  @override
  String get adminTrainerPlayShopItemLabel => 'Товар';

  @override
  String get adminTrainerPlayPriceLabel => 'Цена';

  @override
  String get adminTrainerPlayCoinCountLabel => 'Монет в кассе';

  @override
  String get adminTrainerPlayWholeLabel => 'Целое';

  @override
  String get adminTrainerPlayKnownPartLabel => 'Известная часть';

  @override
  String get adminTrainerPlayAnswerRangeStartLabel =>
      'Начало диапазона ответов';

  @override
  String get adminTrainerPlayTargetFruitLabel => 'Какой фрукт считать';

  @override
  String get adminTrainerPlayFruitTargetCountLabel => 'Сколько на поле';

  @override
  String get adminTrainerPlayFruitTypeCountLabel => 'Видов фруктов';

  @override
  String get adminTrainerPlayTotalFruitsLabel => 'Всего фруктов';

  @override
  String get adminTrainerPlayDigitLabel => 'Цифра';

  @override
  String get adminTrainerPlayTargetCountLabel => 'Сколько найти';

  @override
  String get adminTrainerPlayDistractorCountLabel => 'Отвлекающих';

  @override
  String get adminTrainerPlayMissingSegmentLabel => 'Какой сегмент пропущен';

  @override
  String get adminTrainerPlayLetterCountLabel => 'Сколько букв';

  @override
  String get adminTrainerPlayOddLetterLabel =>
      'Лишняя буква (random или буква)';

  @override
  String get adminTrainerPlayOptionCountLabel => 'Вариантов ответа';

  @override
  String get adminTrainerPlayDotModeLabel => 'Режим точек';

  @override
  String get adminTrainerPlayRoundsLabel => 'Раундов';

  @override
  String get adminTrainerPlayDisplaySecondsLabel => 'Секунд показа';

  @override
  String get adminTrainerPlayGridSizeLabel => 'Размер сетки';

  @override
  String get adminTrainerPlayStepCountLabel => 'Количество шагов';

  @override
  String get adminTrainerPlayFilledCountLabel => 'Заполненных ячеек';

  @override
  String get adminTrainerPlayWordSlugLabel => 'Слово';

  @override
  String get adminTrainerPlayEntityCountLabel => 'Сколько слов';

  @override
  String get adminTrainerPlayPairCountLabel => 'Пар';

  @override
  String get adminTrainerPlayCatchCountLabel => 'Сколько поймать';

  @override
  String get adminTrainerPlaySpeedLabel => 'Скорость';

  @override
  String get adminTrainerPlayWordItemCountLabel => 'Слов в задании';

  @override
  String get adminTrainerPlayTotalRodsLabel => 'Рядов';

  @override
  String get adminTrainerPlayStepPauseSecLabel => 'Пауза (сек)';

  @override
  String get adminTrainerPlayExampleStringLabel => 'Пример';

  @override
  String get adminTrainerPlayChainTopicIdLabel => 'Тема цепочки';

  @override
  String get adminTrainerPlaySolveModeLabel => 'Режим решения';

  @override
  String get adminTrainerPlaySolveModeAbacus => 'На абакусе';

  @override
  String get adminTrainerPlaySolveModeMental => 'В уме';

  @override
  String get adminTrainerPlayActionCountLabel => 'Количество действий';

  @override
  String get adminTrainerPlayExampleCountLabel => 'Количество примеров';

  @override
  String get adminTrainerPlaySignModeLabel => 'Знаки';

  @override
  String get adminTrainerPlayAmountScopeLabel => 'Операнды';

  @override
  String get adminTrainerPlayValueLabel => 'Значение';

  @override
  String get adminTrainerPlayMatchValue1Label => 'Значение 1';

  @override
  String get adminTrainerPlayMatchValue2Label => 'Значение 2';

  @override
  String get adminTrainerPlayMatchValue3Label => 'Значение 3';

  @override
  String get adminTrainerPlayMatchValue4Label => 'Значение 4';

  @override
  String get adminTrainerPlayLetterCaseUpper => 'Заглавные';

  @override
  String get adminTrainerPlayLetterCaseLower => 'Строчные';

  @override
  String get adminTrainerPlayMissingSegmentRandom => 'Случайный';

  @override
  String get adminTrainerPlayMissingSegmentIndex1 => 'Сегмент 1';

  @override
  String get adminTrainerPlayMissingSegmentIndex2 => 'Сегмент 2';

  @override
  String get adminTrainerPlayMissingSegmentIndex3 => 'Сегмент 3';

  @override
  String get adminTrainerPlayMissingSegmentIndex4 => 'Сегмент 4';

  @override
  String get adminTrainerPlayDotModeNumbered => 'По номерам';

  @override
  String get adminTrainerPlayDotModeFree => 'Свободно';

  @override
  String get adminTrainerPlaySpeedSlow => 'Медленно';

  @override
  String get adminTrainerPlaySpeedMedium => 'Средне';

  @override
  String get adminTrainerPlaySpeedFast => 'Быстро';

  @override
  String get adminTrainerPlayMobileHint =>
      'Запуск в mobile-runtime (Flutter). Web-версию проверяйте на ПК.';

  @override
  String get adminTrainerPlayWebOnlyTitle => 'Нет mobile-реализации';

  @override
  String get adminTrainerPlayWebOnlyMessage =>
      'Этот тренажёр пока только в web. Запуск и проверка play — на larnes.ru в разделе «Тренажёры».';

  @override
  String get adminTrainerPlayExit => 'Назад';

  @override
  String get adminTrainerPlayMenuContinue => 'Продолжить проверку';

  @override
  String get adminTrainerPlayFinish => 'Готово';

  @override
  String get adminTrainerPlayNext => 'Далее';

  @override
  String get adminTrainerPlayContinueCheck => 'Продолжить проверку';

  @override
  String get adminAccountTitle => 'Аккаунт';

  @override
  String get adminAccountLoadFailed => 'Не удалось загрузить аккаунт.';

  @override
  String get adminAccountSaveFailed => 'Не удалось сохранить изменения.';

  @override
  String get adminAccountNotSet => 'Не указано';

  @override
  String get adminAccountSectionProfile => 'Профиль';

  @override
  String get adminAccountSectionContacts => 'Контакты';

  @override
  String get adminAccountSectionSecurity => 'Безопасность';

  @override
  String get adminAccountSectionLanguage => 'Язык';

  @override
  String get adminAccountProfileTitle => 'Сменить ФИО';

  @override
  String get adminAccountLoginTitle => 'Сменить логин';

  @override
  String get adminAccountPasswordTitle => 'Сменить пароль';

  @override
  String get adminAccountPhoneTitle => 'Сменить телефон';

  @override
  String get adminAccountEmailTitle => 'Сменить email';

  @override
  String get adminAccountSave => 'Сохранить';

  @override
  String get adminAccountSaveLogin => 'Сохранить логин';

  @override
  String get adminAccountSavePassword => 'Сохранить пароль';

  @override
  String get adminAccountActionLogoutAll => 'Выйти на всех устройствах';

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
  String get parentAccountSectionProfile => 'Профиль родителя';

  @override
  String get parentAccountSectionChildren => 'Ваши дети';

  @override
  String get parentAccountSectionCity => 'Город';

  @override
  String get parentAccountSectionContacts => 'Контакты';

  @override
  String get parentAccountSectionSecurity => 'Безопасность';

  @override
  String get parentAccountSectionLanguage => 'Язык';

  @override
  String get parentAccountSectionFamily => 'Семья';

  @override
  String get parentAccountFieldGuardians => 'Опекуны';

  @override
  String get parentAccountActionManageGuardians => 'Управление опекунами';

  @override
  String get parentFamilySetupGateTitle => 'Семья уже в LARNES?';

  @override
  String get parentFamilySetupContinueAction => 'Настроить семью';

  @override
  String get parentFamilySetupGateLead =>
      'Если кто-то из вашей семьи уже пользуется платформой, попросите его принять вас. Или создайте свою семью и добавьте детей.';

  @override
  String get parentFamilySetupAnswerNo => 'Нет, создать свою семью';

  @override
  String get parentFamilySetupAnswerYes => 'Да, семья уже есть';

  @override
  String get parentFamilySetupWaitingTitle => 'Ждём подтверждения';

  @override
  String get parentFamilySetupWaitingLead =>
      'Отправьте ссылку члену вашей семьи, который использует LARNES.';

  @override
  String get parentFamilySetupShareLinkLabel => 'Ссылка для родственника';

  @override
  String get parentFamilySetupCopyLink => 'Скопировать ссылку';

  @override
  String get parentFamilySetupShowLink => 'Показать ссылку';

  @override
  String get parentFamilySetupHideLink => 'Скрыть ссылку';

  @override
  String get parentFamilySetupCopySuccess => 'Ссылка скопирована';

  @override
  String get parentFamilySetupCopyFailed => 'Не удалось скопировать';

  @override
  String get parentFamilySetupShare => 'Поделиться';

  @override
  String get parentFamilySetupCancelJoin => 'Я ошибся — создать свою семью';

  @override
  String get parentFamilySetupDisplayNameLabel => 'Название семьи';

  @override
  String get parentFamilySetupDisplayNameHint =>
      'Так семью увидит школа. Например: Ивановы.';

  @override
  String get parentFamilySetupDisplayNamePlaceholder => 'Ивановы';

  @override
  String get parentFamilySetupDisplayNameRequired => 'Укажите название семьи';

  @override
  String get parentFamilySetupSoloNameTitle => 'Как назвать семью?';

  @override
  String get parentFamilySetupCreateSolo => 'Создать семью';

  @override
  String get parentFamilySetupBack => 'Назад';

  @override
  String get parentFamilySetupResolveProfiles => 'Уточнить профили детей';

  @override
  String parentFamilyJoinDedupChoiceTitle(String name) {
    return 'Дети с именем «$name»';
  }

  @override
  String get parentFamilyJoinDedupChoiceLead =>
      'Если это один ребёнок — выберите профиль, который оставить. Второй будет удалён из кабинета семьи.';

  @override
  String get parentFamilyJoinDedupDifferentChildren => 'Разные дети';

  @override
  String get parentFamilyJoinDedupSameChild => 'Один ребёнок';

  @override
  String get parentFamilyJoinDedupPickTitle =>
      'Один ребёнок — выберите профиль';

  @override
  String get parentFamilyJoinDedupPickLead =>
      'Какой профиль оставить? Второй будет удалён из кабинета.';

  @override
  String get parentFamilyJoinDedupRegisteredLabel => 'Зарегистрирован';

  @override
  String get parentFamilyJoinDedupNetworkLabel => 'Сеть / группа';

  @override
  String get parentFamilyJoinDedupProgramLabel => 'Программа';

  @override
  String get parentFamilyJoinDedupKeepProfile => 'Оставить этот профиль';

  @override
  String get parentFamilyJoinDedupBack => 'Назад';

  @override
  String get parentFamilyJoinDedupInvalidTitle => 'Уточнение не требуется';

  @override
  String get parentFamilyJoinDedupInvalidLead =>
      'Ссылка устарела или профили уже согласованы.';

  @override
  String get parentGuardiansTitle => 'Опекуны';

  @override
  String get parentGuardiansSectionTitle => 'Семья';

  @override
  String get parentGuardiansEmpty => 'Пока только вы.';

  @override
  String get parentGuardiansYou => 'это вы';

  @override
  String get parentGuardiansInviteGuardian => 'Пригласить опекуна';

  @override
  String get parentGuardiansInviteFamilyMember => 'Пригласить члена семьи';

  @override
  String get parentGuardiansInviteCopied => 'Ссылка скопирована';

  @override
  String get parentGuardiansInviteCreated => 'Приглашение создано';

  @override
  String get parentGuardiansPendingInvitesTitle => 'Ожидают принятия';

  @override
  String get parentGuardiansPendingInviteLabel => 'Приглашение';

  @override
  String get parentGuardiansPendingInviteStatus => 'Ожидает принятия';

  @override
  String get parentGuardiansConfirmRevokeTitle => 'Отозвать приглашение?';

  @override
  String get parentGuardiansConfirmRevokeMessage =>
      'Ссылка перестанет работать.';

  @override
  String get parentGuardiansRevokeInvite => 'Отозвать';

  @override
  String get parentGuardiansRemove => 'Удалить';

  @override
  String get parentGuardiansLeaveFamily => 'Покинуть семью';

  @override
  String get parentGuardiansConfirmRemoveTitle => 'Удалить опекуна?';

  @override
  String get parentGuardiansConfirmRemoveMessage =>
      'Опекун потеряет доступ к детям этой семьи и получит отдельный кабинет.';

  @override
  String get parentGuardiansConfirmLeaveTitle => 'Покинуть семью?';

  @override
  String get parentGuardiansConfirmLeaveMessage =>
      'Вы потеряете доступ к детям этой семьи и получите отдельный кабинет.';

  @override
  String get parentGuardiansRelationshipMother => 'Мама';

  @override
  String get parentGuardiansRelationshipFather => 'Папа';

  @override
  String get parentGuardiansRelationshipGrandmother => 'Бабушка';

  @override
  String get parentGuardiansRelationshipGrandfather => 'Дедушка';

  @override
  String get inviteInvalid => 'Приглашение не найдено или устарело.';

  @override
  String get inviteInvalidTitle => 'Недействительное приглашение';

  @override
  String get inviteFamilyJoinRequestTitle => 'Запрос в семью';

  @override
  String get inviteFamilyJoinRequestSubtitle =>
      'Примите опекуна в вашу семью — он увидит общих детей.';

  @override
  String get inviteFamilyJoinRequestRequesterLabel => 'Кто просит';

  @override
  String get inviteFamilyJoinRequestAccept => 'Принять';

  @override
  String get inviteFamilyJoinRequestDecline => 'Отклонить';

  @override
  String get inviteFamilyJoinRequestLoginTitle => 'Требуется вход';

  @override
  String get inviteFamilyJoinRequestLoginSubtitle =>
      'Войдите как опекун, чтобы принять запрос в семью.';

  @override
  String get inviteFamilyJoinRequestRegister => 'Регистрация опекуна';

  @override
  String get inviteFamilyJoinRequestWrongAccountTitle =>
      'Неверный тип аккаунта';

  @override
  String get inviteFamilyJoinRequestWrongAccountSubtitle =>
      'Запрос может принять только опекун.';

  @override
  String get inviteFamilyJoinRequestOwnRequestTitle => 'Это ваш запрос';

  @override
  String get inviteFamilyJoinRequestOwnRequestSubtitle =>
      'Откройте ссылку другому опекуну вашей семьи в LARNES.';

  @override
  String get inviteFamilyGuardianTitle => 'Приглашение в семью';

  @override
  String get inviteFamilyGuardianSubtitle =>
      'Примите приглашение — вы получите доступ к детям семьи.';

  @override
  String get inviteFamilyGuardianInviterLabel => 'Пригласил';

  @override
  String get inviteFamilyGuardianAccept => 'Принять';

  @override
  String get inviteFamilyGuardianDecline => 'Отклонить';

  @override
  String get inviteFamilyGuardianLoginTitle => 'Требуется вход';

  @override
  String get inviteFamilyGuardianLoginSubtitle =>
      'Войдите или зарегистрируйтесь как опекун, чтобы принять приглашение.';

  @override
  String get inviteFamilyGuardianRegister => 'Регистрация опекуна';

  @override
  String get inviteFamilyGuardianWrongAccountTitle => 'Неверный тип аккаунта';

  @override
  String get inviteFamilyGuardianWrongAccountSubtitle =>
      'Приглашение может принять только опекун.';

  @override
  String get parentAccountFieldFullName => 'ФИО';

  @override
  String get parentAccountFieldDateOfBirth => 'Дата рождения';

  @override
  String get parentAccountFieldRelationship => 'Роль';

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
  String get parentAccountRelationshipTitle => 'Сменить роль';

  @override
  String get parentAccountSaveRelationship => 'Сохранить';

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
  String get parentAccountChildrenArchiveTitle => 'Архив детей';

  @override
  String get parentAccountChildrenArchiveHint =>
      'Подключения закрыты. После восстановления доступ школам и педагогам нужно выдать заново.';

  @override
  String get parentAccountChildrenRestore => 'Восстановить профиль';

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
  String get parentAccountEditChildProfile => 'Редактировать данные';

  @override
  String get parentChildEducationTitle => 'Обучение';

  @override
  String get parentChildEducationEmpty =>
      'Пока нет привязок к педагогам и сетям.';

  @override
  String get parentChildTutorSection => 'Репетитор';

  @override
  String get parentChildTeacherLabel => 'Педагог';

  @override
  String get parentChildGroupsLabel => 'Группы';

  @override
  String get parentChildGroupLabel => 'Группа';

  @override
  String get parentChildTutorNoGroups => 'Пока не добавлен в группы.';

  @override
  String parentChildNetworkSection(String name) {
    return 'Сеть «$name»';
  }

  @override
  String get parentChildNetworkNoGroups => 'В сети, группа пока не назначена.';

  @override
  String parentChildResponsibleTeacher(String name) {
    return 'Педагог: $name';
  }

  @override
  String get parentChildTeacherNotAssigned =>
      'Ответственный педагог не назначен.';

  @override
  String get parentAccountEditChild => 'Редактировать профиль';

  @override
  String get parentAccountEditChildTitle => 'Редактирование';

  @override
  String get parentAccountChildBackToProfile => 'К профилю';

  @override
  String get parentAccountDeleteChildTitle => 'Архивировать профиль ребёнка?';

  @override
  String get parentAccountDeleteChildMessage =>
      'Профиль исчезнет из активного списка, но его можно будет восстановить.';

  @override
  String get parentAccountDeleteChildMessageActiveNetwork =>
      'Профиль исчезнет из активного списка; подключения завершатся; история обучения и оплат сохранится. Профиль можно будет восстановить.';

  @override
  String get parentAccountDeleteChildConfirm => 'Архивировать профиль';

  @override
  String get parentUpdateChildFailed => 'Не удалось обновить профиль ребёнка.';

  @override
  String get parentDeleteChildFailed => 'Не удалось удалить профиль ребёнка.';

  @override
  String get parentProgramLoadFailed => 'Не удалось загрузить программы.';

  @override
  String get parentDirectionLoadFailed => 'Не удалось загрузить направления.';

  @override
  String parentLearningDirectionProgramCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# программ',
      many: '# программ',
      few: '# программы',
      one: '# программа',
    );
    return '$_temp0';
  }

  @override
  String get parentDirectionProgramsBack => 'К занятиям';

  @override
  String get parentDirectionProgramsEmpty =>
      'В этом направлении пока нет опубликованных программ.';

  @override
  String get parentProgramTrackCompleted => 'Направление пройдено';

  @override
  String get parentProgramDirectionStart => 'Начать';

  @override
  String get parentProgramDirectionContinue => 'Продолжить';

  @override
  String get parentProgramDirectionCompleted => 'Пройдено';

  @override
  String get parentProgramStatusInProgress => 'В процессе';

  @override
  String get parentProgramStatusCompleted => 'Пройдено';

  @override
  String get parentProgramPlayLoadFailed => 'Не удалось загрузить программу.';

  @override
  String get parentProgramPlayCompleteFailed =>
      'Не удалось сохранить прогресс.';

  @override
  String parentProgramPlayLessonProgress(
    int topic,
    int lesson,
    int current,
    int total,
  ) {
    return 'Тема $topic · Урок $lesson · шаг $current из $total';
  }

  @override
  String get parentProgramPlayNext => 'Далее';

  @override
  String get parentProgramPlayFinish => 'Завершить';

  @override
  String get parentProgramPlayCompletedTitle => 'Программа завершена';

  @override
  String get parentProgramPlayBackToHub => 'К занятиям';

  @override
  String get parentProgramPlayExit => 'Выйти';

  @override
  String get parentProgramPlayMenuContinue => 'Продолжить занятие';

  @override
  String get parentProgramPlayEmptyProgram =>
      'В программе пока нет тренажёров для прохождения.';

  @override
  String parentProgramPlayEmptyLesson(int topic, int lesson) {
    return 'В уроке $lesson темы $topic пока нет тренажёров. Попросите методиста добавить задания.';
  }

  @override
  String get parentProgramPlayInteractiveHint => 'Выполните задание на экране';

  @override
  String get networkCentersTitle => 'Мои центры';

  @override
  String get networkCentersSectionTitle => 'Ваши центры';

  @override
  String get networkDevicesTitle => 'Устройства сети';

  @override
  String get networkDevicesHint =>
      'Устройства сети. Класс и слот — текущее размещение.';

  @override
  String get networkCentersEmptyTitle => 'У вас пока нет центров';

  @override
  String get networkCentersEmptyDescription =>
      'Центры создаются в web-панели сети.';

  @override
  String get networkDevicesEmpty =>
      'Пока нет устройств. Они появятся после регистрации устройства.';

  @override
  String get networkLoadFailed => 'Не удалось загрузить данные сети.';

  @override
  String get networkDeviceOnline => 'Онлайн';

  @override
  String get networkDeviceOffline => 'Офлайн';

  @override
  String get networkDeviceUnassigned => 'Не размещён';

  @override
  String get networkDeviceKindTablet => 'Планшет';

  @override
  String get networkDeviceKindLaptop => 'Ноутбук';

  @override
  String get networkDeviceKindPhone => 'Телефон';

  @override
  String networkDeviceSlotValue(String slot) {
    return 'Слот $slot';
  }

  @override
  String get kioskRegistrationTitle => 'Устройство не зарегистрировано';

  @override
  String get kioskRegistrationEyebrow => 'Подключение устройства';

  @override
  String get kioskRegistrationSubtitle =>
      'Войдите одноразовым доступом из панели сети.';

  @override
  String get kioskRegistrationSignIn => 'Войти';

  @override
  String get kioskRegistrationStep1 =>
      'В панели сети → Устройства выдайте одноразовый доступ.';

  @override
  String get kioskRegistrationStep2 =>
      'На экране входа укажите логин dev-* и пароль из панели.';

  @override
  String get kioskIdleTitle => 'Занятие не начато';

  @override
  String get kioskIdleEyebrow => 'Устройство на месте';

  @override
  String get kioskIdleSubtitle =>
      'Педагог начнёт занятие. После этого поднесите QR-код к этому устройству.';

  @override
  String get kioskIdleSettings => 'Настройки';

  @override
  String get kioskIdlePlacementLabel => 'Размещение';

  @override
  String get kioskIdleWaiting => 'Ожидаем начала занятия';

  @override
  String get kioskUnplacedTitle => 'Место не назначено';

  @override
  String get kioskUnplacedEyebrow => 'Настройка устройства';

  @override
  String get kioskUnplacedSubtitle =>
      'Назначьте это устройство на место в кабинете — тогда откроется сканирование QR.';

  @override
  String get kioskUnplacedStep1 => 'Откройте панель сети → Устройства.';

  @override
  String get kioskUnplacedStep2 =>
      'Выберите это устройство и укажите кабинет с местом.';

  @override
  String get kioskUnplacedStep3 =>
      'Экран обновится сам — QR и занятие станут доступны.';

  @override
  String get kioskUnplacedWaiting => 'Ожидаем назначения';

  @override
  String get kioskUnplacedSettings => 'Настройки';

  @override
  String get kioskScanTitle => 'Поднесите QR';

  @override
  String get kioskScanSubtitle => 'Покажите свой код на этом устройстве.';

  @override
  String get kioskScanEnableCamera => 'Включить камеру';

  @override
  String get kioskScanEnableCameraHint =>
      'Нажмите кнопку — приложение запросит доступ к камере.';

  @override
  String get kioskScanRetryCamera => 'Попробовать снова';

  @override
  String get kioskScanSwitchCamera => 'Сменить камеру';

  @override
  String get kioskScanStartingCamera => 'Включаем камеру…';

  @override
  String get kioskScanProcessing => 'Проверяем код…';

  @override
  String get kioskScanCameraDenied => 'Доступ к камере не дан.';

  @override
  String get kioskScanCameraDeniedHint =>
      'Разрешите камеру в настройках телефона или нажмите «Попробовать снова».';

  @override
  String get kioskScanErrorCamera =>
      'Не удалось включить камеру. Попробуйте ещё раз.';

  @override
  String get kioskScanErrorGeneric =>
      'Не удалось обработать QR-код. Попробуйте ещё раз.';

  @override
  String get kioskScanErrorForbidden =>
      'Сканирование недоступно на этом устройстве.';

  @override
  String get kioskScanErrorInvalidToken => 'QR-код не распознан или устарел.';

  @override
  String get kioskScanErrorLessonInactive =>
      'Занятие ещё не начато или уже завершено.';

  @override
  String get kioskScanErrorNetwork =>
      'Нет связи с сервером. Проверьте интернет.';

  @override
  String get kioskScanErrorNotInGroup =>
      'Этот ребёнок не записан в группу занятия.';

  @override
  String get kioskScanErrorRateLimited =>
      'Слишком много попыток. Подождите минуту.';

  @override
  String get kioskScanErrorRevoked =>
      'QR-код отозван. Попросите родителя обновить код.';

  @override
  String get kioskScanCameraSoon =>
      'Камера подключается в следующем обновлении.';

  @override
  String get kioskResultTitle => 'Ребёнок на занятии';

  @override
  String get kioskResultProgramAssigned => 'Программа назначена';

  @override
  String get kioskResultNoProgram => 'Пока нет программы для этого ребёнка.';

  @override
  String get kioskTrainerCompletedTitle => 'Задание завершено';

  @override
  String get kioskTrainerCompletedBack => 'Вернуться на занятие';

  @override
  String get kioskTrainerProcessing => 'Запускаем тренажёр…';

  @override
  String get kioskSettingsTitle => 'Настройки устройства';

  @override
  String get kioskSettingsBack => 'Назад';

  @override
  String get kioskSettingsPlacement => 'Размещение';

  @override
  String get kioskSettingsDeviceId => 'ID устройства';

  @override
  String get kioskSettingsUnbindTitle => 'Выйти';

  @override
  String get kioskSettingsUnbindHint =>
      'Устройство будет исключено из сети. Для повторного использования нужна новая регистрация с кодом доступа из панели сети.';

  @override
  String get kioskSettingsUnbindSubmit => 'Выйти';

  @override
  String get kioskSettingsUnbinding => 'Выход…';

  @override
  String get kioskSettingsUnbindConfirmTitle =>
      'Выйти и исключить это устройство из сети?';

  @override
  String get kioskSettingsUnbindConfirmMessage =>
      'Устройство исчезнет из списка сети. Чтобы снова использовать kiosk, получите новый код доступа в панели сети.';

  @override
  String get kioskSettingsUnbindCancel => 'Отмена';

  @override
  String get kioskSettingsUnbindConfirm => 'Выйти';

  @override
  String get kioskSettingsLoginRequired =>
      'Войдите снова, чтобы отвязать устройство.';

  @override
  String get networkAddDevice => 'Добавить устройство';

  @override
  String get kioskEnrollTitle => 'Привязка устройства';

  @override
  String get kioskEnrollSubtitle =>
      'Введите код доступа и пароль из панели сети.';

  @override
  String get kioskEnrollAccessCodeLabel => 'Код доступа';

  @override
  String get kioskEnrollFailed =>
      'Не удалось привязать устройство. Проверьте код и пароль.';

  @override
  String get kioskEnrollSubmit => 'Привязать устройство';

  @override
  String get kioskEnrollSubmitting => 'Привязка…';

  @override
  String get optionalPatronymicLabel => 'Отчество (необязательно)';

  @override
  String get registrationOwnerEmailUnverifiedHint =>
      'Email будет сохранён как неподтверждённый. После регистрации подтвердите его в настройках аккаунта.';

  @override
  String get optionalDateOfBirthLabel => 'Дата рождения (необязательно)';

  @override
  String get optionalCityLabel => 'Город (необязательно)';

  @override
  String get placesAutocompleteUnavailable => 'Поиск мест временно недоступен.';

  @override
  String get placesAutocompleteInvalidSelection =>
      'Не удалось подтвердить место. Выберите пункт из списка ещё раз.';

  @override
  String get notSpecifiedLabel => 'Не указан';

  @override
  String get registrationTermsRequired =>
      'Чтобы создать аккаунт, примите действующее Пользовательское соглашение.';

  @override
  String get registrationTermsLink => 'Пользовательское соглашение';

  @override
  String get registrationPrivacyLink =>
      'Политика обработки персональных данных';

  @override
  String get registrationTermsParent =>
      'Я принимаю Пользовательское соглашение.';

  @override
  String get registrationTermsTeacher =>
      'Я принимаю Пользовательское соглашение.';

  @override
  String get registrationTermsNetworkOwner =>
      'Я принимаю Пользовательское соглашение.';

  @override
  String get voluntaryConsentTitle =>
      'Отдельное согласие на необязательные данные';

  @override
  String get voluntaryConsentParentFields =>
      'Охватывает только отчество, город и дату рождения. Основные функции аккаунта от него не зависят.';

  @override
  String get voluntaryConsentParentCheckbox =>
      'Я согласен на обработку отчества, города и даты рождения для ведения закрытого расширенного профиля.';

  @override
  String voluntaryConsentOpenVersion(String version) {
    return 'Открыть версию $version';
  }

  @override
  String get voluntaryConsentVersionMissing =>
      'Опубликованная версия согласия недоступна.';

  @override
  String get voluntaryConsentRequired =>
      'Подтвердите отдельное согласие для сохранения заполненного необязательного поля.';

  @override
  String get voluntaryConsentRevokeTitle =>
      'Отозвать согласие на данные профиля';

  @override
  String get voluntaryConsentRevokeDescription =>
      'Отчество, город и дата рождения будут безвозвратно удалены. Основной аккаунт продолжит работать.';

  @override
  String get voluntaryConsentRevokeConfirm =>
      'Подтверждаю отзыв и удаление данных';

  @override
  String get voluntaryConsentRevokeButton => 'Отозвать и удалить';

  @override
  String get voluntaryConsentRevokeSuccess =>
      'Согласие отозвано, данные удалены.';

  @override
  String get voluntaryConsentRevokeFailed =>
      'Не удалось отозвать согласие. Данные не удалены.';

  @override
  String inviteFamilyAdultClaimTitle(String school) {
    return 'Школа «$school» приглашает вас в экосистему LARNES';
  }

  @override
  String get inviteFamilyAdultClaimTitleShort => 'Приглашение школы';

  @override
  String get inviteFamilyAdultClaimSubtitle =>
      'Примите приглашение, подтвердите личность, затем заполните необходимые данные';

  @override
  String get inviteFamilyAdultClaimAccept => 'Принять приглашение';

  @override
  String get inviteFamilyAdultClaimDecline => 'Отклонить';

  @override
  String get inviteFamilyAdultClaimWrongAccountTitle => 'Нужен другой аккаунт';

  @override
  String get inviteFamilyAdultClaimWrongAccountSubtitle =>
      'Войдите аккаунтом с тем же телефоном или email, что в приглашении, либо выйдите и зарегистрируйтесь.';

  @override
  String get inviteFamilyAdultClaimContactLabel => 'Контакт';

  @override
  String get inviteFamilyAdultClaimContactNotVerified =>
      'Сначала подтвердите контакт кодом';

  @override
  String get inviteFamilyAdultClaimOtpTitle => 'Подтвердите личность';

  @override
  String get inviteFamilyAdultClaimOtpSentTo =>
      'Введите код, мы отправили его на';

  @override
  String get inviteFamilyAdultClaimOtpSubmit => 'Подтвердить';

  @override
  String get inviteFamilyAdultClaimOtpResend => 'Отправить код снова';

  @override
  String inviteFamilyAdultClaimOtpResendIn(int seconds) {
    return 'Повторная отправка через $seconds с';
  }

  @override
  String get inviteFamilyAdultClaimProfileTitle => 'Представитель';

  @override
  String get inviteFamilyAdultClaimProfileHint =>
      'Проверьте данные и задайте пароль. Детей проверите на следующем шаге.';

  @override
  String get inviteFamilyAdultClaimProfileSubmit => 'Создать аккаунт';

  @override
  String get inviteFamilyAdultClaimLoggedInTitle => 'Принять в текущий аккаунт';

  @override
  String get inviteFamilyAdultClaimLoggedInSubtitle =>
      'Контакт совпал с вашим аккаунтом. После принятия проверите данные детей.';

  @override
  String get inviteFamilyAdultClaimLoggedInSubmit => 'Принять семью';

  @override
  String get parentConfirmFamilyChildrenTitle => 'Проверьте детей';

  @override
  String parentConfirmFamilyChildrenSubtitle(String family) {
    return 'Семья «$family». Школа передала карточки — подтвердите данные.';
  }

  @override
  String get parentConfirmFamilyChildrenNoChildren =>
      'В семье пока нет детей. Можно завершить проверку.';

  @override
  String get parentConfirmFamilyChildrenSubmit => 'Подтвердить';

  @override
  String get parentConfirmFamilyChildrenGender => 'Пол';

  @override
  String get parentConfirmFamilyChildrenGenderMale => 'Мальчик';

  @override
  String get parentConfirmFamilyChildrenGenderFemale => 'Девочка';

  @override
  String get parentConfirmFamilyChildrenAuthority => 'Основание полномочий';

  @override
  String get parentConfirmFamilyChildrenAuthorityParent => 'Родитель';

  @override
  String get parentConfirmFamilyChildrenAuthorityAdoptive => 'Усыновитель';

  @override
  String get parentConfirmFamilyChildrenAuthorityGuardian => 'Опекун';

  @override
  String get parentConfirmFamilyChildrenAuthorityDeclared =>
      'Подтверждаю полномочия представителя';

  @override
  String get parentConfirmFamilyChildrenConsentAccepted =>
      'Согласен на обработку данных детей';

  @override
  String get parentConfirmFamilyChildrenConsentRequired =>
      'Подтвердите полномочия и согласие по детям';

  @override
  String get registerSchoolOffersTitle => 'Приглашения от школ';

  @override
  String get registerSchoolOffersLead =>
      'По вашему контакту нашлись семьи в школах. Выберите, кого принять, или пропустите.';

  @override
  String get registerSchoolOffersContinue => 'Продолжить с выбранными';

  @override
  String get registerSchoolOffersSkip => 'Пропустить';

  @override
  String get registerSchoolOffersSelectOne => 'Выберите хотя бы одного ребёнка';
}
