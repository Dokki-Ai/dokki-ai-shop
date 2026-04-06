import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String botId;

  const PaymentSuccessScreen({
    super.key,
    required this.botId,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isLoading = true;
  String? _error;

  // URL твоего бэкенда на DigitalOcean (для "прогревания" сервиса)
  final String _backendUrl = 'https://stingray-app-ewoo6.ondigitalocean.app';

  @override
  void initState() {
    super.initState();
    _handleSuccess();
  }

  Future<void> _handleSuccess() async {
    try {
      final supabase = ref.read(supabaseClientProvider);

      debugPrint('⏳ PaymentSuccess: Начинаем процесс активации...');

      // 1. ВОССТАНОВЛЕНИЕ СЕССИИ (Fix для Web)
      // Вместо refreshSession() используем получение сессии из URL,
      // так как после редиректа из Stripe в браузере может потребоваться инициализация.
      var user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('🔄 Сессия не найдена, пробуем восстановить из URL...');
        await supabase.auth.getSessionFromUrl(Uri.base);
        user = supabase.auth.currentUser;
      }

      if (user == null) {
        throw 'Пользователь не авторизован. Попробуйте войти заново.';
      }

      debugPrint('👤 Пользователь определен: ${user.id}');

      // 2. "БУДИЛЬНИК" ДЛЯ BACKEND (DigitalOcean)
      try {
        await http
            .get(Uri.parse(_backendUrl))
            .timeout(const Duration(seconds: 5));
        debugPrint('🚀 Бэкенд на DigitalOcean пинганут успешно');
      } catch (e) {
        debugPrint('⚠️ Бэкенд еще просыпается: $e');
      }

      // 3. POLLING (Цикл опроса базы данных)
      int attempts = 0;
      const maxAttempts = 15; // Ждем до 30 секунд

      while (attempts < maxAttempts) {
        debugPrint(
            '🔄 Проверка подписки в Supabase, попытка #${attempts + 1}...');

        final response = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'active')
            .maybeSingle();

        if (response != null) {
          debugPrint('💎 Подписка подтверждена вебхуком!');

          // 4. АКТИВАЦИЯ БИЗНЕСА
          await supabase.from('businesses').upsert({
            'user_id': user.id,
            'bot_id': widget.botId,
            'status': 'active',
          }, onConflict: 'user_id, bot_id');

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        attempts++;
        await Future.delayed(const Duration(seconds: 2));
      }

      throw 'Платеж обработан, но активация задерживается. Обновите страницу через минуту.';
    } catch (e) {
      debugPrint('❌ Ошибка в PaymentSuccessScreen: $e');
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
                const Text(
                  'Проверяем ваш платеж...',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Это обычно занимает несколько секунд',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ] else if (_error != null) ...[
                const Icon(Icons.access_time_rounded,
                    size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent),
                  child: const Text('Вернуться на главную',
                      style: TextStyle(color: Colors.white)),
                ),
              ] else ...[
                const Icon(Icons.check_circle_outline,
                    size: 100, color: Colors.green),
                const SizedBox(height: 32),
                const Text(
                  'Подписка активна!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      final cat = widget.botId.split('_').first;
                      final botName =
                          'Dokki ${cat[0].toUpperCase()}${cat.substring(1)}';

                      context.go('/bot-config/${widget.botId}/$botName/$cat');
                    },
                    child: const Text(
                      'Перейти к настройке бота',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
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
