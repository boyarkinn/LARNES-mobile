import 'package:larnes_mobile/core/time/user_time_zone.dart';
import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';

class ChildSessionApiClient {
  ChildSessionApiClient({
    ChildSessionTokenStorage? childSessionTokenStorage,
    Dio? dio,
  }) : _childSessionTokenStorage =
           childSessionTokenStorage ?? ChildSessionTokenStorage(),
       _dio =
           dio ??
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
          await UserTimeZone.refreshDeviceZone();
          if (UserTimeZone.deviceZone != null) {
            options.headers['x-larnes-time-zone'] = UserTimeZone.deviceZone;
          }
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

  Dio get dio => _dio;

  ChildSessionTokenStorage get childSessionTokenStorage =>
      _childSessionTokenStorage;
}
