import 'dart:convert';
import 'package:http/http.dart' as http;

class DeployService {
  // URL оркестратора на Sevalla
  static const String _baseUrl = 'https://deploy-service-vxjp9.sevalla.app';

  final http.Client _client;

  DeployService({http.Client? client}) : _client = client ?? http.Client();

  /// Деплой нового бота через оркестратор
  Future<DeployResult> deployBot({
    required String businessId,
    required String botId,
    required String botToken,
    required String businessName,
    required String welcomeMessage,
  }) async {
    final url = Uri.parse('$_baseUrl/deploy');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'businessId': businessId,
              'botId': botId,
              'botToken': botToken,
              'businessName': businessName,
              'welcomeMessage': welcomeMessage,
            }),
          )
          .timeout(const Duration(minutes: 5));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return DeployResult(
          success: true,
          url: data['url'] ?? '',
          telegramUsername: data['telegramUsername'] ?? '',
        );
      } else {
        return DeployResult(
          success: false,
          error:
              data['error'] ?? data['details']?.toString() ?? 'Unknown error',
        );
      }
    } catch (e) {
      return DeployResult(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }
}

class DeployResult {
  final bool success;
  final String url;
  final String telegramUsername;
  final String error;

  DeployResult({
    required this.success,
    this.url = '',
    this.telegramUsername = '',
    this.error = '',
  });
}
