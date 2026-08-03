enum ParentActivityPlaceKind {
  summary('summary'),
  network('network'),
  tutor('tutor');

  const ParentActivityPlaceKind(this.apiValue);

  final String apiValue;

  static ParentActivityPlaceKind fromApiValue(String? value) {
    return ParentActivityPlaceKind.values.firstWhere(
      (kind) => kind.apiValue == value,
      orElse: () => ParentActivityPlaceKind.summary,
    );
  }
}

enum ParentActivityClassKind {
  center('center'),
  tutor('tutor');

  const ParentActivityClassKind(this.apiValue);

  final String apiValue;

  static ParentActivityClassKind fromApiValue(String? value) {
    return ParentActivityClassKind.values.firstWhere(
      (kind) => kind.apiValue == value,
      orElse: () => ParentActivityClassKind.center,
    );
  }
}

const parentActivitySummaryPlaceId = 'summary';

class ParentActivityPlace {
  const ParentActivityPlace({
    required this.placeId,
    required this.kind,
    required this.label,
    required this.archived,
    required this.sortOrder,
  });

  factory ParentActivityPlace.fromJson(Map<String, dynamic> json) {
    return ParentActivityPlace(
      placeId: json['placeId'] as String,
      kind: ParentActivityPlaceKind.fromApiValue(json['kind'] as String?),
      label: json['label'] as String? ?? '',
      archived: json['archived'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  final String placeId;
  final ParentActivityPlaceKind kind;
  final String label;
  final bool archived;
  final int sortOrder;
}

class ParentActivityClass {
  const ParentActivityClass({
    required this.groupId,
    required this.groupName,
    required this.placeId,
    required this.placeLabel,
    required this.lineLabel,
    required this.kind,
    required this.isActive,
    this.centerId,
    this.ownerUserId,
    this.teacherId,
  });

  factory ParentActivityClass.fromJson(Map<String, dynamic> json) {
    return ParentActivityClass(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      placeId: json['placeId'] as String,
      placeLabel: json['placeLabel'] as String,
      lineLabel: json['lineLabel'] as String,
      kind: ParentActivityClassKind.fromApiValue(json['kind'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      centerId: json['centerId'] as String?,
      ownerUserId: json['ownerUserId'] as String?,
      teacherId: json['teacherId'] as String?,
    );
  }

  final String groupId;
  final String groupName;
  final String placeId;
  final String placeLabel;
  final String lineLabel;
  final ParentActivityClassKind kind;
  final bool isActive;
  final String? centerId;
  final String? ownerUserId;
  final String? teacherId;
}

class ParentActivityContextPage {
  const ParentActivityContextPage({
    required this.placeId,
    required this.places,
    required this.activeClassCount,
  });

  factory ParentActivityContextPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final places = json['places'] as List<dynamic>? ?? const [];

    return ParentActivityContextPage(
      placeId: json['placeId'] as String? ?? parentActivitySummaryPlaceId,
      places: places
          .map(
            (item) => ParentActivityPlace.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      activeClassCount: meta['activeClassCount'] as int? ?? 0,
    );
  }

  final String placeId;
  final List<ParentActivityPlace> places;
  final int activeClassCount;
}

class ParentActivityClassesPage {
  const ParentActivityClassesPage({
    required this.placeId,
    required this.classes,
  });

  factory ParentActivityClassesPage.fromJson(Map<String, dynamic> json) {
    final classes = json['classes'] as List<dynamic>? ?? const [];

    return ParentActivityClassesPage(
      placeId: json['placeId'] as String? ?? parentActivitySummaryPlaceId,
      classes: classes
          .map(
            (item) => ParentActivityClass.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String placeId;
  final List<ParentActivityClass> classes;
}

enum ParentAttendanceCellTone {
  empty('empty'),
  neutral('neutral'),
  paid('paid'),
  gift('gift'),
  carryover('carryover'),
  firstUnpaid('first-unpaid'),
  unpaid('unpaid'),
  makeup('makeup'),
  otherGroup('other-group');

  const ParentAttendanceCellTone(this.apiValue);

  final String apiValue;

  static ParentAttendanceCellTone fromApiValue(String? value) {
    return ParentAttendanceCellTone.values.firstWhere(
      (tone) => tone.apiValue == value,
      orElse: () => ParentAttendanceCellTone.neutral,
    );
  }
}

class ParentAttendanceCalendarCell {
  const ParentAttendanceCalendarCell({
    required this.day,
    required this.tone,
    this.isoDate,
    this.attendanceCode,
  });

  factory ParentAttendanceCalendarCell.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceCalendarCell(
      day: json['day'] as int? ?? 0,
      tone: ParentAttendanceCellTone.fromApiValue(json['tone'] as String?),
      isoDate: json['isoDate'] as String?,
      attendanceCode: json['attendanceCode'] as String?,
    );
  }

  final int day;
  final String? isoDate;
  final String? attendanceCode;
  final ParentAttendanceCellTone tone;
}

class ParentAttendanceCalendarPage {
  const ParentAttendanceCalendarPage({
    required this.groupId,
    required this.groupName,
    required this.monthKey,
    required this.monthLabel,
    required this.gridCells,
    required this.weekdayLabels,
    required this.showMakeupLegend,
    this.prevMonthKey,
    this.nextMonthKey,
    this.scheduleLabel,
  });

  factory ParentAttendanceCalendarPage.fromJson(Map<String, dynamic> json) {
    final gridCells = json['gridCells'] as List<dynamic>? ?? const [];

    return ParentAttendanceCalendarPage(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      monthKey: json['monthKey'] as String,
      monthLabel: json['monthLabel'] as String,
      prevMonthKey: json['prevMonthKey'] as String?,
      nextMonthKey: json['nextMonthKey'] as String?,
      scheduleLabel: json['scheduleLabel'] as String?,
      showMakeupLegend: json['showMakeupLegend'] as bool? ?? false,
      weekdayLabels: (json['weekdayLabels'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
      gridCells: gridCells.map((item) {
        if (item == null) {
          return null;
        }
        return ParentAttendanceCalendarCell.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
    );
  }

  final String groupId;
  final String groupName;
  final String monthKey;
  final String monthLabel;
  final String? prevMonthKey;
  final String? nextMonthKey;
  final String? scheduleLabel;
  final bool showMakeupLegend;
  final List<String> weekdayLabels;
  final List<ParentAttendanceCalendarCell?> gridCells;
}

enum ParentScheduleLessonTone {
  paid('paid'),
  gift('gift'),
  carryover('carryover'),
  firstUnpaid('first-unpaid'),
  unpaid('unpaid'),
  makeup('makeup'),
  neutral('neutral');

  const ParentScheduleLessonTone(this.apiValue);

  final String apiValue;

  static ParentScheduleLessonTone fromApiValue(String? value) {
    return ParentScheduleLessonTone.values.firstWhere(
      (tone) => tone.apiValue == value,
      orElse: () => ParentScheduleLessonTone.neutral,
    );
  }
}

class ParentScheduleDayLesson {
  const ParentScheduleDayLesson({
    required this.lessonKey,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.tone,
    required this.groupId,
    required this.groupName,
    required this.placeId,
    required this.placeLabel,
    this.plannedLessonId,
  });

  factory ParentScheduleDayLesson.fromJson(Map<String, dynamic> json) {
    return ParentScheduleDayLesson(
      lessonKey: json['lessonKey'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      tone: ParentScheduleLessonTone.fromApiValue(json['tone'] as String?),
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      placeId: json['placeId'] as String,
      placeLabel: json['placeLabel'] as String,
      plannedLessonId: json['plannedLessonId'] as String?,
    );
  }

  final String lessonKey;
  final String title;
  final String subtitle;
  final String startTime;
  final String endTime;
  final ParentScheduleLessonTone tone;
  final String groupId;
  final String groupName;
  final String placeId;
  final String placeLabel;
  final String? plannedLessonId;
}

class ParentActivityScheduleDayPage {
  const ParentActivityScheduleDayPage({
    required this.dateIso,
    required this.dateLabel,
    required this.weekdayLabel,
    required this.isToday,
    required this.prevDateIso,
    required this.nextDateIso,
    required this.lessons,
    required this.showMakeupLegend,
  });

  factory ParentActivityScheduleDayPage.fromJson(Map<String, dynamic> json) {
    final lessons = json['lessons'] as List<dynamic>? ?? const [];

    return ParentActivityScheduleDayPage(
      dateIso: json['dateIso'] as String,
      dateLabel: json['dateLabel'] as String,
      weekdayLabel: json['weekdayLabel'] as String,
      isToday: json['isToday'] as bool? ?? false,
      prevDateIso: json['prevDateIso'] as String,
      nextDateIso: json['nextDateIso'] as String,
      showMakeupLegend: json['showMakeupLegend'] as bool? ?? false,
      lessons: lessons
          .map(
            (item) => ParentScheduleDayLesson.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String dateIso;
  final String dateLabel;
  final String weekdayLabel;
  final bool isToday;
  final String prevDateIso;
  final String nextDateIso;
  final bool showMakeupLegend;
  final List<ParentScheduleDayLesson> lessons;
}

enum ParentActivityPaymentReceiptKind {
  center('center'),
  tutor('tutor');

  const ParentActivityPaymentReceiptKind(this.apiValue);

  final String apiValue;

  static ParentActivityPaymentReceiptKind fromApiValue(String? value) {
    return ParentActivityPaymentReceiptKind.values.firstWhere(
      (kind) => kind.apiValue == value,
      orElse: () => ParentActivityPaymentReceiptKind.center,
    );
  }
}

enum ParentActivityPaymentsTab {
  accruals,
  receipts,
}

class ParentActivityPaymentReceiptItem {
  const ParentActivityPaymentReceiptItem({
    required this.id,
    required this.kind,
    required this.dateIso,
    required this.dateLabel,
    required this.amountLabel,
    required this.placeId,
    required this.placeLabel,
  });

  factory ParentActivityPaymentReceiptItem.fromJson(Map<String, dynamic> json) {
    return ParentActivityPaymentReceiptItem(
      id: json['id'] as String,
      kind: ParentActivityPaymentReceiptKind.fromApiValue(json['kind'] as String?),
      dateIso: json['dateIso'] as String,
      dateLabel: json['dateLabel'] as String,
      amountLabel: json['amountLabel'] as String,
      placeId: json['placeId'] as String,
      placeLabel: json['placeLabel'] as String,
    );
  }

  final String id;
  final ParentActivityPaymentReceiptKind kind;
  final String dateIso;
  final String dateLabel;
  final String amountLabel;
  final String placeId;
  final String placeLabel;
}

class ParentActivityPaymentAccrualItem {
  const ParentActivityPaymentAccrualItem({
    required this.id,
    required this.dateIso,
    required this.dateLabel,
    required this.amountLabel,
    required this.placeId,
    required this.placeLabel,
    required this.totalKopecks,
  });

  factory ParentActivityPaymentAccrualItem.fromJson(Map<String, dynamic> json) {
    return ParentActivityPaymentAccrualItem(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      dateLabel: json['dateLabel'] as String,
      amountLabel: json['amountLabel'] as String,
      placeId: json['placeId'] as String,
      placeLabel: json['placeLabel'] as String,
      totalKopecks: json['totalKopecks'] as int? ?? 0,
    );
  }

  final String id;
  final String dateIso;
  final String dateLabel;
  final String amountLabel;
  final String placeId;
  final String placeLabel;
  final int totalKopecks;
}

class ParentActivityPaymentsPage {
  const ParentActivityPaymentsPage({
    required this.accruals,
    required this.receipts,
  });

  factory ParentActivityPaymentsPage.fromJson(Map<String, dynamic> json) {
    final accruals = json['accruals'] as List<dynamic>? ?? const [];
    final receipts = json['receipts'] as List<dynamic>? ?? const [];

    return ParentActivityPaymentsPage(
      accruals: accruals
          .map(
            (item) => ParentActivityPaymentAccrualItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      receipts: receipts
          .map(
            (item) => ParentActivityPaymentReceiptItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final List<ParentActivityPaymentAccrualItem> accruals;
  final List<ParentActivityPaymentReceiptItem> receipts;
}

class ParentActivityReceiptDetailPage {
  const ParentActivityReceiptDetailPage({
    required this.id,
    required this.kind,
    required this.dateIso,
    required this.dateLabel,
    required this.titleLabel,
    required this.subtitle,
    required this.placeLabel,
    required this.acceptedLabel,
    required this.totalOnAccountLabel,
    required this.isWalletWizardV2,
    required this.hasGift,
    required this.hasRefund,
    this.giftLabel,
    this.refundLabel,
  });

  factory ParentActivityReceiptDetailPage.fromJson(Map<String, dynamic> json) {
    return ParentActivityReceiptDetailPage(
      id: json['id'] as String,
      kind: ParentActivityPaymentReceiptKind.fromApiValue(json['kind'] as String?),
      dateIso: json['dateIso'] as String,
      dateLabel: json['dateLabel'] as String,
      titleLabel: json['titleLabel'] as String,
      subtitle: json['subtitle'] as String,
      placeLabel: json['placeLabel'] as String,
      acceptedLabel: json['acceptedLabel'] as String,
      totalOnAccountLabel: json['totalOnAccountLabel'] as String,
      isWalletWizardV2: json['isWalletWizardV2'] as bool? ?? false,
      hasGift: json['hasGift'] as bool? ?? false,
      hasRefund: json['hasRefund'] as bool? ?? false,
      giftLabel: json['giftLabel'] as String?,
      refundLabel: json['refundLabel'] as String?,
    );
  }

  final String id;
  final ParentActivityPaymentReceiptKind kind;
  final String dateIso;
  final String dateLabel;
  final String titleLabel;
  final String subtitle;
  final String placeLabel;
  final String acceptedLabel;
  final String totalOnAccountLabel;
  final bool isWalletWizardV2;
  final bool hasGift;
  final bool hasRefund;
  final String? giftLabel;
  final String? refundLabel;
}

class ParentActivityAccrualDetailRow {
  const ParentActivityAccrualDetailRow({
    required this.amountLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.centerName,
    required this.classroomLabel,
  });

  factory ParentActivityAccrualDetailRow.fromJson(Map<String, dynamic> json) {
    return ParentActivityAccrualDetailRow(
      amountLabel: json['amountLabel'] as String,
      dateLabel: json['dateLabel'] as String,
      timeLabel: json['timeLabel'] as String,
      centerName: json['centerName'] as String,
      classroomLabel: json['classroomLabel'] as String,
    );
  }

  final String amountLabel;
  final String dateLabel;
  final String timeLabel;
  final String centerName;
  final String classroomLabel;
}

class ParentActivityAccrualDetailPage {
  const ParentActivityAccrualDetailPage({
    required this.id,
    required this.dateIso,
    required this.dateLabel,
    required this.placeLabel,
    required this.subtitle,
    required this.totalKopecks,
    required this.totalLabel,
    required this.rows,
  });

  factory ParentActivityAccrualDetailPage.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as List<dynamic>? ?? const [];

    return ParentActivityAccrualDetailPage(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      dateLabel: json['dateLabel'] as String,
      placeLabel: json['placeLabel'] as String,
      subtitle: json['subtitle'] as String,
      totalKopecks: json['totalKopecks'] as int? ?? 0,
      totalLabel: json['totalLabel'] as String,
      rows: rows
          .map(
            (item) => ParentActivityAccrualDetailRow.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String dateIso;
  final String dateLabel;
  final String placeLabel;
  final String subtitle;
  final int totalKopecks;
  final String totalLabel;
  final List<ParentActivityAccrualDetailRow> rows;
}
