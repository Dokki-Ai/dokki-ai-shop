import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isLoading = true;
  String? _error;
  String _activeBotId = 'admin_basic';

  // ЕДИНСТВЕННЫЙ ВЕРНЫЙ URL БЭКЕНДА
  final String _backendUrl = 'https://stingray-app-ewoo6.ondigitalocean.app';

  @override
  void initState() {
    super.initState();
    _handleSuccess();
  }

  Future<void> _handleSuccess() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;

      if (user == null) throw 'Пользователь не авторизован';

      // Восстанавливаем botId из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final botId = prefs.getString('pending_bot_id') ?? 'admin_basic';

      // 1. Прямой пинг бэкенда на DigitalOcean (пробуждение сервиса)
      try {
        await http
            .get(Uri.parse(_backendUrl))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('⚠️ Backend is waking up at DigitalOcean...');
      }

      // 2. Опрос Supabase (ждем вебхук от Stripe через бэкенд на DO)
      int attempts = 0;
      const maxAttempts = 8; // Даем чуть больше времени на проход вебхука

      while (attempts < maxAttempts) {
        final response = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'active')
            .maybeSingle();

        if (response != null) {
          // Активируем запись в бизнесе с динамическим botId
          await supabase.from('businesses').upsert({
            'user_id': user.id,
            'bot_id': botId,
            'status': 'active',
          }, onConflict: 'user_id, bot_id');

          // Очищаем после использования
          await prefs.remove('pending_bot_id');

          if (mounted) {
            setState(() {
              _isLoading = false;
              _activeBotId = botId;
            });
          }
          return;
        }

        attempts++;
        await Future.delayed(const Duration(seconds: 2));
      }

      throw 'Подписка активируется. Пожалуйста, подождите минуту или обновите страницу.';
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(color: AppColors.accent),
                const SizedBox(height: 32),
                const Text('Активируем подписку...',
                    style: TextStyle(color: AppColors.textPrimary)),
              ] else if (_error != null) ...[
                const Icon(Icons.access_time_rounded,
                    size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Вернуться на главную'),
                ),
              ] else ...[
                const Icon(Icons.check_circle_outline,
                    size: 100, color: Colors.green),
                const SizedBox(height: 32),
                const Text('Оплата успешна!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      // Динамическое определение категории и имени для навигации
                      final category = _activeBotId.split('_').first;
                      final botName =
                          'Dokki ${category[0].toUpperCase()}${category.substring(1)}';
                      context
                          .go('/bot-config/$_activeBotId/$botName/$category');
                    },
                    child: const Text('Перейти к настройке',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
