import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/bot.dart';
import '../../providers/catalog_providers.dart';

class BotDetailScreen extends ConsumerWidget {
  final String category; // 'admin', 'sales', 'support'

  const BotDetailScreen({super.key, required this.category});

  // Вспомогательный метод для сборки URL из Supabase Storage
  String _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) {
      return '';
    }
    if (rawPath.startsWith('http')) {
      return '$rawPath?v=1.0.2';
    }
    final fileName = rawPath.split('/').last;
    const baseUrl =
        'https://clpksrqstnywmrvvzwxu.supabase.co/storage/v1/object/public/bot-images/shop/';
    return '$baseUrl$fileName?v=1.0.2';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(stringsProvider);
    final AppLanguage currentLang = ref.watch(languageProvider);
    final botsAsync = ref.watch(botsByCategoryProvider(category));

    return botsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Ошибка: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
      data: (List<Bot> bots) {
        if (bots.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Информация временно недоступна')),
          );
        }

        final Bot bot = bots.first;
        // Берем полное описание без сокращений
        final String fullDescription = bot.getLocalizedDescription(currentLang);
        final List<String> features = bot.getLocalizedFeatures(currentLang);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: const BackButton(color: AppColors.textPrimary),
            title: Text(
              bot.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          // Возвращаем SingleChildScrollView для прокрутки контента
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ИЗОБРАЖЕНИЕ
                Container(
                  width: double.infinity,
                  height: 200,
                  color: AppColors.surface,
                  child: CachedNetworkImage(
                    imageUrl: _buildImageUrl(bot.imageUrl),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.smart_toy_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // 2. КОНТЕНТНАЯ ЧАСТЬ
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.catDescription.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Полное описание без ограничения строк
                      Text(
                        fullDescription,
                        style: const TextStyle(
                          fontSize: 14, // Немного увеличили для читаемости
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (features.isNotEmpty) ...[
                        Text(
                          s.catFunctions.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Полный список функций
                        ...features.map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      // Отступ внизу, чтобы зафиксированная кнопка не закрывала текст
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Фиксированная кнопка
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final session =
                      ref.read(supabaseClientProvider).auth.currentSession;
                  if (session == null) {
                    context.push('/auth');
                  } else {
                    context.push(
                        '/bot-config/${bot.id}/${bot.name}/${bot.categoryKey}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  '${s.botConnect} - \$50/${s.payMonth}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
