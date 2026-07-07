import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/family_invites_api.dart';
import 'package:larnes_mobile/core/api/family_join_dedup_api.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/api/network_api.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
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
  PasswordResetApi? _passwordResetApi;
  ParentApi? _parentApi;
  ParentAccountApi? _parentAccountApi;
  FamilySetupApi? _familySetupApi;
  GuardiansApi? _guardiansApi;
  FamilyInvitesApi? _familyInvitesApi;
  FamilyJoinDedupApi? _familyJoinDedupApi;
  NetworkApi? _networkApi;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;

  RegisterApi get registerApi => _registerApi ??= RegisterApi(this);

  PasswordResetApi get passwordResetApi =>
      _passwordResetApi ??= PasswordResetApi(this);

  ParentApi get parentApi => _parentApi ??= ParentApi(this);

  ParentAccountApi get parentAccountApi => _parentAccountApi ??= ParentAccountApi(this);

  FamilySetupApi get familySetupApi => _familySetupApi ??= FamilySetupApi(this);

  GuardiansApi get guardiansApi => _guardiansApi ??= GuardiansApi(this);

  FamilyInvitesApi get familyInvitesApi => _familyInvitesApi ??= FamilyInvitesApi(this);

  FamilyJoinDedupApi get familyJoinDedupApi =>
      _familyJoinDedupApi ??= FamilyJoinDedupApi(this);

  NetworkApi get networkApi => _networkApi ??= NetworkApi(this);
}
