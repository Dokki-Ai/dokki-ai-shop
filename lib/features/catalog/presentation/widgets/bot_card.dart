import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/language_provider.dart';
import '../../domain/bot.dart';

class BotCard extends ConsumerWidget {
  final Bot bot;
  final VoidCallback onConnect;

  const BotCard({
    super.key,
    required this.bot,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ЗАДАЧА 35: Увеличиваем высоту со 160 до 170, чтобы убрать overflow
    const double cardHeight = 170.0;
    final s = ref.watch(stringsProvider);

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
            // Левый блок (Изображение)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: cardHeight, // Теперь 170
                height: cardHeight, // Теперь 170
                child: CachedNetworkImage(
                  imageUrl: bot.imageUrl ?? '',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (context, url) => Container(
                    color: AppColors.background,
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.background,
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Правый блок (Контент)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Название
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

                    // 2. Описание (строго 2 строки)
                    Text(
                      bot.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 3. Цена
                    Text(
                      'from \$${(bot.priceMonthly ?? 0).toStringAsFixed(0)}/${s.payMonth}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),

                    // 4. Кнопка (Spacer вытолкнет её вниз в рамках новой высоты 170)
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'ПОДКЛЮЧИТЬ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
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
}
