import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/bot.dart';

class BotRepository {
  final SupabaseClient _supabase;

  BotRepository(this._supabase);

  Future<List<Bot>> getBots() async {
    final response =
        await _supabase.from('bot_catalog').select().eq('is_active', true);

    return (response as List<dynamic>)
        .map((json) => Bot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Bot?> getBotById(String id) async {
    final response =
        await _supabase.from('bot_catalog').select().eq('id', id).maybeSingle();

    if (response == null) return null;

    // Лишний cast (as Map<String, dynamic>) удален,
    // так как Dart уже понимает тип после проверки на null.
    return Bot.fromJson(response);
  }
}
