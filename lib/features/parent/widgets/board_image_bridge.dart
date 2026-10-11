import 'dart:convert';

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
