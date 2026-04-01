import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../domain/dashboard_metrics.dart';

final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  // 1. Берем сессию. Если её нет — пользователь не залогинен.
  final session = supabase.auth.currentSession;
  final userId = session?.user.id;

  debugPrint('--- DASHBOARD DEBUG ---');
  debugPrint('User ID: $userId');

  if (userId == null) {
    debugPrint('Error: User not authenticated');
    return DashboardMetrics(
      activeBots: 0,
      totalMessages: 0,
      activeUsers: 0,
      avgResponseTime: '-',
    );
  }

  try {
    // 2. Делаем запрос к таблице businesses
    final response = await supabase
        .from('businesses')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active');

    // Принудительно приводим к List, чтобы избежать ошибок типа
    final List<dynamic> data = response as List<dynamic>;

    debugPrint('Raw Data from DB: $data');
    debugPrint('Bots Count: ${data.length}');

    return DashboardMetrics(
      activeBots: data.length,
      totalMessages: 0,
      activeUsers: 0,
      avgResponseTime: '< 2 сек',
    );
  } catch (e) {
    debugPrint('DASHBOARD ERROR: $e');
    return DashboardMetrics(
      activeBots: 0,
      totalMessages: 0,
      activeUsers: 0,
      avgResponseTime: 'Error',
    );
  }
});
