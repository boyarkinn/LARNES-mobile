import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'api_client.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

const _bankImageUuid =
    '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
final _bankImageUrl = RegExp(
  '^/api/trainers/content-bank/images/$_bankImageUuid/$_bankImageUuid'
  r'\?grant=[A-Za-z0-9_-]{43}$',
);

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
    String uiLocale = 'ru',
  }) async {
    return _request(
      () => _client.dio.get(
        '/api/mobile/trainers/content-bank',
        queryParameters: {
          'trainerKey': trainerKey,
          ...filters,
          'q': query,
          'page': page,
          'pageSize': 25,
        },
      ),
      uiLocale,
    );
  }

  Future<PreparedTrainerContent> prepare({
    required String trainerKey,
    required Map<String, dynamic> params,
    required String uiLocale,
  }) async {
    final body = await _request(
      () => _client.dio.post(
        '/api/mobile/trainers/content-bank/prepare',
        data: {
          'trainerKey': trainerKey,
          'params': params,
          'uiLocale': uiLocale,
        },
      ),
      uiLocale,
    );
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

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() send,
    String uiLocale,
  ) async {
    try {
      return _body((await send()).data);
    } on DioException catch (error) {
      final data = error.response?.data;
      final serverMessage = data is Map ? data['message'] : null;
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        throw Exception(serverMessage);
      }
      final offline = const {
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      }.contains(error.type);
      final message = switch (uiLocale.split('-').first) {
        'en' =>
          offline
              ? 'No connection. Check your internet and try again.'
              : 'Unable to load materials. Please try again.',
        'ar' =>
          offline
              ? 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.'
              : 'تعذر تحميل المواد. حاول مرة أخرى.',
        _ =>
          offline
              ? 'Нет соединения. Проверьте интернет и повторите.'
              : 'Не удалось загрузить материалы. Повторите попытку.',
      };
      throw Exception(message);
    }
  }

  Future<Uint8List> image(Map descriptor) async {
    final url = descriptor['url'];
    if (url is! String || _bankImageUrl.stringMatch(url) != url)
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
