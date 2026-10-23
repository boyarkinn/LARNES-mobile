enum TrainerDirection {
  math,
  mental,
  reading,
  speedReading,
  intel;

  static TrainerDirection? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    if (value == 'speed-reading') {
      return TrainerDirection.speedReading;
    }
    final normalized = value == 'mental-arithmetic' ? 'mental' : value;
    for (final direction in TrainerDirection.values) {
      if (direction.name == normalized) {
        return direction;
      }
    }
    return null;
  }
}
