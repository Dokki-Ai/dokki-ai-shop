import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/bot.dart';

class BotRepository {
  final SupabaseClient _supabase;

  BotRepository(this._supabase);

  Future<List<Bot>> getBots() async {
    print('>>> getBots called');
    try {
      final response =
          await _supabase.from('bot_catalog').select().eq('is_active', true);
      print('>>> response: $response');
      return (response as List<dynamic>)
          .map((json) => Bot.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      print('>>> Error in getBots: $e');
      print('>>> Stacktrace: $stack');
      rethrow;
    }
  }

  Future<Bot?> getBotById(String id) async {
    final response =
        await _supabase.from('bot_catalog').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Bot.fromJson(response);
  }
}
