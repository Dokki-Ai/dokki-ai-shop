import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../bot_management/providers/bot_management_providers.dart';
import '../widgets/business_card.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';

class MyBotsScreen extends ConsumerStatefulWidget {
  const MyBotsScreen({super.key});

  @override
  ConsumerState<MyBotsScreen> createState() => _MyBotsScreenState();
}

class _MyBotsScreenState extends ConsumerState<MyBotsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Регистрируем наблюдателя за жизненным циклом приложения
    WidgetsBinding.instance.addObserver(this);
    debugPrint('=== MY BOTS SCREEN: Observer Added ===');
  }

  @override
  void dispose() {
    // Обязательно удаляем наблюдателя
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Самый важный момент: когда пользователь возвращается из браузера после оплаты
    if (state == AppLifecycleState.resumed) {
      debugPrint(
          'DEBUG: App resumed, invalidating connectedBotsProvider to refresh data...');
      ref.invalidate(connectedBotsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // === ГЛОБАЛЬНЫЕ ЛОГИ ЭКРАНА ===
    debugPrint('=== MY BOTS SCREEN: build() started ===');

    final authState = ref.watch(authStateProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          s.navMyBots,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: authState.when(
        loading: () {
          debugPrint('DEBUG Auth: Loading...');
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        },
        error: (err, stack) {
          debugPrint('DEBUG Auth ERROR: $err');
          return Center(
            child: Text('Ошибка авторизации: $err',
                style: const TextStyle(color: AppColors.error)),
          );
        },
        data: (user) {
          if (user == null) {
            debugPrint('DEBUG Auth: User is NULL (Showing Locked State)');
            return _buildLockedState(context, s);
          }

          debugPrint('DEBUG Auth: User ID = ${user.id}');

          // Следим за провайдером ботов
          final connectedBotsAsync = ref.watch(connectedBotsProvider);

          return connectedBotsAsync.when(
            loading: () {
              debugPrint('DEBUG Bots Provider: Loading...');
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            },
            error: (err, stack) {
              debugPrint('DEBUG Bots Provider ERROR: $err');
              return Center(
                child: Text('Ошибка базы: $err',
                    style: const TextStyle(color: AppColors.error)),
              );
            },
            data: (businesses) {
              debugPrint(
                  'DEBUG Bots Provider DATA: Received ${businesses.length} items');

              if (businesses.isEmpty) {
                debugPrint(
                    'DEBUG Bots Provider: List is EMPTY (Showing Empty State)');
                return _buildEmptyState(context, s);
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(connectedBotsProvider.future),
                color: AppColors.accent,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final business = businesses[index];
                    debugPrint(
                        'DEBUG: Rendering Bot Card for ID: ${business.id}, Status: ${business.status}');

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: BusinessCard(
                            business: business,
                            onManage: () {
                              debugPrint(
                                  'DEBUG: Navigate decision for ${business.id}');

                              // ПРОВЕРКА: Нужна ли первичная настройка (ввод токена)
                              final needsSetup =
                                  business.telegramToken == null ||
                                      business.telegramToken!.isEmpty;

                              if (needsSetup) {
                                // Если токена нет — на экран настройки
                                context.push(
                                  '/bot-config/${business.botId}/${business.botName}/${business.botCategory}',
                                );
                              } else {
                                // Если токен есть — в панель управления
                                context.push(
                                  '/bot-management/${business.id}',
                                  extra: business,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLockedState(BuildContext context, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              s.myBotsLocked,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('DEBUG UI: Clicked Login Button');
                  context.push('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  s.authLogin.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              s.myBotsEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  debugPrint('DEBUG UI: Clicked Go to Catalog');
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  s.myBotsGoCatalog.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
