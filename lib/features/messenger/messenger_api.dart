import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_wire.dart';

/// Thin calls to the existing lesson messenger. This client does not log bodies or guest keys.
abstract class MessengerGateway {
  Future<MessengerValue<MessengerCapabilities>> open(MessengerScope scope);
  Future<MessengerValue<MessengerPage>> history(
    MessengerScope scope, {
    String? after,
    String? before,
  });
  Future<MessengerValue<({int unread, int waitMs})>> summary(
    MessengerScope scope,
  );
  Future<MessengerValue<void>> markRead(MessengerScope scope, String cursor);
  Future<MessengerValue<MessengerSent>> send(
    MessengerScope scope, {
    required String body,
    required String clientKey,
    required List<String> fileIds,
    String? replyToMessageId,
  });
  Future<MessengerValue<MessengerFileCard>> upload(
    MessengerScope scope, {
    required String id,
    required String name,
    required String mime,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancel,
  });
  Future<MessengerValue<MessengerFileCard>> fileStatus(
    MessengerScope scope,
    String id,
  );
  Future<MessengerValue<MessengerFileCard>> fileMeta(
    MessengerScope scope,
    String id,
  );
  Future<MessengerValue<void>> cancelFile(MessengerScope scope, String id);
  Future<MessengerValue<Uint8List>> download(MessengerScope scope, String id);
  Future<MessengerValue<MessengerArchivePage>> archive(
    MessengerScope scope, {
    String? before,
  });
}

