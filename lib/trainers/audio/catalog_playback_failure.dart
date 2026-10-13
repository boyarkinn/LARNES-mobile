import 'package:flutter/foundation.dart';

/// Only the active exercise's required files can block its shell.
final catalogPlaybackFailures = ValueNotifier<int>(0);
Set<String> _requiredPaths = {};
void setRequiredCatalogPaths(Iterable<String> paths) =>
    _requiredPaths = paths.toSet();
bool reportRequiredCatalogFailure(Iterable<String> paths) {
  if (!paths.any(_requiredPaths.contains)) return false;
  catalogPlaybackFailures.value++;
  return true;
}
