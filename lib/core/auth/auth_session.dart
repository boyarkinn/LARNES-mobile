import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/api_client.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/api/register_api.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({ApiClient? apiClient}) : _client = apiClient ?? ApiClient() {
    _authApi = AuthApi(_client);
    _registerApi = RegisterApi(_client);
  }

  final ApiClient _client;
  late final AuthApi _authApi;
  late final RegisterApi _registerApi;

  AuthUser? _user;
  bool _isLoading = true;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthApi get authApi => _authApi;
  RegisterApi get registerApi => _registerApi;

  Future<String> completeRegistration(LoginResult result) async {
    _user = result.user;
    notifyListeners();
    return result.homePath;
  }

  Future<void> bootstrap() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authApi.fetchSession();
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> login({
    required String login,
    required String password,
  }) async {
    final result = await _authApi.login(login: login, password: password);
    _user = result.user;
    notifyListeners();
    return result.homePath;
  }

  Future<void> logout() async {
    await _authApi.logout();
    _user = null;
    notifyListeners();
  }
}
