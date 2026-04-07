import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business.dart';
import '../domain/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final SupabaseClient _client;

  BusinessRepositoryImpl(this._client);

  @override
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
  }) async {
    final userId = _client.auth.currentUser!.id;

    try {
      final response = await _client
          .from('businesses')
          .upsert(
            {
              'user_id': userId,
              'bot_id': botId,
              'bot_token': botToken,
              'bot_name': botName,
              'bot_category': botCategory,
              'telegram_username': telegramUsername,
              'business_name': businessName,
              'openai_key': openaiKey,
              'alerts_topic_id': alertsTopicId,
              'status': 'active',
              'updated_at': DateTime.now().toIso8601String(),
              if (railwayUrl != null) 'railway_url': railwayUrl,
            },
            onConflict: 'user_id,bot_id',
          )
          .select('*, bot_catalog(image_url, short_description)')
          .single();

      return Business.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Business>> getConnectedBots() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('businesses')
        .select('*, bot_catalog(image_url, short_description)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      return Business.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<Business?> getBusinessById(String id) async {
    try {
      final response = await _client
          .from('businesses')
          .select('*, bot_catalog(image_url, short_description)')
          .eq('id', id)
          .single();

      return Business.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
