import '../../../core/localization/app_strings.dart';

class Bot {
  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final String _categoryKey;
  final String tier; // 'basic', 'plus', 'pro'
  final String? imageUrl;
  final List<String>? features;
  final String? githubRepo;
  final double? priceMonthly;
  final double? priceYearly;
  final List<Map<String, dynamic>>? shortFeatures;

  // Геттер для автоматической локализации категории через статический метод
  String get category => AppStrings.mapCategory(_categoryKey);
  String get categoryKey => _categoryKey; // Сырой ключ категории для фильтрации

  Bot({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required String category,
    required this.tier,
    this.imageUrl,
    this.features,
    this.githubRepo,
    this.priceMonthly,
    this.priceYearly,
    this.shortFeatures,
  }) : _categoryKey = category;

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortDescription: json['specialization'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      tier: json['tier'] as String? ?? 'basic',
      imageUrl: json['image_url'] as String?,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList(),
      githubRepo: json['github_repo'] as String?,
      priceMonthly: (json['price_monthly'] as num?)?.toDouble(),
      priceYearly: (json['price_yearly'] as num?)?.toDouble() ??
          ((json['price_monthly'] as num?)?.toDouble() ?? 0) * 10,
      shortFeatures: (json['short_features'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}
