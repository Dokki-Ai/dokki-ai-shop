import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  final _supabase = Supabase.instance.client;

  Future<void> createCheckoutSession({
    required String botId,
    required String plan,
  }) async {
    try {
      debugPrint(
          '🚀 StripeService: Инициализация сессии для бота $botId, план: $plan');

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'botId': botId,
          'plan': plan,
          // Ссылка на созданный выше HTML файл
          'successUrl': 'https://app.dokki.org/payment-complete.html',
          'cancelUrl': 'https://app.dokki.org/',
        },
      );

      if (response.status != 200 && response.status != 201) {
        final errorMsg =
            response.data?['error'] ?? 'Ошибка сервера: ${response.status}';
        throw errorMsg;
      }

      final String? stripeUrl = response.data['url'];

      if (stripeUrl != null && stripeUrl.startsWith('http')) {
        final uri = Uri.parse(stripeUrl);

        debugPrint(
            '🌍 StripeService: Открытие Stripe в новой вкладке (_blank)');

        // mode: LaunchMode.externalApplication + _blank гарантируют, что
        // Flutter-вкладка не уйдет в фоновый сон или перезагрузку.
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );

        if (!launched) {
          throw 'Не удалось открыть страницу оплаты. Проверьте настройки браузера.';
        }
      } else {
        throw 'Ошибка: Stripe не вернул ссылку на оплату.';
      }
    } catch (e) {
      debugPrint('❌ StripeService Error: $e');
      rethrow;
    }
  }
}