class MessengerApi implements MessengerGateway {
  MessengerApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 2),
              sendTimeout: const Duration(minutes: 2),
              validateStatus: (status) => status != null && status < 600,
            ),
          );
  final Dio _dio;
  final Map<String, Set<CancelToken>> _active = {};

  void cancelScope(MessengerScope scope) {
    for (final token in _active.remove(scope.sessionKey) ?? <CancelToken>{}) {
      token.cancel();
    }
  }

  Future<Response<T>> _run<T>(
    MessengerScope scope,
    Future<Response<T>> Function(Map<String, String>, CancelToken) work, {
    CancelToken? cancel,
  }) async {
    final token = CancelToken();
    (_active[scope.sessionKey] ??= {}).add(token);
    if (cancel != null) {
      if (cancel.isCancelled) token.cancel();
      unawaited(
        cancel.whenCancel.then((_) {
          if (!token.isCancelled) token.cancel();
        }),
      );
    }
    try {
      final headers = await scope.authorization();
      if (token.isCancelled) throw StateError('cancelled');
      return await work(headers, token).timeout(const Duration(minutes: 2));
    } catch (_) {
      token.cancel();
      return Response<T>(
        requestOptions: RequestOptions(path: '/messenger'),
        statusCode: 503,
      );
    } finally {
      _active[scope.sessionKey]?.remove(token);
      if (_active[scope.sessionKey]?.isEmpty == true) {
        _active.remove(scope.sessionKey);
      }
    }
  }

  @override
  Future<MessengerValue<MessengerCapabilities>> open(MessengerScope scope) =>
      _read(scope, view: 'open', parse: messengerCapabilitiesFromJson);
  @override
  Future<MessengerValue<MessengerPage>> history(
    MessengerScope scope, {
    String? after,
    String? before,
  }) => _read(
    scope,
    view: 'history',
    after: after,
    before: before,
    parse: messengerPageFromJson,
  );
  @override
  Future<MessengerValue<({int unread, int waitMs})>> summary(
    MessengerScope scope,
  ) => _read(scope, view: 'summary', parse: messengerSummaryFromJson);
  @override
  Future<MessengerValue<void>> markRead(MessengerScope scope, String cursor) =>
      command(scope, {'action': 'read', 'cursor': cursor});
  Future<MessengerValue<void>> command(
    MessengerScope scope,
    Map<String, Object?> body,
  ) async {
    final response = await _post(scope, body);
    final code = _code(response);
    return code == null ? const MessengerOk(null) : MessengerDenied(code);
  }

  @override
  Future<MessengerValue<MessengerSent>> send(
    MessengerScope scope, {
    required String body,
    required String clientKey,
    required List<String> fileIds,
    String? replyToMessageId,
  }) async => _value(
    await _post(scope, {
      'action': 'send',
      'body': body,
      'clientKey': clientKey,
      'fileIds': fileIds,
      'replyToMessageId': replyToMessageId,
    }),
    messengerSentFromJson,
  );
  @override
  Future<MessengerValue<MessengerFileCard>> upload(
    MessengerScope scope, {
    required String id,
    required String name,
    required String mime,
    required Uint8List bytes,
    void Function(int, int)? onProgress,
    CancelToken? cancel,
  }) async {
    final response = await _run<Object>(
      scope,
      (headers, token) => _dio.post<Object>(
        _filePath(scope, id),
        data: bytes,
        cancelToken: token,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            ...headers,
            'content-type': mime,
            'x-file-size': bytes.length.toString(),
            'x-file-name': Uri.encodeComponent(name),
          },
        ),
      ),
      cancel: cancel,
    );
    return _value(response, messengerFileCardFromJson);
  }

  @override
  Future<MessengerValue<MessengerFileCard>> fileStatus(
    MessengerScope scope,
    String id,
  ) => _fileRead(scope, id, 'status');
  @override
  Future<MessengerValue<MessengerFileCard>> fileMeta(
    MessengerScope scope,
    String id,
  ) => _fileRead(scope, id, 'meta');
  @override
  Future<MessengerValue<void>> cancelFile(
    MessengerScope scope,
    String id,
  ) async {
    final response = await _run<Object>(
      scope,
      (headers, token) => _dio.delete<Object>(
        _filePath(scope, id),
        options: Options(headers: headers),
        cancelToken: token,
      ),
    );
    final code = _code(response);
    return code == null ? const MessengerOk(null) : MessengerDenied(code);
  }

  @override
  Future<MessengerValue<Uint8List>> download(
    MessengerScope scope,
    String id,
  ) async {
    final response = await _run<List<int>>(
      scope,
      (headers, token) => _dio.get<List<int>>(
        _filePath(scope, id),
        options: Options(headers: headers, responseType: ResponseType.bytes),
        cancelToken: token,
      ),
    );
    final code = messengerErrorCode(null, response.statusCode);
    if (code != null) return MessengerDenied(code);
    if (response.data == null) return const MessengerDenied('unavailable');
    return MessengerOk(Uint8List.fromList(response.data!));
  }

  @override
  Future<MessengerValue<MessengerArchivePage>> archive(
    MessengerScope scope, {
    String? before,
  }) async {
    final response = await _run<Object>(
      scope,
      (headers, token) => _dio.get<Object>(
        '/api/messenger/conversations',
        queryParameters: {
          'scope': 'child',
          'childId': ?scope.childId,
          'before': ?before,
        },
        options: Options(headers: headers),
        cancelToken: token,
      ),
    );
    return _value(response, messengerArchiveFromJson);
  }

  Future<MessengerValue<MessengerFileCard>> _fileRead(
    MessengerScope scope,
    String id,
    String view,
  ) async {
    final response = await _run<Object>(
      scope,
      (headers, token) => _dio.get<Object>(
        _filePath(scope, id, view: view),
        options: Options(headers: headers),
        cancelToken: token,
      ),
    );
    return _value(response, messengerFileCardFromJson);
  }

  Future<MessengerValue<T>> _read<T>(
    MessengerScope scope, {
    required String view,
    required T? Function(Object?) parse,
    String? after,
    String? before,
  }) async {
    final response = await _run<Object>(
      scope,
      (headers, token) => _dio.get<Object>(
        _lessonPath(scope),
        queryParameters: scope.query(view: view, after: after, before: before),
        options: Options(headers: headers),
        cancelToken: token,
      ),
    );
    return _value(response, parse);
  }

  Future<Response<Object>> _post(
    MessengerScope scope,
    Map<String, Object?> body,
  ) => _run(
    scope,
    (headers, token) => _dio.post<Object>(
      _lessonPath(scope),
      data: body,
      queryParameters: scope.query(view: 'history'),
      options: Options(
        headers: {...headers, 'content-type': 'application/json'},
      ),
      cancelToken: token,
    ),
  );
  MessengerValue<T> _value<T>(
    Response<Object?> response,
    T? Function(Object?) parse,
  ) {
    final code = _code(response);
    if (code != null) return MessengerDenied(code);
    final value = parse(response.data);
    return value == null
        ? const MessengerDenied('unavailable')
        : MessengerOk(value);
  }

  String? _code(Response<Object?> response) =>
      messengerErrorCode(response.data, response.statusCode);
  String _lessonPath(MessengerScope scope) =>
      '/api/messenger/lessons/${Uri.encodeComponent(scope.lessonSessionId)}';
  String _filePath(MessengerScope scope, String id, {String? view}) =>
      '${_lessonPath(scope)}/files/${Uri.encodeComponent(id)}?${Uri(queryParameters: scope.query(view: view)).query}';
}
