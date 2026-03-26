import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/bot.dart';

/// Провайдер для получения всех ботов из базы данных (базовый поток данных)
final allBotsProvider = FutureProvider<List<Bot>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);

  final response = await supabase
      .from('bot_catalog')
      .select()
      .order('price_monthly', ascending: true);

  return (response as List).map((json) => Bot.fromJson(json)).toList();
});

/// Провайдер для получения только базовых версий ботов (для основного каталога)
final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final allBots = await ref.watch(allBotsProvider.future);
  return allBots.where((bot) => bot.tier == 'basic').toList();
});

/// Провайдер конкретного бота по его ID
final botByIdProvider = FutureProvider.family<Bot?, String>((ref, id) async {
  final bots = await ref.watch(allBotsProvider.future);
  try {
    return bots.firstWhere((bot) => bot.id == id);
  } catch (_) {
    return null;
  }
});

/// Провайдер всех ботов одной категории (для выбора тарифов/уровней в деталях бота)
final botsByCategoryProvider =
    FutureProvider.family<List<Bot>, String>((ref, category) async {
  final bots = await ref.watch(allBotsProvider.future);
  // Используем categoryKey для точного сравнения по ключу (admin, sales, support)
  return bots.where((bot) => bot.categoryKey == category).toList();
});
