enum TrainerDirection {
  math,
  mental,
  reading,
  intel;

  static TrainerDirection? tryParse(String? value) {
    if (value == null) {
      return null;
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
