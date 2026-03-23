class Bot {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? imageUrl;
  final List<String>? features;
  final String? githubRepo;
  // Добавлено в Шаге 2
  final int? priceMonthly;
  final List<Map<String, dynamic>>? shortFeatures;

  Bot({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    this.features,
    this.githubRepo,
    // Добавлено в Шаге 2
    this.priceMonthly,
    this.shortFeatures,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList(),
      githubRepo: json['github_repo'] as String?,
      // Добавлено в Шаге 2: Маппинг новых полей
      priceMonthly: json['price_monthly'] as int?,
      shortFeatures: (json['short_features'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}
