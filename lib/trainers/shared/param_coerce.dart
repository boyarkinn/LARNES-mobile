int? coerceInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.truncate();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? coerceDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

List<int>? coerceIntList(dynamic value) {
  if (value is! List) {
    return null;
  }
  final result = <int>[];
  for (final item in value) {
    final parsed = coerceInt(item);
    if (parsed == null) {
      return null;
    }
    result.add(parsed);
  }
  return result;
}
