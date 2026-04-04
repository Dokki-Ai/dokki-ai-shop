import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../domain/bot.dart';

class BotCard extends ConsumerWidget {
  final Bot bot;
  final VoidCallback onConnect;
  final bool isGridMode;

  const BotCard({
    super.key,
    required this.bot,
    required this.onConnect,
    this.isGridMode = false,
  });

  // --- ПОЛНОСТЬЮ ИСПРАВЛЕННЫЙ СБОРЩИК URL ---
  String _getFinalUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) {
      return '';
    }

    // Если в БД уже лежит полная ссылка (https://...)
    if (rawPath.startsWith('http')) {
      // Версия 1.0.4 для принудительного сброса кэша картинок
      final url =
          rawPath.contains('?') ? '$rawPath&v=1.0.4' : '$rawPath?v=1.0.4';
      debugPrint('🚀 BOT IMAGE LOAD (direct): $url');
      return url;
    }

    // Извлекаем только имя файла
    final fileName = rawPath.split('/').last;

    const baseUrl =
        'https://capqdnwuquxdeuqnohps.supabase.co/storage/v1/object/public/bot-images/';

    final finalUrl = '$baseUrl$fileName?v=1.0.4';
    debugPrint('🚀 BOT IMAGE LOAD (constructed): $finalUrl');

    return finalUrl;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: onConnect,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isGridMode ? _buildVerticalLayout(s) : _buildHorizontalLayout(s),
      ),
    );
  }

  Widget _buildVerticalLayout(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildImageWidget(),
        ),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildContent(s, isVertical: true),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(dynamic s) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          height: double.infinity,
          child: _buildImageWidget(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildContent(s, isVertical: false),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    final finalUrl = _getFinalUrl(bot.imageUrl);

    return Image.network(
      finalUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.background,
          child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('DEBUG Image.network Error on: $finalUrl');
        return Container(
          color: AppColors.background,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy_outlined,
                  color: AppColors.textSecondary, size: 40),
              SizedBox(height: 4),
              Text('No Image',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(dynamic s, {required bool isVertical}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bot.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bot.shortDescription,
          maxLines: isVertical ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.2,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'from \$${(bot.priceMonthly ?? 0).toStringAsFixed(0)}/${s.payMonth}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
        const Spacer(),
        _buildButton(s),
      ],
    );
  }

  Widget _buildButton(dynamic s) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: onConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          s.catDetails.toUpperCase(),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
