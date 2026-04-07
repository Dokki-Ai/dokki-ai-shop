import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../bot_management/providers/bot_management_providers.dart';

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

  // URL бэкенда на DigitalOcean
  final String _backendUrl = 'https://stingray-app-ewoo6.ondigitalocean.app';

  @override
  void initState() {
    super.initState();
    _waitForSessionThenHandle();
  }

  Future<void> _waitForSessionThenHandle() async {
    final supabase = ref.read(supabaseClientProvider);

    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      debugPrint('✅ Сессия уже активна: ${currentUser.id}');
      _handleSuccess(currentUser);
      return;
    }

    try {
      debugPrint('🔄 Ожидание события авторизации от Supabase...');

      final authState = await supabase.auth.onAuthStateChange
          .firstWhere((data) =>
              data.event == AuthChangeEvent.initialSession ||
              data.event == AuthChangeEvent.signedIn ||
              data.event == AuthChangeEvent.tokenRefreshed)
          .timeout(const Duration(seconds: 10));

      final user = authState.session?.user;
      if (user != null) {
        debugPrint('✅ Сессия получена через событие: ${user.id}');
        _handleSuccess(user);
      } else {
        debugPrint('⚠️ Пользователь не найден после события');
        if (mounted) context.go('/auth');
      }
    } on TimeoutException {
      debugPrint('❌ Таймаут ожидания сессии (10 сек)');
      if (mounted) context.go('/auth');
    } catch (e) {
      debugPrint('❌ Ошибка при ожидании сессии: $e');
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _handleSuccess(User user) async {
    try {
      final supabase = ref.read(supabaseClientProvider);

      debugPrint('🚀 Начинаем активацию для пользователя: ${user.id}');

      // 1. "БУДИЛЬНИК" ДЛЯ BACKEND (DigitalOcean)
      try {
        await http
            .get(Uri.parse(_backendUrl))
            .timeout(const Duration(seconds: 5));
        debugPrint('✅ Бэкенд пинганут');
      } catch (e) {
        debugPrint('⚠️ Бэкенд не ответил (просыпается)');
      }

      // 2. POLLING (Цикл опроса базы данных)
      int attempts = 0;
      const maxAttempts = 15;

      while (attempts < maxAttempts) {
        debugPrint('🔄 Проверка подписки, попытка #${attempts + 1}...');

        final response = await supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'active')
            .maybeSingle();

        if (response != null) {
          debugPrint('💎 Подписка подтверждена!');

          // Подготовка данных для создания/обновления записи бизнеса
          final category =
              widget.botId.split('_').first; // sales, admin, support
          final capitalizedCategory =
              category[0].toUpperCase() + category.substring(1);
          final derivedName = 'Dokki $capitalizedCategory';

          // 3. АКТИВАЦИЯ БИЗНЕСА (Проверка существования и Upsert логика)
          final existing = await supabase
              .from('businesses')
              .select()
              .eq('user_id', user.id)
              .eq('bot_id', widget.botId)
              .maybeSingle();

          if (existing != null) {
            // Запись существует — обновляем до статуса настройки
            await supabase
                .from('businesses')
                .update({
                  'bot_name': derivedName,
                  'business_name': derivedName,
                  'bot_category': category,
                  'status': 'setup',
                })
                .eq('user_id', user.id)
                .eq('bot_id', widget.botId);
          } else {
            // Записи нет — создаём новую со статусом setup
            await supabase.from('businesses').insert({
              'user_id': user.id,
              'bot_id': widget.botId,
              'bot_name': derivedName,
              'business_name': derivedName,
              'bot_category': category,
              'status': 'setup',
            });
          }

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

      throw 'Платеж обработан, но активация задерживается. Обновите страницу позже.';
    } catch (e) {
      debugPrint('❌ Ошибка активации: $e');
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
                  'Активируем вашу подписку...',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Это займет всего несколько секунд',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ] else if (_error != null) ...[
                const Icon(Icons.access_time_rounded,
                    size: 80, color: AppColors.warning),
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
                      style: TextStyle(color: AppColors.surface)),
                ),
              ] else ...[
                const Icon(Icons.check_circle_outline,
                    size: 100, color: AppColors.success),
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
                      // Инвалидируем провайдер перед переходом, чтобы список ботов обновился
                      ref.invalidate(connectedBotsProvider);
                      context.go('/');
                    },
                    child: const Text(
                      'Перейти к списку ботов',
                      style: TextStyle(
                          color: AppColors.surface,
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
