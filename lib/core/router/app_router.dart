import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../navigation/main_screen.dart';
import '../../features/bot_management/presentation/screens/connect_bot_screen.dart';
import '../../features/bot_management/presentation/screens/bot_management_screen.dart';
import '../../features/bot_management/domain/business.dart';
import '../supabase/supabase_client.dart';
// Добавленные импорты для нового роута
import '../../features/catalog/presentation/screens/bot_detail_screen.dart';
import '../../features/catalog/domain/bot.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notifier = _AuthNotifier(supabase);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/auth';
      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      // Новый роут для деталей бота
      GoRoute(
        path: '/bot-detail/:botId',
        builder: (context, state) => BotDetailScreen(bot: state.extra as Bot),
      ),
      GoRoute(
        path: '/connect-bot/:botId/:botName',
        builder: (context, state) => ConnectBotScreen(
          botId: state.pathParameters['botId']!,
          botName: state.pathParameters['botName']!,
        ),
      ),
      GoRoute(
        path: '/bot-management/:businessId',
        builder: (context, state) {
          final business = state.extra as Business;
          return BotManagementScreen(business: business);
        },
      ),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(SupabaseClient supabase) {
    supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}
