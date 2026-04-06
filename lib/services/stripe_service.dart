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
          'StripeService: Принудительное обновление сессии перед оплатой...');
      // ГАРАНТИЯ СВЕЖЕГО JWT: Обновляем сессию прямо перед вызовом Edge Function
      final authResponse = await _supabase.auth.refreshSession();
      final session = authResponse.session;
      if (session == null) {
        throw 'Сессия не найдена. Пожалуйста, войдите в аккаунт заново.';
      }
      debugPrint(
          'StripeService: JWT обновлен, вызываем функцию для бота $botId...');
      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'plan': plan,
          // Формируем URL без решеток (Path Strategy)
          'successUrl': 'https://app.dokki.org/payment-success/$botId',
          'cancelUrl': 'https://app.dokki.org/payment-cancel',
        },
      );
      if (response.status == 200 || response.status == 201) {
        final String? stripeRedirectUrl = response.data['url'];
        if (stripeRedirectUrl != null && stripeRedirectUrl.startsWith('http')) {
          final uri = Uri.parse(stripeRedirectUrl);
          // Кроссплатформенный вызов:
          // webOnlyWindowName: '_self' откроет ссылку в той же вкладке для Web (замена dart:js)
          // mode: LaunchMode.externalApplication откроет браузер для мобилок
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_self',
          );
          if (!launched) throw 'Не удалось открыть страницу оплаты';
        } else {
          throw 'Ошибка: Stripe не вернул ссылку на оплату';
        }
      } else {
        final errorMsg =
            response.data?['error'] ?? 'Ошибка сервера ${response.status}';
        throw errorMsg;
      }
    } catch (e) {
      debugPrint('StripeService Error: $e');
      rethrow;
    }
  }
}
