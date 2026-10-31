import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';

import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/config/app_config.dart';

/// Откуда доска в WebView берёт картинки: адрес сайта переадресует на файл.
String boardImageBase() =>
    '${AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api/boards/images';

/// Мост `boardImage`: страница отдаёт уже сжатый файл, приложение загружает его со своим входом.
/// Ответ странице — `{fileId}` или `{code}`.
Future<Map<String, String>> uploadBoardImageFromPage(
  ParentApi api,
  List<dynamic> args,
) async {
  final input = args.isNotEmpty && args.first is Map ? args.first as Map : null;
  final data = input?['data'];
  final mimeType = input?['mimeType'];
  if (data is! String || mimeType is! String) return {'code': 'invalid'};
  try {
    final fileId = await api.uploadBoardImage(
      bytes: base64Decode(data),
      mimeType: mimeType,
    );
    return {'fileId': fileId};
  } on ParentApiException catch (error) {
    return {'code': error.code ?? 'failed'};
  } catch (_) {
    return {'code': 'failed'};
  }
}

/// Native credentials stay in Dart. The server authorizes the current lesson/room on every request.
Future<Map<String, String>> lessonBoardImageFromPage({required MessengerScope scope,
  required String roomId, required Map input, required bool upload}) async {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20), sendTimeout: const Duration(seconds: 20), validateStatus: (code) => code != null && code < 600));
  final query = <String, dynamic>{'lessonSessionId': scope.lessonSessionId, 'childId': scope.childId, 'roomId': roomId};
  const path = '/api/classroom/lesson-board-images';
  try {
    final headers = await scope.authorization();
    if (upload) {
      final data = input['data'], mime = input['mimeType'];
      if (data is! String || data.length > 6 * 1024 * 1024 || !{'image/png', 'image/jpeg', 'image/webp'}.contains(mime)) return {'code': 'invalid'};
      final bytes = base64Decode(data);
      if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) return {'code': 'size'};
      final created = await dio.post(path, data: bytes, queryParameters: query,
        options: Options(headers: {...headers, 'content-type': mime}));
      if (created.statusCode != 202 || created.data is! Map || created.data['imageId'] is! String) return {'code': 'failed'};
      query['imageId'] = created.data['imageId'];
      final end = DateTime.now().add(const Duration(seconds: 60));
      while (DateTime.now().isBefore(end)) {
        final state = await dio.get(path, queryParameters: query, options: Options(headers: headers));
        if (state.statusCode != 200 || state.data is! Map || state.data['rejected'] == true) return {'code': 'failed'};
        if (state.data['ready'] == true) return {'fileId': query['imageId'] as String};
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
      return {'code': 'failed'};
    }
    final imageId = input['imageId'];
    if (imageId is! String || !RegExp(r'^[a-f0-9]{32}$').hasMatch(imageId)) return {'code': 'invalid'};
    final content = await dio.get<List<int>>(path, queryParameters: {...query, 'imageId': imageId, 'content': '1'},
      options: Options(headers: headers, responseType: ResponseType.bytes));
    final mime = content.headers.value('content-type')?.split(';').first;
    if (content.statusCode != 200 || content.data == null || content.data!.length > 4 * 1024 * 1024 || !{'image/png', 'image/jpeg', 'image/webp'}.contains(mime)) return {'code': 'failed'};
    return {'dataURL': 'data:$mime;base64,${base64Encode(content.data!)}'};
  } catch (_) { return {'code': 'failed'}; }
  finally { dio.close(force: true); }
}
