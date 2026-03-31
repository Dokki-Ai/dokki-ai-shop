import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bot_management/domain/business.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onManage;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    // Статус: если botId не пуст — Активен, иначе — Настройка
    final bool isConfigured = business.botId.isNotEmpty;

    // ЗАДАЧА 35: Увеличиваем высоту со 160 до 170
    const double cardHeight = 170.0;

    return GestureDetector(
      onTap: onManage,
      child: Container(
        height: cardHeight,
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
            // Левый блок: Изображение бота
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: cardHeight, // Теперь 170
                height: cardHeight, // Теперь 170
                child: CachedNetworkImage(
                  imageUrl: business.imageUrl ?? '',
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

            // Правый блок: Контент
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Название (1 строка)
                    Text(
                      business.businessName.isNotEmpty
                          ? business.businessName
                          : business.botName,
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

                    // 2. Описание (2 строки)
                    Text(
                      business.botDescription,
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

                    // 3. Статус Row
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConfigured ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConfigured ? 'Активен' : 'Настройка',
                          style: TextStyle(
                            color: isConfigured ? Colors.green : Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),

                    // 4. Кнопка
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onManage,
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
                          'УПРАВЛЕНИЕ',
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
