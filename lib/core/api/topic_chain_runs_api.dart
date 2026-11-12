import 'package:dio/dio.dart';

/// Uses the same authenticated mobile client as parent homework.
class TopicChainRunsApi {
  TopicChainRunsApi(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> request(Map<String, dynamic> command) async {
    try {
      final response = await dio.post(
        '/api/mobile/trainers/topic-chain-runs',
        data: command,
      );
      return _reply(response.statusCode, response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return _reply(409, error.response?.data);
      }
      throw StateError('topic-chain-unavailable');
    }
  }

  Map<String, dynamic> _reply(int? statusCode, dynamic body) {
    if ((statusCode == 200 || statusCode == 409) &&
        body is Map &&
        ['ok', 'conflict'].contains(body['status']) &&
        body['run'] is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw StateError('topic-chain-unavailable');
  }
}
