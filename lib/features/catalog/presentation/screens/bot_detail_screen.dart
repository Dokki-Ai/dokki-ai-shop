import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bot.dart';

class BotDetailScreen extends StatelessWidget {
  final Bot bot;

  const BotDetailScreen({super.key, required this.bot});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение бота (250px)
                  _buildHeaderImage(),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название бота
                        Text(
                          bot.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Категория в виде Chip
                        Chip(
                          label: Text(
                            bot.category.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Описание
                        Text(
                          'ОПИСАНИЕ',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bot.description,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                        // Список возможностей (features)
                        if (bot.features != null &&
                            bot.features!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'ВОЗМОЖНОСТИ',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...bot.features!.map(
                              (feature) => _buildFeatureItem(context, feature)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Фиксированная нижняя панель с кнопкой
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return CachedNetworkImage(
      imageUrl: bot.imageUrl ?? '',
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 250,
        color: AppColors.border,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      errorWidget: (context, url, error) => Container(
        height: 250,
        color: AppColors.border,
        child: const Icon(Icons.smart_toy_outlined,
            size: 64, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton(
        onPressed: () => context.push('/connect-bot/${bot.id}/${bot.name}'),
        child: const Text('ПОДКЛЮЧИТЬ'),
      ),
    );
  }
}
