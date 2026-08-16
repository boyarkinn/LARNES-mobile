import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/api/kiosk_trainer_api.dart';
import 'package:larnes_mobile/core/auth/device_token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';

class KioskApiClient {
  KioskApiClient({DeviceTokenStorage? deviceTokenStorage, Dio? dio})
      : _deviceTokenStorage = deviceTokenStorage ?? DeviceTokenStorage(),
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
          final token = await _deviceTokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final DeviceTokenStorage _deviceTokenStorage;
  KioskApi? _kioskApi;
  KioskTrainerApi? _trainerApi;

  Dio get dio => _dio;

  DeviceTokenStorage get deviceTokenStorage => _deviceTokenStorage;

  KioskApi get kioskApi => _kioskApi ??= KioskApi(this);

  KioskTrainerApi get trainerApi => _trainerApi ??= KioskTrainerApi(this);
}
