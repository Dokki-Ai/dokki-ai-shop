import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BotPromptRepository {
  /// Обновление системного промпта (инструкций ИИ)
  /// [botUrl] — URL инстанса бота
  /// [businessId] — UUID бизнеса (botId)
  Future<bool> updateSystemPrompt({
    required String botUrl,
    required String businessId,
    required String systemPrompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$botUrl/api/config/prompt/$businessId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'systemPrompt': systemPrompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        debugPrint('Update Prompt Error: Status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Update Prompt Exception: $e');
      return false;
    }
  }
}

final botPromptRepositoryProvider = Provider((ref) => BotPromptRepository());
