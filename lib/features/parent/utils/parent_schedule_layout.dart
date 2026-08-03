const parentScheduleStartHour = 7;
const parentScheduleEndHour = 21;
const parentScheduleHourHeight = 56.0;

int scheduleTimeToMinutes(String value) {
  final parts = value.split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return hours * 60 + minutes;
}

String scheduleFormatHourLabel(int hour) {
  return '${hour.toString().padLeft(2, '0')}:00';
}

double scheduleSlotTopPx(String startTime) {
  return ((scheduleTimeToMinutes(startTime) - parentScheduleStartHour * 60) / 60) *
      parentScheduleHourHeight;
}

double scheduleSlotHeightPx(String startTime, String endTime) {
  final durationMinutes = scheduleTimeToMinutes(endTime) - scheduleTimeToMinutes(startTime);
  return (durationMinutes / 60 * parentScheduleHourHeight).clamp(28.0, double.infinity);
}

double get parentScheduleGridHeight =>
    (parentScheduleEndHour - parentScheduleStartHour) * parentScheduleHourHeight;
