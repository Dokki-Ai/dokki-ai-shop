import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../providers/catalog_providers.dart';
import '../widgets/bot_card.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botsAsync = ref.watch(botsProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          s.navShop,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: botsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Ошибка: $err',
            style: const TextStyle(
              color: AppColors.error,
              fontFamily: 'Inter',
            ),
          ),
        ),
        data: (bots) {
          if (bots.isEmpty) {
            return Center(
              child: Text(
                s.catEmpty,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Адаптивная логика колонок
              final int crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;

              // Если экран узкий (мобилка), оставляем привычный отступ 16,
              // на широких экранах увеличиваем для эстетики.
              final double horizontalPadding =
                  constraints.maxWidth > 600 ? 24.0 : 16.0;

              return GridView.builder(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  // Для 1 колонки делаем карточку вытянутой (как раньше),
                  // для сетки — ближе к квадрату.
                  childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: bots.length,
                itemBuilder: (context, index) {
                  final bot = bots[index];
                  return BotCard(
                    bot: bot,
                    isGridMode: crossAxisCount > 1, // Передаем флаг режима
                    onConnect: () => context.push(
                      '/bot-config/${bot.id}/${bot.name}/${bot.categoryKey}',
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
