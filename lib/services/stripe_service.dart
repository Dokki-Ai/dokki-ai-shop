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
          'StripeService: Создание сессии для плана $plan (бот: $botId)...');

      // Вызываем Edge Function
      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'botId': botId,
          'plan': plan,
          // Редирект обратно на экран успеха с передачей ID бота в пути
          'successUrl': 'https://app.dokki.org/payment-success/$botId',
          'cancelUrl': 'https://app.dokki.org/',
        },
      );

      // Проверка статуса ответа
      if (response.status != 200 && response.status != 201) {
        final errorMsg =
            response.data?['error'] ?? 'Ошибка сервера ${response.status}';
        throw errorMsg;
      }

      final String? stripeRedirectUrl = response.data['url'];

      if (stripeRedirectUrl != null && stripeRedirectUrl.startsWith('http')) {
        final uri = Uri.parse(stripeRedirectUrl);

        debugPrint('StripeService: Переход на Stripe в текущей вкладке...');

        // ИСПРАВЛЕНО: _self — самый стабильный вариант для мобильных браузеров.
        // Приложение перезагрузится при возврате, но сессия восстановится в PaymentSuccessScreen.
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_self',
        );

        if (!launched) {
          throw 'Не удалось открыть страницу оплаты.';
        }
      } else {
        throw 'Ошибка: Stripe не вернул валидную ссылку на оплату';
      }
    } catch (e) {
      debugPrint('❌ StripeService Error: $e');
      rethrow;
    }
  }
}
