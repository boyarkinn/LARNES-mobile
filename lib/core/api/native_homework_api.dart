import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class NativeHomeworkError implements Exception {
  NativeHomeworkError(this.code);
  final String code;
}

class NativeHomeworkTarget {
  const NativeHomeworkTarget(this.childId, this.assignmentId, this.itemId);
  final String childId, assignmentId, itemId;
  String get path =>
      '/api/mobile/parent/children/$childId/homework/$assignmentId/board/$itemId';
}

/// Uses the app's authenticated Dio client. Credentials never enter the WebView.
class NativeHomeworkApi {
  NativeHomeworkApi(this.dio);
  final Dio dio;
  Options get _writeOptions =>
      Options(headers: {'Origin': Uri.parse(dio.options.baseUrl).origin});
  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (error) {
      final body = error.response?.data;
      throw NativeHomeworkError(
        body is Map ? '${body['code'] ?? 'unavailable'}' : 'unavailable',
      );
    }
  }

  Future<Map<String, dynamic>> open(NativeHomeworkTarget target) async {
    final response = await _request(
      () => dio.get(target.path, queryParameters: {'native': '1'}),
    );
    final body = response.data;
    if (body is! Map || body['board'] is! Map) {
      throw NativeHomeworkError('invalid');
    }
    return Map<String, dynamic>.from(body['board'] as Map);
  }

  Options _proof(String actorUserId, int sessionVersion) => Options(
    headers: {
      ...?_writeOptions.headers,
      'X-Drive-Actor': actorUserId,
      'X-Drive-Session': '$sessionVersion',
    },
  );
  Future<Map<String, dynamic>> save(
    NativeHomeworkTarget target,
    Map<String, dynamic> command, {
    required String actorUserId,
    required int sessionVersion,
  }) async {
    final response = await _request(
      () => dio.put(
        target.path,
        queryParameters: {'native': '1'},
        data: command,
        options: _proof(actorUserId, sessionVersion),
      ),
    );
    final body = response.data;
    if (body is! Map || body['receipt'] is! Map) {
      throw NativeHomeworkError('invalid');
    }
    final receipt = Map<String, dynamic>.from(body['receipt'] as Map);
    if (receipt['operationId'] != command['operationId'] ||
        receipt['generation'] != command['generation'] ||
        receipt['actorUserId'] != actorUserId) {
      throw NativeHomeworkError('invalid');
    }
    if (!['cloud', 'server-durable'].contains(receipt['level'])) {
      throw NativeHomeworkError('${receipt['error'] ?? 'conflict'}');
    }
    return receipt;
  }

  Future<void> waitCloud(
    NativeHomeworkTarget target,
    String operationId,
  ) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      final response = await _request(
        () => dio.get(
          target.path,
          queryParameters: {'native': '1', 'operationId': operationId},
        ),
      );
      final data = response.data,
          receipt = data is Map ? data['receipt'] : null;
      if (receipt is Map &&
          receipt['operationId'] == operationId &&
          receipt['level'] == 'cloud') {
        return;
      }
      if (receipt is Map && ['conflict', 'failed'].contains(receipt['level'])) {
        throw NativeHomeworkError('${receipt['error'] ?? 'conflict'}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw NativeHomeworkError('unavailable');
  }

  Future<String> image(NativeHomeworkTarget target, String imageId) async {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(imageId)) {
      throw NativeHomeworkError('invalid');
    }
    final response = await dio.get<List<int>>(
      target.path,
      queryParameters: {'native': '1', 'image': imageId},
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data!,
        mime = response.headers.value('content-type')?.split(';').first;
    if (bytes.length > 4 * 1024 * 1024 ||
        !['image/png', 'image/jpeg', 'image/webp'].contains(mime)) {
      throw NativeHomeworkError('invalid');
    }
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<String> upload(
    NativeHomeworkTarget target,
    List<int> bytes,
    String mime, {
    required String actorUserId,
    required int sessionVersion,
  }) async {
    if (bytes.length > 4 * 1024 * 1024) throw NativeHomeworkError('size');
    final response = await _request(
      () => dio.post(
        target.path,
        queryParameters: {'native': '1', 'upload': '1'},
        data: Uint8List.fromList(bytes),
        options: Options(
          headers: _proof(actorUserId, sessionVersion).headers,
          contentType: mime,
        ),
      ),
    );
    final body = response.data, id = body is Map ? body['imageId'] : null;
    if (id is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
      throw NativeHomeworkError('invalid');
    }
    for (var count = 0; count < 40; count++) {
      final ready = await _request(
        () => dio.get(
          target.path,
          queryParameters: {'native': '1', 'image': id, 'status': '1'},
        ),
      );
      if (ready.data is Map && ready.data['ready'] == true) return id;
      if (ready.data is Map && ready.data['rejected'] == true) {
        throw NativeHomeworkError('rejected');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw NativeHomeworkError('unavailable');
  }
}
