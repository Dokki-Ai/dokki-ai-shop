import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StripeService {
  final _supabase = Supabase.instance.client;

  // Актуальный Price ID из Stripe
  static const String priceId = 'price_1THeDO1nVM8AbdfCUeaylULL';

  /// Создает сессию оплаты и запоминает, какого бота мы покупаем
  Future<void> createCheckoutSession({required String botId}) async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      debugPrint('StripeService: No active Supabase session');
      throw 'User not authenticated';
    }

    try {
      // 💾 ШАГ 1: Сохраняем botId локально ДО редиректа
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_bot_id', botId);
      debugPrint('StripeService: Saved pending_bot_id: $botId');

      debugPrint('StripeService: Initiating checkout session...');

      // ШАГ 2: Запрашиваем сессию у Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'successUrl': 'https://app.dokki.org/payment-success',
          'cancelUrl': 'https://app.dokki.org/payment-cancel',
        },
      );

      if (response.status == 200 || response.status == 201) {
        final String? stripeRedirectUrl = response.data['url'];

        if (stripeRedirectUrl != null && stripeRedirectUrl.startsWith('http')) {
          final uri = Uri.parse(stripeRedirectUrl);

          // Открываем Stripe во внешнем браузере
          final launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) throw 'Could not launch payment URL';
        } else {
          throw 'Server returned invalid checkout URL';
        }
      } else {
        throw response.data?['error'] ?? 'Server error ${response.status}';
      }
    } catch (e) {
      debugPrint('StripeService Exception: $e');
      rethrow;
    }
  }
}
