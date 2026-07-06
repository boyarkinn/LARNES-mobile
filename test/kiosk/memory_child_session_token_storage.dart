import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';

/// In-memory [ChildSessionTokenStorage] for unit/widget tests.
class MemoryChildSessionTokenStorage extends ChildSessionTokenStorage {
  MemoryChildSessionTokenStorage();

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}
