enum TrainerDirection {
  math,
  mental;

  static TrainerDirection? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final direction in TrainerDirection.values) {
      if (direction.name == value) {
        return direction;
      }
    }
    return null;
  }
}
