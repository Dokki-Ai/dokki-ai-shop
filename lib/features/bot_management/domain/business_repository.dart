import 'business.dart';

abstract class BusinessRepository {
  Future<Business> connectBot({
    required String botId,
    required String botToken,
    required String botName,
    required String botCategory,
    required String telegramUsername,
    required String businessName,
    String? openaiKey,
    int? alertsTopicId,
    String? railwayUrl,
  });

  Future<List<Business>> getConnectedBots();

  Future<Business?> getBusinessById(String id);
}
