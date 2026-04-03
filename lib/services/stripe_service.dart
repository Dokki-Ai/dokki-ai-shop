import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  final _supabase = Supabase.instance.client;

  // Твой эндпоинт Edge Function
  static const String checkoutUrl =
      'https://capqdnwuquxdeuqnohps.supabase.co/functions/v1/create-checkout-session';

  // Актуальный Price ID из Stripe
  static const String priceId = 'price_1THeDO1nVM8AbdfCUeaylULL';

  Future<void> createCheckoutSession() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      debugPrint('StripeService: No active Supabase session');
      throw 'User not authenticated';
    }

    try {
      debugPrint('StripeService: Initiating checkout session...');

      final response = await http.post(
        Uri.parse(checkoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'priceId': priceId,
          // ИСПОЛЬЗУЕМ ТОЛЬКО HTTPS UNIVERSAL LINKS
          // Это исключает ошибку "Bad state: Origin..."
          'successUrl': 'https://app.dokki.org/payment-success',
          'cancelUrl': 'https://app.dokki.org/payment-cancel',
        }),
      );

      debugPrint('Stripe Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? stripeRedirectUrl = data['url'];

        if (stripeRedirectUrl != null && stripeRedirectUrl.startsWith('http')) {
          final uri = Uri.parse(stripeRedirectUrl);

          debugPrint('StripeService: Launching Stripe Checkout URL...');

          // LaunchMode.externalApplication КРИТИЧЕН.
          // Мы открываем системный браузер. Когда оплата завершится,
          // редирект на https://app.dokki.org будет перехвачен iOS/Android
          // и вернет пользователя в приложение через Universal Links.
          final launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
            throw 'Could not launch payment URL';
          }
        } else {
          debugPrint('StripeService: Received invalid URL: $stripeRedirectUrl');
          throw 'Server returned empty or invalid checkout URL';
        }
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('StripeService Error Response: ${response.body}');
        throw errorData['error'] ?? 'Server error ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('StripeService Exception: $e');
      rethrow;
    }
  }
}
