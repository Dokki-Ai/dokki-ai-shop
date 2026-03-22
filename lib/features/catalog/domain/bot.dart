class Bot {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isActive;
  final String? githubRepo; // Добавлено поле

  const Bot({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    this.githubRepo,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      // Маппинг snake_case из БД в camelCase модели
      isActive: json['is_active'] as bool,
      githubRepo: json['github_repo'] as String?, // Маппинг нового поля
    );
  }
}
