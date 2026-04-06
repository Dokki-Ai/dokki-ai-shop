import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
// Исправленный импорт: enum AppLanguage находится в app_strings.dart
import '../core/localization/app_strings.dart';

class StripeService {
  final _supabase = Supabase.instance.client;

  /// Инициирует сессию оплаты Stripe через Edge Function Supabase.
  /// [botId] — ID бота, [plan] — ID тарифа, [currentLang] — текущий язык.
  Future<void> createCheckoutSession({
    required String botId,
    required String plan,
    required AppLanguage currentLang,
  }) async {
    try {
      debugPrint(
          '🚀 StripeService: Инициализация сессии для бота $botId, план: $plan');

      final String langCode = currentLang.name; // 'ru', 'en' или 'ar'

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'botId': botId,
          'plan': plan,
          // Пробрасываем язык в URL для локализации страницы успеха
          'successUrl':
              'https://app.dokki.org/payment-complete.html?lang=$langCode',
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
            '🌍 StripeService: Открытие Stripe в новой вкладке (_blank) для языка: $langCode');

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
