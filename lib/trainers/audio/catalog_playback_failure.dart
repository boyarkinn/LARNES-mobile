import 'package:flutter/foundation.dart';

/// Only the active exercise's required files can block its shell.
final catalogPlaybackFailures = ValueNotifier<int>(0);
final catalogPlaybackIssues = ValueNotifier<CatalogPlaybackIssue?>(null);

class CatalogPlaybackIssue {
  const CatalogPlaybackIssue(this.paths, this.blocking);
  final List<String> paths;
  final bool blocking;
}

Set<String> _requiredPaths = {};
Set<String> _observedPaths = {};
void setObservedCatalogPaths(Iterable<String> paths) =>
    _observedPaths = paths.toSet();
void setRequiredCatalogPaths(Iterable<String> paths) =>
    _requiredPaths = paths.toSet();
bool reportRequiredCatalogFailure(Iterable<String> paths) {
  final affected = paths.toList();
  final blocking = affected.any(_requiredPaths.contains);
  if (blocking || affected.any(_observedPaths.contains)) {
    catalogPlaybackIssues.value = CatalogPlaybackIssue(affected, blocking);
  }
  if (!blocking) return false;
  catalogPlaybackFailures.value++;
  return true;
}
