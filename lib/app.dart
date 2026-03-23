import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class DokkiApp extends ConsumerWidget {
  const DokkiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Восстановлена оригинальная инициализация роутера
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dokki Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // ИСПРАВЛЕНО: Удален darkTheme и зафиксирован светлый режим
      themeMode: ThemeMode.light,
      // Восстановлен оригинальный routerConfig
      routerConfig: router,
    );
  }
}
