import 'package:larnes_mobile/features/parent/models/parent_activity.dart';
import 'package:larnes_mobile/features/parent/theme/activity_payment_colors.dart';

ActivityPaymentSurfaceColors attendanceCalendarCellColors(ParentAttendanceCellTone tone) {
  return activityPaymentSurfaceColors(tone.apiValue);
}

ActivityPaymentSurfaceColors scheduleLessonColors(ParentScheduleLessonTone tone) {
  return activityPaymentSurfaceColors(tone.apiValue);
}

const attendanceCalendarLegendPaid = activityPaymentLegendPaid;
const attendanceCalendarLegendFirstUnpaid = activityPaymentLegendFirstUnpaid;
const attendanceCalendarLegendUnpaid = activityPaymentLegendUnpaid;
const attendanceCalendarLegendMakeup = activityPaymentLegendMakeup;
