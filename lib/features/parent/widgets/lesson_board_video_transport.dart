import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Streams a fixed lesson asset through loopback. Platform credentials never enter
/// the WebView, a scene, a URL query or a buffered/base64 copy of the video.
class LessonBoardVideoTransport {
  LessonBoardVideoTransport({
    required this.apiBase,
    required this.lessonSessionId,
    required this.roomId,
    required this.authorization,
    required this.isCurrent,
    this.childId,
  }) {
    if (!{'https', 'http'}.contains(apiBase.scheme) ||
        apiBase.host.isEmpty ||
        apiBase.userInfo.isNotEmpty ||
        !_uuid.hasMatch(lessonSessionId) ||
        !(roomId == 'main' || _uuid.hasMatch(roomId))) {
      throw ArgumentError('invalid_video_scope');
    }
  }

  static final _uuid = RegExp(
    r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
  );
  static final _asset = RegExp(r'^[a-f0-9]{32}$');
  static final _range = RegExp(
    r'^bytes=(?:[0-9]{1,15}-[0-9]{0,15}|-[0-9]{1,15})$',
  );
  static const maxVideoBytes = 256 * 1024 * 1024;
  static const _maxJsonBytes = 128 * 1024;
  static const _maxRequests = 6;
  final Uri apiBase;
  final String lessonSessionId;
  final String roomId;
  final String? childId;
  final Future<Map<String, String>> Function() authorization;
  final bool Function() isCurrent;
  static HttpClient _http(int sockets) => HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 10)
    ..maxConnectionsPerHost = sockets;
  final HttpClient _mediaClient = _http(6);
  // A room with several buffering clips must still receive play/pause/seek.
  final HttpClient _controlClient = _http(4);
  final _active = <HttpClientRequest>{};
  final _capability = List<int>.generate(
    24,
    (_) => Random.secure().nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  Future<HttpServer>? _starting;
  HttpServer? _server;
  bool _closed = false;
  int _requests = 0;
  int _controls = 0;

  bool get _current => !_closed && isCurrent();
  Map<String, String> get _query => {
    'lessonSessionId': lessonSessionId,
    'roomId': roomId,
    'childId': ?childId,
  };

  Uri _upstream(String path, Map<String, String> query) =>
      apiBase.replace(path: path, queryParameters: query, fragment: '');

  Future<String> source(String assetId) async {
    if (!_current || !_asset.hasMatch(assetId)) {
      throw StateError('video_scope_changed');
    }
    final server = await (_starting ??= () async {
      final next = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = next;
      if (!_current) {
        await next.close(force: true);
        throw StateError('video_scope_changed');
      }
      next.listen((request) {
        // Malformed local HTTP must be rejected, not escape as an unhandled
        // Future from a multi-valued Host/Origin/Range header.
        unawaited(
          _serve(request).catchError(
            (Object _) => _reject(request.response, HttpStatus.badRequest),
          ),
        );
      });
      return next;
    }());
    if (!_current) throw StateError('video_scope_changed');
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      path: '/video/$_capability/$assetId',
    ).toString();
  }

  Future<HttpClientRequest> _open(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    bool control = false,
  }) async {
    if (!_current) throw StateError('video_scope_changed');
    final credentials = await authorization().timeout(
      const Duration(seconds: 5),
    );
    if (!_current) throw StateError('video_scope_changed');
    final request = await (control ? _controlClient : _mediaClient).openUrl(
      method,
      uri,
    );
    request.done.ignore();
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    for (final entry in credentials.entries) {
      // No ambient cookie jar, arbitrary proxy headers or URL credentials.
      if ({
        'authorization',
        'x-larnes-lesson-guest-key',
      }.contains(entry.key.toLowerCase())) {
        request.headers.set(entry.key, entry.value);
      }
    }
    headers.forEach(request.headers.set);
    if (!_current) {
      request.abort();
      throw StateError('video_scope_changed');
    }
    _active.add(request);
    return request;
  }

  Future<Map<String, dynamic>> playback(
    String method,
    Map<String, dynamic>? command,
  ) async {
    if (!{'GET', 'POST'}.contains(method) || !_current) {
      throw StateError('video_scope_changed');
    }
    if (command != null && utf8.encode(jsonEncode(command)).length > 8192) {
      throw ArgumentError('invalid_video_command');
    }
    if (_controls >= 4) throw StateError('video_unavailable');
    _controls++;
    HttpClientRequest? opened;
    Timer? timer;
    try {
      final request = await _open(
        method,
        _upstream('/api/classroom/lesson-room/video-playback', _query),
        control: true,
      );
      opened = request;
      timer = Timer(const Duration(seconds: 25), () => request.abort());
      if (method == 'POST') {
        final data = utf8.encode(jsonEncode({...?command, ..._query}));
        request.headers
          ..contentType = ContentType.json
          ..set('Origin', apiBase.origin);
        request.contentLength = data.length;
        request.add(data);
      }
      final response = await request.close();
      if (!_current ||
          {401, 403, 404, 410}.contains(response.statusCode) ||
          (method == 'GET' && response.statusCode == 409)) {
        throw StateError('video_forbidden');
      }
      if (!{200, 409}.contains(response.statusCode)) {
        throw StateError('video_unavailable');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        if (!_current || bytes.length + chunk.length > _maxJsonBytes) {
          throw StateError('video_unavailable');
        }
        bytes.addAll(chunk);
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> || !_current) {
        throw StateError('video_unavailable');
      }
      if (method == 'GET') return _publicDelivery(value);
      final accepted = value['accepted'], reason = value['reason'];
      if (accepted is! bool) throw StateError('video_unavailable');
      return {
        'accepted': accepted,
        if ({
          'invalid',
          'forbidden',
          'missing',
          'wrong-revision',
          'operation-conflict',
          'unavailable',
        }.contains(reason))
          'reason': reason,
        'snapshot': _publicDelivery(value['snapshot']),
      };
    } finally {
      timer?.cancel();
      if (opened != null) {
        _active.remove(opened);
        opened.abort();
      }
      _controls--;
    }
  }

  Map<String, dynamic> _publicDelivery(Object? value) {
    // Only the public timeline crosses the bridge, even if an intermediary
    // added extra diagnostics to an otherwise valid JSON response.
    if (value is! Map ||
        value['protocolVersion'] != 1 ||
        value['lessonSessionId'] != lessonSessionId ||
        value['roomId'] != roomId ||
        value['serverAt'] is! num ||
        value['sequence'] is! int ||
        value['states'] is! List ||
        (value['states'] as List).length > 16) {
      throw StateError('video_unavailable');
    }
    const numbers = ['duration', 'revision', 'position', 'rate', 'anchorAt'];
    return {
      'protocolVersion': 1,
      'lessonSessionId': lessonSessionId,
      'roomId': roomId,
      'serverAt': value['serverAt'],
      'sequence': value['sequence'],
      'states': (value['states'] as List)
          .map((state) {
            if (state is! Map ||
                state['instanceId'] is! String ||
                !_uuid.hasMatch(state['instanceId'] as String) ||
                state['assetId'] is! String ||
                !_asset.hasMatch(state['assetId'] as String) ||
                state['playing'] is! bool ||
                numbers.any((key) => state[key] is! num)) {
              throw StateError('video_unavailable');
            }
            return {
              for (final key in [
                'instanceId',
                'assetId',
                'playing',
                ...numbers,
              ])
                key: state[key],
            };
          })
          .toList(growable: false),
    };
  }

  Future<void> _reject(HttpResponse response, int status) async {
    try {
      response.statusCode = status;
      response.headers.set(HttpHeaders.cacheControlHeader, 'private, no-store');
      await response.close();
    } catch (_) {
      // The WebView may have already cancelled its range request.
    }
  }

  Future<void> _serve(HttpRequest local) async {
    final response = local.response, server = _server;
    final parts = local.uri.pathSegments;
    final origin = local.headers.value('Origin');
    if (!_current ||
        server == null ||
        local.headers.value(HttpHeaders.hostHeader) !=
            '127.0.0.1:${server.port}' ||
        parts.length != 3 ||
        parts[0] != 'video' ||
        parts[1] != _capability ||
        !_asset.hasMatch(parts[2]) ||
        local.uri.hasQuery ||
        (origin != null && origin != apiBase.origin)) {
      return _reject(response, HttpStatus.forbidden);
    }
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'private, no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Cross-Origin-Resource-Policy', 'cross-origin')
      ..set('Access-Control-Allow-Origin', apiBase.origin)
      ..set('Vary', 'Origin')
      ..set(
        'Access-Control-Expose-Headers',
        'Content-Range,Accept-Ranges,ETag',
      );
    if (local.method == 'OPTIONS') {
      response.headers
        ..set('Access-Control-Allow-Methods', 'GET,HEAD,OPTIONS')
        ..set('Access-Control-Allow-Headers', 'Range,If-Range')
        ..set('Access-Control-Allow-Private-Network', 'true');
      return _reject(response, HttpStatus.noContent);
    }
    if (!{'GET', 'HEAD'}.contains(local.method)) {
      return _reject(response, HttpStatus.methodNotAllowed);
    }
    final range = local.headers.value(HttpHeaders.rangeHeader);
    final ifRange = local.headers.value(HttpHeaders.ifRangeHeader);
    if ((range != null && !_range.hasMatch(range)) ||
        (ifRange != null && ifRange.length > 512)) {
      return _reject(response, HttpStatus.requestedRangeNotSatisfiable);
    }
    if (_requests >= _maxRequests) {
      return _reject(response, HttpStatus.serviceUnavailable);
    }
    _requests++;
    HttpClientRequest? upstream;
    Timer? timer;
    var started = false;
    try {
      upstream = await _open(
        local.method,
        _upstream('/api/classroom/lesson-room/video', {
          ..._query,
          'assetId': parts[2],
          'content': '1',
        }),
        headers: {
          HttpHeaders.rangeHeader: ?range,
          HttpHeaders.ifRangeHeader: ?ifRange,
        },
      );
      final active = upstream;
      timer = Timer(const Duration(minutes: 5), () => active.abort());
      unawaited(
        response.done.then<void>(
          (_) => active.abort(),
          onError: (Object _, StackTrace _) => active.abort(),
        ),
      );
      final incoming = await active.close().timeout(
        const Duration(seconds: 20),
      );
      if (!_current) return _reject(response, HttpStatus.forbidden);
      if (!{200, 206, 416}.contains(incoming.statusCode)) {
        return _reject(
          response,
          {401, 403, 404, 409, 410}.contains(incoming.statusCode)
              ? incoming.statusCode
              : HttpStatus.badGateway,
        );
      }
      if (incoming.statusCode != 416 &&
          (incoming.headers.contentType?.mimeType != 'video/mp4' ||
              incoming.contentLength < 0 ||
              incoming.contentLength > maxVideoBytes ||
              !{null, 'identity'}.contains(
                incoming.headers.value(HttpHeaders.contentEncodingHeader),
              ))) {
        return _reject(response, HttpStatus.badGateway);
      }
      response.statusCode = incoming.statusCode;
      response.bufferOutput = false;
      for (final key in [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.contentRangeHeader,
        HttpHeaders.acceptRangesHeader,
        HttpHeaders.etagHeader,
        HttpHeaders.lastModifiedHeader,
      ]) {
        final value = incoming.headers.value(key);
        if (value != null) response.headers.set(key, value);
      }
      if (incoming.statusCode == 416) {
        response.contentLength = 0;
      } else if (incoming.contentLength >= 0) {
        response.contentLength = incoming.contentLength;
      }
      started = true;
      if (local.method != 'HEAD' && incoming.statusCode != 416) {
        var bytes = 0;
        Stream<List<int>> checked() async* {
          await for (final chunk in incoming.timeout(
            const Duration(seconds: 25),
          )) {
            if (!_current || (bytes += chunk.length) > maxVideoBytes) {
              throw StateError('video_scope_changed');
            }
            yield chunk;
          }
          if (bytes != incoming.contentLength) {
            throw StateError('video_incomplete');
          }
        }

        await response.addStream(checked());
      }
      await response.close();
    } catch (_) {
      if (!started) {
        await _reject(response, HttpStatus.badGateway);
      } else {
        try {
          await response.close();
        } catch (_) {}
      }
    } finally {
      timer?.cancel();
      if (upstream != null) {
        _active.remove(upstream);
        upstream.abort();
      }
      _requests--;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final request in _active.toList()) {
      request.abort();
    }
    _active.clear();
    _mediaClient.close(force: true);
    _controlClient.close(force: true);
    await _server?.close(force: true);
  }
}
