import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/family_invites_api.dart';
import 'package:larnes_mobile/core/api/family_join_dedup_api.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/api/network_api.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

class AuthSession extends ChangeNotifier {
  factory AuthSession({ApiClient? apiClient}) {
    final client = apiClient ?? ApiClient();
    return AuthSession._(client);
  }

  AuthSession._(this._client) : _authApi = AuthApi(_client);

  final ApiClient _client;
  final AuthApi _authApi;

  AuthUser? _user;
  FamilySetupSnapshot? _familySetup;
  bool _isLoading = true;

  AuthUser? get user => _user;
  FamilySetupSnapshot? get familySetup => _familySetup;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// `null` — не parent или статус ещё не загружен.
  bool? get familySetupComplete {
    if (!isParentAccount(_user?.accountType)) {
      return null;
    }
    return _familySetup?.isComplete;
  }

  AuthApi get authApi => _authApi;

  RegisterApi get registerApi => _client.registerApi;

  PasswordResetApi get passwordResetApi => _client.passwordResetApi;

  ParentApi get parentApi => _client.parentApi;

  ParentAccountApi get parentAccountApi => _client.parentAccountApi;

  FamilySetupApi get familySetupApi => _client.familySetupApi;

  GuardiansApi get guardiansApi => _client.guardiansApi;

  FamilyInvitesApi get familyInvitesApi => _client.familyInvitesApi;

  FamilyJoinDedupApi get familyJoinDedupApi => _client.familyJoinDedupApi;

  NetworkApi get networkApi => _client.networkApi;

  void applyUser(AuthUser user) {
    _user = user;
    _notifySafely();
  }

  void applyFamilySetup(FamilySetupSnapshot snapshot) {
    _familySetup = snapshot;
    _notifySafely();
  }

  Future<void> refreshFamilySetup({String locale = 'ru'}) async {
    if (!isParentAccount(_user?.accountType)) {
      _familySetup = null;
      _notifySafely();
      return;
    }

    try {
      _familySetup = await _client.familySetupApi.fetchStatus(locale: locale);
      _notifySafely();
    } catch (_) {
      // keep previous snapshot on transient errors
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authApi.fetchSession();
      _user = user;
      _notifySafely();
    } catch (_) {
      // keep current user on transient errors
    }
  }

  void _notifySafely() {
    if (!hasListeners) {
      return;
    }

    scheduleMicrotask(() {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<String> completeRegistration(LoginResult result) async {
    _user = result.user;
    await refreshFamilySetup();
    _notifySafely();
    return result.homePath;
  }

  Future<void> bootstrap() async {
    _isLoading = true;
    _notifySafely();
    try {
      _user = await _authApi.fetchSession();
      if (isParentAccount(_user?.accountType)) {
        try {
          _familySetup = await _client.familySetupApi.fetchStatus();
        } catch (_) {
          _familySetup = null;
        }
      } else {
        _familySetup = null;
      }
    } catch (_) {
      _user = null;
      _familySetup = null;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<String> login({
    required String login,
    required String password,
    String locale = 'ru',
  }) async {
    final result = await _authApi.login(
      login: login,
      password: password,
      locale: locale,
    );
    _user = result.user;
    await refreshFamilySetup(locale: locale);
    _notifySafely();
    return result.homePath;
  }

  Future<void> logout() async {
    await _authApi.logout();
    _user = null;
    _familySetup = null;
    _notifySafely();
  }

  Future<void> persistToken(String token) async {
    await _client.tokenStorage.writeToken(token);
  }
}
