import 'package:larnes_mobile/core/api/api_client.dart';

class TrainerResultsApi {
  const TrainerResultsApi(this.client);
  final ApiClient client;
  Future<void> save(
    String trainerKey,
    Map<String, dynamic> context,
    Map<String, dynamic> result,
  ) async {
    final response = await client.dio.post(
      '/api/mobile/trainers/results',
      data: {'trainerKey': trainerKey, 'context': context, 'result': result},
    );
    if (response.statusCode != 200) throw Exception('result_save_failed');
  }
}
