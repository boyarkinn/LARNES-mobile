import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';

class AuthSession extends ChangeNotifier {
  factory AuthSession({ApiClient? apiClient}) {
    final client = apiClient ?? ApiClient();
    return AuthSession._(client);
  }

  AuthSession._(this._client) : _authApi = AuthApi(_client);

  final ApiClient _client;
  final AuthApi _authApi;

  AuthUser? _user;
  bool _isLoading = true;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthApi get authApi => _authApi;

  /// Через ApiClient — ленивая инициализация, устойчивее к hot reload.
  RegisterApi get registerApi => _client.registerApi;

  ParentApi get parentApi => _client.parentApi;

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<String> completeRegistration(LoginResult result) async {
    _user = result.user;
    _notifySafely();
    return result.homePath;
  }

  Future<void> bootstrap() async {
    _isLoading = true;
    _notifySafely();
    try {
      _user = await _authApi.fetchSession();
    } catch (_) {
      _user = null;
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
    _notifySafely();
    return result.homePath;
  }

  Future<void> logout() async {
    await _authApi.logout();
    _user = null;
    _notifySafely();
  }
}
