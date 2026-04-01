import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Импорты экранов
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../navigation/main_screen.dart';
import '../supabase/supabase_client.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/language_screen.dart';
import '../../features/settings/presentation/screens/notifications_screen.dart';
import '../../features/bot_management/presentation/screens/bot_management_screen.dart';
import '../../features/bot_management/presentation/screens/bot_config_screen.dart';
import '../../features/bot_management/presentation/screens/price_list_screen.dart';
import '../../features/bot_management/presentation/screens/product_edit_screen.dart';
import '../../features/catalog/presentation/screens/bot_detail_screen.dart';

// Импорты домена
import '../../features/bot_management/domain/business.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  // Слушатель состояния авторизации для обновления роутера
  final authListener = _AuthNotifier(supabase);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListener,
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final location = state.matchedLocation;

      // Список защищенных маршрутов
      final isProtectedRoute = location.startsWith('/profile') ||
          location.startsWith('/payment') ||
          location.startsWith('/bot-config') ||
          location.startsWith('/bot-management') ||
          location.startsWith('/price-list') ||
          location.startsWith('/product-edit');

      final isAuthRoute = location == '/auth';

      // Логика перенаправления
      if (!isLoggedIn && isProtectedRoute) {
        return '/auth';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Главный экран (Магазин / Dashboard)
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),

      // Авторизация
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Детали бота (принимает категорию: admin, sales, support)
      GoRoute(
        path: '/bot-details/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'admin';
          return BotDetailScreen(category: category);
        },
      ),

      // Профиль пользователя
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ProfileScreen(currentEmail: email);
        },
      ),

      // Настройки: Язык
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),

      // Настройки: Уведомления
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Экран оплаты/подписки
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentScreen(
            botId: extra['botId'] as String,
            botName: extra['botName'] as String,
            botDescription: extra['botDescription'] as String,
            priceMonthly: extra['priceMonthly'] as double,
            priceYearly: extra['priceYearly'] as double,
          );
        },
      ),

      // Первичная настройка бота
      GoRoute(
        path: '/bot-config/:botId/:botName/:botCategory',
        builder: (context, state) => BotConfigScreen(
          botId: state.pathParameters['botId']!,
          botName: state.pathParameters['botName']!,
          botCategory: state.pathParameters['botCategory']!,
        ),
      ),

      // Панель управления конкретным ботом
      GoRoute(
        path: '/bot-management/:id',
        builder: (context, state) => BotManagementScreen(
          business: state.extra as Business,
        ),
      ),

      // Список товаров (Прайс-лист)
      GoRoute(
        path: '/price-list',
        builder: (context, state) => PriceListScreen(
          business: state.extra as Business,
        ),
      ),

      // Создание или редактирование товара
      GoRoute(
        path: '/product-edit',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return ProductEditScreen(
            business: data['business'] as Business,
            product: data['product'] as Map<String, dynamic>?,
          );
        },
      ),
    ],
  );
});

/// Класс-утилита для прослушивания событий Supabase Auth
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(SupabaseClient supabase) {
    supabase.auth.onAuthStateChange.listen((data) {
      if (kDebugMode) {
        print('Router Auth Change Event: ${data.event}');
      }
      notifyListeners();
    });
  }
}
