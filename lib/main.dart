import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/env/env.dart';
import 'core/localization/language_provider.dart';
import 'app.dart';

void main() async {
  // 1. Инициализация движка Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Включаем Path URL Strategy
  usePathUrlStrategy();

  // 3. Предварительная загрузка SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 4. Инициализация Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final client = Supabase.instance.client;

  // --- ДИАГНОСТИКА: НАЧАЛО ---
  debugPrint('=== MAIN DIAGNOSTICS START ===');
  debugPrint('1. Immediately after initialize:');
  debugPrint('   currentUser: ${client.auth.currentUser?.id}');
  debugPrint('   currentSession exists: ${client.auth.currentSession != null}');

  try {
    // Ждём первое событие из потока Auth (initialSession / signedIn)
    final event = await client.auth.onAuthStateChange.first
        .timeout(const Duration(seconds: 3));

    debugPrint('2. Auth event captured: ${event.event}');
    debugPrint('   User after event: ${event.session?.user.id}');
  } catch (e) {
    debugPrint('2. Auth event error/timeout: $e');
  }

  debugPrint('3. Final check before runApp:');
  debugPrint('   currentUser: ${client.auth.currentUser?.id}');
  debugPrint('=== MAIN DIAGNOSTICS END ===');
  // --- ДИАГНОСТИКА: КОНЕЦ ---

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DokkiApp(),
    ),
  );
}
