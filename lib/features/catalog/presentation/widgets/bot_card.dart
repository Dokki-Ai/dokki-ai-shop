import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../domain/bot.dart';

class BotCard extends ConsumerWidget {
  final Bot bot;
  final VoidCallback onConnect;
  final bool isGridMode; // Добавили параметр для смены лэйаута

  const BotCard({
    super.key,
    required this.bot,
    required this.onConnect,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    // В режиме сетки (isGridMode) используем Column, в обычном — Row
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

  // ВЕРТИКАЛЬНЫЙ ЛЭЙАУТ (Для десктопной сетки)
  Widget _buildVerticalLayout(dynamic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildImage(),
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

  // ГОРИЗОНТАЛЬНЫЙ ЛЭЙАУТ (Для мобильного списка - как было)
  Widget _buildHorizontalLayout(dynamic s) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: _buildImage(),
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

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: bot.imageUrl ?? '',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      placeholder: (context, url) => Container(
        color: AppColors.background,
        child: const Icon(Icons.smart_toy_outlined,
            color: AppColors.textSecondary),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.background,
        child: const Icon(Icons.smart_toy_outlined,
            color: AppColors.textSecondary),
      ),
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
          maxLines: isVertical ? 2 : 2,
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
        _buildButton(),
      ],
    );
  }

  Widget _buildButton() {
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
        child: const Text(
          'ПОДКЛЮЧИТЬ',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
