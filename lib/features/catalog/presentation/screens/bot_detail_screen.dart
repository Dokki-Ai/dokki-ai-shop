import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/stripe_service.dart';
import '../../domain/bot.dart';
import '../../providers/catalog_providers.dart';

class BotDetailScreen extends ConsumerWidget {
  final String category;

  const BotDetailScreen({super.key, required this.category});

  // ФУНКЦИЯ С ДЕБАГ-ЛОГАМИ
  String _buildImageUrl(String? rawPath) {
    // ЛОГ 1: Что пришло из базы данных
    debugPrint('DEBUG _buildImageUrl input: $rawPath');

    if (rawPath == null || rawPath.isEmpty) {
      debugPrint('DEBUG _buildImageUrl: rawPath is null or empty');
      return '';
    }

    // Если путь уже является полной ссылкой
    if (rawPath.startsWith('http')) {
      final url = '$rawPath?v=1.0.5';
      debugPrint('DEBUG _buildImageUrl (direct http): $url');
      return url;
    }

    // Формируем путь к файлу.
    // ВНИМАНИЕ: Если в базе путь 'folder/image.png', split('/').last оставит только 'image.png'
    final fileName = rawPath.split('/').last;

    const baseUrl =
        'https://capqdnwuquxdeuqnohps.supabase.co/storage/v1/object/public/bot-images/';

    final fullUrl = '$baseUrl$fileName?v=1.0.5';

    // ЛОГ 2: Что получилось на выходе
    debugPrint('DEBUG _buildImageUrl output: $fullUrl');

    return fullUrl;
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
            body: Center(child: Text('Информация временно недоступна')),
          );
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
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      color: AppColors.surface,
                      child: Image.network(
                        _buildImageUrl(bot.imageUrl),
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              'DEBUG Image.network ERROR for URL: ${_buildImageUrl(bot.imageUrl)}');
                          return const Icon(Icons.smart_toy_outlined,
                              size: 64, color: AppColors.textSecondary);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
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
                          Text(
                            fullDescription,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4),
                          ),
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
                            ...features.take(4).map((feature) => Padding(
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
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
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
            child: SafeArea(
              child: Center(
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final session = ref
                              .read(supabaseClientProvider)
                              .auth
                              .currentSession;

                          if (session == null) {
                            context.push('/auth');
                            return;
                          }

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent),
                            ),
                          );

                          try {
                            // ✅ ИСПРАВЛЕНО: Передаем bot.id в сессию оплаты
                            await StripeService()
                                .createCheckoutSession(botId: bot.id);
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
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
          ),
        );
      },
    );
  }
}
