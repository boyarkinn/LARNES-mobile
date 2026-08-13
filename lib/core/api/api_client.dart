import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/api_error_body.dart';
import 'package:larnes_mobile/core/api/admin_trainers_api.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';
import 'package:larnes_mobile/core/api/confirm_family_children_api.dart';
import 'package:larnes_mobile/core/api/family_adult_claim_api.dart';
import 'package:larnes_mobile/core/api/family_invites_api.dart';
import 'package:larnes_mobile/core/api/family_join_dedup_api.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/api/network_api.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/api/register_school_offers_api.dart';
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
                validateStatus: apiStatusAcceptable,
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
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint('[API] $object'),
        ),
      );
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  RegisterApi? _registerApi;
  PasswordResetApi? _passwordResetApi;
  ParentApi? _parentApi;
  ParentAccountApi? _parentAccountApi;
  AdminAccountApi? _adminAccountApi;
  AdminTrainersApi? _adminTrainersApi;
  FamilySetupApi? _familySetupApi;
  GuardiansApi? _guardiansApi;
  FamilyInvitesApi? _familyInvitesApi;
  FamilyAdultClaimApi? _familyAdultClaimApi;
  ConfirmFamilyChildrenApi? _confirmFamilyChildrenApi;
  FamilyJoinDedupApi? _familyJoinDedupApi;
  NetworkApi? _networkApi;
  PlacesApi? _placesApi;
  RegisterSchoolOffersApi? _registerSchoolOffersApi;

  Dio get dio => _dio;

  TokenStorage get tokenStorage => _tokenStorage;

  RegisterApi get registerApi => _registerApi ??= RegisterApi(this);

  PasswordResetApi get passwordResetApi =>
      _passwordResetApi ??= PasswordResetApi(this);

  ParentApi get parentApi => _parentApi ??= ParentApi(this);

  ParentAccountApi get parentAccountApi => _parentAccountApi ??= ParentAccountApi(this);

  AdminAccountApi get adminAccountApi => _adminAccountApi ??= AdminAccountApi(this);

  AdminTrainersApi get adminTrainersApi => _adminTrainersApi ??= AdminTrainersApi(this);

  FamilySetupApi get familySetupApi => _familySetupApi ??= FamilySetupApi(this);

  GuardiansApi get guardiansApi => _guardiansApi ??= GuardiansApi(this);

  FamilyInvitesApi get familyInvitesApi => _familyInvitesApi ??= FamilyInvitesApi(this);

  FamilyAdultClaimApi get familyAdultClaimApi =>
      _familyAdultClaimApi ??= FamilyAdultClaimApi(this);

  ConfirmFamilyChildrenApi get confirmFamilyChildrenApi =>
      _confirmFamilyChildrenApi ??= ConfirmFamilyChildrenApi(this);

  FamilyJoinDedupApi get familyJoinDedupApi =>
      _familyJoinDedupApi ??= FamilyJoinDedupApi(this);

  NetworkApi get networkApi => _networkApi ??= NetworkApi(this);

  PlacesApi get placesApi => _placesApi ??= PlacesApi(this);

  RegisterSchoolOffersApi get registerSchoolOffersApi =>
      _registerSchoolOffersApi ??= RegisterSchoolOffersApi(this);
}
