import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business.dart';
import '../domain/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final SupabaseClient _client;

  BusinessRepositoryImpl(this._client);

  @override
  Future<List<Business>> getConnectedBots() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Пользователь не авторизован');

    final response = await _client
        .from('businesses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Business.fromJson(json)).toList();
  }

  @override
  Future<Business> connectBot({
    required String botId,
    required String botToken,
    required String railwayToken,
    required String railwayWorkspaceId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Пользователь не авторизован');

    final response = await _client
        .from('businesses')
        .insert({
          'user_id': userId,
          'bot_id': botId,
          'bot_token': botToken,
          'client_railway_token': railwayToken,
          'client_railway_workspace_id': railwayWorkspaceId,
          'status': 'pending',
        })
        .select()
        .single();

    return Business.fromJson(response);
  }

  @override
  Future<Business?> getBusinessById(String id) async {
    final response =
        await _client.from('businesses').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return Business.fromJson(response);
  }
}
