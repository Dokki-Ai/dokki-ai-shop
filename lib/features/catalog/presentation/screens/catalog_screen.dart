import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/catalog_providers.dart';
import '../widgets/bot_card.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botsAsync = ref.watch(botsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        centerTitle: true,
      ),
      body: botsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Ошибка загрузки: $err'),
        ),
        data: (bots) {
          if (bots.isEmpty) {
            return const Center(
              child: Text('Нет доступных ботов'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: bots.length,
            itemBuilder: (context, index) {
              final bot = bots[index];

              return BotCard(
                bot: bot,
                onTap: () => context.push('/bot-detail/${bot.id}', extra: bot),
              );
            },
          );
        },
      ),
    );
  }
}
