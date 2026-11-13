import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'api_client.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

class PreparedTrainerContent {
  const PreparedTrainerContent({
    required this.params,
    required this.runtimeSnapshot,
    this.audioManifest,
    this.audioManifestJson,
  });
  final Map<String, dynamic> params;
  final Map<String, dynamic> runtimeSnapshot;
  final ExerciseAudioManifest? audioManifest;
  final Map<String, dynamic>? audioManifestJson;
}

class TrainerContentBankApi {
  TrainerContentBankApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> browse({
    required String trainerKey,
    Map<String, dynamic> filters = const {},
    String query = '',
    int page = 1,
  }) async {
    final response = await _client.dio.get(
      '/api/mobile/trainers/content-bank',
      queryParameters: {
        'trainerKey': trainerKey,
        ...filters,
        'q': query,
        'page': page,
        'pageSize': 25,
      },
    );
    return _body(response.data);
  }

  Future<PreparedTrainerContent> prepare({
    required String trainerKey,
    required Map<String, dynamic> params,
    required String uiLocale,
  }) async {
    final response = await _client.dio.post(
      '/api/mobile/trainers/content-bank/prepare',
      data: {'trainerKey': trainerKey, 'params': params, 'uiLocale': uiLocale},
    );
    final body = _body(response.data);
    if (body['params'] is! Map || body['runtimeSnapshot'] is! Map)
      throw const FormatException('Invalid prepared trainer content');
    return PreparedTrainerContent(
      params: Map<String, dynamic>.from(body['params'] as Map),
      runtimeSnapshot: Map<String, dynamic>.from(
        body['runtimeSnapshot'] as Map,
      ),
      audioManifest: ExerciseAudioManifest.fromJson(body['audioManifest']),
      audioManifestJson: body['audioManifest'] is Map
          ? Map<String, dynamic>.from(body['audioManifest'] as Map)
          : null,
    );
  }

  Future<Uint8List> image(Map descriptor) async {
    final url = descriptor['url'];
    if (url is! String || !url.startsWith('/api/trainers/content-bank/images/'))
      throw const FormatException('Invalid bank image URL');
    final response = await _client.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (response.statusCode != 200 ||
        bytes == null ||
        bytes.isEmpty ||
        bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Invalid bank image');
    }
    if (descriptor['byteSize'] != bytes.length ||
        descriptor['sha256'] != sha256.convert(bytes).toString()) {
      throw const FormatException('Bank image integrity mismatch');
    }
    return Uint8List.fromList(bytes);
  }

  Map<String, dynamic> _body(Object? raw) {
    if (raw is! Map)
      throw const FormatException('Invalid content bank response');
    final body = Map<String, dynamic>.from(raw);
    if (body['status'] != 'success')
      throw Exception(body['message'] ?? 'Не удалось подготовить материалы.');
    return body;
  }
}
