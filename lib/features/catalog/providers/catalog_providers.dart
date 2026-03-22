import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/bot.dart';
import '../data/bot_repository.dart';

final botRepositoryProvider = Provider<BotRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BotRepository(supabase);
});

final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final repository = ref.watch(botRepositoryProvider);
  return repository.getBots();
});

final botByIdProvider = FutureProvider.family<Bot?, String>((ref, botId) async {
  final repository = ref.watch(botRepositoryProvider);
  return repository.getBotById(botId);
});
