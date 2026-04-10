class Business {
  final String id;
  final String userId;
  final String botId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Основные данные бота
  final String botName;
  final String botCategory;
  final String botDescription;
  final String telegramUsername;
  final String businessName;

  // Функционал и визуал
  final List<String> features;
  final String? imageUrl;

  // Технические поля
  final String? telegramToken;
  final String? openaiKey;
  final String? telegramGroupId;
  final String? botBusinessId;
  final int? alertsTopicId;
  final String? systemPrompt;
  final String? serviceUrl;

  // Поля из каталога
  final String? specialization;
  final String? tier;

  Business({
    required this.id,
    required this.userId,
    required this.botId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.botName,
    required this.botCategory,
    required this.botDescription,
    required this.telegramUsername,
    required this.businessName,
    this.features = const [],
    this.imageUrl,
    this.telegramToken,
    this.openaiKey,
    this.telegramGroupId,
    this.botBusinessId,
    this.alertsTopicId,
    this.systemPrompt,
    this.serviceUrl,
    this.specialization,
    this.tier,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final botCatalog = json['bot_catalog'];
    String? joinedImageUrl;
    String? joinedDescription;

    if (botCatalog != null) {
      final Map<String, dynamic> catalogData = (botCatalog is List)
          ? (botCatalog.isNotEmpty ? botCatalog[0] : {})
          : botCatalog;

      joinedImageUrl = catalogData['image_url'] as String?;
      joinedDescription = catalogData['short_description'] as String?;
    }

    final dynamic featuresData = json['features'];
    List<String> parsedFeatures = [];
    if (featuresData is List) {
      parsedFeatures = featuresData.map((e) => e.toString()).toList();
    }

    return Business(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      botId: json['bot_id'] as String? ?? '',
      botName: json['bot_name'] as String? ?? '',
      botCategory: json['bot_category'] as String? ?? '',
      botDescription: (joinedDescription ??
          json['bot_description'] ??
          json['description'] ??
          '') as String,
      telegramUsername: json['telegram_username'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      imageUrl: joinedImageUrl ?? json['image_url'] as String?,
      features: parsedFeatures,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      telegramToken: json['bot_token'] as String?,
      openaiKey: json['openai_key'] as String?,
      telegramGroupId: json['telegram_group_id'] as String?,
      botBusinessId: json['bot_business_id'] as String?,
      alertsTopicId: json['alerts_topic_id'] as int?,
      systemPrompt: json['system_prompt'] as String?,
      serviceUrl: json['service_url'] as String?,
      specialization: json['specialization'] as String?,
      tier: json['tier'] as String?,
    );
  }

  Business copyWith({
    String? id,
    String? userId,
    String? botId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? botName,
    String? botCategory,
    String? botDescription,
    String? telegramUsername,
    String? businessName,
    List<String>? features,
    String? imageUrl,
    String? telegramToken,
    String? openaiKey,
    String? telegramGroupId,
    String? botBusinessId,
    int? alertsTopicId,
    String? systemPrompt,
    String? serviceUrl,
    String? specialization,
    String? tier,
  }) {
    return Business(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      botId: botId ?? this.botId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      botName: botName ?? this.botName,
      botCategory: botCategory ?? this.botCategory,
      botDescription: botDescription ?? this.botDescription,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      businessName: businessName ?? this.businessName,
      features: features ?? this.features,
      imageUrl: imageUrl ?? this.imageUrl,
      telegramToken: telegramToken ?? this.telegramToken,
      openaiKey: openaiKey ?? this.openaiKey,
      telegramGroupId: telegramGroupId ?? this.telegramGroupId,
      botBusinessId: botBusinessId ?? this.botBusinessId,
      alertsTopicId: alertsTopicId ?? this.alertsTopicId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      serviceUrl: serviceUrl ?? this.serviceUrl,
      specialization: specialization ?? this.specialization,
      tier: tier ?? this.tier,
    );
  }
}