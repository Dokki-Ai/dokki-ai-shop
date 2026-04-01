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
  final String category;

  const BotDetailScreen({super.key, required this.category});

  String _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    if (rawPath.startsWith('http')) return '$rawPath?v=1.0.2';
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
                style: const TextStyle(color: AppColors.error))),
      ),
      data: (List<Bot> bots) {
        if (bots.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Информация временно недоступна')));
        }

        final Bot bot = bots.first;
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
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Center(
            // Центрируем для Web
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 600), // Ограничиваем ширину лендинга
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ИЗОБРАЖЕНИЕ
                    Container(
                      width: double.infinity,
                      height: 250,
                      color: AppColors.surface,
                      child: CachedNetworkImage(
                        imageUrl: _buildImageUrl(bot.imageUrl),
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent)),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.smart_toy_outlined, size: 64),
                      ),
                    ),

                    // 2. КОНТЕНТНАЯ ЧАСТЬ
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.catDescription.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 13,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent),
                          ),
                          const SizedBox(height: 12),

                          // Рендерим описание абзацами
                          ...fullDescription
                              .split('\n\n')
                              .map((paragraph) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      paragraph.trim(),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textSecondary,
                                          height: 1.5),
                                    ),
                                  )),

                          const SizedBox(height: 24),
                          if (features.isNotEmpty) ...[
                            Text(
                              s.catFunctions.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent),
                            ),
                            const SizedBox(height: 16),
                            ...features.map((feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: AppColors.accent, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 120), // Место под bottomSheet
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomSheet: Container(
            width: double.infinity,
            color: AppColors.background, // Чтобы фон не просвечивал в Web
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border:
                        const Border(top: BorderSide(color: AppColors.border)),
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
                        final session = ref
                            .read(supabaseClientProvider)
                            .auth
                            .currentSession;
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
                            color: Colors.white),
                      ),
                    ),
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
