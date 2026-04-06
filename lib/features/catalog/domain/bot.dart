import '../../../core/localization/app_strings.dart';

class Bot {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final String shortDescriptionRu;
  final String shortDescriptionEn;
  final String shortDescriptionAr;

  final String _categoryKey;
  final String tier;
  final String? imageUrl;
  final String descriptionRu;
  final String descriptionEn;
  final String? descriptionAr;
  final List<String> featuresRu;
  final List<String> featuresEn;
  final List<String> featuresAr;
  final String? githubRepo;
  final double? priceMonthly;
  final double? priceYearly;

  Bot({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    this.shortDescriptionRu = '',
    this.shortDescriptionEn = '',
    this.shortDescriptionAr = '',
    required String category,
    required this.tier,
    this.imageUrl,
    required this.descriptionRu,
    required this.descriptionEn,
    this.descriptionAr,
    required this.featuresRu,
    required this.featuresEn,
    this.featuresAr = const [],
    this.githubRepo,
    this.priceMonthly,
    this.priceYearly,
  }) : _categoryKey = category;

  String get category => AppStrings.mapCategory(_categoryKey);
  String get categoryKey => _categoryKey;

  factory Bot.fromJson(Map<String, dynamic> json) {
    final String rawCategory = json['category_key'] as String? ?? 'general';

    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      shortDescriptionRu: json['short_description_ru'] as String? ?? '',
      shortDescriptionEn: json['short_description_en'] as String? ?? '',
      shortDescriptionAr: json['short_description_ar'] as String? ?? '',
      category: rawCategory,
      tier: json['tier'] as String? ?? 'basic',
      imageUrl: json['image_url'] as String?,
      descriptionRu: json['description_ru'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionAr: json['description_ar'] as String?,
      featuresRu: List<String>.from(json['features_ru'] ?? []),
      featuresEn: List<String>.from(json['features_en'] ?? []),
      featuresAr: List<String>.from(json['features_ar'] ?? []),
      githubRepo: json['github_repo'] as String?,
      priceMonthly: (json['price_monthly'] as num?)?.toDouble(),
      priceYearly: (json['price_yearly'] as num?)?.toDouble(),
    );
  }

  String getLocalizedShortDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return shortDescriptionRu.isNotEmpty
            ? shortDescriptionRu
            : shortDescriptionEn;
      case AppLanguage.ar:
        return shortDescriptionAr.isNotEmpty
            ? shortDescriptionAr
            : shortDescriptionEn;
      case AppLanguage.en:
        return shortDescriptionEn;
    }
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
    switch (language) {
      case AppLanguage.ru:
        return featuresRu.isNotEmpty ? featuresRu : featuresEn;
      case AppLanguage.ar:
        return featuresAr.isNotEmpty ? featuresAr : featuresEn;
      case AppLanguage.en:
        return featuresEn;
    }
  }
}
