import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.accountType,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      accountType: json['accountType'] as String,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
    );
  }

  final String id;
  final String accountType;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  String get displayName {
    final parts = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty);
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return email ?? phone ?? id;
  }
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.accountType,
    required this.homePath,
    required this.user,
  });

  final String token;
  final String accountType;
  final String homePath;
  final AuthUser user;
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<LoginResult> login({
    required String login,
    required String password,
    String locale = 'ru',
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/mobile/auth/login',
        data: {'login': login, 'password': password, 'locale': locale},
      );
      final data = response.data;
      if (data == null || data['status'] != 'success') {
        throw AuthApiException(_messageFromBody(data));
      }
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Не удалось получить токен.');
      }
      await _client.tokenStorage.writeToken(token);
      return LoginResult(
        token: token,
        accountType: data['accountType'] as String,
        homePath: data['homePath'] as String? ?? '/parent',
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        throw AuthApiException(_messageFromBody(body));
      }
      throw AuthApiException(_networkMessage(error));
    }
  }

  Future<AuthUser?> fetchSession() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/mobile/auth/session',
      );
      final data = response.data;
      if (data == null || data['status'] != 'success') {
        return null;
      }
      return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _client.tokenStorage.clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() => _client.tokenStorage.clearToken();

  static String _messageFromBody(Map<String, dynamic>? body) {
    final message = body?['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
    return 'Ошибка запроса.';
  }

  static String _networkMessage(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Нет связи с сервером. Проверьте интернет.';
    }
    return 'Не удалось выполнить запрос.';
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
