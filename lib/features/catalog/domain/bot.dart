import '../../../core/localization/app_strings.dart';
import 'package:flutter/foundation.dart';

class Bot {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final String _categoryKey;
  final String tier;
  final String? imageUrl;

  final String descriptionRu;
  final String descriptionEn;
  final String? descriptionAr;
  final List<String> featuresRu;
  final List<String> featuresEn;

  final String? githubRepo;
  final double? priceMonthly;
  final double? priceYearly;

  Bot({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required String category,
    required this.tier,
    this.imageUrl,
    required this.descriptionRu,
    required this.descriptionEn,
    this.descriptionAr,
    required this.featuresRu,
    required this.featuresEn,
    this.githubRepo,
    this.priceMonthly,
    this.priceYearly,
  }) : _categoryKey = category;

  String get category => AppStrings.mapCategory(_categoryKey);
  String get categoryKey => _categoryKey;

  factory Bot.fromJson(Map<String, dynamic> json) {
    // ✅ ИСПРАВЛЕНО: Используем правильное имя колонки из Supabase
    final String rawCategory = json['category_key'] as String? ?? 'general';

    debugPrint(
        '🤖 ПАРСИНГ: ${json['name']} | Key из БД: ${json['category_key']} -> Итог: $rawCategory');

    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortDescription: json['specialization'] as String? ?? '',
      category: rawCategory,
      tier: json['tier'] as String? ?? 'basic',
      imageUrl: json['image_url'] as String?,
      descriptionRu: json['description_ru'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      featuresRu: List<String>.from(json['features_ru'] ?? []),
      featuresEn: List<String>.from(json['features_en'] ?? []),
      githubRepo: json['github_repo'] as String?,
      priceMonthly: (json['price_monthly'] as num?)?.toDouble(),
      priceYearly: (json['price_yearly'] as num?)?.toDouble(),
    );
  }

  String getLocalizedDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return descriptionRu.isNotEmpty ? descriptionRu : description;
      case AppLanguage.ar:
        return descriptionAr ?? description;
      case AppLanguage.en:
        return descriptionEn.isNotEmpty ? descriptionEn : description;
    }
  }

  List<String> getLocalizedFeatures(AppLanguage language) {
    return language == AppLanguage.ru ? featuresRu : featuresEn;
  }
}
