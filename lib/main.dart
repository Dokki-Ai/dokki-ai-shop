import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/env/env.dart';
import 'core/localization/language_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // КРИТИЧНО для Web: ждём пока Supabase восстановит сессию из localStorage
  // Без этого _AuthNotifier подписывается на auth раньше чем он инициализирован → crash
  try {
    await Supabase.instance.client.auth.onAuthStateChange.first
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    // Timeout или ошибка — продолжаем, краша нет
    debugPrint('⚠️ Auth init timeout: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DokkiApp(),
    ),
  );
}
