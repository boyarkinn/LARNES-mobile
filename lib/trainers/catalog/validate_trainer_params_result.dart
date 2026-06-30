class ValidateTrainerParamsResult {
  const ValidateTrainerParamsResult._({
    required this.ok,
    this.params,
    this.error,
  });

  const ValidateTrainerParamsResult.success(Map<String, dynamic> params)
      : this._(ok: true, params: params);

  const ValidateTrainerParamsResult.failure(String error)
      : this._(ok: false, error: error);

  final bool ok;
  final Map<String, dynamic>? params;
  final String? error;
}
