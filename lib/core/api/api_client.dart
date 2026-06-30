import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';

class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
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
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  RegisterApi? _registerApi;
  ParentApi? _parentApi;
  ParentAccountApi? _parentAccountApi;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;

  RegisterApi get registerApi => _registerApi ??= RegisterApi(this);

  ParentApi get parentApi => _parentApi ??= ParentApi(this);

  ParentAccountApi get parentAccountApi => _parentAccountApi ??= ParentAccountApi(this);
}
