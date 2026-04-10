import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/bot.dart';

/// Провайдер для получения всех ботов из базы данных
final allBotsProvider = FutureProvider<List<Bot>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);

  // DEBUG: Проверяем состояние auth
  debugPrint('🔐 AUTH CHECK:');
  debugPrint('   currentUser: ${supabase.auth.currentUser?.id ?? 'NULL'}');
  debugPrint('   currentSession: ${supabase.auth.currentSession != null}');

  try {
    debugPrint('📡 Запрос к bot_catalog...');
    final response = await supabase
        .from('bot_catalog')
        .select('*')
        .order('price_monthly', ascending: true);
    debugPrint('✅ Ответ получен');

    final List data = response as List;

    debugPrint('🚀 [SUPABASE FETCH] Получено строк: ${data.length}');
    for (var item in data) {
      debugPrint(
          '🤖 БД: ${item['name']} | Key: ${item['category_key']} | URL: ${item['image_url']}');
    }

    return data.map((json) => Bot.fromJson(json)).toList();
  } catch (e, stack) {
    debugPrint('❌ ОШИБКА SUPABASE: $e');
    debugPrint('📚 СТЕКТРЕЙС:');
    debugPrint(stack.toString());
    rethrow;
  }
});

/// Провайдер для отображения в магазине
final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final allBots = await ref.watch(allBotsProvider.future);

  final displayBots = List<Bot>.from(allBots);

  final categoryOrder = {'admin': 1, 'sales': 2, 'support': 3};

  displayBots.sort((a, b) {
    final priorityA = categoryOrder[a.categoryKey] ?? 999;
    final priorityB = categoryOrder[b.categoryKey] ?? 999;
    return priorityA.compareTo(priorityB);
  });

  return displayBots;
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

/// Провайдер всех ботов одной категории
final botsByCategoryProvider =
    FutureProvider.family<List<Bot>, String>((ref, category) async {
  final bots = await ref.watch(allBotsProvider.future);
  final filtered = bots.where((bot) => bot.categoryKey == category).toList();

  debugPrint('🔍 ПОИСК ПО КАТЕГОРИИ [$category]: Найдено ${filtered.length}');

  return filtered;
});
