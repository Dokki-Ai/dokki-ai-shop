import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/catalog_providers.dart';
import '../widgets/bot_card.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botsAsync = ref.watch(botsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Каталог ИИ-ботов'),
        centerTitle: false,
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
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (bots) {
          if (bots.isEmpty) {
            return const Center(
              child: Text(
                'Список пуст',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: bots.length,
            itemBuilder: (context, index) {
              final bot = bots[index];

              return BotCard(
                bot: bot,
                // ИСПРАВЛЕНО: возвращен параметр onConnect
                onConnect: () =>
                    context.push('/bot-detail/${bot.id}', extra: bot),
              );
            },
          );
        },
      ),
    );
  }
}
