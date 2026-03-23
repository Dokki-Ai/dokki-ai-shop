import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/bot.dart';

class BotCard extends StatelessWidget {
  final Bot bot;
  final VoidCallback onConnect;

  const BotCard({
    super.key,
    required this.bot,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 160.0;

    return GestureDetector(
      onTap: onConnect,
      child: Container(
        height: cardHeight,
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Row(
          children: [
            // Левый блок: Иллюстрация 160x160 с жесткой фиксацией сверху
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: cardHeight,
                height: cardHeight,
                child: CachedNetworkImage(
                  imageUrl: bot.imageUrl ?? '',
                  fit: BoxFit.cover,
                  // ИСПРАВЛЕНО: Центрируем по верху, чтобы роботы не "вылезали" снизу
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
                ),
              ),
            ),

            // Правый блок: Контент
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (bot.shortFeatures != null)
                      _buildShortFeatures(bot.shortFeatures!),
                    const SizedBox(height: 4),
                    Text(
                      '₽${bot.priceMonthly ?? 0}/мес',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Подробнее',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortFeatures(List<Map<String, dynamic>> shortFeatures) {
    const iconMap = {
      'calendar_month': Icons.calendar_month,
      'notifications': Icons.notifications,
      'cancel': Icons.cancel,
      'support_agent': Icons.support_agent,
      'trending_up': Icons.trending_up,
      'handshake': Icons.handshake,
    };

    final visibleFeatures = shortFeatures.take(3).toList();

    return Row(
      children: visibleFeatures.map((feature) {
        final iconName = feature['icon'] as String?;
        final iconData = iconMap[iconName] ?? Icons.star_outline;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(
            iconData,
            size: 22,
            color: AppColors.accent,
          ),
        );
      }).toList(),
    );
  }
}
