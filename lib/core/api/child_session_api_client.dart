import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/kiosk_program_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';

class ChildSessionApiClient {
  ChildSessionApiClient({ChildSessionTokenStorage? childSessionTokenStorage, Dio? dio})
      : _childSessionTokenStorage =
            childSessionTokenStorage ?? ChildSessionTokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _childSessionTokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final ChildSessionTokenStorage _childSessionTokenStorage;
  KioskProgramApi? _kioskProgramApi;

  Dio get dio => _dio;

  ChildSessionTokenStorage get childSessionTokenStorage => _childSessionTokenStorage;

  KioskProgramApi get kioskProgramApi => _kioskProgramApi ??= KioskProgramApi(this);
}
