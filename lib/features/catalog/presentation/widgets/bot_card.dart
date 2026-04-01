import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  // --- НАДЕЖНЫЙ СБОРЩИК URL (Задача 66) ---
  String _getFinalUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';

    // Если в БД уже лежит полная ссылка
    if (rawPath.startsWith('http')) {
      return rawPath.contains('?') ? '$rawPath&v=1.0.2' : '$rawPath?v=1.0.2';
    }

    // Извлекаем только имя файла (например, 'sales.png')
    final fileName = rawPath.split('/').last;

    // Твой эндпоинт Supabase Storage
    const baseUrl =
        'https://clpksrqstnywmrvvzwxu.supabase.co/storage/v1/object/public/bot-images/shop/';

    return '$baseUrl$fileName?v=1.0.2';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: onConnect,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 4),
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
          width: 150, // Немного уменьшил для баланса
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

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: BoxFit.contain, // contain лучше для прозрачных PNG
      alignment: Alignment.center,
      placeholder: (context, url) => Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
      ),
      errorWidget: (context, url, error) {
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
            fontSize: 17,
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
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          s.catDetails.toUpperCase(),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
